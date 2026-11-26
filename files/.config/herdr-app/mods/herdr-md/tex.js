// Inline math ($…$, $`…`$, $$…$$ mid-sentence) as Unicode text (x², ŷ, ∑ᵢ, α ≤ β): what a
// formula shows until its typeset image is ready, and in previews.
const SYM = {
  alpha: "α", beta: "β", gamma: "γ", delta: "δ", epsilon: "ε", varepsilon: "ε", zeta: "ζ", eta: "η", theta: "θ",
  iota: "ι", kappa: "κ", lambda: "λ", mu: "μ", nu: "ν", xi: "ξ", pi: "π", rho: "ρ", sigma: "σ", tau: "τ",
  upsilon: "υ", phi: "φ", varphi: "φ", chi: "χ", psi: "ψ", omega: "ω",
  Gamma: "Γ", Delta: "Δ", Theta: "Θ", Lambda: "Λ", Xi: "Ξ", Pi: "Π", Sigma: "Σ", Phi: "Φ", Psi: "Ψ", Omega: "Ω",
  cdot: "·", times: "×", div: "÷", pm: "±", mp: "∓", le: "≤", leq: "≤", ge: "≥", geq: "≥", ne: "≠", neq: "≠",
  approx: "≈", sim: "∼", equiv: "≡", propto: "∝", infty: "∞", sum: "∑", prod: "∏", int: "∫", partial: "∂",
  nabla: "∇", in: "∈", notin: "∉", subset: "⊂", subseteq: "⊆", cup: "∪", cap: "∩", emptyset: "∅",
  forall: "∀", exists: "∃", to: "→", rightarrow: "→", leftarrow: "←", Rightarrow: "⇒", Leftrightarrow: "⇔",
  mapsto: "↦", top: "ᵀ", ldots: "…", cdots: "⋯", dots: "…", mid: "∣", ell: "ℓ", log: "log", exp: "exp",
  max: "max", min: "min", arg: "arg", lim: "lim", sqrt: "√", quad: " ", qquad: "  ", ",": " ", ";": " ", "!": "",
  mathbb: "", R: "ℝ", N: "ℕ", Z: "ℤ",
  thinspace: " ", ln: "ln", ast: "∗", vert: "|", lvert: "|", rvert: "|", lbrace: "{", rbrace: "}", diamond: "⋄", ll: "≪", gg: "≫", lVert: "‖", rVert: "‖", Vert: "‖",
};
const SUP = { "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "+": "⁺", "-": "⁻", "=": "⁼", "(": "⁽", ")": "⁾", n: "ⁿ", i: "ⁱ", T: "ᵀ", "ᵀ": "ᵀ", t: "ᵗ", k: "ᵏ", d: "ᵈ", j: "ʲ", x: "ˣ", "*": "*", "′": "′",
  a: "ᵃ", b: "ᵇ", c: "ᶜ", e: "ᵉ", h: "ʰ", l: "ˡ", m: "ᵐ", o: "ᵒ", p: "ᵖ", r: "ʳ", s: "ˢ", u: "ᵘ", v: "ᵛ", w: "ʷ", y: "ʸ", z: "ᶻ" };
const SUB = { "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄", "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉", "+": "₊", "-": "₋", "=": "₌", "(": "₍", ")": "₎", i: "ᵢ", j: "ⱼ", k: "ₖ", n: "ₙ", t: "ₜ", d: "d", a: "ₐ", e: "ₑ", o: "ₒ", x: "ₓ", m: "ₘ", l: "ₗ", s: "ₛ", p: "ₚ", r: "ᵣ" };
const ACCENT = { hat: "̂", bar: "̄", tilde: "̃", vec: "⃗", dot: "̇", overline: "̅" };

// One {…} group or a single token, from position i.
function group(s, i) {
  while (s[i] === " ") i++;
  if (s[i] === "{") { let d = 0, j = i; for (; j < s.length; j++) { if (s[j] === "{") d++; else if (s[j] === "}" && --d === 0) break; } return [s.slice(i + 1, j), j + 1]; }
  if (s[i] === "\\") { const m = s.slice(i).match(/^\\([a-zA-Z]+|.)/); return m ? [m[0], i + m[0].length] : ["\\", i + 1]; }
  return [s[i] ?? "", i + 1];
}

const script = (t, map, mark) => [...t].every(c => map[c]) ? [...t].map(c => map[c]).join("") : `${mark}(${t})`;

export function texToUnicode(src, depth = 0) {
  if (depth > 20) return src;   // pathological nesting: leave it as written
  let s = src, out = "", i = 0;
  while (i < s.length) {
    const c = s[i];
    if (c === "\\") {
      const m = s.slice(i).match(/^\\([a-zA-Z]+|.)/);
      if (!m) { out += "\\"; i++; continue; }   // a lone trailing backslash
      const name = m[1]; i += m[0].length;
      if (/^[dt]?frac$/.test(name)) { const [a, j] = group(s, i); const [b, k] = group(s, j); i = k; out += `${wrap(texToUnicode(a, depth + 1))}/${wrap(texToUnicode(b, depth + 1))}`; continue; }
      if (ACCENT[name]) { const [a, j] = group(s, i); i = j; const t = texToUnicode(a, depth + 1); out += t.length === 1 ? t + ACCENT[name] : `${t}${ACCENT[name]}`; continue; }
      if (/^(mathbf|mathrm|textrm|text|mathit|operatorname|boldsymbol|mathcal|textbf|left|right|big|Big)$/.test(name)) {
        if (/^(left|right|big|Big)$/.test(name)) continue;
        const [a, j] = group(s, i); i = j; out += texToUnicode(a, depth + 1); continue;
      }
      if (name === "sqrt") { const [a, j] = group(s, i); i = j; out += `√${wrap(texToUnicode(a, depth + 1))}`; continue; }
      out += SYM[name] ?? name; continue;
    }
    if (c === "^" || c === "_") { const [a, j] = group(s, i + 1); i = j; out += script(texToUnicode(a, depth + 1), c === "^" ? SUP : SUB, c); continue; }
    if (c === "{" || c === "}") { i++; continue; }
    out += c; i++;
  }
  return out.replace(/\s+/g, " ").trim();
}

const wrap = t => t.length > 1 && /[^\w′]/.test(t) ? `(${t})` : t;

// Replace inline $…$ in a markdown paragraph. Pandoc's rule keeps prices like
// "$5 and $10" as text: no space just inside the dollars, no digit right after.
export function inlineMath(md) {
  try { return replaceInline(md); } catch { return md; }   // never let a bad formula break the view
}

// The first backtick run of the opening length ends the code span.
const INLINE_MATH = /(^|[^\\$])(?:\$(`+)(?!`)((?:[^`\r\n]|(?!\2(?!`))`+(?!`))+)\2\$|\$\$([^$\n]+?)\$\$(?!\d)|\$(?![\s`])([^$\n]+?)(?<!\s)\$(?!\d))/g;

function replaceInline(md) {
  return md.replace(INLINE_MATH,
    (_, pre, _ticks, quoted, double, plain) => `${pre}*${texToUnicode(quoted ?? double ?? plain).replace(/[*_]/g, "\\$&")}*`);
}

// The markdown split around its inline formulas: [{ text } | { tex }], in order.
export function splitInline(md) {
  const parts = []; let at = 0;
  for (const m of md.matchAll(INLINE_MATH)) {
    const start = m.index + m[1].length;
    if (start > at) parts.push({ text: md.slice(at, start) });
    parts.push({ tex: m[3] ?? m[4] ?? m[5] });
    at = m.index + m[0].length;
  }
  if (at < md.length) parts.push({ text: md.slice(at) });
  return parts;
}
