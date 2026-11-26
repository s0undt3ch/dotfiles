// The ctrl-p file picker's logic, kept free of Herdr APIs so node can test it:
// which markdown files to offer, the recently-opened list, and fuzzy matching.

// At most this many files are listed; a folder (no git) is searched this deep.
export const MAX_FILES = 5000, FIND_DEPTH = 4, MAX_RECENT = 100;
const MD = /\.(md|markdown)$/i;
// Folders never worth listing, even when git doesn't ignore them.
const SKIP = new Set(["node_modules", ".git", ".cache"]);
const skipped = rel => rel.split("/").some(part => SKIP.has(part));

const depth = p => p.split("/").length;
const byDepth = (a, b) => depth(a) - depth(b) || (a < b ? -1 : a > b ? 1 : 0);

// "/a/b/c" + "../../x" → "/a/x" (no symlink resolution: keeps the person's spelling).
export function join(dir, rel) {
  const out = [];
  for (const part of `${dir}/${rel}`.split("/")) {
    if (!part || part === ".") continue;
    if (part === "..") out.pop(); else out.push(part);
  }
  return "/" + out.join("/");
}

// Markdown files under the git work tree holding `dir` (tracked plus untracked,
// not ignored), else under `dir` itself, FIND_DEPTH levels deep. Every path goes
// to git/find as its own argument, never through a shell.
// `exec(cmd, args)` resolves to { code, stdout, stderr } (Herdr's exec).
// Returns { root, kind: "git" | "folder", files: [relative paths], total, capped }.
// A document can live in a cloned repo that isn't trusted. Its .git/config may
// name programs git runs on its own (core.fsmonitor runs on ls-files --others),
// so every call turns those off, and git is used only in a work tree the person
// owns (else the folder listing below). Herdr's exec takes no env, so system
// config (GIT_CONFIG_NOSYSTEM) can't be skipped; that file isn't the repo's.
const GIT_SAFE = ["-c", "core.fsmonitor=false", "-c", "core.untrackedCache=false"];

async function ownedByMe(exec, path) {
  const me = await exec("id", ["-u"]).catch(() => null);
  let st = await exec("stat", ["-f", "%u", path]).catch(() => null);                        // macOS / BSD
  if (!st || st.code !== 0) st = await exec("stat", ["-c", "%u", path]).catch(() => null);   // GNU
  const uid = me?.code === 0 ? me.stdout.trim() : "";
  return Boolean(uid && st?.code === 0 && st.stdout.trim() === uid);
}

// opts: { noIgnore: also git-ignored files, depth: how deep a folder (no git) is searched }.
export async function listFiles(exec, dir, { noIgnore = false, depth = FIND_DEPTH } = {}) {
  const top = await exec("git", [...GIT_SAFE, "-C", dir, "rev-parse", "--show-cdup"]).catch(() => null);
  if (top && top.code === 0) {
    const root = join(dir, top.stdout.trim());
    if (await ownedByMe(exec, root)) {
      const r = await exec("git", [...GIT_SAFE, "-C", root, "ls-files", "-z", "--cached", "--others", ...(noIgnore ? [] : ["--exclude-standard"]),
        "--", ":(icase)*.md", ":(icase)*.markdown"]).catch(() => null);
      if (r && r.code === 0) return finish(root, "git", [...new Set(r.stdout.split("\0"))].filter(p => p && MD.test(p) && !skipped(p)));
    }
  }
  // -H: follow a symlink given as the root itself (/tmp -> private/tmp), none inside the tree.
  const r = await exec("find", ["-H", dir, "-maxdepth", String(depth),
    "(", "-name", "node_modules", "-o", "-name", ".git", "-o", "-name", ".cache", "-o", "-name", "Library", "-o", "-name", ".Trash", ")", "-prune",
    "-o", "-type", "f", "(", "-iname", "*.md", "-o", "-iname", "*.markdown", ")", "-print"]).catch(() => ({ stdout: "" }));
  const base = dir.replace(/\/+$/, "");
  const files = (r.stdout || "").split("\n").filter(p => p.startsWith(base + "/")).map(p => p.slice(base.length + 1));
  return finish(base || "/", "folder", files.filter(p => !skipped(p)));
}

function finish(root, kind, files) {
  files.sort(byDepth);
  return { root, kind, files: files.slice(0, MAX_FILES), total: files.length, capped: files.length > MAX_FILES };
}

// ---- options (~/.config/herdr-md/picker.json) ----
// Telescope's option names, so a Neovim config reads the same. `files: false`
// (folders only) comes from telescope-file-browser. null means "as before":
// with no file, the picker looks and lists exactly as it always has.
export const PICK_DEFAULTS = {
  layout_strategy: "horizontal",   // "horizontal" (list | preview) or "center" (one small box)
  layout_config: {},               // width, height, preview_width, preview_height, prompt_position; per strategy too
  previewer: null,                 // null: on for horizontal, off for center
  files: true,                     // false: list folders (that hold markdown) instead of files
  hidden: true,                    // dot files and dot folders
  no_ignore: false,                // git-ignored files too
  file_ignore_patterns: [],        // regexes (JavaScript, not Lua) tested against the relative path
  path_display: [],                // "tail" (name only) or "shorten" (folders cut to one letter)
  prompt_prefix: "›",
  depth: FIND_DEPTH,               // how deep a folder without git is searched
};
const STRATEGIES = ["horizontal", "center"], SIZES = ["width", "height", "preview_width", "preview_height"];

// picker.json's text → { opts, error }. Bad JSON leaves every default; a bad
// value leaves that one default. error names the first problem, for the footer.
export function parseConfig(text) {
  const opts = { ...PICK_DEFAULTS, layout_config: {}, ignore: [] }, errs = [];
  if (text == null || !text.trim()) return { opts, error: null };
  let c;
  try { c = JSON.parse(text); } catch (e) { return { opts, error: `picker.json: ${String(e.message || e).slice(0, 80)}` }; }
  if (!c || typeof c !== "object" || Array.isArray(c)) return { opts, error: "picker.json: expected an object { … }" };
  const bad = (k, want) => errs.push(`picker.json: ${k} should be ${want}`);
  const take = (k, ok, want) => { if (k in c) { if (ok(c[k])) opts[k] = c[k]; else bad(k, want); } };
  take("layout_strategy", v => STRATEGIES.includes(v), `"horizontal" or "center"`);
  take("previewer", v => typeof v === "boolean" || v === null, "true or false");
  for (const k of ["files", "hidden", "no_ignore"]) take(k, v => typeof v === "boolean", "true or false");
  take("prompt_prefix", v => typeof v === "string" && v.length <= 8, "a short string");
  take("depth", v => Number.isInteger(v) && v >= 1 && v <= 12, "a whole number from 1 to 12");
  take("path_display", v => Array.isArray(v) && v.every(x => x === "tail" || x === "shorten"), `a list of "tail" or "shorten"`);
  take("file_ignore_patterns", v => Array.isArray(v) && v.every(x => typeof x === "string"), "a list of strings");
  for (const p of opts.file_ignore_patterns) {
    try { opts.ignore.push(new RegExp(p)); } catch { bad(`file_ignore_patterns "${p}"`, "a valid regex"); }
  }
  // layout_config: flat sizes apply to every strategy; { center: { … } } to one.
  const lc = c.layout_config;
  if (lc !== undefined) {
    if (!lc || typeof lc !== "object" || Array.isArray(lc)) bad("layout_config", "an object");
    else {
      const sizes = (o, at, into) => {
        for (const [k, v] of Object.entries(o)) {
          if (STRATEGIES.includes(k) && at === "layout_config") {
            if (v && typeof v === "object" && !Array.isArray(v)) sizes(v, `layout_config.${k}`, into[k] = {}); else bad(`layout_config.${k}`, "an object");
          } else if (SIZES.includes(k)) {
            if (typeof v === "number" && v > 0) into[k] = v; else bad(`${at}.${k}`, "a number (0–1 a fraction, more: pixels)");
          } else if (k === "prompt_position") {
            if (v === "top" || v === "bottom") into[k] = v; else bad(`${at}.${k}`, `"top" or "bottom"`);
          }
        }
      };
      sizes(lc, "layout_config", opts.layout_config);
    }
  }
  return { opts, error: errs[0] ?? null };
}

// The layout_config for the strategy in use: per-strategy values over flat ones.
export function layoutOf(opts) {
  const lc = opts.layout_config ?? {}, flat = {};
  for (const [k, v] of Object.entries(lc)) if (!STRATEGIES.includes(k)) flat[k] = v;
  return { ...flat, ...(lc[opts.layout_strategy] ?? {}) };
}

// A size from layout_config: 0–1 is a fraction of `total`, more is pixels;
// none gives `auto`. Never more than `total`.
export function sizeOf(v, total, auto) {
  const px = v == null ? auto : v <= 1 ? total * v : v;
  return Math.round(Math.max(0, Math.min(px, total)));
}

// ---- what the picker lists ----
// The listing narrowed to `dir` (a folder at or under list.root): its files,
// relative to it. Re-rooting into a folder of a git repo keeps git's listing.
export function within(list, dir) {
  const base = dir.replace(/\/+$/, "") || "/";
  if (base === list.root) return list;
  if (!base.startsWith(list.root + "/")) return { ...list, root: base, files: [], total: 0, capped: false };
  const pre = base.slice(list.root.length + 1) + "/";
  const files = list.files.filter(f => f.startsWith(pre)).map(f => f.slice(pre.length));
  return { ...list, root: base, files, total: files.length, capped: list.capped };
}

// Every folder that holds a listed file, at any depth, shallow first.
export function foldersOf(files) {
  const out = new Set();
  for (const f of files) for (let i = f.indexOf("/"); i > 0; i = f.indexOf("/", i + 1)) out.add(f.slice(0, i));
  return [...out].sort(byDepth);
}

// The listing as the options want it shown: hidden and ignored paths dropped,
// then folders instead of files when `folders`. files stays the full markdown
// list (for a folder's README); rows is what the picker ranks.
export function shape(list, opts, folders) {
  const keep = rel => (opts.hidden || !rel.split("/").some(p => p.startsWith("."))) && !opts.ignore?.some(r => r.test(rel));
  const files = list.files.filter(keep);
  if (!folders) return { ...list, files, rows: files, folders: false };
  // Each folder's README, found once here rather than per row on every keystroke.
  const readmes = new Map(), rank = { "readme.md": 0, "readme.markdown": 1, "index.md": 2 };
  for (const f of files) {
    const cut = f.lastIndexOf("/"), r = rank[f.slice(cut + 1).toLowerCase()];
    if (r === undefined) continue;
    const dir = cut < 0 ? "" : f.slice(0, cut), had = readmes.get(dir);
    if (!had || r < rank[had.slice(had.lastIndexOf("/") + 1).toLowerCase()]) readmes.set(dir, f);
  }
  return { ...list, files, rows: foldersOf(files), folders: true, readmes };
}

// A folder's README.md (else index.md, any case) among the listed files, for its preview.
export function readmeOf(files, dir) {
  const pre = dir ? dir + "/" : "";
  for (const want of ["readme.md", "readme.markdown", "index.md"])
    for (const f of files) if (f.startsWith(pre) && f.slice(pre.length).toLowerCase() === want) return f;
  return null;
}

// Folders cut to their first letter ("docs/guides/x.md" → "d/g/x.md"), Telescope's "shorten".
export const shorten = dir => dir.split("/").map(p => p ? (p[0] === "." ? p.slice(0, 2) : p[0]) : p).join("/");

// ---- preview source ----
// The preview lexes only the start of a file. marked's lexer grows faster than
// the text in Herdr's QuickJS (a 78 KB note took ~1 s in qjs, and in Herdr ran
// the shared mod runtime out of memory, killing every mod), and the preview
// draws at most a screenful of blocks anyway. Cut at a blank line (a block
// boundary) at or before `max` characters, else a line end, else hard.
export const PV_CHARS = 12000;
export function previewSource(text, max = PV_CHARS) {
  if (text.length <= max) return { text, cut: false };
  const head = text.slice(0, max);
  let at = head.lastIndexOf("\n\n");
  if (at < max / 2) at = head.lastIndexOf("\n");
  if (at < max / 2) at = max;
  return { text: text.slice(0, at), cut: true };
}

// ---- recently opened (~/.cache/herdr-md/recent.json: absolute paths, newest first) ----
export function parseRecent(text) {
  try { const a = JSON.parse(text ?? "[]"); return Array.isArray(a) ? a.filter(x => typeof x === "string") : []; } catch { return []; }
}
export const pushRecent = (list, file) => [file, ...list.filter(f => f !== file)].slice(0, MAX_RECENT);

// ---- fuzzy matching ----
const SEP = /[/_\-. ]/;

// Is every character of `q` (lowercase) in `s`, in order? Finds the first place
// the whole query fits, then walks back from its end for the tightest window
// (fzf's v1). Returns { score, pos } or null. Scores: every hit counts, more at
// the start, after a separator or at a camelCase hump, more for a run of
// consecutive hits; gaps cost a little.
export function fuzzy(q, s) {
  const n = q.length, l = s.toLowerCase();
  if (!n) return { score: 0, pos: [] };
  let j = 0, end = -1;
  for (let i = 0; i < l.length; i++) if (l[i] === q[j] && ++j === n) { end = i; break; }
  if (end < 0) return null;
  const pos = [];
  for (let i = end, k = n - 1; i >= 0 && k >= 0; i--) if (l[i] === q[k]) { pos.push(i); k--; }
  pos.reverse();
  let score = 0, prev = -2;
  for (const p of pos) {
    let b = 16;
    const c = s[p - 1];
    if (p === 0) b += 14;
    else if (c === "/") b += 13;
    else if (SEP.test(c)) b += 11;
    else if (c === c.toLowerCase() && s[p] !== s[p].toLowerCase()) b += 9;
    if (p === prev + 1) b += 10;
    else if (prev >= 0) score -= Math.min(12, 3 + (p - prev - 1));
    score += b; prev = p;
  }
  return { score: score - s.length * 0.05, pos };
}

// Match a query (space-separated terms, all required) against a relative path.
// Each term tries the file name first, then the whole path. `named` counts the
// terms that matched in the file name: it sorts before the score, so a file
// name match always ranks above a match spread over folders.
export function match(query, rel) {
  const terms = query.toLowerCase().split(/\s+/).filter(Boolean);
  const name = rel.slice(rel.lastIndexOf("/") + 1), at = rel.length - name.length;
  let score = 0, named = 0; const pos = new Set();
  for (const term of terms) {
    let m = fuzzy(term, name);
    if (m) {
      named++; score += m.score + (name.toLowerCase().startsWith(term) ? 24 : 0);
      m.pos.forEach(p => pos.add(p + at));
      continue;
    }
    m = fuzzy(term, rel);
    if (!m) return null;
    score += m.score; m.pos.forEach(p => pos.add(p));
  }
  return { score, named, pos: [...pos].sort((a, b) => a - b) };
}

// The picker's list. Empty query: recently opened files first (newest first,
// leaving out `current`, the file on screen), then the rest in listing order
// (shallow first). Otherwise: matches by file-name hits, score, recency, length.
// Returns [{ rel, abs, pos, recent }] (recent: true for an MRU entry), at most `limit`.
export function rank(query, list, recent, current, limit = 500) {
  const abs = rel => `${list.root}/${rel}`;
  const age = new Map(recent.map((f, i) => [f, i]));
  if (!query.trim()) {
    const top = list.files.filter(r => age.has(abs(r)) && abs(r) !== current).sort((a, b) => age.get(abs(a)) - age.get(abs(b)));
    const seen = new Set(top);
    return [...top.map(rel => ({ rel, abs: abs(rel), pos: [], recent: true })),
      ...list.files.filter(r => !seen.has(r)).map(rel => ({ rel, abs: abs(rel), pos: [], recent: false }))].slice(0, limit);
  }
  const out = [];
  for (const rel of list.files) {
    const m = match(query, rel);
    if (m) out.push({ rel, abs: abs(rel), pos: m.pos, named: m.named, score: m.score, recent: age.has(abs(rel)), age: age.get(abs(rel)) ?? Infinity });
  }
  out.sort((a, b) => b.named - a.named || b.score - a.score || a.age - b.age || a.rel.length - b.rel.length);
  return out.slice(0, limit);
}

// A string cut into runs of matched / unmatched characters, for highlighting.
// `pos` holds indexes into the full string; `from` is where `s` starts in it.
export function runs(s, pos, from = 0) {
  const hit = new Set(pos), out = [];
  for (let i = 0; i < s.length; i++) {
    const h = hit.has(i + from);
    if (out.length && out[out.length - 1].hit === h) out[out.length - 1].text += s[i];
    else out.push({ text: s[i], hit: h });
  }
  return out;
}
