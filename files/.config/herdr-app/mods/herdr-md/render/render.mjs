// Batch renderer for the md viewer: TeX -> SVG (MathJax, no browser) and
// Mermaid -> PNG (mermaid-cli driving the installed Chrome, one browser per batch).
//   node render.mjs '<jobs JSON>' | jobs.json   ->  prints [{ out, w, h, error? }] (w/h in CSS px)
// jobs: [{ kind: "math" | "mermaid", src, out, color, font, display?, scale? }]
// scale: Mermaid's device pixel ratio (default 2; the zoom overlay asks for 4).
// A job whose `out` exists is skipped (outputs are named by content hash).
import fs from "node:fs";

// The jobs arrive as a JSON argument (a mod can't write temp files outside its
// app folder when it's installed as a symlink), or as a path to a JSON file.
const arg = process.argv[2] ?? "[]";
const jobs = JSON.parse(arg.trimStart().startsWith("[") ? arg : fs.readFileSync(arg, "utf8"));
const results = [];

function pngSize(buf) { return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) }; }
function svgSize(svg, exPx) {
  const w = svg.match(/width="([\d.]+)ex"/), h = svg.match(/height="([\d.]+)ex"/);
  return { w: Math.ceil(+w[1] * exPx), h: Math.ceil(+h[1] * exPx) };
}

// ---- math ----
let tex;
async function math(job) {
  if (!tex) {
    const { mathjax } = await import("mathjax-full/js/mathjax.js");
    const { TeX } = await import("mathjax-full/js/input/tex.js");
    const { SVG } = await import("mathjax-full/js/output/svg.js");
    const { liteAdaptor } = await import("mathjax-full/js/adaptors/liteAdaptor.js");
    const { RegisterHTMLHandler } = await import("mathjax-full/js/handlers/html.js");
    const { AllPackages } = await import("mathjax-full/js/input/tex/AllPackages.js");
    const adaptor = liteAdaptor(); RegisterHTMLHandler(adaptor);
    const doc = mathjax.document("", { InputJax: new TeX({ packages: AllPackages }), OutputJax: new SVG({ fontCache: "none" }) });
    tex = (src, display) => adaptor.innerHTML(doc.convert(src, { display }));
  }
  let svg = tex(job.src, !job.inline && job.display !== false);
  if (/data-mjx-error|merror/.test(svg)) throw new Error("TeX error");
  svg = svg.replace(/currentColor/g, job.color || "#c0caf5");
  if (!/xmlns=/.test(svg)) svg = svg.replace("<svg", '<svg xmlns="http://www.w3.org/2000/svg"');
  if (job.inline) return inlineSvg(job, svg);
  fs.writeFileSync(job.out, svg);
  // ~9.5px per ex at the viewer's 19px display-math size.
  return svgSize(svg, job.exPx || 9.5);
}

// Inline math sits in a line of text, which centers an image on the line
// (`center` px above the baseline). Pad the SVG so its baseline lands on the
// text's, and size it in px.
function inlineSvg(job, svg) {
  const exPx = job.exPx || 7.5, { w, h } = svgSize(svg, exPx);
  const depth = +(svg.match(/vertical-align:\s*(-?[\d.]+)ex/)?.[1] ?? 0) * -exPx;
  const vb = svg.match(/viewBox="([-\d.]+) ([-\d.]+) ([-\d.]+) ([-\d.]+)"/).slice(1).map(Number);
  const unit = vb[3] / h, above = h - depth, center = job.center ?? exPx * 0.66;
  // Centered, the image's middle is at `center`: above - center must equal half its height.
  const top = Math.max(0, h - 2 * (above - center)), bottom = Math.max(0, 2 * (above - center) - h);
  const H = h + top + bottom;
  svg = svg.replace(/viewBox="[^"]*"/, `viewBox="${vb[0]} ${vb[1] - top * unit} ${vb[2]} ${H * unit}"`)
    .replace(/width="[\d.]+ex"/, `width="${w}"`).replace(/height="[\d.]+ex"/, `height="${H}"`)
    .replace(/ style="[^"]*"/, "");
  fs.writeFileSync(job.out, svg);
  return { w, h: H };
}

// ---- mermaid ----
// An installed Chrome-family browser drives Mermaid; none is downloaded.
function chrome() {
  const found = [
    process.env.PUPPETEER_EXECUTABLE_PATH, process.env.CHROME_PATH,
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "/usr/bin/google-chrome", "/usr/bin/google-chrome-stable", "/usr/bin/chromium", "/usr/bin/chromium-browser",
    "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  ].find(p => p && fs.existsSync(p));
  if (!found) throw new Error("Mermaid needs Chrome, Chromium, Brave or Edge installed (or set CHROME_PATH)");
  return found;
}
let browser, renderMermaid;
async function mermaid(job) {
  if (!browser) {
    ({ renderMermaid } = await import("@mermaid-js/mermaid-cli"));
    const puppeteer = (await import("puppeteer")).default;
    browser = await puppeteer.launch({ headless: "shell", executablePath: chrome() });
  }
  const c = job.colors || {};
  const { data } = await renderMermaid(browser, job.src, "png", {
    viewport: { width: 1200, height: 800, deviceScaleFactor: job.scale || 2 },
    backgroundColor: "transparent",
    mermaidConfig: {
      theme: "base",
      fontFamily: job.font || "sans-serif",
      themeVariables: {
        darkMode: true, background: "transparent", fontFamily: job.font || "sans-serif", fontSize: "15px",
        primaryColor: c.surface || "#24283b", primaryTextColor: c.fg || "#c0caf5", primaryBorderColor: c.blue || "#7aa2f7",
        secondaryColor: c.raised || "#2f334d", tertiaryColor: c.bg || "#1a1b26", lineColor: c.dim || "#565f89",
        textColor: c.fg || "#c0caf5", mainBkg: c.surface || "#24283b", nodeBorder: c.blue || "#7aa2f7",
        clusterBkg: c.bg || "#1a1b26", clusterBorder: c.dim || "#565f89", edgeLabelBackground: c.bg || "#1a1b26",
        noteBkgColor: c.raised || "#2f334d", noteTextColor: c.fg || "#c0caf5", noteBorderColor: c.purple || "#bb9af7",
        actorBkg: c.surface || "#24283b", actorBorder: c.blue || "#7aa2f7", actorTextColor: c.fg || "#c0caf5",
        signalColor: c.fg || "#c0caf5", signalTextColor: c.fg || "#c0caf5", labelBoxBkgColor: c.surface || "#24283b",
      },
    },
  });
  const buf = Buffer.from(data);
  fs.writeFileSync(job.out, buf);
  const { w, h } = pngSize(buf);
  const k = job.scale || 2;
  return { w: Math.round(w / k), h: Math.round(h / k) };
}

for (const job of jobs) {
  try {
    if (fs.existsSync(job.out) && fs.existsSync(job.out + ".json")) { results.push({ out: job.out, ...JSON.parse(fs.readFileSync(job.out + ".json", "utf8")) }); continue; }
    const size = job.kind === "math" ? await math(job) : await mermaid(job);
    fs.writeFileSync(job.out + ".json", JSON.stringify(size));
    results.push({ out: job.out, ...size });
  } catch (e) {
    results.push({ out: job.out, error: String(e.message || e).split("\n")[0].slice(0, 200) });
  }
}
if (browser) await browser.close();
process.stdout.write(JSON.stringify(results));
