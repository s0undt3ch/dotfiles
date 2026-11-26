// md: a native markdown viewer pane. Open with
//   pane.split {direction: "right", mod: "herdr-md", props: {file: "/abs/path.md"}}
// Blocks are native elements (real font sizes and colors); inline runs go
// through TextView.markdown, which inherits size and font from its parent.
//
// Annotations: the `mdh` script (next to this file) writes
// ~/.cache/herdr-md/<file-key>.json = { seq, focus, highlights: [{lines:[a,b]} | {text}, note?, color?] }.
// The viewer watches that folder, tints the matching blocks, shows notes under
// them and scrolls to `focus` whenever `seq` changes.
//
// A viewer in a remote space (hc machine) reads that machine's files: `this.on` is
// the machine (null: this Mac), and file reads, execs, the notes folder and the
// picker all go there (props().machine names it; else the tab it opened from).
// Herdr can't watch a remote folder, so a remote viewer polls stat; images and
// videos are copied here (base64 over exec) because the app only draws local files.
import { View, div, image } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState, TextView, InputState, Input } from "gpui-base";
import { props, readTextFile, watchFolder, exec, theme, settings, home, appHome, nextCommand, panes, spaces, focused, run, shared } from "herdr";
import { marked, splitChunks, capSource, refDefs, lexChunk, blocks, LEX_MAX } from "./lex.js";
import { inlineMath, splitInline, texToUnicode } from "./tex.js";
import { hash as bhash, diffBlocks, slug, labelOf, inlineRoles, footnoteBackId, alertOf, ALERTS, nextNumberMode, ordinals, gutterLabel, nextLook, nextMotion, parseCursorPref, cursorParts, LOOK_NAMES } from "./doc.js";
import { cacheFlow } from "./flow-cache.js";
import { listFiles, parseRecent, pushRecent, rank, runs, previewSource, parseConfig, layoutOf, sizeOf, within, shape, shorten } from "./picker.js";
import { VIDEO_FPS, stopped, command, tick } from "./video.js";
import { machineCandidates, STAT_SH, parseStats, CHUNK, CHUNK_SH, slices } from "./remote.js";

// Figures (display math, Mermaid) are rendered by render/render.mjs into
// .cache/r/<hash>.{svg,png}; the hash covers the source and the colors used.
const MOD = "herdr-md";
const FIG = `mods/${MOD}/.cache/r`;
function fnv(str) { let h = 0x811c9dc5; for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 0x01000193); } return (h >>> 0).toString(16); }
const isMermaid = tok => tok.type === "code" && /^mermaid\b/i.test(tok.lang || "");
const isMath = tok => tok.type === "math" || (tok.type === "code" && /^(math|latex|tex)$/i.test(tok.lang || ""));

// Body text in the person's terminal font (BerkeleyMono), falling back to Geist.
const BODY = () => settings().font_family || "Geist";
const SIZE = { body: 15, h1: 34, h2: 26, h3: 21, h4: 18, h5: 16, h6: 15 };
// MathJax lays math out in ex, at half an em: this sets display math to the body text size.
const MATH_EX = SIZE.body / 2;
const MAX_W = 960, PAD = 64, TOP = 28;
// The height assumed for a row not yet measured; a spacer() takes it too, so positions agree.
const ROW_GUESS = 40;
// Scroll animation, done natively by GPUI's transition on the content's `top`:
// a long glide for jumps (highlights, search, headings, gg/G), short for j/k and the wheel.
// A new agent note waits for the glide, fades in, then types itself out.
const GLIDE = 560, STEP = 140, NUDGE = 60;
// The help overlay's list, in the order of the key handler (keys()).
// Two columns of sections.
const HELP = [[
  ["MOVE", [["j k", "next / previous block (5j)"], ["gg G", "top / bottom"], ["{ }", "previous / next heading"],
    ["ctrl-d ctrl-u", "half page down / up"], ["ctrl-f ctrl-b", "page down / up"], ["space", "page down"], ["ctrl-e ctrl-y", "scroll a line, cursor stays"], ["zz", "center the cursor"]]],
  ["SHARE", [["V", "select blocks"], ["y", "copy the markdown source"], ["p", "pin the selection for Claude"], ["Esc", "unselect, close search, unpin"]]],
  ["FIND A FILE (ctrl-p)", [["ctrl-n ctrl-p", "next / previous (or ctrl-j ctrl-k, arrows)"], ["Enter", "open here (Backspace comes back)"],
    ["ctrl-v", "open in a split to the right"], ["ctrl-d ctrl-u", "scroll the preview"], ["Esc", "close"],
    ["cmd-shift-o", "anywhere in Herdr: a new viewer, picker open (keys.json)"]]],
], [
  ["READ", [["ctrl-p", "find a markdown file, with preview (ctrl-f: folders, ctrl-g: up a folder)"], ["o", "outline"], ["Enter", "fold a heading, follow a link, zoom a figure, play a video"], ["O", "open a video in QuickTime"], ["Backspace", "back after a link"],
    ["za zc zo", "toggle / close / open fold"], ["zM zR", "fold / unfold all"], ["] [", "next / previous change"], ["c", "clear change marks"],
    ["/", "search"], ["n N", "next / previous match or note"], ["#", "line numbers: absolute, relative, off (remembered)"],
    ["C", "cursor look: highlight, number badge, lift"], ["B", "cursor motion: blink (default), steady, pulse, grow"]]],
  ["ZOOM (Enter on a diagram or image)", [["h j k l", "pan (or drag, or scroll)"], ["+ -", "zoom in / out (or ctrl-scroll)"], ["0", "fit"], ["Esc", "close"]]],
  ["VIEWER", [["? h", "this help"], ["q", "close the viewer"]]],
]];
// Local video blocks: ![](clip.mp4) becomes a JPEG frame sequence (ffmpeg) in
// .cache/v/<hash>/, played by a nested view that swaps frames on a timer.
// Capped at the first VIDEO_MAX seconds, VIDEO_FPS frames a second, VIDEO_W px wide.
const isVideo = href => /\.(mp4|mov|m4v|webm)$/i.test(href.split(/[?#]/)[0]);
const VIDEO_MAX = 20, VIDEO_W = 720;
const clock = s => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`;

// A video block: draws the frame the viewer's clock picked (props.st, video.js).
class Video extends View {
  init(p) { this.p = p; }
  update(p) { this.p = p; }

  render(cx) {
    const { dir, meta, w, h, t, st } = this.p, n = meta.n, i = st.i, playing = st.playing && n > 0;
    const frame = i => n ? `${dir}/f${String(Math.max(0, Math.min(n - 1, i)) + 1).padStart(4, "0")}.jpg` : `${dir}/poster.jpg`;
    const pic = i => image(frame(i)).absolute().top(0).left(0).w(w).h(h);
    // Next frame at the bottom (so it decodes before it's needed), previous frame
    // under the current one (shown if the current one hasn't decoded yet).
    const shown = Math.min(meta.dur, VIDEO_MAX), cut = meta.dur > VIDEO_MAX + 0.5;
    return div().id("video").relative().w(w).h(h).rounded(8).overflow_hidden().bg("#000000")
      .child(pic(i + 1)).child(pic(i - 1)).child(pic(i))
      .child(div().absolute().left(0).bottom(0).h(3).bg(t.accent).w(n > 1 ? w * i / (n - 1) : 0))
      .child(h_flex().absolute().left(8).bottom(8).gap(8).items_center().px(8).py(1).rounded(6).bg("#000000aa").text_size(12).text_color("#ffffff")
        .child(div().child(playing ? "❚❚" : "▶"))
        .child(div().child(`${clock(i / VIDEO_FPS)} / ${clock(shown)}${cut ? " (first " + VIDEO_MAX + "s)" : ""}`)))
      .when(!playing, el => el.child(h_flex().absolute().top(0).left(0).w(w).h(h).items_center().justify_center()
        .child(h_flex().h(56).min_w(56).px(this.p.loading ? 16 : 0).rounded(28).bg("#000000aa").items_center().justify_center().text_size(this.p.loading ? 14 : 22).text_color("#ffffff")
          .child(this.p.loading ? "preparing frames…" : "▶"))));
  }
}

const MODIFIER_KEYS = ["shift", "control", "alt", "platform", "function", "capslock"];
// The app only loads images from its own folder, so local images are copied
// here first. Hidden folder: saving into it doesn't hot-reload the mod.
const CACHE = `mods/${MOD}/.cache`;
const REMOTE_POLL = 1500;   // ms between stats of a remote file
const REMOTE_HOME = {};   // machine -> promise of its $HOME
const REMOTE_IMG_MAX = 20 << 20, REMOTE_VIDEO_MAX = 32 << 20;
const NOTES = () => `${home()}/.cache/herdr-md`;
const noteKey = file => file.replace(/[^a-zA-Z0-9]+/g, "_") + ".json";
// The ctrl-p picker: recently opened files (newest first), its row height, how
// many blocks a preview renders, and how long the selection must rest before
// a file is read for the preview (so holding ctrl-n never waits on disk).
const CURSOR_PREF = () => `${NOTES()}/cursor.json`;
// The picker's options, Telescope-style (see picker.js PICK_DEFAULTS), read each time it opens.
const PICK_CONF = () => `${home()}/.config/herdr-md/picker.json`;
// The cursor's motions, run natively by .loop (no timer, no redraws). A pulse
// breathes slowly; a blink swings far past 0 and 1 so the clamped opacity spends
// most of each beat fully on or fully off, as a vim cursor does; a grow swells the
// highlight GROW px on every side and back, which needs the block's size.
const PULSE = { from: 1, to: 0.35, period: 1800, easing: "ease-in-out" };
const BLINK = { from: 5, to: -4, period: 2120, easing: "linear" };
const GROW = 3, REST = 700;
// The gutter number. The cursor's stays put: with a motion, a dim copy sits
// underneath and the accent copy on top pulses or blinks, so only its color changes.
function numLabel(i, cp, label, t) {
  const box = div().id(`num-${i}`).relative().when(Boolean(cp?.badge), el => el.px(6).mr(-6).rounded(4).bg(t.accent + "26"));
  if (!cp?.numAnim) return box.child(label);
  return box.text_color(t.dim).child(label)
    .child(animate(h_flex().justify_center().absolute().top(0).bottom(0).left(0).right(0).text_color(t.accent).child(label), cp.numAnim));
}

function animate(el, a, size) {
  if (!a) return el;
  if (a === "blink") return el.loop("opacity", BLINK);
  if (a.includes("pulse")) el = el.loop("opacity", PULSE);
  if (a.startsWith("grow") && size) {
    // .loop takes zoomed pixels, unlike .w()/.top(): size is kept zoomed for it.
    const swing = (from, to) => ({ from, to, period: PULSE.period, easing: "ease-in-out" }), g = GROW * Z();
    el = el.loop("left", swing(0, -g)).loop("top", swing(0, -g))
      .loop("width", swing(size.w, size.w + g * 2)).loop("height", swing(size.h, size.h + g * 2));
  }
  return el;
}
const PICK_ROW = 28, PV_BLOCKS = 60, PV_WAIT = 70;
const LANG = { sh: "bash", shell: "bash", zsh: "bash", console: "bash", ts: "typescript", js: "javascript", py: "python", rs: "rust", yml: "yaml", toml: "yaml", jsonc: "json" };

// on_size_change and wheel deltas report zoomed pixels; layout sizes (top, h)
// are written at zoom 1 and scaled by the app. Convert measurements back.
const Z = () => Number(settings().zoom) || 1;
// A note's text without markdown marks, for the typing animation.
const plainNote = md => md.replace(/\*\*|__|[*_`]/g, "").replace(/\[([^\]]*)\]\([^)]*\)/g, "$1");
const dirname = p => p.slice(0, p.lastIndexOf("/")) || "/";
const plain = tokens => (tokens ?? []).map(t => t.tokens ? plain(t.tokens) : t.text ?? t.raw ?? "").join("");
const isComment = tok => tok.type === "html" && /^\s*(<!--[\s\S]*?-->\s*)+$/.test(tok.raw);
// A cell's text for width estimates: like plain(), but a code span's spaces become
// non-spaces, so the whole span counts as one word (it renders as an unbreakable chip).
const solid = tokens => (tokens ?? []).map(t => t.type === "codespan" ? t.raw.replace(/^`+ ?| ?`+$/g, "").replace(/\s/g, "_")
  : t.tokens ? solid(t.tokens) : t.text ?? t.raw ?? "").join("");
const squash = s => s.replace(/\s+/g, " ").trim().toLowerCase();

export default class Md extends View {
  init(_props, cx) {
    this.file = props()?.file ?? null;
    this.blocks = []; this.error = null; this.codes = []; this.images = {}; this.figs = {}; this.videos = {}; this.videoList = []; this.born = Date.now() * 1e6; this.videoSeq = null; this.pendingVideo = null;
    this.noteAlpha = 1; this.typed = Infinity;
    this.offset = 0; this.motion = 0; this.heights = []; this.loadGen = 0; this.shown = null; this.viewH = 0; this.contentH = 0; this.colW = MAX_W - PAD * 2;
    this.notes = { highlights: [] }; this.seq = null; this.pendingFocus = null; this.aim = null;
    this.folded = new Set(); this.hidden = []; this.ord = [];
    this.labels = new Map(); this.anchors = new Map(); this.changed = new Set(); this.removed = new Map(); this.lastHashes = null;
    this.eqX = new Map(); this.inlineJobs = []; this.inlineBusy = false; this.flows = new Map();
    this.history = []; this.pendingAnchor = null; this.restore = null; this.outline = false; this.oi = 0; this.watchGen = 0;
    this.help = false; this.helpIn = 0; this.zoom = null; this.viewW = 0;
    this.query = ""; this.matches = []; this.mi = 0; this.searching = false; this.typing = false;
    // Vim-ish cursor: one rendered block is one "line". anchor !== null means visual mode.
    this.cursor = 0; this.anchor = null; this.pending = ""; this.count = ""; this.numbers = "absolute"; this.look = "highlight"; this.cmotion = "blink number"; this.resting = true; this.restAt = 0; this.restGen = 0; this.picked = null; this.src = ""; this.lines = 0;
    this.handle = cx.focus_handle();
    this.input = InputState.new({ value: "", placeholder: "Search" });
    this.input.on("change", (_e, cx) => { this.search(this.input.value()); this.aimAt(this.matches[this.mi = 0]); cx.notify(); });
    this.input.on("submit", (e, cx) => { this.step(e?.shift ? -1 : 1); cx.notify(); });
    this.input.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    // The key help's filter: / in the help, then type; Enter goes back to j/k.
    this.helpQ = ""; this.helpTyping = false;
    this.helpInput = InputState.new({ value: "", placeholder: "Search the keys (/)" });
    this.helpInput.on("change", (_e, cx) => { this.helpQ = this.helpInput.value(); this.helpY = 0; cx.notify(); });
    this.helpInput.on("submit", (_e, cx) => { this.handle.focus(); cx.notify(); });
    this.helpInput.on("focus", (_e, cx) => { this.helpTyping = true; cx.notify(); });
    this.helpInput.on("blur", (_e, cx) => { this.helpTyping = false; cx.notify(); });
    // The ctrl-p picker. pick: { query, rows, sel, top, pvY } while open.
    this.pick = null; this.pickIn = 0; this.pickList = null; this.recent = []; this.pv = null; this.pvCache = new Map(); this.pvSeq = 0; this.pvLoading = false; this.pickVis = 12;
    // Options, the folder it lists (null: the file's tree), folders-only, and a config error for the footer.
    this.popts = parseConfig(null).opts; this.pickErr = null; this.pickScope = null; this.pickFolders = false; this.pickView = null;
    this.pickInput = InputState.new({ value: "", placeholder: "Find markdown" });
    this.pickInput.on("change", (_e, cx) => { if (this.pick && this.pick.query !== this.pickInput.value()) { this.pick.query = this.pickInput.value(); this.pickNote = null; this.rerank(cx, false); } });
    this.pickInput.on("submit", (_e, cx) => this.pickOpen(cx));
    this.pickInput.on("focus", () => { this.pickTyping = true; });
    this.pickInput.on("blur", () => { this.pickTyping = false; });
    // An empty viewer (no file) can start in the picker: `mdh pick` with no viewer
    // open passes { pick: true, dir: <shell cwd> }; the cmd-shift-o key passes no dir.
    // Without one it roots at the focused terminal's folder (read now: the new
    // pane takes focus right after), else at the newest recent file's, else home.
    this.pickRoot = this.file ? null : (props()?.dir || null);
    if (!this.file && !this.pickRoot) { const f = focused(); if (f?.terminal && f.cwd) this.pickRoot = f.cwd; }
    if (!this.file && props()?.pick) cx.timer.after(30, cx => { this.openPicker(cx); cx.notify(); });
    // Where this viewer's files live. The focused tab is read now: it is the pane this
    // one split from (the new pane takes focus right after). load() and the picker wait on it.
    this.on = null; this.rhome = null;
    const p = props(), explicit = p && "machine" in p ? p.machine : undefined;
    this.ready = this.locate(machineCandidates({ explicit, focusedTab: focused()?.tab, spaces: spaces(), panes: panes(), mod: MOD }));
    this.remember(this.file);
    readTextFile(CURSOR_PREF()).catch(() => null).then(text => { const p = parseCursorPref(text); this.look = p.look; this.cmotion = p.motion; this.numbers = p.numbers; cx.notify(); });
    this.load(cx);
    this.watch(cx);
    this.watchNotes(cx);
    // "focus" also arrives when a popup over this pane closes, e.g. the leader
    // panel just before it runs pane.go. Take the keyboard only if this is still
    // the focused pane a moment later, or the keyboard stays here while focus moves on.
    cx.spawn(async cx => {
      for (;;) {
        const c = await nextCommand();
        // `mdh pick` (herdr-app do herdr-md.pick): the focused viewer opens its
        // picker; with no viewer focused, the only viewer does (and takes focus).
        if (c === "pick") {
          // Shown copies hear it (viewers in other tabs don't), so "the only one"
          // counts this tab's viewers; the one holding the keyboard is the focused one.
          const tab = focused()?.tab, mine = panes().filter(p => p.mod === MOD && p.tab === tab);
          if (this.pick) continue;
          if (this.handle.is_focused() || this.typing) this.openPicker(cx);
          else if (mine.length === 1) { run("pane.focus", { pane: mine[0].pane }); this.openPicker(cx); }
          continue;
        }
        // `herdr-md.open` after setShared("herdr-md.open", { file }): the shown tab's
        // only viewer shows that local file in place. A remote viewer ignores it.
        if (c === "open") {
          const req = shared("herdr-md.open"), tab = focused()?.tab, mine = panes().filter(p => p.mod === MOD && p.tab === tab);
          if (req?.file && mine.length === 1 && !this.on) this.navigate(req.file, null, cx, true);
          continue;
        }
        if (c !== "focus") continue;
        cx.timer.after(60, () => { if (panes().find(p => p.focused)?.mod === MOD) (this.pick ? this.pickInput : this.handle).focus(); });
      }
    });
  }

  // The machine the file is on: the first candidate that has it (all but the first only
  // matter for a restored layout), else the best guess. A remote one needs its $HOME for notes.
  async locate(cands) {
    let on = cands[0];
    if (this.file && cands.length > 1) {
      // Probe in order and stop at the first hit. A file over 1 MiB can't be read whole but exists.
      for (const m of cands) if (await readTextFile(this.file, { on: m }).then(t => t !== null, e => /exceeds/i.test(String(e)))) { on = m; break; }
    }
    this.on = on;
    await this.homeReady();
  }

  // A remote machine's $HOME, looked up until it succeeds (a failure is never cached).
  async homeReady() {
    const on = this.on;
    if (on && !this.rhome) {
      REMOTE_HOME[on] ??= exec("sh", ["-c", 'printf %s "$HOME"'], { on }).then(r => r.code === 0 && r.stdout.trim().startsWith("/") ? r.stdout.trim() : null, () => null);
      this.rhome = await REMOTE_HOME[on];
      if (!this.rhome) delete REMOTE_HOME[on];
    }
    return !on || Boolean(this.rhome);
  }

  rd(path) { return readTextFile(path, { on: this.on }); }
  ex(cmd, args) { return exec(cmd, args, { on: this.on }); }
  // Where mdh (on the file's machine) keeps annotations; `~` there.
  // Null while a remote $HOME is unknown: callers skip the read or write then.
  notesDir() { return !this.on ? NOTES() : this.rhome ? `${this.rhome}/.cache/herdr-md` : null; }
  // Shorten the home folder to ~ (not while a remote home is unknown).
  tilde(p) { const h = this.homeDir(); return h ? p.replace(h, "~") : p; }
  homeDir() { return this.on ? this.rhome ?? "" : home(); }
  // "mtime:size" of each path on the file's machine (null: missing).
  async stats(paths) {
    const r = await this.ex("sh", ["-c", STAT_SH, "stat", ...paths]).catch(() => null);
    return r?.code === 0 ? parseStats(r.stdout) : paths.map(() => null);
  }

  // Copy a remote file here, exactly: the remote side prints base64, this side decodes it.
  // Resolves false when it is missing, over `max` bytes, or the copy fails.
  async fetchRemote(abs, dest, size, max) {
    if (!(size <= max)) return false;
    try {
      if ((await exec("sh", ["-c", ': > "$1.part"', "fetch", dest])).code !== 0) return false;
      for (let off = 0; off < size; off += CHUNK) {
        const r = await this.ex("sh", ["-c", CHUNK_SH, "chunk", abs, String(off), String(CHUNK)]);
        if (r.code !== 0 || !r.stdout.trim()) return this.dropPart(dest);
        for (const part of slices(r.stdout.trim())) {
          if ((await exec("sh", ["-c", 'printf %s "$1" | base64 -d >> "$2.part"', "decode", part, dest])).code !== 0) return this.dropPart(dest);
        }
      }
      // The copy must be as long as the file was when stat'ed, or it is not a copy.
      const wc = await exec("wc", ["-c", `${dest}.part`]);
      if (parseInt(wc.stdout, 10) !== size) return this.dropPart(dest);
      return (await exec("mv", ["-f", `${dest}.part`, dest])).code === 0;
    } catch { return this.dropPart(dest); }
  }

  dropPart(dest) { exec("rm", ["-f", `${dest}.part`]).catch(() => {}); return false; }

  // Read and lex the file in bounded chunks (lex.js), pausing between them so the
  // pane never blocks. A file not on screen yet shows its first chunk at once;
  // a reload swaps the whole document in when it's done. Everything that needs
  // the whole document (change marks, agent highlights, anchors, figures) waits
  // for the last chunk. A newer load (file changed, navigated) stops this one.
  load(cx) {
    if (!this.file) return;   // the empty state (render) points at ctrl-p
    const gen = ++this.loadGen, file = this.file, codes = [];
    const stale = () => gen !== this.loadGen;
    // This load's code editors replace the old ones when its blocks go on screen.
    const adopt = () => { if (this.codes !== codes) { this.codes.forEach(c => c.release?.()); this.codes = codes; } };
    cx.spawn(async cx => {
      try {
        let text = null, cap = null;
        await this.ready;
        try { text = await this.rd(file); }
        catch (e) {
          // Herdr won't read a text file over 1 MiB: read its start instead.
          if (!/exceeds/i.test(String(e))) throw e;
          const [head, wc] = await Promise.all([this.ex("head", ["-c", String(LEX_MAX + 4096), file]), this.ex("wc", ["-l", file])]);
          if (head.code !== 0) throw e;
          text = head.stdout;
          cap = { ...capSource(text, Math.min(LEX_MAX, text.length - 4096)), total: parseInt(wc.stdout, 10) || 0 };
        }
        if (stale()) return;
        if (text === null) { this.error = this.on ? `File not found on ${this.on}` : "File not found"; return cx.notify(); }
        cap ??= capSource(text);
        const chunks = splitChunks(cap.text);
        const links = chunks.length > 1 ? refDefs(cap.text) : null;
        const fresh = this.shown !== file, tokens = [], list = [];
        for (let k = 0; k < chunks.length; k++) {
          const c = chunks[k], toks = lexChunk(c.text, links);
          this.prepare(toks, codes);
          for (const x of toks) tokens.push(x);
          for (const b of blocks(c.text, toks, c.line - 1)) list.push(b);
          if (k === chunks.length - 1) break;
          if (k === 0 && fresh) { adopt(); this.src = text; this.lines = cap.total; this.setBlocks(list.slice()); this.shown = file; cx.notify(); }
          await cx.sleep(1);
          if (stale()) { if (this.codes !== codes) codes.forEach(c => c.release?.()); return; }
        }
        if (cap.cut) list.push({ type: "notice", raw: "", from: cap.lines, to: cap.lines,
          text: `Showing the first ${cap.lines.toLocaleString()} lines of ${cap.total.toLocaleString()}: the file is too long to show whole. Open it in an editor for the rest.` });
        adopt(); this.src = text; this.lines = cap.total; this.setBlocks(list); this.shown = file;
        this.highlightAimed = false; this.applyFocus();
        await this.markChanges();
        if (stale()) return;
        if (this.pendingAnchor !== null) { this.jumpAnchor(this.pendingAnchor); this.pendingAnchor = null; }
        else if (this.restore) { this.cursor = Math.min(this.restore.cursor, this.blocks.length - 1); this.aimAt(this.cursor); this.restore = null; }
        this.reaim();
        cx.notify();
        await this.loadImages(tokens);
        cx.notify();
        await this.loadVideos(tokens, cx);
        cx.notify();
        this.figTokens = tokens; this.figSig = this.figTheme();
        await this.renderFigures(tokens);
      } catch (e) { if (!stale()) this.error = String(e); }
      cx.notify();
    });
  }

  // Put a document's blocks on screen. Keep measured heights: a reloaded block
  // whose size didn't change never reports again (on_size_change fires on new or
  // changed sizes only), and reaim() waits for every height above its target.
  setBlocks(list) {
    this.blocks = this.index(list); this.heights.length = Math.min(this.heights.length, this.blocks.length); this.error = null;
    this.blocks.forEach(b => { b.find = squash(b.type === "heading" ? plain(b.tokens) : b.raw.replace(/[*_`#>|~]+/g, " ")); });
    if ([...this.folded].some(i => this.blocks[i]?.type !== "heading")) this.folded.clear();
    this.refold(); this.search(this.query);
    this.cursor = Math.min(this.cursor, Math.max(0, this.blocks.length - 1)); this.anchor = null;
    this.resolve();
  }

  // Reload when the file changes on disk. Herdr can't watch another machine's
  // folder, so a remote file (and its notes) is polled with stat instead.
  watch(cx) {
    if (!this.file) return;
    const gen = ++this.watchGen, dir = dirname(this.file);
    cx.spawn(async cx => {
      await this.ready;
      let last = null;
      while (gen === this.watchGen) {
        if (this.on) {
          await this.homeReady();
          const file = this.file, dir = this.notesDir(), note = dir ? `${dir}/${noteKey(file)}` : file;
          const [f, n] = await this.stats([file, note]);
          if (gen !== this.watchGen) return;
          if (last?.file === file) { if (f !== last.f) this.load(cx); if (n !== last.n) this.readNotes(cx); }
          last = { file, f, n };
          await cx.sleep(f === null && n === null ? REMOTE_POLL * 4 : REMOTE_POLL);
          continue;
        }
        const changed = await watchFolder(dir);
        if (gen !== this.watchGen) return;   // navigated to another file
        // Match by name: the watcher reports resolved paths (/private/tmp/… for
        // /tmp/…, or a symlinked folder's target), which needn't equal this.file.
        const base = this.file.slice(dir.length);
        if (changed.some(p => p === this.file || p.endsWith(dir) || p.endsWith(base))) this.load(cx);
      }
    });
  }

  // Drop d2l label paragraphs (they name the block before them), number labeled
  // equations, and index heading anchors for #links.
  index(list) {
    const out = [], labels = new Map(), anchors = new Map(), refs = new Map(); let eq = 0;
    for (const b of list) {
      if (b.type !== "footnote" && b.type !== "code") for (const m of (b.raw ?? "").replace(/(`+)[\s\S]*?\1/g, "").matchAll(/\[\^([^\]\s]+)\](?!:)/g)) if (!refs.has(m[1])) refs.set(m[1], out.length);
      if (b.type === "footnote" && !labels.has(`^${b.id}`)) labels.set(`^${b.id}`, { block: out.length, title: b.id, note: b });
      const l = labelOf(b);
      if (l) {
        // A table's label names the whole table: its first row.
        let target = out.length - 1;
        while (target > 0 && (out[target].type === "trow" || out[target].type === "pline") && !out[target].first) target--;
        if (target >= 0) {
          const t = out[target];
          if (l.eq) t.eqNum = ++eq;
          labels.set(l.name, { block: target, num: t.eqNum, title: t.type === "heading" ? plain(t.tokens) : l.name.replace(/^(fig|sec|tab|eq)_/, "").replace(/_/g, " ") });
        }
        continue;
      }
      if (b.type === "heading") { let a = slug(plain(b.tokens)), k = a, n = 1; while (anchors.has(k)) k = `${a}-${n++}`; anchors.set(k, out.length); }
      out.push(b);
    }
    // Notes are numbered in the order they are first cited, as on GitHub; uncited ones come last.
    let note = 0;
    for (const [id, block] of refs) { const l = labels.get(`^${id}`); if (l) { l.ref = block; l.num = l.note.num = ++note; } }
    for (const l of labels.values()) if (l.note && l.num === undefined) l.num = l.note.num = ++note;
    this.labels = labels; this.anchors = anchors;
    return out;
  }

  // Mark blocks that are new or edited since this file was last shown (in this
  // pane, or in any viewer before: hashes are kept in ~/.cache/herdr-md/seen-*).
  async markChanges() {
    const hashes = this.blocks.map(b => bhash(b.raw.trim()));
    await this.homeReady();
    const nd = this.notesDir(), seen = nd && `${nd}/seen-${noteKey(this.file)}`;
    let prev = this.lastHashes;
    if (!prev && seen) { try { prev = JSON.parse(await this.rd(seen) ?? "null"); } catch { prev = null; } }
    const { changed, removed } = diffBlocks(prev ?? [], hashes);
    const fresh = this.lastHashes !== null;
    this.changed = changed; this.removed = removed; this.lastHashes = hashes; this.ci = -1;
    if (seen) this.ex("sh", ["-c", 'mkdir -p "$1" && printf %s "$2" > "$3"', "seen", nd, JSON.stringify(hashes), seen]).catch(() => {});
    // Glide to the first change, unless an agent highlight is taking the view.
    // (aim alone isn't enough: it stays set after any glide until the person scrolls.)
    const busy = this.highlightAimed; this.highlightAimed = false;
    if (changed.size && !busy && this.pendingAnchor === null && !this.restore) {
      const first = Math.min(...changed); this.cursor = first; this.aimAt(first);
      this.flash = `${changed.size} changed${fresh ? "" : " since you last looked"} · ] next · c clear`;
    }
  }

  stepChange(dir, cx) {
    const list = [...this.changed].sort((a, b) => a - b); if (!list.length) return;
    const after = list.filter(i => dir > 0 ? i > this.cursor : i < this.cursor);
    const i = after.length ? (dir > 0 ? after[0] : after[after.length - 1]) : (dir > 0 ? list[0] : list[list.length - 1]);
    this.cursor = i; this.aimAt(i); cx.notify();
  }

  // ---- links ----
  jumpAnchor(frag) {
    const f = decodeURIComponent(frag);
    const i = f.startsWith("label:") ? this.labels.get(f.slice(6))?.block : this.anchors.get(f) ?? this.anchors.get(slug(f));
    if (i !== undefined) { this.cursor = i; this.aimAt(i); }
  }

  follow(url, cx) {
    if (url.startsWith("#fnback:")) {
      const id = footnoteBackId(url);
      return id === null ? cx.notify() : this.footnoteBack(id, cx);
    }
    if (url.startsWith("#")) {
      this.history.push({ file: this.file, cursor: this.cursor });
      this.jumpAnchor(url.slice(1)); return cx.notify();
    }
    // Links come from untrusted documents: never hand `open` anything it could
    // run. Web and mail links go to the browser or mail app; local non-markdown
    // files are only revealed in Finder; other schemes are refused.
    if (/^(https?|mailto):/i.test(url)) { exec("open", [url]); return; }
    if (/^[a-z][a-z0-9+.-]*:/i.test(url) && !url.startsWith("file:")) { this.flash = `not opening ${url.split(":")[0]}: links`; return cx.notify(); }
    const [path, frag = null] = url.replace(/^file:\/\//, "").split("#");
    const abs = path.startsWith("/") ? path : `${dirname(this.file)}/${decodeURIComponent(path)}`.replace(/\/\.\//g, "/");
    if (/\.(md|markdown|mdx)$/i.test(abs)) this.navigate(abs, frag, cx, true);
    else if (this.on) { this.flash = `${abs.split("/").pop()} is on ${this.on}: can't show it in Finder`; cx.notify(); }
    else { exec("open", ["-R", abs]); this.flash = "shown in Finder"; cx.notify(); }
  }

  navigate(file, frag, cx, push) {
    if (push && this.file) this.history.push({ file: this.file, cursor: this.cursor });
    if (file === this.file) { if (frag) this.jumpAnchor(frag); return cx.notify(); }
    this.file = file.replace(/\/[^/]+\/\.\.\//g, "/"); this.remember(this.file);
    // Another file's heights would size its far rows, which spacers never re-measure.
    this.folded.clear(); this.offset = 0; this.motion = 0; this.cursor = 0; this.anchor = null; this.heights = [];
    this.eqX.clear(); this.flows.clear();
    this.lastHashes = null; this.changed = new Set(); this.removed = new Map(); this.seq = null; this.aim = null;
    this.pendingAnchor = frag;
    this.load(cx); this.watch(cx); this.readNotes(cx);
  }

  // A footnote's ↩: back to the reference that was followed here, else to the first one.
  footnoteBack(id, cx) {
    const h = this.history[this.history.length - 1], ref = new RegExp(`\\[\\^${id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\](?!:)`);
    if (h?.file === this.file && ref.test(this.blocks[h.cursor]?.raw ?? "")) return this.back(cx);
    const i = this.labels.get(`^${id}`)?.ref;
    if (i === undefined) return;
    this.history.push({ file: this.file, cursor: this.cursor });
    this.cursor = i; this.aimAt(i); cx.notify();
  }

  back(cx) {
    const h = this.history.pop(); if (!h) return;
    if (h.file === this.file) { this.cursor = h.cursor; this.aimAt(h.cursor); return cx.notify(); }
    this.navigate(h.file, null, cx, false); this.restore = { cursor: h.cursor };
  }

  // Runs for an empty viewer too: it starts reading notes once a file is picked.
  watchNotes(cx) {
    cx.spawn(async cx => {
      await this.ready;
      if (await this.homeReady()) await this.ex("mkdir", ["-p", this.notesDir()]).catch(() => {});
      await this.readNotes(cx);
      // A remote viewer's notes are polled by watch().
      while (!this.on) {
        await watchFolder(this.notesDir());
        await this.readNotes(cx);
      }
    });
  }

  async readNotes(cx) {
    if (!this.file) return;
    let n = null;
    await this.ready; await this.homeReady();
    const nd = this.notesDir();
    if (nd) try { n = JSON.parse(await this.rd(`${nd}/${noteKey(this.file)}`) ?? "null"); } catch {}
    this.notes = n && Array.isArray(n.highlights) ? n : { highlights: [] };
    // A video command (mdh video) has its own seq. One written before this viewer
    // opened is stale and ignored.
    const vc = n?.video;
    if (vc && vc.seq !== this.videoSeq) { this.videoSeq = vc.seq; if (vc.seq > this.born) { this.pendingVideo = vc; this.applyVideo(cx); } }
    if (n && n.seq !== this.seq) { this.seq = n.seq; this.pendingFocus = n.focus ?? (n.highlights.length ? 0 : null); this.animateNotes(cx); }
    this.resolve();
    this.applyFocus();
    cx.notify();
  }

  // Hide new notes until the glide is mostly done, fade them in, then type the
  // text out (plain while typing, markdown once complete).
  animateNotes(cx) {
    this.typingTask?.cancel(); this.noteAlpha = 0; this.typed = 0;
    const longest = Math.max(0, ...this.notes.highlights.map(h => plainNote(h.note ?? "").length));
    const step = Math.max(1, Math.ceil(longest / 50));
    cx.timer.after(GLIDE * 0.7, cx => {
      this.noteAlpha = 1; cx.notify();
      this.typingTask = cx.timer.every(22, cx => {
        this.typed += step;
        if (this.typed >= longest) { this.typed = Infinity; this.typingTask?.cancel(); }
        cx.notify();
      });
    });
  }

  // Jump to the highlight the last `mdh` call asked for, once the document is loaded.
  applyFocus() {
    if (this.pendingFocus === null || !this.blocks.length) return;
    this.aimAt(this.notes.highlights[this.pendingFocus]?.blocks?.[0]); this.pendingFocus = null; this.highlightAimed = true;
  }

  // Map each highlight to the blocks it covers: by source lines, or by quoted text.
  resolve() {
    this.marks = new Map();
    this.notes.highlights.forEach((h, k) => {
      let hit = [];
      if (Array.isArray(h.lines)) { const [a, b = a] = h.lines; hit = this.blocks.map((x, i) => x.to >= a && x.from <= b ? i : -1).filter(i => i >= 0); }
      else if (h.text) hit = this.findText(squash(h.text));
      h.blocks = hit;
      hit.forEach((i, j) => this.marks.set(i, { ...h, k, last: j === hit.length - 1 }));
    });
  }

  // The first block holding the phrase `q` (squashed). A paragraph shown line
  // by line is searched whole, and the lines the phrase touches are the hit.
  findText(q) {
    for (let i = 0; i < this.blocks.length; i++) {
      const b = this.blocks[i];
      if (b.type !== "pline") { if (squash(b.raw).includes(q)) return [i]; continue; }
      if (!b.first) continue;
      const at = squash(b.para.raw).indexOf(q); if (at < 0) continue;
      const hit = []; let pos = 0;
      for (let j = i; j < this.blocks.length && this.blocks[j].para === b.para; j++) {
        const end = pos + squash(this.blocks[j].raw).length;
        if (end > at && pos < at + q.length) hit.push(j);
        pos = end + 1;
      }
      return hit;
    }
    return [];
  }

  // Scroll so block `i` sits a little below the top, unfolding what hides it.
  // Keeps aiming while blocks settle (wrapping, images) until the person scrolls.
  aimAt(i) {
    if (i === undefined || i === null || !this.blocks[i]) return;
    if (this.hidden[i]) { for (let h = i - 1; h >= 0; h--) if (this.folded.has(h) && this.covers(h, i)) this.folded.delete(h); this.refold(); }
    this.aim = i; this.reaim();
  }

  reaim() {
    const i = this.aim;
    if (i === null || i === undefined) return;
    let y = TOP;
    for (let j = 0; j < i; j++) if (!this.hidden[j]) y += this.heights[j] ?? ROW_GUESS;
    const to = this.clamp(y - Math.min(120, this.viewH / 4));
    if (Math.abs(to - this.offset) > 2) this.motion = GLIDE;
    this.offset = to;
  }

  // Folding: a folded heading hides everything up to the next heading of the same or higher level.
  covers(h, i) {
    const d = this.blocks[h].depth;
    for (let j = h + 1; j <= i; j++) if (this.blocks[j].type === "heading" && this.blocks[j].depth <= d) return false;
    return i > h;
  }

  refold() {
    this.hidden = []; let depth = null;
    this.blocks.forEach((b, i) => {
      if (b.type === "heading" && depth !== null && b.depth <= depth) depth = null;
      this.hidden[i] = depth !== null;
      if (depth === null && b.type === "heading" && this.folded.has(i)) depth = b.depth;
    });
    this.ord = ordinals(this.hidden, this.blocks.length);
  }

  sectionSize(h) { let n = 0; for (let j = h + 1; j < this.blocks.length && this.covers(h, j); j++) n++; return n; }

  toggleFold(i) { this.folded.has(i) ? this.folded.delete(i) : this.folded.add(i); this.refold(); }

  // The heading of the section at the top of the view.
  currentHeading() {
    let y = TOP, last = null;
    for (let i = 0; i < this.blocks.length; i++) {
      if (this.hidden[i]) continue;
      if (y > this.offset + 40) break;
      if (this.blocks[i].type === "heading") last = i;
      y += this.heights[i] ?? ROW_GUESS;
    }
    return last;
  }

  // Search: whole blocks whose text contains the query (case-insensitive).
  search(q) {
    this.query = q; const s = squash(q);
    this.matches = s ? this.blocks.map((b, i) => b.find.includes(s) ? i : -1).filter(i => i >= 0) : [];
    this.mi = Math.min(this.mi, Math.max(0, this.matches.length - 1));
  }

  step(dir) {
    const n = this.matches.length; if (!n) return;
    this.mi = (this.mi + dir + n) % n; this.aimAt(this.matches[this.mi]);
  }

  openSearch(cx) { this.searching = true; this.input.focus(); cx.notify(); }

  closeSearch(cx) { this.searching = false; this.input.set_value(""); this.search(""); this.handle.focus(); cx.notify(); }

  clamp(y) { return Math.max(0, Math.min(y, Math.max(0, this.contentH - this.viewH))); }

  // The scrollbar: a press on the thumb drags it, a press on the track jumps there first.
  grabBar(e, thumbH, thumbY, cx) {
    const y = (e.local_position?.y ?? 0) / Z();
    if (y < thumbY || y > thumbY + thumbH) {
      this.aim = null; this.motion = 0;
      this.offset = this.clamp((y - thumbH / 2) * (this.contentH - this.viewH) / (this.viewH - thumbH));
    }
    this.barDrag = { y, offset: this.offset };
    this.handle.focus(); cx.notify();
  }

  dragBar(e, thumbH, cx) {
    const y = (e.local_position?.y ?? e.position.y) / Z(), d = this.barDrag;
    this.aim = null; this.motion = 0;
    this.offset = this.clamp(d.offset + (y - d.y) * (this.contentH - this.viewH) / (this.viewH - thumbH));
    cx.notify();
  }

  scrollBy(dy, cx) { this.aim = null; this.motion = NUDGE; const o = this.clamp(this.offset + dy); if (o !== this.offset) { this.offset = o; cx.notify(); } }

  // Editor states must be made outside render: build one per code block at load.
  prepare(tokens, into = this.codes) {
    const t = theme();
    marked.walkTokens(tokens, tok => {
      if (tok.type !== "code") return;
      const lang = (tok.lang || "").split(/\s/)[0].toLowerCase();
      tok.state = EditorState.new({ language: LANG[lang] ?? (lang || "text"), readonly: true, value: tok.text,
        font_family: settings().font_family, font_size: 13,
        syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 } });
      into.push(tok.state);
    });
  }

  async loadImages(tokens) {
    const srcs = [];
    marked.walkTokens(tokens, tok => { if (tok.type === "image" && !isVideo(tok.href) && !this.images[tok.href]) srcs.push(tok.href); });
    await exec("mkdir", ["-p", `${appHome()}/${CACHE}`]);
    for (const href of [...new Set(srcs)]) {
      if (/^[a-z]+:\/\//i.test(href)) { this.images[href] = { remote: true }; continue; }
      let abs = href.startsWith("/") ? href : `${dirname(this.file)}/${decodeURIComponent(href)}`;
      const ext = (abs.split(".").pop() || "png").toLowerCase();
      const name = (this.on ? this.on.replace(/[^A-Za-z0-9._-]/g, "_") + "_" : "") + abs.replace(/[^a-zA-Z0-9]+/g, "_").slice(-120) + "." + ext;
      const local = `${appHome()}/${CACHE}/${name}`;
      let ok;
      if (this.on) {   // copied over, unless the cached copy still matches the remote file
        const [sig] = await this.stats([abs]), meta = `${local}.sig`;
        const have = sig && await readTextFile(meta).catch(() => null) === sig && (await exec("test", ["-f", local])).code === 0;
        ok = Boolean(have) || (sig !== null && await this.fetchRemote(abs, local, Number(sig.split(":")[1]), REMOTE_IMG_MAX)
          && (await exec("sh", ["-c", 'printf %s "$1" > "$2"', "sig", sig, meta])).code === 0);
        abs = local;
      } else ok = (await exec("cp", ["-p", abs, local])).code === 0;
      if (!ok) { this.images[href] = { missing: true }; continue; }
      let w = 800, h = 450;
      const s = await exec("sips", ["-g", "pixelWidth", "-g", "pixelHeight", abs]);
      const mw = s.stdout.match(/pixelWidth: (\d+)/), mh = s.stdout.match(/pixelHeight: (\d+)/);
      if (mw && mh) { w = +mw[1]; h = +mh[1]; }
      this.images[href] = { path: `${CACHE}/${name}`, w, h };
    }
  }

  // Videos come from untrusted documents, and ffmpeg sniffs content, not the
  // file extension: an "x.mp4" can be an HLS or concat playlist that makes it
  // fetch URLs or read other local files into frames we'd show. So ffprobe
  // first, with only the file protocol allowed; refuse any container but
  // MP4/QuickTime (or Matroska/WebM for .webm); then decode with that format
  // forced and the same protocol whitelist. Paths reach sh as "$1"/"$2"
  // arguments, never spliced into the script.
  // On open: probe and a poster frame only. Frames are extracted on first play.
  // this.videoList is document order (mdh video N).
  async loadVideos(tokens, cx) {
    const hrefs = [];
    marked.walkTokens(tokens, tok => { if (tok.type === "image" && isVideo(tok.href)) hrefs.push(tok.href); });
    this.videoList = [...new Set(hrefs)];
    for (const href of this.videoList) {
      const v = this.videos[href] ??= {};
      if (/^[a-z][a-z0-9+.-]*:/i.test(href)) { v.remote = true; continue; }
      const src = href.startsWith("/") ? href : `${dirname(this.file)}/${decodeURIComponent(href)}`;
      let sig;
      if (this.on) {
        // ffmpeg runs here, so a remote clip is copied first (once per mtime+size).
        [sig] = await this.stats([src]);
        if (!sig) { v.missing = true; continue; }
        const local = `${appHome()}/${CACHE}/rv/${fnv(this.on + src + sig)}.${(src.split(".").pop() || "mp4").toLowerCase().replace(/[^a-z0-9]/g, "")}`;
        if ((await exec("test", ["-f", local])).code !== 0) {
          v.note = "copying from " + this.on + "…"; cx.notify();
          await exec("mkdir", ["-p", dirname(local)]);
          const got = await this.fetchRemote(src, local, Number(sig.split(":")[1]), REMOTE_VIDEO_MAX);
          v.note = null;
          if (!got) { v.error = `couldn't copy it from ${this.on} (over ${REMOTE_VIDEO_MAX >> 20} MB, or the copy failed)`; cx.notify(); continue; }
        }
        v.abs = local;
      } else {
        v.abs = src;
        const st = await exec("stat", ["-f", "%m:%z", v.abs]);
        if (st.code !== 0) { v.missing = true; continue; }
        sig = st.stdout.trim();
      }
      const key = fnv(v.abs + sig), dir = `${CACHE}/v/${key}`;
      if (v.dir === dir && v.meta) continue;
      v.dir = dir; v.absDir = `${appHome()}/${dir}`; v.meta = null; v.st = stopped(); v.missing = false; v.error = null; v.extracting = null; cx.notify();
      let meta = null;
      try { meta = JSON.parse(await readTextFile(`${v.absDir}/meta.json`) ?? "null"); } catch {}
      if (!meta) {
        const probe = await this.probeVideo(v.abs);
        if (probe.error) { v.error = probe.error; cx.notify(); continue; }
        const r = await exec("sh", ["-c", `PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"; set -e; mkdir -p "$1"
          ffmpeg -v error -y -protocol_whitelist file -f ${probe.fmt} -i "file:$2" -an -frames:v 1 -vf "scale='min(iw,${VIDEO_W})':-2" -q:v 4 "$1/poster.jpg"`,
          "video", v.absDir, v.abs]);
        if (r.code !== 0) { v.error = (r.stderr || "ffmpeg failed").trim().split("\n").pop().slice(0, 160); cx.notify(); continue; }
        meta = { n: 0, w: probe.w, h: probe.h, dur: probe.dur, fmt: probe.fmt };
      }
      v.meta = meta;
      const props = this.videoProps(v);
      if (v.entity) v.entity.set_props(props); else v.entity = cx.new(Video, props);
      this.applyVideo(cx);
      cx.notify();
    }
  }

  // ffprobe a local file: { fmt, w, h, dur } for an allowed container, else { error }.
  async probeVideo(abs) {
    if (!abs.startsWith("/")) return { error: "not a local file" };
    const r = await exec("sh", ["-c", `PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
      ffprobe -v error -protocol_whitelist file -select_streams v:0 -show_entries format=format_name,duration:stream=width,height -of json "file:$1"`, "probe", abs]);
    let j = null; try { j = JSON.parse(r.stdout); } catch {}
    if (!j) return { error: (r.stderr || "ffprobe failed (is ffmpeg installed?)").trim().split("\n").pop().slice(0, 160) };
    const name = j.format?.format_name, webm = /\.webm$/i.test(abs);
    const fmt = !webm && name === "mov,mp4,m4a,3gp,3g2,mj2" ? "mov" : webm && name === "matroska,webm" ? "matroska" : null;
    const s0 = j.streams?.[0];
    if (!fmt || !s0?.width) return { error: `not a ${webm ? "WebM" : "MP4/QuickTime"} video (${name ?? "unknown"}); refused` };
    return { fmt, w: s0.width, h: s0.height, dur: Number(j.format.duration) || 0 };
  }

  // First play: extract the frame sequence (format forced, file protocol only).
  extractFrames(v, cx) {
    if (v.extracting) return;
    v.extracting = true; v.entity?.set_props(this.videoProps(v));
    cx.spawn(async cx => {
      const m = v.meta;
      const r = await exec("sh", ["-c", `PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"; set -e; d="$1"; rm -rf "$d/f.tmp"; mkdir -p "$d/f.tmp"
        ffmpeg -v error -y -protocol_whitelist file -f ${m.fmt} -t ${VIDEO_MAX} -i "file:$2" -an -vf "fps=${VIDEO_FPS},scale='min(iw,${VIDEO_W})':-2" -q:v 4 "$d/f.tmp/f%04d.jpg"
        mv "$d/f.tmp/"*.jpg "$d/"; rmdir "$d/f.tmp"; ls "$d" | grep -c '^f[0-9]*\\.jpg$'`, "video", v.absDir, v.abs]);
      v.extracting = false;
      const n = parseInt(r.stdout, 10);
      if (r.code !== 0 || !(n > 0)) { v.error = (r.stderr || "ffmpeg failed").trim().split("\n").pop().slice(0, 160); cx.notify(); return; }
      v.meta = { ...m, n };
      exec("sh", ["-c", 'printf %s "$2" > "$1/meta.json"', "meta", v.absDir, JSON.stringify(v.meta)]);
      if (v.cmd) v.st = command(v.st, v.cmd, n, Date.now());   // the command that asked to play
      v.entity.set_props(this.videoProps(v)); cx.notify(v.entity); cx.notify();
      this.videoClock(cx);
    });
  }

  videoSize(v) {
    let w = Math.min(v.meta.w, this.colW), h = Math.round(v.meta.h * w / v.meta.w);
    if (h > 560) { w = Math.round(w * 560 / h); h = 560; }
    return { w, h };
  }

  videoProps(v) { return { dir: v.dir, meta: v.meta, ...this.videoSize(v), t: theme(), st: v.st ??= stopped(), loading: Boolean(v.extracting) }; }

  applyVideo(cx) {
    const c = this.pendingVideo; if (!c) return;
    if (this.videoCmd(c.n ?? 0, c.state, c.t, cx)) {
      this.pendingVideo = null;
      const b = this.blocks.findIndex(x => this.blockVideo(x) === (c.n ?? 0));
      if (b >= 0 && !this.onScreen(b)) { this.cursor = b; this.aimAt(b); }
    }
  }

  // Send a play/pause/seek command to video n (0-based, document order).
  videoCmd(n, state, t, cx) {
    const v = this.videos[this.videoList?.[n]]; if (!v?.entity) return false;
    v.cmd = { state, t };
    if (!v.meta.n && state !== "pause") { this.extractFrames(v, cx); return true; }
    v.st = command(v.st ?? stopped(), v.cmd, v.meta.n, Date.now());
    v.entity.set_props(this.videoProps(v)); cx.notify(v.entity);
    this.videoClock(cx);
    return true;
  }

  // One clock for every video, running only while one plays: it polls every
  // third of a frame and redraws a video only when its frame changes.
  videoClock(cx) {
    const playing = () => Object.values(this.videos).some(v => v.st?.playing && v.meta?.n);
    if (!playing()) { this.clock?.cancel(); this.clock = null; return; }
    if (this.clock) return;
    this.clock = cx.timer.every(1000 / VIDEO_FPS / 3, cx => {
      const now = Date.now();
      for (const v of Object.values(this.videos)) {
        if (!v.st?.playing || !v.entity || !v.meta?.n) continue;
        const st = tick(v.st, v.meta.n, now);
        if (st !== v.st) { v.st = st; v.entity.set_props(this.videoProps(v)); cx.notify(v.entity); }
      }
      if (!playing()) { this.clock?.cancel(); this.clock = null; }
    });
  }

  resizeVideos() { for (const v of Object.values(this.videos)) if (v.entity && v.meta) v.entity.set_props(this.videoProps(v)); }

  videoBlock(tok, t) {
    const v = this.videos[tok.href];
    const note = v?.remote ? "remote video not fetched" : v?.note ? v.note : v?.missing ? "not found" : v?.error ? `couldn't prepare: ${v.error}` : "preparing frames…";
    if (!v?.entity || !v.meta) return div().my(6).px(12).py(8).rounded(6).bg(t.surface).text_color(v?.error ? t.blocked : t.dim).text_size(13)
      .child(`▶  ${tok.text || tok.href} · ${note}`);
    const n = this.videoList.indexOf(tok.href);
    return v_flex().my(8).gap(6).items_center()
      .child(div().id(`video-${n}`).cursor_pointer().on_click((_e, cx) => this.videoCmd(n, "toggle", undefined, cx)).child(v.entity))
      .child(div().text_size(13).text_color(t.dim).italic().child(`${tok.text ? tok.text + " · " : ""}Enter plays · O opens in QuickTime`));
  }

  figKey(tok) {
    const t = theme();
    return fnv(JSON.stringify([isMath(tok) ? "m" : "d", tok.text, t.foreground, t.surface, settings().font_family, isMath(tok) ? MATH_EX : 1]));
  }

  // What figures are drawn with: a change (a theme switch) renders them again.
  figTheme() {
    const t = theme();
    return [t.foreground, t.surface, t.raised, t.background, t.ansi4, t.ansi5, t.dim, settings().font_family].join("|");
  }

  // Render every display formula and Mermaid diagram not already cached, in one
  // batch (one Chrome launch for all diagrams). A figure keeps showing its old
  // image (the last theme's) until the new one is ready, so nothing jumps.
  async renderFigures(tokens) {
    const t = theme(), font = settings().font_family || "sans-serif", jobs = [], waiting = [];
    const root = `${appHome()}/${FIG}`;
    marked.walkTokens(tokens, tok => {
      if (!isMath(tok) && !isMermaid(tok)) return;
      const key = this.figKey(tok);
      if (this.figs[key]?.path || this.figs[key]?.error || !tok.fig || !this.figs[tok.fig]?.path) tok.fig = key;
      else waiting.push([tok, key]);
      if (this.figs[key]?.path || this.figs[key]?.error || this.figs[key]?.pending) return;
      this.figs[key] = { pending: true };
      jobs.push({ kind: isMath(tok) ? "math" : "mermaid", src: tok.text, out: `${root}/${key}.${isMath(tok) ? "svg" : "png"}`, color: t.foreground, exPx: MATH_EX, font,
        colors: { fg: t.foreground, surface: t.surface, raised: t.raised, bg: t.background, blue: t.ansi4, purple: t.ansi5, dim: t.dim } });
    });
    if (!jobs.length) { for (const [tok, key] of waiting) tok.fig = key; return; }
    try {
      await exec("mkdir", ["-p", root]);
      const r = await this.runRenderer(JSON.stringify(jobs));
      if (r.code !== 0 || !r.stdout) throw new Error((r.stderr || `renderer exited ${r.code}`).trim().split("\n").pop().slice(0, 200));
      const out = JSON.parse(r.stdout);
      for (const res of out) {
        const key = res.out.split("/").pop().replace(/\.\w+$/, "");
        this.figs[key] = res.error ? { error: res.error } : { path: `${FIG}/${key}.${res.out.split(".").pop()}`, w: res.w, h: res.h };
      }
    } catch (e) { for (const j of jobs) this.figs[j.out.split("/").pop().replace(/\.\w+$/, "")] = { error: String(e) }; }
    for (const [tok, key] of waiting) tok.fig = key;
  }

  // Run the batch renderer, installing its npm packages on first use
  // (MathJax and mermaid-cli; Chrome itself is not downloaded).
  async runRenderer(jobs) {
    const dir = `${appHome()}/mods/${MOD}/render`;
    // One promise, so figures and inline formulas met together share one npm install.
    this.deps ??= (async () => {
      const has = await exec("test", ["-d", `${dir}/node_modules/mathjax-full`]);
      if (has.code !== 0) {
        const i = await exec("sh", ["-c", 'cd "$1" && PUPPETEER_SKIP_DOWNLOAD=1 npm install --no-audit --no-fund --silent', "install", dir]);
        if (i.code !== 0) throw new Error(`npm install failed (Node.js and npm are needed): ${(i.stderr || "").slice(0, 160)}`);
      }
    })();
    try { await this.deps; } catch (e) { this.deps = null; throw e; }
    return exec("node", [`${dir}/render.mjs`, jobs]);
  }

  figure(tok, id, t) {
    // A theme switch back to a look already rendered shows that image at once,
    // without waiting a frame for renderFigures to repoint tok.fig.
    if (tok.liveSig !== this.figSig) { tok.liveSig = this.figSig; tok.liveKey = this.figKey(tok); }   // hashed once per theme, not per frame
    const live = this.figs[tok.liveKey];
    const f = (live?.path ? live : this.figs[tok.fig]) ?? { pending: true }, math = isMath(tok);
    if (f.path) {
      const max = this.colW - (math ? 0 : 34);
      // Equations keep one size, as on GitHub: a wide one scrolls sideways instead of shrinking.
      // Not overflow_x_scroll: GPUI turns vertical wheel moves into horizontal ones
      // there, so the page would stop scrolling under the pointer.
      if (math && f.w > max) {
        const room = max - (tok.eqNum ? 48 : 0), x = Math.min(this.eqX.get(id) ?? 0, f.w - room);
        return h_flex().w_full().items_center().py(10).gap(8)
          .child(div().id(`${id}-x`).relative().flex_1().min_w(0).h(f.h + 8).overflow_hidden()
            .on_scroll_wheel((e, cx) => {
              // macOS already turns shift-wheel into a horizontal delta; elsewhere it stays vertical.
              const dx = e.delta.x || (e.modifiers?.shift ? e.delta.y : 0);
              if (Math.abs(dx) <= Math.abs(e.delta.x ? e.delta.y : 0)) return;
              cx.stop_propagation();
              this.eqX.set(id, Math.max(0, Math.min(f.w - room, (this.eqX.get(id) ?? 0) - dx / Z()))); cx.notify();
            })
            .child(image(f.path).absolute().top(0).left(-x).w(f.w).h(f.h))
            .child(div().absolute().bottom(0).h(3).rounded(2).bg(t.border).left(x / f.w * room).w(room * room / f.w)))
          .when(Boolean(tok.eqNum), el => el.child(div().flex_none().text_size(13).text_color(t.dim).child(`(${tok.eqNum})`)));
      }
      let w = f.w, h = f.h; if (w > max) { h = Math.round(h * max / w); w = max; }
      return math
        ? h_flex().w_full().items_center().py(10)
            .child(div().flex_1()).child(image(f.path).w(w).h(h))
            .child(div().flex_1().text_right().text_size(13).text_color(t.dim).child(tok.eqNum ? `(${tok.eqNum})` : ""))
        : h_flex().w_full().justify_center().my(8).p(16).rounded(8).bg(t.surface).border_1().border_color(t.border).child(image(f.path).w(w).h(h));
    }
    const label = f.error ? `${math ? "math" : "mermaid"} · couldn't render: ${f.error}` : `${math ? "math" : "mermaid"} · ${tok.pv ? "rendered when opened" : "rendering…"}`;
    return v_flex().my(8).rounded(8).overflow_hidden().border_1().border_color(f.error ? t.blocked : t.border).bg(t.surface)
      .child(div().px(12).py(4).text_size(12).text_color(f.error ? t.blocked : t.dim).child(label))
      .child(div().px(12).pb(8).text_size(13).text_color(t.muted).child(tok.text));
  }

  inline(id, md, ex = MATH_EX) {
    const pv = this.pvMode;   // a preview's links go nowhere (they'd move the viewer)
    const linked = inlineRoles(md, pv ? new Map() : this.labels);
    // TextView loads no local images, so text with formulas is laid out here
    // once every formula is typeset; until then the formulas show as Unicode.
    const parts = pv ? [] : splitInline(linked);
    if (parts.some(p => p.tex !== undefined)) {
      const figs = parts.map(p => p.tex === undefined ? null : this.inlineFormula(p.tex, ex));
      if (parts.every((p, k) => p.tex === undefined || figs[k])) return this.mathFlow(id, parts, figs, ex);
    }
    return TextView.markdown(id, inlineMath(linked)).selectable(!pv)
      .on_link_click((url, cx) => {
        if (pv) return;
        this.followFrom(id, url, cx);
      });
  }

  // A clicked footnote reference becomes the cursor, so the note's ↩ comes back to it.
  followFrom(id, url, cx) {
    const b = /^b(\d+)/.exec(id);
    if (b && url.startsWith("#label:%5E")) this.cursor = Number(b[1]);
    this.follow(url, cx);
  }

  // Text and typeset formulas as one wrapping line of words: markdown styles
  // (bold, italic, code, strike, links) and hard breaks carry over. Unlike
  // TextView, the words can't be selected.
  mathFlow(id, parts, figs, ex) {
    const t = theme(), gap = ex * 1.1;
    const src = parts.map((p, k) => p.tex === undefined ? p.text : `\uE000${k}\uE001`).join("");
    let atoms = this.flows.get(src);
    const walk = (tokens, style) => {
      for (const tok of tokens) {
        if (tok.type === "strong") walk(tok.tokens, { ...style, bold: true });
        else if (tok.type === "em") walk(tok.tokens, { ...style, italic: true });
        else if (tok.type === "del") walk(tok.tokens, { ...style, strike: true });
        else if (tok.type === "link") walk(tok.tokens, { ...style, href: tok.href });
        else if (tok.type === "codespan") words(tok.text, { ...style, code: true });
        else if (tok.type === "br") atoms.push({ br: true, style });
        else if (tok.tokens) walk(tok.tokens, style);
        else words(tok.type === "image" ? tok.text : (tok.text ?? tok.raw ?? ""), style);
      }
    };
    const words = (text, style) => {
      for (const piece of text.split(/(\s+|\uE000\d+\uE001)/)) {
        if (!piece) continue;
        if (/^\s+$/.test(piece)) { if (atoms.length) atoms[atoms.length - 1].space = true; continue; }
        const fig = /^\uE000(\d+)\uE001$/.exec(piece);
        atoms.push(fig ? { fig: Number(fig[1]), style } : { word: piece, style });
      }
    };
    atoms = cacheFlow(this.flows, src, () => { atoms = []; walk(marked.Lexer.lexInline(src), {}); return atoms; });
    // A line may break only where the source has a space: pieces that touch
    // (a formula and its comma, code and a semicolon) stay together.
    const units = [[]];
    atoms.forEach((a, k) => { if (a.br) { units.push([[a, k]], []); return; } units[units.length - 1].push([a, k]); if (a.space) units.push([]); });
    return h_flex().w_full().flex_wrap().items_center().children(units.filter(w => w.length).map(w => w[0][0].br ? div().w_full().h(0) :
      h_flex().flex_none().items_center().when(Boolean(w[w.length - 1][0].space), e => e.mr(gap)).children(w.map(([a, k]) => {
      const s = a.style, fig = a.fig === undefined ? null : figs[a.fig];
      const el = fig ? image(fig.path).flex_none().w(fig.w).h(fig.h)
        : div().flex_none().child(a.word)
          .when(Boolean(s.bold), e => e.font_weight(700)).when(Boolean(s.italic), e => e.italic()).when(Boolean(s.strike), e => e.line_through())
          .when(Boolean(s.code), e => e.px(3).rounded(4).bg(t.surface).font_family(settings().font_family || "monospace"));
      return el.when(Boolean(s.href), e => e.id(`${id}-lnk-${k}`).cursor_pointer().text_color(t.accent).on_click((_e, cx) => this.followFrom(id, s.href, cx)));
    }))));
  }

  // An inline formula's typeset image ({ path, w, h }), or null while it renders
  // or if it failed: the text shows it as Unicode then.
  inlineFormula(tex, ex) {
    const key = fnv(JSON.stringify(["i", tex, theme().foreground, ex])), f = this.figs[key];
    if (f) return f.path ? f : null;
    this.figs[key] = { pending: true };
    this.inlineJobs.push({ kind: "math", inline: true, src: tex, out: `${appHome()}/${FIG}/${key}.svg`, color: theme().foreground, exPx: ex });
    // One worker drains the queue, so a screenful of formulas is a few node runs, not one each.
    if (!this.inlineBusy && this.renderCx) {
      this.inlineBusy = true;
      this.renderCx.spawn(async cx => {
        try {
          await null;   // let the rest of this frame queue its formulas first
          while (this.inlineJobs.length) {
            const jobs = this.inlineJobs; this.inlineJobs = [];
            const keyOf = j => j.out.split("/").pop().replace(/\.svg$/, "");
            try {
              await exec("mkdir", ["-p", `${appHome()}/${FIG}`]);
              const r = await this.runRenderer(JSON.stringify(jobs));
              if (r.code !== 0 || !r.stdout) throw new Error((r.stderr || `renderer exited ${r.code}`).trim().split("\n").pop());
              for (const res of JSON.parse(r.stdout)) this.figs[keyOf(res)] = res.error ? { error: res.error } : { path: `${FIG}/${res.out.split("/").pop()}`, w: res.w, h: res.h };
            } catch (e) { for (const j of jobs) this.figs[keyOf(j)] = { error: String(e) }; }
            cx.notify();
          }
        } finally { this.inlineBusy = false; }
      });
    }
    return null;
  }


  picture(tok, id, t) {
    // In the picker's preview: a light placeholder (images load when the file opens).
    if (tok.pv) return div().my(6).px(12).py(6).rounded(6).bg(t.surface).text_color(t.dim).text_size(12)
      .child(`${isVideo(tok.href) ? "▶" : "🖼"}  ${tok.text || tok.href}`);
    if (isVideo(tok.href)) return this.videoBlock(tok, t);
    const img = this.images[tok.href];
    if (!img?.path) return div().my(6).px(12).py(8).rounded(6).bg(t.surface).text_color(t.dim).text_size(13)
      .child(`🖼  ${tok.text || tok.href}${img?.remote ? " (remote image not fetched)" : img?.missing ? " (not found)" : ""}`);
    // Fit the column width, but never taller than 560px.
    let w = Math.min(img.w, this.colW), h = Math.round(img.h * w / img.w);
    if (h > 560) { w = Math.round(w * 560 / h); h = 560; }
    return v_flex().my(8).gap(6).items_center()
      .child(image(img.path).w(w).h(h).rounded(8))
      .when(Boolean(tok.text), el => el.child(div().text_size(13).text_color(t.dim).italic().child(tok.text)));
  }

  bullet(item, ordered, n, id, i, t) {
    return h_flex().items_start().gap(10).py(2)
      .child(div().w(22).flex_none().text_right().text_color(item.task ? (item.checked ? t.ansi2 : t.dim) : t.accent)
        .child(item.task ? (item.checked ? "✓" : "○") : ordered ? `${n}.` : "•"))
      .child(v_flex().flex_1().min_w(0).when(item.task && item.checked, el => el.text_color(t.dim))
        .children(item.tokens.filter(c => c.type !== "checkbox").map((c, k) => c.type === "text"
          // A soft line break is a space; TextView would draw the indented continuation line as a new paragraph.
          ? this.inline(`${id}-${k}`, c.raw.replace(/^\[[ xX]\]\s*/, "").trim().replace(/(?<! {2}|\\)\n[^\S\n]*/g, " "))
          : this.block(c, `${i}-${k}`, t))));
  }

  block(tok, i, t) {
    const id = `b${i}`;
    switch (tok.type) {
      case "heading": {
        const color = [t.ansi4, t.ansi5, t.ansi6, t.ansi2, t.ansi3, t.muted][tok.depth - 1];
        const pv = this.pvMode, folded = !pv && this.folded.has(i), n = folded ? this.sectionSize(i) : 0;
        return h_flex().id(`fold-${i}`).items_center().gap(10).pt(tok.depth <= 2 ? 22 : 14).pb(tok.depth <= 2 ? 10 : 4)
          .text_size(SIZE[`h${tok.depth}`]).font_weight(tok.depth <= 2 ? 700 : 600).text_color(color)
          .when(tok.depth <= 2, el => el.border_b(1).border_color(t.border).mb(6))
          // The heading's text is selectable, so only its arrow folds on a click (za still folds anywhere).
          .when(!pv, el => el.child(div().id(`fold-arrow-${i}`).cursor_pointer().w(14).ml(-24).flex_none().text_size(13).text_color(folded ? color : t.border)
            .on_click((_e, cx) => { this.toggleFold(i); cx.notify(); }).child(folded ? "▸" : "▾")))
          .child(div().flex_1().min_w(0).child(this.inline(`${id}-h`, tok.text.replace(/\s*\n\s*/g, " ").replace(/^(\d+)([.)])(?=\s|$)/, "$1\\$2").replace(/^([-+*>#])/, "\\$1"), MATH_EX * SIZE[`h${tok.depth}`] / SIZE.body)))
          .when(folded, el => el.child(div().flex_none().text_size(13).font_weight(400).text_color(t.dim).child(`${n} block${n === 1 ? "" : "s"} folded`)));
      }
      case "paragraph": {
        const imgs = tok.tokens.filter(x => x.type === "image");
        const onlyImages = imgs.length && tok.tokens.every(x => x.type === "image" || (x.type === "text" && !x.text.trim()) || x.type === "br");
        if (onlyImages) return v_flex().children(imgs.map((im, j) => this.picture(im, `${id}-${j}`, t)));
        return div().py(5).child(this.inline(id, tok.raw.trim()));
      }
      case "math":
        return this.figure(tok, id, t);
      case "notice":   // a file cut at LEX_MAX (lex.js)
        return div().my(10).px(14).py(10).rounded(8).bg(t.ansi3 + "1c").border_l(3).border_color(t.ansi3).text_size(14).text_color(t.foreground).child(tok.text);
      case "code": {
        if (isMath(tok) || isMermaid(tok)) return this.figure(tok, id, t);
        const lines = tok.text.split("\n").length;
        return v_flex().my(8).rounded(8).overflow_hidden().border_1().border_color(t.border).bg(t.surface)
          .child(h_flex().h(28).px(12).items_center().justify_between().border_b(1).border_color(t.border).text_size(12).text_color(t.dim)
            .child(div().child(tok.lang || "text"))
            .child(div().id(`${id}-copy`).px(8).rounded(4).cursor_pointer().hover(s => s.bg(t.hover).text_color(t.foreground))
              .on_click(() => exec("sh", ["-c", 'printf %s "$1" | LANG=en_US.UTF-8 pbcopy', "copy", tok.text])).child("copy")))
          .child(div().h(Math.min(lines, 40) * 20 + 4).child(Editor.new(tok.state).size_full()));
      }
      case "blockquote": {
        const al = alertOf(tok);
        if (al) {
          const a = ALERTS[al.kind], c = t[a.color];
          return v_flex().my(8).px(16).py(10).gap(4).rounded(8).bg(c + "14").border_l(3).border_color(c)
            .child(h_flex().gap(8).items_center().text_color(c).font_semibold().child(div().child(a.icon)).child(div().child(a.title)))
            .child(this.inline(`${id}-al`, al.body));
        }
        return v_flex().my(8).pl(16).py(2).border_l(3).border_color(t.ansi5).text_color(t.muted)
          .children(tok.tokens.map((c, j) => this.block(c, `${i}-${j}`, t)));
      }
      case "listitem":
        return this.bullet(tok.item, tok.list.ordered, tok.n, id, i, t);
      case "list":
        return v_flex().py(4).children(tok.items.map((item, j) => this.bullet(item, tok.ordered, (tok.start || 1) + j, `${id}-${j}`, `${i}-${j}`, t)));
      case "hr":
        return div().my(16).h(1).bg(t.border);
      case "table": {
        const hasHeader = tok.header.some(h => h.text.trim());
        return v_flex().my(8).rounded(8).overflow_hidden().border_1().border_color(t.border)
          .when(hasHeader, el => el.child(this.tableRow(tok, -1, id, t).bg(t.surface)))
          .children(tok.rows.map((_row, r) => this.tableRow(tok, r, id, t).when(r > 0 || hasHeader, el => el.border_t(1).border_color(t.border))
            .when(r % 2 === 1, el => el.bg(t.canvas))));
      }
      case "pline":
        // One source line of a paragraph (paraLines in lex.js); row() spaces the ends.
        return div().py(1).child(this.inline(id, tok.text));
      case "trow":
        // One row of a top-level table; its frame and stripes are drawn by row().
        return this.tableRow(tok.table, tok.r, id, t);
      case "footnote":
        return h_flex().items_start().gap(8).py(2).text_size(13)
          .child(div().w(22).flex_none().text_right().text_color(t.dim).child(`${tok.num ?? tok.id}.`))
          .child(div().flex_1().min_w(0).text_color(t.muted).child(this.inline(id,
            this.pvMode || this.labels.get(`^${tok.id}`)?.ref === undefined ? tok.text : `${tok.text} [↩](#fnback:${encodeURIComponent(tok.id)})`)));
      case "html":
        if (isComment(tok)) return div();
        return div().py(2).text_size(13).text_color(t.dim).child(tok.raw.trim());
      case "space":
        return div();
      default:
        return div().py(4).text_color(t.dim).child(this.inline(id, tok.raw?.trim() ?? ""));
    }
  }

  // A table's column widths, as flex-grow weights. Auto layout, like a
  // browser's: every column gets at least its longest word (min) and shares the
  // rest by content length (max). If even the mins don't fit, only the widest
  // columns give way. No text measuring here, so widths are estimated from a
  // monospace advance (0.6em) and padded. Kept on the token: a table split into
  // row blocks needs one set of widths for all its rows.
  tableWidths(tok) {
    const avail = this.colW - 2;
    if (tok.widths?.avail === avail) return tok.widths.weight;
    const ch = SIZE.body * 0.62, padX = 24 + 6, all = c => [tok.header[c], ...tok.rows.map(r => r[c])];
    // A formula is as wide as what it draws, not its TeX source, and never wraps inside.
    const shown = x => splitInline(x?.text ?? "").map(q => q.tex === undefined ? plainNote(q.text) : texToUnicode(q.tex).replace(/\s/g, "\u00a0")).join("");
    const hasMath = x => /\$/.test(x?.text ?? "");
    const cols = tok.header.map((_h, c) => all(c).map(x => hasMath(x) ? shown(x) : plain(x?.tokens) || x?.text || ""));
    const words = tok.header.map((_h, c) => all(c).map(x => hasMath(x) ? shown(x) : solid(x?.tokens) || x?.text || ""));
    const min = words.map(xs => padX + ch * Math.max(1, ...xs.flatMap(s => s.split(/\s+/).map(w => [...w].length))));
    const max = cols.map((xs, c) => Math.max(min[c], padX + ch * Math.max(...xs.map(s => [...s.trim()].length))));
    const sum = a => a.reduce((x, y) => x + y, 0);
    let weight;
    if (sum(max) <= avail) weight = max;
    else if (sum(min) <= avail) weight = min.map((m, c) => m + (max[c] - m) * (avail - sum(min)) / (sum(max) - sum(min)));
    else {
      // Cap the widest columns at the level where the total just fits.
      const sorted = [...min].sort((a, b) => a - b);
      let cap = avail / min.length;
      for (let k = 0, rest = avail; k < sorted.length; k++) {
        if (sorted[k] * (sorted.length - k) > rest) { cap = rest / (sorted.length - k); break; }
        rest -= sorted[k];
      }
      weight = min.map(m => Math.min(m, cap));
    }
    tok.widths = { avail, weight };
    return weight;
  }

  // One table row's cells; r = -1 is the header.
  tableRow(tok, r, id, t) {
    const weight = this.tableWidths(tok), head = r < 0;
    const cell = (c, j) => div().w(0).flex_grow(weight[j]).min_w(0).px(12).py(7)
      .when(tok.align[j] === "right", el => el.text_right()).when(tok.align[j] === "center", el => el.text_center())
      .child(this.inline(head ? `${id}-h${j}` : `${id}-${r}-${j}`, c.text));
    return h_flex().when(head, el => el.font_semibold().text_color(t.ansi4)).children((head ? tok.header : tok.rows[r]).map(cell));
  }

  // One top-level block, measured, with its highlight tint and note.
  // A row far from the view, as empty space of its last measured height (with
  // the margins row() gives it): scrolling rebuilds only the rows near the view.
  spacer(tok, i) {
    if (this.hidden[i]) return div();
    const tr = tok.type === "trow", pl = tok.type === "pline";
    return div().id(`row-${i}`).flex_none().h(this.heights[i] ?? ROW_GUESS)
      .when(tr && Boolean(tok.first), el => el.mt(8)).when(tr && Boolean(tok.last), el => el.mb(8))
      .when(pl && Boolean(tok.first), el => el.mt(4)).when(pl && Boolean(tok.last), el => el.mb(4));
  }

  row(tok, i, t) {
    if (this.hidden[i]) return div();
    const m = this.marks?.get(i);
    const hit = this.matches.includes(i), current = hit && this.matches[this.mi] === i;
    const color = m ? ({ green: t.ansi2, red: t.ansi1, blue: t.ansi4, purple: t.ansi5, cyan: t.ansi6 }[m.color] ?? t.ansi3) : null;
    const [a, b] = this.range(), sel = this.anchor !== null && i >= a && i <= b, cur = i === this.cursor;
    const picked = this.picked && i >= this.picked[0] && i <= this.picked[1];
    const cp = cur ? cursorParts(this.look, this.resting ? this.cmotion : "steady", this.numbers !== "off") : null;
    const size = this.curSize?.i === i ? this.curSize : null, grows = Boolean(cp?.rowAnim?.startsWith("grow") && size);
    // Line number lined up with the block's first line of text.
    const fs = tok.type === "heading" ? SIZE[`h${tok.depth}`] : SIZE.body, tr = tok.type === "trow" ? tok : null, pl = tok.type === "pline" ? tok : null;
    const pad = tok.type === "heading" ? (tok.depth <= 2 ? 22 : 14) : { paragraph: 5, listitem: 2, code: 8, table: 8, blockquote: 8, trow: 8, pline: 1 }[tok.type] ?? 4;
    const numTop = pad + (tok.type === "code" ? 2 : (fs * 1.65 - 19) / 2);
    const changed = this.changed.has(i), gone = this.removed.get(i);
    return v_flex().id(`row-${i}`).relative().when(Boolean(tr?.first), el => el.mt(8)).when(Boolean(tr?.last), el => el.mb(8))
      .when(Boolean(pl?.first), el => el.mt(4)).when(Boolean(pl?.last), el => el.mb(4))
      .on_mouse_down("left", (_e, cx) => { if (this.zoom) return; this.cursor = i; this.rest(cx); this.handle.focus(); cx.notify(); })
      .when(Boolean(gone), el => el.child(this.removedMark(gone, t)))
      .when(Boolean(picked) && i === this.picked[0] && (!tr || tr.first), el => el.child(h_flex().mb(2).gap(6).items_center().text_size(11).text_color(t.ansi4)
        .child(div().child("📌 Pinned for Claude")).child(div().text_color(t.dim).child("· Esc unpins"))))
      .when(changed, el => el.child(div().absolute().left(-12).top(gone ? 26 : 4).bottom(4).w(3).rounded(2).bg(t.ansi2)))
      .when(this.numbers !== "off", el => el.child(h_flex().justify_end().absolute().left(-PAD - 12).top(numTop).w(PAD - 14).font_family(BODY()).text_size(12).line_height(1.6)
        .text_color(cur ? t.accent : t.dim).when(cur, el => el.font_semibold())
        .child(numLabel(i, cur ? cp : null, gutterLabel(this.numbers, i, this.cursor, tok.from, this.ord), t))))
      .on_size_change((size, cx) => {
        const h = size.height / Z(), was = this.heights[i];
        if (was === h) return;
        // A row above the view that grows or shrinks (first measured, or reflowed)
        // moves the view by as much, so the text being read stays still.
        if (this.aim === null && this.yOf(i) + (was ?? ROW_GUESS) <= this.offset) { this.offset = this.clamp(this.offset + h - (was ?? ROW_GUESS)); this.motion = 0; }
        this.heights[i] = h; this.reaim(); cx.notify();
      })
      .child(div().id(`blk-${i}`).relative()
        .when(!tr, el => el.px(14).mx(-14).rounded(6))
        // A table row draws its piece of the table's frame, and its stripe under
        // any tint, so the cursor layer still shows on it.
        .when(Boolean(tr), el => el.overflow_hidden().border_x(1).border_t(1).border_color(t.border)
          .when(tr.first, el => el.rounded_t(8)).when(tr.last, el => el.rounded_b(8).border_b(1))
          .when(tr.r < 0, el => el.bg(t.surface)).when(tr.r % 2 === 1, el => el.bg(t.canvas)))
        .when(cur, el => el.on_size_change((size, cx) => {
          const w = size.width, h = size.height, c = this.curSize;   // zoomed px, as .loop wants
          if (c?.i !== i || c.w !== w || c.h !== h) { this.curSize = { i, w, h }; cx.notify(); }
        }))
        .when(Boolean(m), el => el.bg(color + "1f"))
        .when(Boolean(picked) && !m, el => el.bg(t.ansi4 + "1c"))
        .when(sel, el => el.bg(t.selection))
        .when(!m && hit, el => el.bg(t.accent + (current ? "2e" : "12")))
        // The cursor: a layer behind the block, so it can pulse or blink without
        // fading the text.
        .when(cur && !sel && Boolean(cp.row), el => el.child(animate(div().id(`cur-${i}`).absolute().top(0).left(0).when(!grows, el => el.bottom(0).right(0)).rounded(tr ? 0 : 6)
          .when(cp.row === "lift", el => el.bg(t.raised).shadow_md()).when(cp.row !== "lift", el => el.bg(t.hover)), cp.rowAnim, size)))
        .child(this.block(tok, i, t)))
      .when(Boolean(m?.note) && m?.last, el => el.child(
        h_flex().mt(6).mb(10).gap(10).items_start().px(14).py(10).rounded(8).bg(t.surface).border_1().border_color(color)
          .opacity(this.noteAlpha).transition("opacity", { duration: 280, easing: "ease-out" })
          .child(div().flex_none().text_size(12).font_semibold().text_color(color).child(`✦ Claude${this.notes.highlights.length > 1 ? ` ${m.k + 1}` : ""}`))
          .child(div().flex_1().min_w(0).text_size(14).child(this.typed === Infinity
            ? this.inline(`note-${i}`, m.note)
            : div().child(plainNote(m.note).slice(0, this.typed) + "▍")))));
  }

  removedMark(n, t) {
    return h_flex().gap(8).items_center().py(2).text_size(11).text_color(t.ansi1)
      .child(div().w(10).h(1).bg(t.ansi1)).child(div().child(`${n} block${n === 1 ? "" : "s"} removed`)).child(div().flex_1().h(1).bg(t.ansi1 + "55"));
  }

  // Enter: fold a heading, or follow the first link in the block.
  activate(cx) {
    const b = this.blocks[this.cursor]; if (!b) return;
    if (b.type === "heading") { this.toggleFold(this.cursor); return cx.notify(); }
    const vid = this.blockVideo(b);
    if (vid >= 0) { this.videoCmd(vid, "toggle", undefined, cx); return; }
    if (this.openZoom(b, cx)) return;
    const m = /\[[^\]]*\]\(([^)\s]+)[^)]*\)/.exec(b.raw);
    if (m) return this.follow(m[1], cx);
    this.flash = "Enter: fold a heading, follow a link or zoom a figure · p pins for Claude"; cx.notify();
  }

  // The index in this.videoList of the first video in block b, or -1.
  blockVideo(b) {
    const im = b?.type === "paragraph" ? b.tokens.find(x => x.type === "image" && isVideo(x.href)) : null;
    return im ? this.videoList.indexOf(im.href) : -1;
  }

  // O: open the clip in QuickTime Player. Only video files reach this, and only
  // that app is asked to open them, so a document can't launch anything else.
  // QuickTime sniffs content too (an "x.mp4" HLS playlist makes it fetch URLs),
  // so only a clip that passed the container check opens, and it is re-probed
  // first: the cache key is path+mtime+size, which a swapped file can match.
  openVideo(cx) {
    const v = this.videos[this.videoList[this.blockVideo(this.blocks[this.cursor])]];
    if (!v?.abs || v.missing) { this.flash = "O: put the cursor on a video"; return cx.notify(); }
    if (v.error || !v.meta) { this.flash = v.error ? `O: couldn't prepare: ${v.error}` : "O: video not checked yet"; return cx.notify(); }
    cx.spawn(async cx => {
      const probe = await this.probeVideo(v.abs);
      if (probe.error) { v.error = probe.error; this.flash = `O: couldn't prepare: ${probe.error}`; return cx.notify(); }
      exec("open", ["-a", "QuickTime Player", v.abs]); this.flash = "opened in QuickTime Player"; cx.notify();
    });
  }

  // ---- zoom: Enter on a diagram or image fills the pane with it ----
  // gpui-kit has no scale transform, so zooming resizes the image and panning
  // moves it; GPUI animates left/top/width/height natively. A Mermaid diagram
  // is re-rendered at 4x on open so it stays sharp when zoomed in.
  zoomTarget(b) {
    if (b.type === "paragraph") {
      const im = b.tokens.find(x => x.type === "image"), img = im && this.images[im.href];
      return img?.path ? { path: img.path, w: img.w, h: img.h } : null;
    }
    if (b.type === "math" || (b.type === "code" && (isMath(b) || isMermaid(b)))) {
      const f = this.figs[b.fig];
      return f?.path ? { path: f.path, w: f.w, h: f.h, tok: isMermaid(b) ? b : null } : null;
    }
    return null;
  }

  openZoom(b, cx) {
    const z = this.zoomTarget(b); if (!z) return false;
    this.zoom = { ...z, hi: null, show: z.path, in: 0, motion: 0, drag: null };
    this.fitZoom(0.92); this.zoom.motion = 0; cx.notify();
    cx.timer.after(16, cx => { if (!this.zoom) return; this.zoom.in = 1; this.zoom.motion = 320; this.fitZoom(); cx.notify(); });
    if (z.tok) this.hiRes(z.tok, cx);
    return true;
  }

  // The 4x PNG loads invisibly first (image() shows nothing while it decodes),
  // then replaces the 2x one in place.
  hiRes(tok, cx) {
    const t = theme(), root = `${appHome()}/${FIG}`, out = `${root}/${tok.fig}@4.png`, z = this.zoom;
    cx.spawn(async cx => {
      const r = await this.runRenderer(JSON.stringify([{ kind: "mermaid", scale: 4, src: tok.text, out, font: settings().font_family || "sans-serif",
        colors: { fg: t.foreground, surface: t.surface, raised: t.raised, bg: t.background, blue: t.ansi4, purple: t.ansi5, dim: t.dim } }]));
      let res = null; try { res = JSON.parse(r.stdout)[0]; } catch {}
      if (this.zoom !== z || !res || res.error) return;
      z.hi = `${FIG}/${tok.fig}@4.png`; cx.notify();
      cx.timer.after(600, cx => { if (this.zoom === z) { z.show = z.hi; z.hi = null; cx.notify(); } });
    });
  }

  zoomArea() { return { vw: Math.max(100, this.viewW), vh: Math.max(100, this.viewH) }; }

  fitScale() { const { vw, vh } = this.zoomArea(), z = this.zoom; return Math.min((vw - 64) / z.w, (vh - 96) / z.h, 4); }

  fitZoom(k = 1) {
    const z = this.zoom, { vw, vh } = this.zoomArea();
    z.s = this.fitScale() * k; z.x = (vw - z.w * z.s) / 2; z.y = (vh - 28 - z.h * z.s) / 2;
  }

  // Keep the image on screen: centered on an axis where it fits, else no
  // further past an edge than a small margin.
  clampZoom() {
    const z = this.zoom, { vw, vh } = this.zoomArea(), W = z.w * z.s, H = z.h * z.s, M = 32;
    z.x = W <= vw - 2 * M ? (vw - W) / 2 : Math.min(M, Math.max(vw - M - W, z.x));
    z.y = H <= vh - 28 - 2 * M ? (vh - 28 - H) / 2 : Math.min(M, Math.max(vh - 28 - M - H, z.y));
  }

  // Zoom by factor k, keeping the point (px, py) of the pane still.
  zoomAt(k, px, py, motion, cx) {
    const z = this.zoom, fit = this.fitScale();
    const s = Math.min(Math.max(z.s * k, Math.min(fit, 1) * 0.5), Math.max(8, fit));
    z.x = px - (px - z.x) * s / z.s; z.y = py - (py - z.y) * s / z.s; z.s = s;
    z.motion = motion; this.clampZoom(); cx.notify();
  }

  panZoom(dx, dy, motion, cx) { const z = this.zoom; z.x += dx; z.y += dy; z.motion = motion; this.clampZoom(); cx.notify(); }

  closeZoom(cx) {
    const z = this.zoom; z.in = 0; z.motion = 200; cx.notify();
    cx.timer.after(180, cx => { if (this.zoom === z) { this.zoom = null; cx.notify(); } });
  }

  zoomKeys(k, mod, cx) {
    cx.stop_propagation();
    const { vw, vh } = this.zoomArea(), step = 90;
    if (mod.control) return;
    switch (k) {
      case "h": case "left": return this.panZoom(step, 0, 200, cx);
      case "l": case "right": return this.panZoom(-step, 0, 200, cx);
      case "k": case "up": return this.panZoom(0, step, 200, cx);
      case "j": case "down": return this.panZoom(0, -step, 200, cx);
      case "+": case "=": return this.zoomAt(1.25, vw / 2, (vh - 28) / 2, 220, cx);
      case "-": case "_": return this.zoomAt(0.8, vw / 2, (vh - 28) / 2, 220, cx);
      case "0": this.zoom.motion = 320; this.fitZoom(); return cx.notify();
      case "escape": case "q": case "enter": return this.closeZoom(cx);
    }
  }

  zoomPanel(t) {
    const z = this.zoom, W = z.w * z.s, H = z.h * z.s;
    const move = { duration: z.motion, easing: "ease-out" };
    const layer = (id, path, alpha) => image(path).id(id).absolute().left(z.x).top(z.y).w(W).h(H).opacity(alpha)
      .transition("left", move).transition("top", move).transition("width", move).transition("height", move);
    const pos = e => ({ x: (e.local_position?.x ?? e.position.x) / Z(), y: (e.local_position?.y ?? e.position.y) / Z() });
    return div().id("md-zoom").absolute().top(0).left(0).size_full().overflow_hidden().bg(t.background)
      .opacity(z.in).transition("opacity", { duration: 200, easing: "ease-out" })
      .when(!z.drag, el => el.cursor_grab()).when(Boolean(z.drag), el => el.cursor_grabbing())
      .on_scroll_wheel((e, cx) => {
        cx.stop_propagation();
        const p = pos(e);
        if (e.modifiers?.control || e.modifiers?.platform) this.zoomAt(Math.exp(e.delta.y / Z() * 0.01), p.x, p.y, 60, cx);
        else this.panZoom(e.delta.x / Z(), e.delta.y / Z(), 0, cx);
      })
      .on_mouse_down("left", (e, cx) => { const p = pos(e); z.drag = { mx: p.x, my: p.y, x: z.x, y: z.y }; this.handle.focus(); cx.notify(); })
      .on_mouse_move((e, cx) => {
        if (!z.drag) return;
        const p = pos(e); z.x = z.drag.x + p.x - z.drag.mx; z.y = z.drag.y + p.y - z.drag.my; z.motion = 0; this.clampZoom(); cx.notify();
      })
      .on_mouse_up("left", (_e, cx) => { z.drag = null; cx.notify(); })
      .child(div().id("md-zoom-plate").absolute().left(z.x - 16).top(z.y - 16).w(W + 32).h(H + 32).rounded(10).bg(t.surface).border_1().border_color(t.border)
        .transition("left", move).transition("top", move).transition("width", move).transition("height", move))
      .child(layer("md-zoom-img", z.show, 1))
      .when(Boolean(z.hi), el => el.child(layer("md-zoom-hi", z.hi ?? z.show, 0.01)))
      .child(h_flex().absolute().left(0).bottom(10).w_full().justify_center()
        .child(h_flex().gap(10).px(12).py(3).rounded(8).bg(t.popover).border_1().border_color(t.input).text_size(12).font_family(BODY()).text_color(t.dim)
          .child(div().text_color(t.foreground).font_semibold().child(`${Math.round(z.s * 100)}%`))
          .child(div().child("hjkl / drag  pan · + −  zoom · 0  fit · Esc  close"))));
  }

  // ---- outline ----
  headings() { return this.blocks.map((b, i) => b.type === "heading" ? i : -1).filter(i => i >= 0); }

  outlinePanel(t) {
    const hs = this.headings(), cur = this.sectionOf(this.cursor);
    return v_flex().id("md-outline").absolute().top(10).left(10).w(340).max_h(Math.max(160, this.viewH - 20)).overflow_y_scrollbar()
      .py(8).rounded(10).bg(t.popover).border_1().border_color(t.input).shadow_md().text_size(13).font_family(BODY())
      .child(div().px(14).pb(6).text_size(11).text_color(t.dim).child("OUTLINE · j/k · Enter · Esc"))
      .children(hs.map((h, k) => {
        const b = this.blocks[h], sel = k === this.oi;
        return div().id(`ol-${h}`).pl(14 + (b.depth - 1) * 14).pr(12).py(3).truncate().cursor_pointer()
          .text_color(sel ? t.foreground : b.depth <= 2 ? t.muted : t.dim).when(b.depth <= 2, el => el.font_semibold())
          .when(sel, el => el.bg(t.selected)).when(h === cur && !sel, el => el.text_color(t.accent))
          .hover(s => s.bg(t.hover))
          .on_click((_e, cx) => { this.outline = false; this.cursor = h; this.aimAt(h); this.handle.focus(); cx.notify(); })
          .child(plain(b.tokens));
      }));
  }

  // ---- file picker (ctrl-p) ----
  // Telescope-style: a prompt and a fuzzy-filtered list on the left, a live
  // preview on the right drawn by block(). Files: markdown under the git work
  // tree (tracked + untracked, not ignored), else under this folder; see picker.js.

  // Newest first in ~/.cache/herdr-md/recent.json (read by the picker and `mdh pick`).
  async remember(file) {
    if (!file) return;
    await this.ready; await this.homeReady();
    const nd = this.notesDir(); if (!nd) return;
    let list = [];
    try { list = parseRecent(await this.rd(`${nd}/recent.json`)); } catch {}
    if (list[0] === file) return;
    this.recent = pushRecent(list, file);
    this.ex("sh", ["-c", 'mkdir -p "$1" && printf %s "$2" > "$1/.recent.$$" && mv -f "$1/.recent.$$" "$1/recent.json"', "recent", nd, JSON.stringify(this.recent)]).catch(() => {});
  }

  openPicker(cx) {
    if (this.pick) return;
    this.outline = false; if (this.help) this.help = false; this.helpIn = 0;
    this.pick = { query: "", rows: [], sel: 0, top: 0, pvY: 0 }; this.pickIn = 0;
    this.pickInput.set_value(""); this.pickInput.focus();
    // A listing narrowed by the last open's moves is not this tree's: list afresh.
    if (this.pickScope) this.pickList = null;
    this.pickScope = null; this.pickFolders = !this.popts.files; this.pickNote = null;
    // A listing of this tree from an earlier open shows at once; a fresh one replaces it.
    const here = this.file ?? this.pickRoot;
    if (this.pickList && !(here && (here === this.pickList.root || here.startsWith(this.pickList.root + "/")))) this.pickList = null;
    this.rerank(cx, false);
    cx.timer.after(16, cx => { this.pickIn = 1; cx.notify(); });
    cx.spawn(async cx => {
      await this.ready; await this.homeReady();
      const conf = parseConfig(await readTextFile(PICK_CONF()).catch(() => null));
      if (!this.pick) return;
      const was = JSON.stringify([this.popts.no_ignore, this.popts.depth]);
      this.popts = conf.opts; this.pickErr = conf.error; this.pickFolders = !conf.opts.files;
      if (was !== JSON.stringify([conf.opts.no_ignore, conf.opts.depth])) this.pickList = null;
      this.rerank(cx, true);
      const nd = this.notesDir(), recent = parseRecent(nd ? await this.rd(`${nd}/recent.json`).catch(() => null) : null);
      // No file behind the picker: its root, else the newest recent file's folder, else home.
      if (!this.file && !this.pickRoot) this.pickRoot = recent[0] ? dirname(recent[0]) : this.homeDir() || null;
      this.recent = recent;
      await this.relist(cx);
    });
  }

  // List the picker's folder: the scope it was moved into, else the open
  // file's tree (git work tree or folder). Stale answers are dropped.
  async relist(cx) {
    const scope = this.pickScope, o = this.popts, seq = this.pickSeq = (this.pickSeq ?? 0) + 1;
    await this.ready;
    const dir = scope ?? (this.file ? dirname(this.file) : this.pickRoot);
    if (!dir) return;   // no root yet (a remote home still unknown): nothing to list
    let list = await listFiles((c, a) => this.ex(c, a), dir, { noIgnore: o.no_ignore, depth: o.depth });
    if (scope) list = within(list, scope);
    if (seq !== this.pickSeq || !this.pick) return;
    this.pickList = list;
    this.rerank(cx, true);
  }

  // Move the picker into `dir` (Enter on a folder, or up a level), listing
  // files or folders; the prompt empties.
  reroot(dir, folders, cx) {
    const p = this.pick; if (!p) return;
    this.pickScope = dir; this.pickFolders = folders;
    if (this.pickList && !(dir === this.pickList.root || dir.startsWith(this.pickList.root + "/"))) this.pickList = null;
    else if (this.pickList) this.pickList = within(this.pickList, dir);
    p.query = ""; this.pickInput.set_value("");
    this.rerank(cx, false);
    cx.spawn(async cx => { await this.relist(cx); });
  }

  // Up a folder, but not past home (listing / would search the whole disk).
  pickUp(cx) {
    const root = this.pickList?.root ?? this.pickScope; if (!root) return;
    if ((this.homeDir() && root === this.homeDir()) || dirname(root) === "/") { this.pickNote = `already at the top (${this.tilde(root)})`; cx.notify(); return; }
    this.pickNote = null;
    this.reroot(dirname(root), this.pickFolders, cx);
  }

  closePicker(cx) {
    if (!this.pick) return;
    this.pickIn = 0; this.pvSeq++; this.handle.focus(); cx.notify();
    const p = this.pick;
    cx.timer.after(180, cx => { if (this.pick === p && !this.pickIn) { this.pick = null; cx.notify(); } });
  }

  // New rows for the query. keep: stay on the same file (a refreshed listing),
  // else back to the top (the query changed).
  rerank(cx, keep) {
    const p = this.pick; if (!p) return;
    const was = p.rows[p.sel]?.abs;
    const v = this.pickView = this.pickList ? shape(this.pickList, this.popts, this.pickFolders) : null;
    p.rows = v ? rank(p.query, { root: v.root, files: v.rows }, this.recent, this.file, Infinity) : [];
    // A folder row previews its README (or index.md), when it has one.
    if (v?.folders) for (const r of p.rows) { r.dir = true; const md = v.readmes.get(r.rel); r.pv = md ? `${v.root}/${md}` : null; }
    const at = keep && was ? p.rows.findIndex(r => r.abs === was) : -1;
    this.pickSelect(at >= 0 ? at : 0, cx);
  }

  // Move the selection; the list window follows it with a two-row margin.
  pickSelect(i, cx) {
    const p = this.pick; if (!p) return;
    const n = p.rows.length, vis = this.pickVis;
    p.sel = Math.max(0, Math.min(i, n - 1)); if (p.sel < 0) p.sel = 0;
    const m = Math.min(2, Math.floor((vis - 1) / 2));
    if (p.sel < p.top + m) p.top = Math.max(0, p.sel - m);
    else if (p.sel > p.top + vis - 1 - m) p.top = Math.min(Math.max(0, n - vis), p.sel - vis + 1 + m);
    const row = p.rows[p.sel];
    this.preview(row ? (row.dir ? row.pv : row.abs) : null, cx);
    cx.notify();
  }

  // Show a file's preview: from the cache at once, else read it once the
  // selection has rested PV_WAIT ms (typing and fast moves never wait on disk).
  // Until then the old preview stays, dimmed.
  preview(abs, cx) {
    const seq = ++this.pvSeq;
    if (this.pv?.abs === abs) { this.pvLoading = false; return; }
    if (!abs) { this.pv = null; this.pvLoading = false; return; }
    const hit = this.pvCache.get(abs);
    if (hit) { this.pvCache.delete(abs); this.pvCache.set(abs, hit); this.pv = hit; this.pick.pvY = 0; this.pvLoading = false; return; }
    this.pvLoading = true;
    cx.timer.after(PV_WAIT, cx => {
      if (seq !== this.pvSeq) return;
      cx.spawn(async cx => {
        let text = null, error = null;
        try { text = await this.rd(abs); } catch (e) { error = String(e).slice(0, 120); }
        if (seq !== this.pvSeq || !this.pick) return;
        const pv = { abs, blocks: [], codes: [], lines: 0, more: 0, error: error ?? (text === null ? "not found" : null) };
        if (text !== null) try {
          // Only the start of the file is lexed (see previewSource in picker.js).
          const src = previewSource(text);
          const all = blocks(src.text, marked.lexer(src.text)).filter(b => !labelOf(b));
          pv.blocks = all.slice(0, PV_BLOCKS); pv.more = all.length - pv.blocks.length; pv.cut = src.cut; pv.lines = (text.match(/\n/g)?.length ?? 0) + 1;
          // The blocks' own tokens (a list item's list), each made once.
          const top = [...new Set(pv.blocks.map(b => b.type === "listitem" ? b.list : b.type === "trow" ? b.table : b.type === "pline" ? b.para : b))];
          marked.walkTokens(top, tok => { tok.pv = true; if (isMath(tok) || isMermaid(tok)) tok.fig = this.figKey(tok); });
          this.prepare(top, pv.codes);
        } catch (e) { pv.blocks = []; pv.error = `couldn't preview: ${String(e).slice(0, 100)}`; }
        this.pvCache.set(abs, pv);
        // Keep a few; drop the oldest and its code editors.
        while (this.pvCache.size > 12) { const [k, old] = this.pvCache.entries().next().value; if (old === this.pv) break; old.codes.forEach(c => c.release?.()); this.pvCache.delete(k); }
        this.pv = pv; this.pick.pvY = 0; this.pvLoading = false;
        cx.notify();
        // Math and diagrams this machine already rendered (any document, same
        // source and colors) show as images; the rest stay placeholders.
        const root = `${appHome()}/${FIG}`; let found = false;
        for (const b of pv.blocks) {
          if (!b.fig || this.figs[b.fig]?.path) continue;
          const ext = isMath(b) ? "svg" : "png";
          try { const m = JSON.parse(await readTextFile(`${root}/${b.fig}.${ext}.json`) ?? "null"); if (m?.w) { this.figs[b.fig] = { path: `${FIG}/${b.fig}.${ext}`, w: m.w, h: m.h }; found = true; } } catch {}
        }
        if (found && this.pv === pv) cx.notify();
      });
    });
  }

  pickOpen(cx) {
    const row = this.pick?.rows[this.pick.sel]; if (!row) return;
    // A folder: move into it and list its files (telescope-file-browser).
    if (row.dir) return this.reroot(row.abs, false, cx);
    this.closePicker(cx);
    if (row.abs !== this.file) this.navigate(row.abs, null, cx, true);
  }

  // ctrl-v: a new viewer to the right of this one, this one unchanged.
  pickSplit(cx) {
    const row = this.pick?.rows[this.pick.sel]; if (!row || row.dir) return;
    this.closePicker(cx);
    run("pane.split", { direction: "right", mod: MOD, props: { file: row.abs, machine: this.on } });
  }

  scrollPreview(dy, cx) {
    const p = this.pick; if (!p || !this.pv) return;
    p.pvY = Math.max(0, Math.min(p.pvY + dy, Math.max(0, (this.pvH ?? 0) - (this.pvViewH ?? 0) + 40)));
    cx.notify();
  }

  pickKeys(e, cx) {
    const k = e.key, c = Boolean(e.modifiers?.control), p = this.pick;
    if (e.modifiers?.platform || e.modifiers?.alt) return;
    const done = () => cx.stop_propagation();
    if (!this.pickIn) return done();   // closing
    if (k === "escape" || (c && k === "c")) { this.closePicker(cx); return done(); }
    // While the prompt has the keyboard its submit opens the row; doing it here
    // too would act twice (Enter on a folder: move in, then open a file there).
    if (k === "enter") { if (!this.pickTyping) this.pickOpen(cx); return done(); }
    if (k === "down" || (c && (k === "n" || k === "j"))) { this.pickSelect(p.sel + 1, cx); return done(); }
    if (k === "up" || (c && (k === "p" || k === "k"))) { this.pickSelect(p.sel - 1, cx); return done(); }
    if (k === "pagedown" || k === "pageup") { this.pickSelect(p.sel + (k === "pagedown" ? 1 : -1) * Math.max(1, this.pickVis - 1), cx); return done(); }
    if (c && (k === "d" || k === "u")) { this.scrollPreview((k === "d" ? 1 : -1) * Math.max(120, (this.pvViewH ?? 400) / 2), cx); return done(); }
    if (c && k === "v") { this.pickSplit(cx); return done(); }
    // telescope-file-browser's keys: ctrl-f files ⇄ folders, ctrl-g up a folder,
    // Backspace on an empty prompt up a folder too.
    if (c && k === "f") { this.reroot(this.pickList?.root ?? this.pickScope ?? (this.file ? dirname(this.file) : this.pickRoot), !this.pickFolders, cx); return done(); }
    if (c && k === "g") { this.pickUp(cx); return done(); }
    if (k === "backspace" && !c && !p.query) { this.pickUp(cx); return done(); }
    // Anything else types into the prompt (it may have lost the keyboard to a click).
    if (!c && !this.pickTyping) this.pickInput.focus();
  }

  // A path with its matched characters lit: file name bright, folder dim.
  // path_display "tail" drops the folder, "shorten" cuts it to first letters.
  pickRow(row, i, t) {
    const cut = row.rel.lastIndexOf("/") + 1, name = row.rel.slice(cut), dir = row.rel.slice(0, cut).replace(/\/$/, "");
    const pd = this.popts.path_display;
    const piece = (r, base, size) => div().text_size(size).text_color(r.hit ? t.accent : base).when(r.hit, el => el.font_semibold()).child(r.text);
    const sel = i === this.pick.sel, cur = row.abs === this.file;
    const where = pd.includes("tail") ? [] : pd.includes("shorten") ? [{ text: shorten(dir), hit: false }] : runs(dir, row.pos, 0);
    return h_flex().id(`pk-${i}`).absolute().left(0).right(0).top(i * PICK_ROW).h(PICK_ROW).px(12).gap(8).items_center().overflow_hidden().cursor_pointer()
      .on_click((_e, cx) => { this.pick.sel = i; this.pickOpen(cx); })
      .child(div().w(8).flex_none().text_size(9).text_color(row.recent ? t.accent : t.border).child(row.recent ? "●" : ""))
      .child(h_flex().flex_none().children(runs(name, row.pos, cut).map(r => piece(r, sel ? t.foreground : t.muted, 13)))
        .when(Boolean(row.dir), el => el.child(div().text_size(13).text_color(t.dim).child("/"))))
      .child(h_flex().flex_1().min_w(0).overflow_hidden().children(where.map(r => piece(r, t.dim, 11.5))))
      .when(cur, el => el.child(div().flex_none().px(5).rounded(3).bg(t.surface).text_size(10.5).text_color(t.dim).child("open")));
  }

  // Telescope's layouts. horizontal: the prompt and list on the left, the
  // preview on the right (the default). center: one small box, the preview
  // (off unless previewer is true) above the prompt and list.
  pickPanel(t) {
    const p = this.pick, view = this.pickView, o = this.popts, lc = layoutOf(o);
    const center = o.layout_strategy === "center";
    // Without a preview the list alone needn't span the pane: it gets a list's width.
    const showPv = o.previewer ?? !center;
    const W = Math.max(center ? 320 : 360, sizeOf(lc.width, this.viewW - 40, Math.min(this.viewW - 40, center || !showPv ? 680 : 1240)));
    const H = Math.max(center ? 200 : 240, sizeOf(lc.height, this.viewH - 32, Math.min(this.viewH - 32, center ? (showPv ? 640 : 440) : 760)));
    // horizontal: today's split unless preview_width is set; too narrow, no preview.
    let pvW = 0, pvH = 0;
    if (showPv && !center && W >= 720) pvW = lc.preview_width != null ? sizeOf(lc.preview_width, W - 240, 0) : W - Math.round(Math.min(Math.max(W * 0.4, 320), 460));
    if (showPv && center) pvH = sizeOf(lc.preview_height ?? 0.5, H - 46 - 28 - 3 * PICK_ROW, 0);
    const listW = W - pvW, bodyH = H - 46 - 28 - pvH;   // minus the prompt, the footer and a center preview
    this.pickVis = Math.max(3, Math.floor((bodyH - 8) / PICK_ROW));
    const from = Math.max(0, p.top - 4), to = Math.min(p.rows.length, p.top + this.pickVis + 4);
    const folders = this.pickFolders, what = folders ? "folder" : "file", n = view ? view.rows.length : 0;
    // A capped listing: files count the first MAX_FILES; folders come from those files.
    const count = !view ? "" : view.folders ? `${n} folder${n === 1 ? "" : "s"}${view.capped ? ` (in the first ${view.files.length} of ${view.total} files)` : ""}`
      : view.capped ? `first ${n} of ${view.total} files` : `${n} file${n === 1 ? "" : "s"}`;
    const where = view ? `${view.kind === "git" ? "git" : "folder"} · ${this.tilde(view.root)} · ${count}` : "listing…";
    // The key hints; a box without a preview has room only for the main ones.
    const hint = center || !showPv ? `↵ ${folders ? "enter" : "open"} · ctrl-f ${folders ? "files" : "folders"} · ctrl-g up · Esc`
      : `↵ ${folders ? "enter" : "open"} · ctrl-f ${folders ? "files" : "folders"} · ctrl-g up${folders ? "" : " · ctrl-v split"} · ctrl-n/p move${showPv ? " · ctrl-d/u preview" : ""} · Esc close`;
    const glide = { duration: 130, easing: "ease-out" };
    const bottom = lc.prompt_position === "bottom";
    const prompt = h_flex().h(46).flex_none().px(14).gap(10).items_center().border_color(t.border).when(bottom, el => el.border_t(1)).when(!bottom, el => el.border_b(1))
      .child(div().text_size(16).text_color(t.accent).font_semibold().child(o.prompt_prefix))
      .child(Input.new(this.pickInput).flex_1().h(30).text_size(14).text_color(t.foreground).font_family(BODY()))
      .child(div().flex_none().text_size(11.5).text_color(p.query && !p.rows.length && view ? t.blocked : t.dim)
        .child(view ? `${p.rows.length ? p.sel + 1 : 0} / ${p.rows.length}` : ""));
    const list = div().id("md-pick-list").flex_1().min_h(0).relative().overflow_hidden().mt(4)
      .when(!p.rows.length, el => el.child(div().px(16).py(10).text_size(13).text_color(t.dim)
        .child(!view ? "listing…" : p.query ? `no ${what} matches` : folders ? "no folders with markdown here" : "no markdown files here")))
      .child(div().absolute().left(0).right(0).top(-p.top * PICK_ROW).h((p.rows.length || 1) * PICK_ROW).transition("top", glide)
        .when(p.rows.length > 0, el => el.child(div().id("md-pick-bar").absolute().left(6).right(6).top(p.sel * PICK_ROW + 2).h(PICK_ROW - 4)
          .rounded(6).bg(t.selected).transition("top", glide)))
        .children(p.rows.slice(from, to).map((row, k) => this.pickRow(row, from + k, t))));
    const column = v_flex().w(listW).flex_none().min_h(0).h_full()
      .when(pvW > 0, el => el.border_r(1).border_color(t.border))
      .when(!bottom, el => el.child(prompt)).child(list).when(bottom, el => el.child(prompt));
    const top = center ? Math.max(16, Math.round((this.viewH - H) / 3)) : 16;
    return div().id("md-pick-wrap").absolute().top(0).left(0).size_full()
      .on_scroll_wheel((e, cx) => { cx.stop_propagation(); this.scrollPreview(-e.delta.y / Z(), cx); })
      .child(div().id("md-pick-dim").absolute().top(0).left(0).size_full().bg(t.background).opacity(this.pickIn ? 0.6 : 0)
        .transition("opacity", { duration: 180, easing: "ease-out" }).on_mouse_down("left", (_e, cx) => this.closePicker(cx)))
      .child(h_flex().absolute().left(0).w_full().justify_center().top(this.pickIn ? top : top + 14)
        .opacity(this.pickIn).transition("opacity", { duration: 180, easing: "ease-out" }).transition("top", { duration: 220, easing: "ease-out" })
        .child(v_flex().id("md-pick").w(W).h(H).rounded(12).overflow_hidden().bg(t.popover).border_1().border_color(t.input).shadow_lg()
          .font_family(BODY()).on_mouse_down("left", (_e, cx) => cx.stop_propagation())
          .when(center && pvH > 0, el => el.child(h_flex().h(pvH).flex_none().border_b(1).border_color(t.border).child(this.previewPane(t, W))))
          .child(h_flex().flex_1().min_h(0).child(column).when(pvW > 0, el => el.child(this.previewPane(t, pvW))))
          .child(h_flex().h(28).flex_none().px(14).gap(12).items_center().border_t(1).border_color(t.border).bg(t.chrome).text_size(11.5).text_color(t.dim)
            .child(div().flex_1().min_w(0).truncate().text_color(this.pickErr ? t.blocked : t.dim).child(this.pickErr ?? this.pickNote ?? where))
            .child(div().flex_none().child(hint)))));
  }

  previewPane(t, w) {
    const pv = this.pv, p = this.pick, pad = 26;
    const head = pv ? this.tilde(pv.abs) : "";
    let body = [];
    if (pv && !pv.error) {
      // block() draws the preview's tokens with the viewer's own renderer; the
      // flag makes headings and links inert and the ids its own.
      const colW = this.colW; this.colW = Math.max(120, w - pad * 2); this.pvMode = true;
      try { body = pv.blocks.map((b, i) => this.block(b, `pv${i}`, t)); } finally { this.colW = colW; this.pvMode = false; }
    }
    return v_flex().flex_1().min_w(0).h_full().bg(t.background)
      .child(h_flex().h(30).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border).bg(t.chrome).text_size(11.5)
        .child(div().flex_1().min_w(0).truncate().text_color(t.dim).child(head))
        .when(Boolean(pv?.lines), el => el.child(div().flex_none().text_color(t.dim).child(`${pv.lines} lines`))))
      .child(div().id("md-pick-pv").flex_1().min_h(0).relative().overflow_hidden()
        .on_size_change((size, cx) => { this.pvViewH = size.height / Z(); })
        .opacity(this.pvLoading ? 0.45 : 1).transition("opacity", { duration: 140, easing: "ease-out" })
        .child(v_flex().absolute().left(0).w_full().top(-(p?.pvY ?? 0)).transition("top", { duration: STEP * 1.4, easing: "ease-out" })
          .px(pad).pt(6).pb(30).text_size(SIZE.body - 1).line_height(1.6).text_color(t.foreground)
          .on_size_change((size, cx) => { this.pvH = size.height / Z(); })
          .when(Boolean(pv?.error), el => el.child(div().pt(14).text_color(t.blocked).child(pv.error)))
          .when(Boolean(pv) && !pv.error && !pv.blocks.length, el => el.child(div().pt(14).text_color(t.dim).italic().child("empty file")))
          .when(!pv && Boolean(p?.rows[p.sel]?.dir), el => el.child(div().pt(14).text_color(t.dim).italic().child("no README here · Enter lists its files")))
          .children(body)
          .when(Boolean(pv?.more || pv?.cut), el => el.child(div().pt(12).text_size(12).text_color(t.dim).italic()
            .child(pv.cut ? "… more below, Enter opens the file" : `… ${pv.more} more block${pv.more === 1 ? "" : "s"}, Enter opens the file`)))));
  }

  // ---- key help (? or h) ----
  // Fades and drifts in; j/k, ctrl-d/ctrl-u, g/G and the wheel scroll it (its
  // own viewport: top(-helpY), plain divs can't be scrolled from code); any
  // other key fades it out, then it unmounts.
  openHelp(cx) {
    this.help = true; this.helpIn = 0; this.helpY = 0; this.helpQ = ""; this.helpInput.set_value(""); cx.notify();
    cx.timer.after(16, cx => { this.helpIn = 1; cx.notify(); });
  }

  closeHelp(cx) {
    this.helpIn = 0; if (this.helpTyping) this.handle.focus(); cx.notify();
    cx.timer.after(180, cx => { if (!this.helpIn) { this.help = false; cx.notify(); } });
  }

  scrollHelp(dy, cx) {
    const max = Math.max(0, (this.helpH ?? 0) - (this.helpViewH ?? 0));
    this.helpY = Math.max(0, Math.min((this.helpY ?? 0) + dy, max)); cx.notify();
  }

  helpKeys(k, mod, cx) {
    const half = Math.max(80, (this.helpViewH ?? 300) / 2);
    if (k === "j" || k === "down") return this.scrollHelp(40, cx);
    if (k === "k" || k === "up") return this.scrollHelp(-40, cx);
    if (mod.control && k === "d") return this.scrollHelp(half, cx);
    if (mod.control && k === "u") return this.scrollHelp(-half, cx);
    if (k === "g") return this.scrollHelp(-1e9, cx);
    if (k === "G") return this.scrollHelp(1e9, cx);
    if (k === "/") { this.helpInput.focus(); cx.notify(); return; }
    this.closeHelp(cx);
  }

  helpPanel(t) {
    const key = k => div().px(6).rounded(4).bg(t.surface).border_1().border_color(t.border).text_color(t.foreground).child(k);
    const w = Math.min(720, Math.max(280, this.colW + PAD * 2 - 40));
    const maxView = Math.max(110, this.viewH - 36 - 48);   // the panel's max height minus its padding and header
    const viewH = Math.min(this.helpH ?? maxView, maxView), scrolls = (this.helpH ?? 0) > maxView + 0.5;
    // The filter: every word must appear in the section name, the keys or the description.
    const words = this.helpQ.toLowerCase().split(/\s+/).filter(Boolean);
    const hit = (section, [keys, what]) => words.every(w => `${section} ${keys} ${what}`.toLowerCase().includes(w));
    const cols = HELP.map(col => col.map(([section, rows]) => [section, rows.filter(r => hit(section, r))]).filter(([, rows]) => rows.length)).filter(col => col.length);
    const count = cols.reduce((n, col) => n + col.reduce((m, [, rows]) => m + rows.length, 0), 0);
    return h_flex().id("md-help-wrap").absolute().left(0).w_full().justify_center().top(this.helpIn ? 18 : 30)
      .opacity(this.helpIn).transition("opacity", { duration: 180, easing: "ease-out" }).transition("top", { duration: 220, easing: "ease-out" })
      .child(v_flex().id("md-help").w(w).overflow_hidden()
        .py(10).rounded(10).bg(t.popover).border_1().border_color(t.input).shadow_md().text_size(13).font_family(BODY())
        .on_scroll_wheel((e, cx) => { cx.stop_propagation(); this.scrollHelp(-e.delta.y / Z(), cx); })
        // The filter box is always mounted (focusing an unmounted Input loses the keyboard).
        .child(h_flex().mx(12).mb(8).h(30).px(8).gap(8).items_center().rounded(8).bg(t.background)
          .border_1().border_color(this.helpTyping ? t.accent : t.input)
          .child(div().text_color(t.dim).text_size(13).child("⌕"))
          .child(Input.new(this.helpInput).flex_1().h(24).text_size(13).text_color(t.foreground).font_family(BODY()))
          .child(div().flex_none().text_size(11).text_color(this.helpQ && !count ? t.blocked : t.dim)
            .child(this.helpTyping ? (this.helpQ ? `${count} key${count === 1 ? "" : "s"} · Enter: j/k · Esc` : "Enter: j/k · Esc")
              : this.helpQ ? `${count} key${count === 1 ? "" : "s"} · / edit` : (scrolls ? "/ search · j/k scroll · other keys close" : "/ search · other keys close"))))
        .child(div().id("md-help-view").relative().overflow_hidden().w_full().h(viewH)
          .on_size_change((size, cx) => { this.helpViewH = size.height / Z(); })
          .when(scrolls, el => el.child(div().absolute().right(3).w(5).rounded(3).bg(t.border)
            .h(Math.max(24, viewH * viewH / this.helpH)).top((viewH - Math.max(24, viewH * viewH / this.helpH)) * (this.helpY ?? 0) / Math.max(1, this.helpH - viewH))
            .transition("top", { duration: STEP, easing: "ease-out" })))
        .child(h_flex().absolute().left(0).w_full().top(-(this.helpY ?? 0)).transition("top", { duration: STEP, easing: "ease-out" })
          .on_size_change((size, cx) => { const h = size.height / Z(); if (Math.abs(h - (this.helpH ?? 0)) > 0.5) { this.helpH = h; cx.notify(); } })
          .flex_wrap().items_start()
          .when(!count, el => el.child(div().px(16).py(6).text_color(t.dim).italic().child("No keys match")))
          .children(cols.map(col => v_flex().flex_1().min_w(320)
          .children(col.map(([section, rows]) => v_flex().px(16).pb(8)
            .child(div().pb(2).text_size(11).font_semibold().text_color(t.accent).child(section))
            .children(rows.map(([keys, what]) => h_flex().gap(10).items_center().py(1)
              .child(h_flex().w(118).flex_none().gap(4).text_size(12).children(keys.split(" ").map(key)))
              .child(div().flex_1().min_w(0).text_color(t.muted).child(what)))))))))));
  }

  // ---- cursor ----
  yOf(i) { let y = TOP; for (let j = 0; j < i; j++) if (!this.hidden[j]) y += this.heights[j] ?? ROW_GUESS; return y; }

  move(i, d) { let j = i; for (;;) { const n = j + d; if (n < 0 || n >= this.blocks.length) return j; j = n; if (!this.hidden[j]) return j; } }

  // The first block on screen, for when the cursor was scrolled away from.
  firstOnScreen() {
    let y = TOP;
    for (let i = 0; i < this.blocks.length; i++) { if (this.hidden[i]) continue; const h = this.heights[i] ?? ROW_GUESS; if (y + h > this.offset + 10) return i; y += h; }
    return 0;
  }

  onScreen(i) { const y = this.yOf(i), h = this.heights[i] ?? ROW_GUESS; return y + h > this.offset && y < this.offset + this.viewH; }

  setCursor(i, cx, center) {
    this.cursor = Math.max(0, Math.min(i, this.blocks.length - 1)); this.aim = null;
    const y = this.yOf(this.cursor), h = this.heights[this.cursor] ?? ROW_GUESS, m = 60, from = this.offset;
    if (center) this.offset = this.clamp(y + h / 2 - this.viewH / 2);
    else if (y < this.offset + m || h > this.viewH - 2 * m) this.offset = this.clamp(y - m);
    else if (y + h > this.offset + this.viewH - m) this.offset = this.clamp(y + h - this.viewH + m);
    this.motion = Math.abs(this.offset - from) > this.viewH / 2 ? GLIDE : STEP;
    cx.notify();
  }

  // Move by about `px` pixels of content, block by block.
  moveBy(px, cx) {
    let i = this.cursor, gone = 0; const d = Math.sign(px);
    while (gone < Math.abs(px)) { const n = this.move(i, d); if (n === i) break; gone += this.heights[d > 0 ? i : n] ?? ROW_GUESS; i = n; }
    this.offset = this.clamp(this.offset + px); this.setCursor(i, cx); this.motion = 200;
  }

  heading(d) { let i = this.cursor; for (;;) { const n = this.move(i, d); if (n === i) return i; i = n; if (this.blocks[i].type === "heading") return i; } }

  range() { const a = this.anchor ?? this.cursor; return [Math.min(a, this.cursor), Math.max(a, this.cursor)]; }

  // Source lines and text of the current selection (or the cursor block).
  // Rows picked out of a table keep its header and |---| line, so the text is
  // still a table; `lines` stays the rows themselves.
  selection() {
    const [a, b] = this.range(), from = this.blocks[a].from, to = this.blocks[b].to, src = this.src.split("\n");
    let text = src.slice(from - 1, to).join("\n");
    const s = this.blocks[a];
    if (s.type === "trow" && s.r >= 0) {
      let h = a; while (h > 0 && this.blocks[h - 1].type === "trow" && this.blocks[h - 1].table === s.table) h--;
      const top = this.blocks[h];
      // The header block when it's shown; otherwise the two lines above the first row.
      const head = top.r < 0 ? src.slice(top.from - 1, top.to) : src.slice(top.from - 3, top.from - 1);
      if (head.length === 2) text = `${head.join("\n")}\n${text}`;
    }
    return { file: this.file, lines: [from, to], text };
  }

  // The motion's loop runs on a clock shared by every view, so a cursor that just
  // moved could land mid-blink, unlit. As in an editor, it stays solid while it
  // moves and starts pulsing or blinking once it has rested REST ms.
  rest(cx) {
    if (this.cursor === this.restAt) return;
    this.restAt = this.cursor; this.resting = false;
    if (this.cmotion === "steady") return;
    const gen = ++this.restGen;
    cx.timer.after(REST, cx => { if (gen === this.restGen) { this.resting = true; cx.notify(); } });
  }

  saveCursor() {
    exec("sh", ["-c", 'mkdir -p "$1" && printf %s "$2" > "$1/.cursor.$$" && mv -f "$1/.cursor.$$" "$1/cursor.json"', "cursor", NOTES(), JSON.stringify({ look: this.look, motion: this.cmotion, numbers: this.numbers })]);
  }

  yank() { const { text } = this.selection(); exec("sh", ["-c", 'printf %s "$1" | LANG=en_US.UTF-8 pbcopy', "yank", text]); this.flash = "copied"; }

  // Pin the selection for Claude: `mdh sel` prints it.
  share() {
    const sel = this.selection();
    this.picked = this.range();
    const nd = this.notesDir();
    if (nd) this.ex("sh", ["-c", 'mkdir -p "$1" && printf %s "$2" > "$1/selection.json"', "share", nd, JSON.stringify({ ...sel, at: new Date().toISOString() })]).catch(() => {});
    this.flash = `📌 pinned lines ${sel.lines[0]}–${sel.lines[1]} for Claude · ask it about "this" · Esc unpins`;
  }

  keys(e, cx) {
    if (this.pick) return this.pickKeys(e, cx);
    if (this.helpTyping) {
      // Esc empties the filter first, then leaves the box; the help stays open.
      if (e.key === "escape") {
        if (this.helpQ) { this.helpInput.set_value(""); this.helpQ = ""; this.helpY = 0; } else this.handle.focus();
        cx.notify(); cx.stop_propagation();
      }
      return;
    }
    if (this.typing) {
      if (e.key === "escape") { this.closeSearch(cx); cx.stop_propagation(); }
      return;
    }
    const mod = e.modifiers ?? {};
    // Option types a character on many layouts (# is Option-3 on a UK or German Mac):
    // that character is the key; any other Option chord stays the app's.
    const typed = mod.alt && !mod.platform && !mod.control && e.key_char?.length === 1 ? e.key_char : null;
    if (mod.platform || (mod.alt && !typed)) return;
    const k = typed ?? (mod.shift && e.key.length === 1 ? (e.key_char ?? e.key.toUpperCase()) : e.key);
    if (this.help) { if (!MODIFIER_KEYS.includes(e.key)) this.helpKeys(k, mod, cx); return cx.stop_propagation(); }
    if (this.zoom) return this.zoomKeys(k, mod, cx);
    const half = Math.max(80, this.viewH / 2), page = Math.max(100, this.viewH - 80);
    if (this.outline) {
      const hs = this.headings();
      if (e.key === "j" || e.key === "down") this.oi = Math.min(this.oi + 1, hs.length - 1);
      else if (e.key === "k" || e.key === "up") this.oi = Math.max(this.oi - 1, 0);
      else if (e.key === "enter") { this.outline = false; if (hs[this.oi] !== undefined) { this.cursor = hs[this.oi]; this.aimAt(hs[this.oi]); } }
      else if (e.key === "escape" || e.key === "o") this.outline = false;
      return cx.notify();
    }
    this.flash = null;
    if (mod.control) {
      // ctrl-e / ctrl-y: scroll the view a line (40px) without moving the cursor, as in vim.
      if (e.key === "e" || e.key === "y") { this.scrollBy(e.key === "e" ? 40 : -40, cx); this.motion = STEP; return cx.stop_propagation(); }
      if (e.key === "p") { this.openPicker(cx); return cx.stop_propagation(); }
      const c = { d: half, u: -half, f: page, b: -page }[e.key];
      if (c) { this.moveBy(c, cx); cx.stop_propagation(); }
      return;
    }
    // Pull the cursor back on screen if the wheel scrolled it away.
    if (!this.onScreen(this.cursor) && ["j", "k", "down", "up", "V", "v", "y", "enter"].includes(k)) this.cursor = this.firstOnScreen();
    if (/^[0-9]$/.test(k) && (this.count || k !== "0")) { this.count += k; return; }
    const n = Math.max(1, parseInt(this.count || "1", 10)); this.count = "";
    const p = this.pending; this.pending = "";
    if (p === "g") { if (k === "g") this.setCursor(this.move(-1, 1), cx); return; }
    if (p === "z") {
      const h = this.blocks[this.cursor]?.type === "heading" ? this.cursor : this.sectionOf(this.cursor);
      if (k === "z") this.setCursor(this.cursor, cx, true);
      if (k === "a" && h !== null) { this.toggleFold(h); this.setCursor(h, cx); }
      if (k === "c" && h !== null) { this.folded.add(h); this.refold(); this.setCursor(h, cx); }
      if (k === "o" && h !== null) { this.folded.delete(h); this.refold(); cx.notify(); }
      if (k === "M") { this.blocks.forEach((b, i) => { if (b.type === "heading" && b.depth >= 2) this.folded.add(i); }); this.refold(); this.setCursor(this.hidden[this.cursor] ? this.sectionOf(this.cursor) ?? 0 : this.cursor, cx); }
      if (k === "R") { this.folded.clear(); this.refold(); cx.notify(); }
      return;
    }
    let to = null;
    switch (k) {
      case "j": case "down": to = this.cursor; for (let x = 0; x < n; x++) to = this.move(to, 1); break;
      case "k": case "up": to = this.cursor; for (let x = 0; x < n; x++) to = this.move(to, -1); break;
      case "d": return this.moveBy(half, cx);
      case "u": return this.moveBy(-half, cx);
      case "space": case "pagedown": return this.moveBy(page, cx);
      case "pageup": return this.moveBy(-page, cx);
      case "G": to = this.move(this.blocks.length, -1); break;
      case "}": to = this.heading(1); break;
      case "{": to = this.heading(-1); break;
      case "]": return this.stepChange(1, cx);
      case "[": return this.stepChange(-1, cx);
      case "c": this.changed = new Set(); this.removed = new Map(); return cx.notify();
      case "o": { const hs = this.headings(), cur = this.sectionOf(this.cursor); this.oi = Math.max(0, hs.indexOf(cur)); this.outline = true; return cx.notify(); }
      case "backspace": return this.back(cx);
      case "g": case "z": this.pending = k; return;
      case "V": case "v": this.anchor = this.anchor === null ? this.cursor : null; return cx.notify();
      case "y": this.yank(); this.anchor = null; return cx.notify();
      case "p": this.share(); this.anchor = null; return cx.notify();
      case "enter": return this.activate(cx);
      case "escape":
        if (this.anchor !== null) this.anchor = null;
        else if (this.searching) return this.closeSearch(cx);
        else { this.picked = null; const nd = this.notesDir(); if (nd) this.ex("rm", ["-f", `${nd}/selection.json`]).catch(() => {}); }
        return cx.notify();
      case "#": this.numbers = nextNumberMode(this.numbers); this.flash = `line numbers: ${this.numbers}`; this.saveCursor(); return cx.notify();
      case "C": this.look = nextLook(this.look); this.flash = `cursor: ${LOOK_NAMES[this.look]} · C next look · B motion`; this.saveCursor(); return cx.notify();
      case "B": this.cmotion = nextMotion(this.cmotion); this.flash = `cursor motion: ${this.cmotion} · B next · C look`; this.resting = true; this.saveCursor(); return cx.notify();
      case "O": return this.openVideo(cx);
      case "/": return this.openSearch(cx);
      case "?": case "h": return this.openHelp(cx);
      case "q": { const me = panes().find(p => p.focused && p.mod === MOD); if (me) run("pane.close", { pane: me.pane }); return; }
      case "n": case "N": {
        if (this.matches.length) { this.step(k === "n" ? 1 : -1); this.cursor = this.matches[this.mi]; return cx.notify(); }
        const c = this.notes.highlights.length; if (!c) return;
        this.cur = ((this.cur ?? -1) + (k === "n" ? 1 : c - 1)) % c;
        const i = this.notes.highlights[this.cur]?.blocks?.[0]; if (i !== undefined) { this.aimAt(i); this.cursor = i; }
        return cx.notify();
      }
    }
    if (to !== null) this.setCursor(to, cx);
  }

  // The heading whose section holds block i.
  sectionOf(i) { for (let j = Math.min(i, this.blocks.length - 1); j >= 0; j--) if (this.blocks[j]?.type === "heading") return j; return null; }

  render(cx) {
    this.renderCx = cx;   // inline formulas met while rendering start their batch on it
    // Only rows within a screen of the view are built (spacer() stands in for the
    // rest), so a long paper scrolls as fast as a short one.
    // During a long glide the rows where it started stay built too, so the slide shows text.
    const vh = this.viewH || 1200;   // before the first size report, a screen's guess
    if (this.drawnOffset !== undefined && this.motion > 0 && Math.abs(this.drawnOffset - this.offset) > vh) { this.glideFrom = this.drawnOffset; this.glideEnd = Date.now() + this.motion; }
    else if (Date.now() > (this.glideEnd ?? 0)) this.glideFrom = undefined;
    this.drawnOffset = this.offset;
    const around = (y, h, o) => y + h > o - vh && y < o + 2 * vh;
    this.near = []; for (let i = 0, y = TOP; i < this.blocks.length; i++) {
      if (this.hidden[i]) continue;
      const h = this.heights[i] ?? ROW_GUESS;
      this.near[i] = around(y, h, this.offset) || (this.glideFrom !== undefined && around(y, h, this.glideFrom)); y += h;
    }
    const t = theme();
    if (this.figTokens && !this.figBusy && this.figTheme() !== this.figSig) {
      this.figSig = this.figTheme(); this.figBusy = true;
      const tokens = this.figTokens;
      cx.spawn(async cx => {
        try { await this.renderFigures(tokens); } finally { this.figBusy = false; }
        if (this.figTokens === tokens) cx.notify();
      });
    }
    const thumbH = this.contentH > this.viewH ? Math.max(30, this.viewH * this.viewH / this.contentH) : 0;
    const thumbY = thumbH ? (this.viewH - thumbH) * this.offset / (this.contentH - this.viewH) : 0;
    return v_flex().id("md").size_full().min_h(0).bg(t.background).text_color(t.foreground)
      .track_focus(this.handle).on_key_down((e, cx) => { this.keys(e, cx); this.rest(cx); })
      .child(this.headerBar(t))
      .child(div().id("md-view").flex_1().min_h(0).relative().overflow_hidden()
        .on_size_change((size, cx) => { this.viewH = size.height / Z(); this.viewW = size.width / Z(); if (this.zoom) this.clampZoom(); this.offset = this.clamp(this.offset); this.reaim(); cx.notify(); })
        .on_scroll_wheel((e, cx) => { if (!this.zoom) this.scrollBy(-e.delta.y / Z(), cx); })
        .on_mouse_move((e, cx) => { if (this.barDrag) this.dragBar(e, thumbH, cx); })
        .on_mouse_up("left", (_e, cx) => { if (this.barDrag) { this.barDrag = null; cx.notify(); } })
        // A release outside the pane never reaches it, so leaving the pane ends a drag.
        .on_hover((hovered, cx) => { if (!hovered && this.barDrag) { this.barDrag = null; cx.notify(); } })
        .on_mouse_down("left", () => { this.barDrag = null; })
        .child(div().id("md-content").absolute().left(0).w_full().top(-this.offset)
          .transition("top", { duration: this.motion, easing: this.motion === GLIDE ? "ease-in-out" : "ease-out" })
          .on_size_change((size, cx) => { this.contentH = size.height / Z(); this.reaim(); cx.notify(); })
          .child(h_flex().w_full().justify_center()
            .child(v_flex().id("md-col").w_full().max_w(MAX_W).px(PAD).pt(TOP).pb(80)
              .on_size_change((size, cx) => { const w = Math.max(120, size.width / Z() - PAD * 2); if (Math.abs(w - this.colW) > 1) { this.colW = w; this.resizeVideos(); cx.notify(); } }).font_family(BODY()).text_size(SIZE.body).line_height(1.65)
              .when(Boolean(this.error), el => el.child(div().text_color(t.blocked).child(this.error)))
              .children(this.blocks.map((tok, i) => this.near[i] ? this.row(tok, i, t) : this.spacer(tok, i)))
              .when(this.removed.has(this.blocks.length), el => el.child(this.removedMark(this.removed.get(this.blocks.length), t))))))
        .when(!this.file && !this.error, el => el.child(this.emptyState(t)))
        .when(thumbH > 0, el => el.child(div().id("md-bar").absolute().top(0).right(0).w(14).h_full()
          .on_mouse_down("left", (e, cx) => { cx.stop_propagation(); this.grabBar(e, thumbH, thumbY, cx); })
          .on_mouse_up("left", (_e, cx) => { this.barDrag = null; cx.notify(); })
          .child(div().absolute().right(3).w(this.barDrag ? 8 : 6).rounded(4).bg(this.barDrag ? t.muted : t.border).hover(s => s.bg(t.muted))
            .top(thumbY).h(thumbH).transition("top", { duration: this.motion, easing: "ease-out" }))))
        .when(this.outline, el => el.child(this.outlinePanel(t)))
        .when(Boolean(this.zoom), el => el.child(this.zoomPanel(t)))
        .when(this.help, el => el.child(this.helpPanel(t)))
        .when(this.searching, el => el.child(h_flex().absolute().top(10).right(20).w(340).h(38).px(10).gap(8).items_center()
          .rounded(10).bg(t.popover).border_1().border_color(this.typing ? t.accent : t.input).shadow_md()
          .child(div().text_color(t.dim).text_size(14).child("⌕"))
          .child(Input.new(this.input).flex_1().h(30).text_size(14).text_color(t.foreground).font_family(BODY()))
          .child(div().text_size(12).text_color(this.query && !this.matches.length ? t.blocked : t.dim)
            .child(this.query ? (this.matches.length ? `${this.mi + 1}/${this.matches.length}` : "none") : ""))
          .child(div().id("md-search-close").px(4).cursor_pointer().text_color(t.dim).hover(s => s.text_color(t.foreground))
            .on_click((_e, cx) => this.closeSearch(cx)).child("✕"))))
        .when(Boolean(this.pick), el => el.child(this.pickPanel(t))))
      .child(this.statusBar(t));
  }

  // No file yet (an empty viewer, or Esc in its picker): one calm line pointing at ctrl-p.
  emptyState(t) {
    const chip = k => div().px(6).rounded(4).bg(t.surface).border_1().border_color(t.border).text_size(12).text_color(t.muted).child(k);
    return v_flex().id("md-empty").absolute().top(0).left(0).size_full().items_center().justify_center().gap(10).font_family(BODY())
      .child(h_flex().gap(10).items_center().text_size(SIZE.body).text_color(t.muted)
        .child(div().child("Find a markdown file")).child(div().text_color(t.dim).child("·")).child(chip("ctrl-p")))
      .child(h_flex().gap(6).items_center().text_size(12).text_color(t.dim)
        .when(Boolean(this.pickRoot), el => el.child(div().child(`in ${this.tilde(this.pickRoot)}`)).child(div().child("·")))
        .child(chip("q")).child(div().child("close")));
  }

  // Top: where you are. The file (home shortened), and a crumb back after a link.
  headerBar(t) {
    const path = this.tilde((this.file ?? "")), name = path.split("/").pop(), dir = path.slice(0, path.length - name.length);
    const prev = this.history.length ? this.history[this.history.length - 1].file.split("/").pop() : null;
    return h_flex().h(30).flex_none().px(14).gap(10).items_center().bg(t.chrome).border_b(1).border_color(t.border).text_size(12)
      .when(Boolean(prev), el => el.child(div().id("md-back").px(6).rounded(4).cursor_pointer().text_color(t.accent).hover(s => s.bg(t.hover))
        .on_click((_e, cx) => this.back(cx)).child(`← ${prev}`)))
      .when(Boolean(this.on), el => el.child(div().flex_none().px(6).rounded(4).bg(t.accent + "26").text_color(t.accent).child(this.on)))
      .child(h_flex().flex_1().min_w(0).items_center().child(div().truncate().text_color(t.dim).child(dir)).child(div().flex_none().text_color(t.foreground).font_semibold().child(name)))
      .when(this.changed.size > 0, el => el.child(div().px(8).rounded(4).bg(t.ansi2 + "22").text_color(t.ansi2).child(`${this.changed.size} changed`)));
  }

  // Bottom: a vim-style status line. Mode and messages left; section, line and progress right.
  statusBar(t) {
    const b = this.blocks[this.cursor], lines = this.lines;
    const pct = this.contentH <= this.viewH ? 100 : Math.round(100 * this.offset / (this.contentH - this.viewH));
    const sec = this.sectionOf(this.cursor), secName = sec !== null ? plain(this.blocks[sec].tokens) : "";
    const mode = this.pick ? "FIND" : this.anchor !== null ? "VISUAL" : this.searching ? "SEARCH" : this.outline ? "OUTLINE" : "NORMAL";
    return h_flex().h(24).flex_none().px(10).gap(10).items_center().bg(t.chrome).border_t(1).border_color(t.border).text_size(11.5).font_family(BODY())
      .child(div().px(6).rounded(3).font_semibold().bg(mode === "NORMAL" ? t.surface : t.accent).text_color(mode === "NORMAL" ? t.muted : t.accent_foreground).child(mode))
      .when(Boolean(this.pending || this.count), el => el.child(div().text_color(t.dim).child(this.count + this.pending)))
      .child(div().flex_1().min_w(0).truncate().text_color(t.ansi2).child(this.flash ?? ""))
      .when(Boolean(secName), el => el.child(div().max_w(220).truncate().text_color(t.dim).child(`§ ${secName}`)))
      .when(Boolean(b), el => el.child(div().text_color(t.muted).child(`L${b.from}/${lines}`)))
      .child(div().w(36).text_right().text_color(t.muted).child(pct <= 0 ? "Top" : pct >= 100 ? "Bot" : `${pct}%`));
  }
}
