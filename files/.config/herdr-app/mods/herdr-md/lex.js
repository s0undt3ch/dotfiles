// Lexing a document in bounded pieces, kept free of Herdr APIs so node can test it.
//
// marked's lexer grows faster than the text in Herdr's QuickJS (each block
// re-slices the rest of the source), and one 78 KB note ran the shared mod
// runtime out of memory. So the viewer lexes a file in chunks of about CHUNK
// characters, cut only where a block can't continue (see boundaries()), and
// numbers each chunk's lines from where it starts: the total is linear and the
// line numbers are the file's own. Past LEX_MAX characters it stops at a block
// boundary and says so (capSource()).
import { marked } from "./marked.js";

const MATH_OPEN = /(^|\n) {0,3}\$\$/;

// $$…$$ display math as its own block: one line that is all math, or a $$ line
// alone that opens a block closed by a later $$. Anything else, such as $$…$$ in
// a sentence or wrapped across lines, is inline math (as on GitHub); taking it
// here would pair its closer with the next block's opener.
marked.use({ extensions: [{
  name: "math", level: "block",
  start(src) { const m = MATH_OPEN.exec(src); return m ? m.index + m[1].length : undefined; },
  tokenizer(src) {
    const m = /^ {0,3}\$\$([^\n]+?)\$\$[^\S\n]*(?:\n|$)/.exec(src) ?? /^ {0,3}\$\$[^\S\n]*\n([\s\S]*?)\$\$[^\S\n]*(?:\n|$)/.exec(src);
    if (m) return { type: "math", raw: m[0], text: m[1].trim() };
  },
}] });
// GitHub footnote definitions: `[^id]: text`, continued by indented lines (a
// blank line may sit between them). The reference `[^id]` is linked in doc.js.
const NOTE_OPEN = /(^|\n) {0,3}\[\^[^\]\s]+\]:/;
marked.use({ extensions: [{
  name: "footnote", level: "block",
  start(src) { const m = NOTE_OPEN.exec(src); return m ? m.index + m[1].length : undefined; },
  tokenizer(src) {
    const m = /^ {0,3}\[\^([^\]\s]+)\]:[^\n]*(?:\n(?:[^\S\n]*\n)*(?: {4}|\t)[^\n]*)*(?:\n|$)/.exec(src);
    if (!m) return;
    const text = m[0].replace(/^ {0,3}\[\^[^\]]+\]:[^\S\n]*/, "").split("\n").map(l => l.replace(/^(?: {4}|\t)/, "")).join("\n").trim();
    return { type: "footnote", raw: m[0], id: m[1], text };
  },
}] });
export { marked };

export const CHUNK = 4000, LEX_MAX = 512000;

// Can a chunk start at this line? Only a line at column 0 that can't carry on
// what came before a blank line: not indented (a list item's continuation, or
// indented code) and not a list marker (one loose list would become two).
const LIST = /^(?:[-*+]|\d{1,9}[.)])(?:\s|$)/;
const startsBlock = l => /^[^\s]/.test(l) && !LIST.test(l);
const FENCE = /^ {0,3}(`{3,}|~{3,})/;
const RAW_HTML = /^ {0,3}<(pre|script|style|textarea)(?:\s|>|$)/i;

// Every position where a new chunk may start: the first character of a line
// that follows a blank line, outside fenced code, $$ math, an HTML comment or a
// <pre>/<script>/<style>/<textarea> block (all of which may hold blank lines).
// Yields [index, line] (line is 1-based). Linear in the text.
export function* boundaries(text) {
  let pos = 0, line = 1, blank = false;
  let fence = null, until = -1;           // inside a fence; or inside math/comment/html up to index `until`
  const closer = /\$\$[^\S\n]*(?:\n|$)/g;
  let noCloserFrom = Infinity;            // no math closer at or after this index
  const mathEnd = from => {
    if (from >= noCloserFrom) return -1;
    closer.lastIndex = from;
    const m = closer.exec(text);
    if (!m) { noCloserFrom = from; return -1; }
    return m.index;
  };
  while (pos < text.length) {
    let eol = text.indexOf("\n", pos); if (eol < 0) eol = text.length;
    const l = text.slice(pos, eol);
    if (blank && startsBlock(l)) yield [pos, line];
    if (fence) {
      const m = FENCE.exec(l);
      if (m && m[1][0] === fence[0] && m[1].length >= fence.length && !l.slice(m[0].length).trim()) fence = null;
    } else if (until < pos) {
      const f = FENCE.exec(l);
      if (f && !(f[1][0] === "`" && l.slice(f[0].length).includes("`"))) fence = f[1];
      else {
        let end = -1;
        const d = /^ {0,3}\$\$[^\S\n]*$/.exec(l);
        if (d) end = mathEnd(pos + d[0].length);
        const c = l.indexOf("<!--");
        if (c >= 0) { const e = text.indexOf("-->", pos + c + 4); if (e > end) end = e; }
        const h = RAW_HTML.exec(l);
        if (h) { const e = indexOfCi(text, `</${h[1]}>`, pos); if (e > end) end = e; }
        if (end > eol) until = end;
      }
    }
    blank = !fence && until < pos && !l.trim();
    // A line inside a span that ends on this line is still inside.
    if (until >= pos && until <= eol) { until = -1; blank = false; }
    pos = eol + 1; line++;
  }
}

function indexOfCi(text, needle, from) {
  const re = new RegExp(needle, "ig"); re.lastIndex = from;
  const m = re.exec(text); return m ? m.index : -1;
}

// The text in chunks of at least `size` characters (the last may be shorter),
// each cut at a boundary: [{ text, start, line }]. Joined, they are the text.
export function splitChunks(text, size = CHUNK) {
  const out = []; let start = 0, line = 1;
  if (text.length > size) for (const [at, ln] of boundaries(text)) {
    if (at - start < size) continue;
    out.push({ text: text.slice(start, at), start, line }); start = at; line = ln;
  }
  out.push({ text: text.slice(start), start, line });
  return out;
}

// The start of a huge file: up to `max` characters, cut at a boundary (else at
// a line end). { text, cut, lines, total } (lines shown / lines in the file).
export function capSource(text, max = LEX_MAX) {
  const count = s => { let n = 1, i = -1; while ((i = s.indexOf("\n", i + 1)) >= 0) n++; return n; };
  if (text.length <= max) { const n = count(text); return { text, cut: false, lines: n, total: n }; }
  let at = -1;
  for (const [b] of boundaries(text)) { if (b > max) break; at = b; }
  if (at < max / 2) { at = text.lastIndexOf("\n", max); at = at < max / 2 ? max : at + 1; }
  const shown = text.slice(0, at).replace(/\n+$/, "");
  return { text: text.slice(0, at), cut: true, lines: count(shown), total: count(text.replace(/\n+$/, "")) };
}

// Reference definitions ([x]: url) anywhere in the text, so a chunk can resolve
// a reference whose definition sits in another chunk. First one wins, as in marked.
// A candidate starts a line after a blank line, a heading or another definition.
export function refDefs(text) {
  const links = Object.create(null), lx = new marked.Lexer();
  let pos = 0, ok = true;
  let fence = null;
  while (pos < text.length) {
    let eol = text.indexOf("\n", pos); if (eol < 0) eol = text.length;
    const l = text.slice(pos, eol), f = FENCE.exec(l);
    let def = false;
    if (fence) { if (f && f[1][0] === fence[0] && f[1].length >= fence.length && !l.slice(f[0].length).trim()) fence = null; }
    else if (f) fence = f[1];
    else if (ok && /^ {0,3}\[/.test(l)) {
      const tok = lx.tokenizer.def(text.slice(pos, Math.min(text.length, eol + 400)));
      if (tok) { def = true; if (!links[tok.tag]) links[tok.tag] = { href: tok.href, title: tok.title }; }
    }
    ok = !fence && (def || !l.trim() || /^ {0,3}#{1,6}(\s|$)/.test(l));
    pos = eol + 1;
  }
  return links;
}

// Lex one chunk, with the whole document's reference definitions.
export function lexChunk(text, links = null) {
  const lx = new marked.Lexer();
  if (links) Object.assign(lx.tokens.links, links);
  return lx.lex(text);
}

const isComment = tok => tok.type === "html" && /^\s*(<!--[\s\S]*?-->\s*)+$/.test(tok.raw);

// Top-level blocks, with lists split into one block per item so a highlight or
// a scroll target can land on a single bullet. Each gets its source lines,
// counted from `base` (the lines before this text, for a chunk).
export function blocks(src, tokens, base = 0) {
  const out = [];
  for (const tok of tokens) {
    if (tok.type === "list") tok.items.forEach((item, j) => out.push({ type: "listitem", item, list: tok, n: (tok.start || 1) + j, raw: item.raw }));
    else if (tok.type === "table") out.push(...tableRows(tok));
    else if (tok.type === "paragraph") out.push(...paraLines(tok));
    // Space and comment-only HTML render nothing, so they aren't blocks (no cursor stop).
    // Safe: each block's lines come from finding its raw text, not from counting.
    else if (tok.type !== "space" && !isComment(tok)) out.push(tok);
  }
  // Line numbers by walking a single position through the text (once, not per block).
  let cursor = 0, pos = 0, line = 1;
  const lineAt = i => {
    for (; pos < i; pos++) if (src.charCodeAt(pos) === 10) line++;
    for (; pos > i; pos--) if (src.charCodeAt(pos - 1) === 10) line--;
    return line;
  };
  for (const b of out) {
    const at = src.indexOf(b.raw, cursor), start = at < 0 ? cursor : at;
    const end = start + b.raw.replace(/\s+$/, "").length;
    b.from = base + lineAt(start);
    b.to = base + lineAt(end);
    if (at >= 0) cursor = end;
  }
  return out;
}

// A table is one block per row, so the cursor steps through it: the header
// (with its |---| line) is row -1, body rows are 0…n-1. Every GFM row is one
// source line. All rows share the table token, which holds the column widths.
// A header with no text isn't shown, so it isn't a stop. Anything unexpected
// keeps the table whole.
export function tableRows(tok) {
  const lines = tok.raw.replace(/\n+$/, "").split("\n");
  if (lines.length !== tok.rows.length + 2) return [tok];
  const head = tok.header.some(h => h.text.trim());
  const out = head ? [{ type: "trow", table: tok, r: -1, raw: `${lines[0]}\n${lines[1]}` }] : [];
  tok.rows.forEach((_row, r) => out.push({ type: "trow", table: tok, r, raw: lines[r + 2] }));
  out.forEach((b, k) => { b.first = k === 0; b.last = k === out.length - 1; });
  return out.length ? out : [tok];
}

// A paragraph whose source lines are separate statements (PREMISE: … / EVIDENCE: …,
// one sentence per line) is one block per line, so the cursor steps through it
// and each line shows its own number. Prose that was hard-wrapped at a column
// stays one block and reflows. The test is whether the line breaks were forced:
// wrapped text breaks only where the next word wouldn't fit. A paragraph is
// split when a line ends in a hard break, when its lines are too long or too
// short to have been wrapped (WRAP_MAX, WRAP_MIN), or when its breaks left
// room for the next word: at least half of them by WRAP_SLACK characters
// (wrapped prose is ragged, and an edited one has a short line or two), or,
// with only two lines, the first ending before 60% of the second's width.
// Hand-wrapped prose can be that ragged too, so lines that mostly pick up
// mid-sentence keep it whole.
// Each line is drawn as markdown on its own, so anything that can't stand
// alone keeps the paragraph whole: an image, inline markup or math that
// crosses a break, a d2l label, or a line that would read as another kind of
// block.
export const WRAP_MAX = 140, WRAP_MIN = 50, WRAP_SLACK = 8;
const hasImage = toks => (toks ?? []).some(x => x.type === "image" || hasImage(x.tokens));
export function statementLines(lines) {
  if (lines.slice(0, -1).some(l => /( {2,}|\\)$/.test(l))) return true;
  const text = lines.map(l => l.trim()), spaced = text.filter(l => /\s/.test(l));
  if (!spaced.length) return true;
  const width = Math.max(...spaced.map(l => l.length));
  if (width < WRAP_MIN) return true;
  const breaks = text.length - 1, room = k => text[k].length + 1 + text[k + 1].split(/\s/, 1)[0].length;
  // A line that picks up mid-sentence (lowercase, after no closing punctuation).
  const carries = k => /^\p{Ll}/u.test(text[k + 1]) && !/[.!?:;]$/.test(text[k]);
  let unforced = 0, carried = 0;
  for (let k = 0; k < breaks; k++) { if (room(k) <= width - WRAP_SLACK) unforced++; if (carries(k)) carried++; }
  if (carried * 2 >= breaks) return false;
  if (width > WRAP_MAX) return true;
  return breaks === 1 ? room(0) <= width * 0.6 : unforced * 2 >= breaks;
}
export function paraLines(tok) {
  const lines = tok.raw.replace(/\s+$/, "").split("\n");
  if (lines.length < 2 || !tok.tokens || hasImage(tok.tokens)) return [tok];
  if (tok.tokens.some(x => x.type !== "text" && x.type !== "br" && x.raw.includes("\n"))) return [tok];
  if (lines.some(l => !l.trim() || (l.match(/\$/g)?.length ?? 0) % 2 || /^\s*:(eq)?label:`/.test(l))) return [tok];
  if (!statementLines(lines)) return [tok];
  for (const l of lines) { const alone = marked.lexer(l.trim()); if (alone.length !== 1 || alone[0].type !== "paragraph") return [tok]; }
  return lines.map((l, k) => ({ type: "pline", para: tok, raw: l, text: l.trim().replace(/\s*\\$/, ""), first: k === 0, last: k === lines.length - 1 }));
}

// The whole text lexed chunk by chunk, at once (tests, and the benchmark).
// The viewer does the same loop with a pause between chunks.
export function lexAll(text, size = CHUNK) {
  const chunks = splitChunks(text, size), links = chunks.length > 1 ? refDefs(text) : null;
  const tokens = [], list = [];
  for (const c of chunks) {
    const toks = lexChunk(c.text, links);
    for (const t of toks) tokens.push(t);
    for (const b of blocks(c.text, toks, c.line - 1)) list.push(b);
  }
  return { tokens, blocks: list, chunks: chunks.length };
}
