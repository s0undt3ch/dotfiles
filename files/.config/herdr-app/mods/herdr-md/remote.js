// Files on another machine (a space's `machine`, see `hc machine ls`): which
// machine a viewer reads from, and the pieces for copying a binary file over
// exec (text-only): base64 chunks, decoded here.

// Machines to try, best guess first (null is this Mac). `explicit` is the machine
// the opener named (props().machine); else the machine of the tab that had focus
// when the viewer opened (the pane it split from), then the machines of tabs that
// hold a viewer (a restored layout), then this Mac. Only one entry when explicit.
export function machineCandidates({ explicit, focusedTab, spaces, panes, mod }) {
  if (explicit !== undefined) return [explicit || null];
  const of = tab => spaces.find(s => s.tabs.some(t => t.id === tab))?.machine ?? null;
  const out = [];
  for (const tab of [focusedTab, ...panes.filter(p => p.mod === mod).map(p => p.tab)]) {
    if (!tab) continue;
    const m = of(tab); if (!out.includes(m)) out.push(m);
  }
  if (!out.includes(null)) out.push(null);
  return out;
}

// stat's "mtime:size" with sub-second mtime, GNU first: BSD stat has no -c (prints usage, exits 1),
// but GNU's -f means "filesystem" and would print junk, so it must not run there. Paths arrive as "$@".
export const STAT_SH = 'for f in "$@"; do stat -c %.9Y:%s "$f" 2>/dev/null || stat -f %Fm:%z "$f" 2>/dev/null || echo -; done';

// One stat line per path -> [sig | null].
export const parseStats = out => out.trim().split("\n").map(l => (/^\d+(\.\d+)?:\d+$/.test(l.trim()) ? l.trim() : null));

export const CHUNK = 3 * 1024 * 1024;   // raw bytes per remote exec (base64 of it is under exec's 8 MiB output cap)
export const SLICE = 384 * 1024;        // base64 chars per local decode: an argument, and macOS caps arguments near 1 MB (a multiple of 4)
// Remote script printing one chunk of "$1" as one base64 line (offset "$2", length "$3").
// A pipeline reports its last command's status, so readability is checked first.
export const CHUNK_SH = '[ -r "$1" ] || exit 1; tail -c +$(($2 + 1)) "$1" | head -c "$3" | base64 | tr -d "\\n"';
export const slices = (b64, n = SLICE) => { const out = []; for (let i = 0; i < b64.length; i += n) out.push(b64.slice(i, i + n)); return out; };
export const chunkCount = size => Math.ceil(size / CHUNK);
