// Document helpers for the viewer: what changed between two versions,
// heading anchors, d2l-book labels and references, GitHub-style callouts.

export function hash(str) { let h = 0x811c9dc5; for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 0x01000193); } return (h >>> 0).toString(36); }

// Block-level diff (LCS over block hashes). Returns
// { changed: Set<new index>, removed: Map<new index, count removed just before it> }.
// Blocks with no counterpart in the old version count as changed: new or edited.
export function diffBlocks(oldHashes, newHashes) {
  const n = oldHashes.length, m = newHashes.length;
  const changed = new Set(), removed = new Map();
  if (!n) return { changed, removed };              // nothing seen before: nothing to mark
  if (n * m > 4e6) return { changed, removed };      // huge documents: skip rather than stall
  const L = Array.from({ length: n + 1 }, () => new Uint32Array(m + 1));
  for (let i = n - 1; i >= 0; i--) for (let j = m - 1; j >= 0; j--)
    L[i][j] = oldHashes[i] === newHashes[j] ? L[i + 1][j + 1] + 1 : Math.max(L[i + 1][j], L[i][j + 1]);
  let i = 0, j = 0, gone = 0;
  while (i < n || j < m) {
    if (i < n && j < m && oldHashes[i] === newHashes[j]) { if (gone) { removed.set(j, gone); gone = 0; } i++; j++; }
    else if (j < m && (i >= n || L[i][j + 1] >= L[i + 1][j])) { changed.add(j); j++; }
    else { gone++; i++; }
  }
  if (gone) removed.set(m, gone);
  // A removal right where a block changed is an edit, not a separate removal.
  for (const [at, count] of removed) if (changed.has(at) || changed.has(at - 1)) removed.delete(at);
  return { changed, removed };
}

// GitHub's heading anchors: lowercase, drop punctuation, spaces to hyphens.
export function slug(text) {
  return text.trim().toLowerCase().replace(/[^\p{L}\p{N}\s_-]/gu, "").replace(/\s+/g, "-");
}

// d2l-book roles. A paragraph that is only `:label:`x`` or `:eqlabel:`x`` names
// the block before it; returns the name, or null.
export function labelOf(tok) {
  if (tok.type !== "paragraph") return null;
  const m = /^:(eq)?label:`([^`]+)`\s*$/.exec(tok.raw.trim());
  return m ? { name: m[2], eq: Boolean(m[1]) } : null;
}

// Inline roles → markdown links the viewer handles (#label:name), or plain text.
// A footnote reference [^id] becomes a superscript link to its definition, which
// index() files under the label "^id".
export function inlineRoles(md, labels) {
  // The reference hugs the word before it, as a superscript does. Code spans keep theirs as written.
  md = md.replace(/(`+)[\s\S]*?\1|[^\S\n]*\[\^([^\]\s]+)\](?!:)/g, (ref, code, id) => {
    const l = code ? null : labels.get(`^${id}`);
    return l ? `[${superscript(l.num)}](#label:${encodeURIComponent(`^${id}`)})` : ref;
  });
  return md.replace(/:(eqref|numref|ref|cite|citet|citep):`([^`]+)`/g, (_, role, name) => {
    if (role.startsWith("cit")) return `[${name}]`;
    const l = labels.get(name);
    const text = role === "eqref" ? `(${l?.num ?? "?"})` : l?.title ?? name;
    return `[${text}](#label:${encodeURIComponent(name)})`;
  });
}

export function footnoteBackId(url) {
  const prefix = "#fnback:";
  if (!url.startsWith(prefix)) return null;
  try { return decodeURIComponent(url.slice(prefix.length)); }
  catch { return null; }
}

const SUPERSCRIPT = "⁰¹²³⁴⁵⁶⁷⁸⁹";
const superscript = n => String(n).replace(/\d/g, d => SUPERSCRIPT[d]);

// GitHub alerts: a blockquote whose first line is [!NOTE] / [!TIP] / [!IMPORTANT] / [!WARNING] / [!CAUTION].
export const ALERTS = {
  NOTE: { icon: "ⓘ", title: "Note", color: "ansi4" },
  TIP: { icon: "✦", title: "Tip", color: "ansi2" },
  IMPORTANT: { icon: "❖", title: "Important", color: "ansi5" },
  WARNING: { icon: "⚠", title: "Warning", color: "ansi3" },
  CAUTION: { icon: "⛔", title: "Caution", color: "ansi1" },
};
export function alertOf(tok) {
  if (tok.type !== "blockquote") return null;
  const m = /^>\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*\n?/i.exec(tok.raw);
  if (!m) return null;
  const body = tok.raw.slice(m[0].length).split("\n").map(l => l.replace(/^>\s?/, "")).join("\n").trim();
  return { kind: m[1].toUpperCase(), body };
}

// Line numbers in the gutter. `#` cycles absolute → relative → off.
export const NUMBER_MODES = ["absolute", "relative", "off"];
export const nextNumberMode = mode => NUMBER_MODES[(NUMBER_MODES.indexOf(mode) + 1) % NUMBER_MODES.length];

// Each block's position among the visible (unfolded) blocks: j/k skip hidden
// blocks, so the j/k distance between two blocks is the difference of their
// ordinals. Hidden blocks share the ordinal of the next visible one.
export function ordinals(hidden, n) {
  const ord = new Array(n); let k = 0;
  for (let i = 0; i < n; i++) { ord[i] = k; if (!hidden[i]) k++; }
  return ord;
}

// The gutter label for block i, as vim's number + relativenumber: the cursor's
// block shows its source line, every other block its j/k distance from the cursor.
export function gutterLabel(mode, i, cursor, line, ord) {
  if (mode === "off") return null;
  if (mode !== "relative" || i === cursor) return String(line);
  return String(Math.abs((ord[i] ?? 0) - (ord[cursor] ?? 0)));
}

// The cursor's look (`C` cycles) and motion (`B` cycles), saved in
// ~/.cache/herdr-md/cursor.json so every viewer uses the last choice.
export const CURSOR_LOOKS = ["highlight", "badge", "lift", "badge+highlight"];
// Each motion: what the number and the highlight do (null: stay still).
const MOTIONS = {
  "steady": {},
  "pulse number": { num: "pulse" }, "pulse highlight": { row: "pulse" }, "pulse both": { num: "pulse", row: "pulse" },
  "grow highlight": { row: "grow" }, "grow + pulse highlight": { row: "grow+pulse" },
  "blink number": { num: "blink" }, "blink highlight": { row: "blink" }, "blink both": { num: "blink", row: "blink" },
};
export const CURSOR_MOTIONS = Object.keys(MOTIONS);
export const LOOK_NAMES = { highlight: "highlight", badge: "number badge", lift: "lift", "badge+highlight": "number badge + highlight" };
const after = (list, x) => list[(list.indexOf(x) + 1) % list.length];
export const nextLook = look => after(CURSOR_LOOKS, look);
export const nextMotion = motion => after(CURSOR_MOTIONS, motion);

export function parseCursorPref(text) {
  let p = null; try { p = JSON.parse(text); } catch { /* missing or bad: defaults */ }
  return {
    look: CURSOR_LOOKS.includes(p?.look) ? p.look : "highlight",
    motion: CURSOR_MOTIONS.includes(p?.motion) ? p.motion : "blink number",
    numbers: NUMBER_MODES.includes(p?.numbers) ? p.numbers : "absolute",
  };
}

// What to draw for the cursor block. row: "tint" | "lift" | null (the
// layer behind the block); badge: a pill behind the line number. With numbers
// off a badge can't show, so the block lifts instead and the cursor never vanishes.
// numAnim: null | "pulse" | "blink"; rowAnim: also "grow" | "grow+pulse".
export function cursorParts(look, motion, numbersOn) {
  let row = { highlight: "tint", lift: "lift", "badge+highlight": "tint" }[look] ?? null;
  let badge = numbersOn && (look === "badge" || look === "badge+highlight");
  if (!numbersOn && look === "badge") row = "lift";
  const m = MOTIONS[motion] ?? {};
  return { row, badge, numAnim: numbersOn ? m.num ?? null : null, rowAnim: row ? m.row ?? null : null };
}
