// A video block's playback state, kept free of Herdr APIs so node can test it.
// state: { i: frame shown, playing, t0: wall-clock ms at which frame 0 would have shown }.
// Frames follow the wall clock (the viewer's timer only polls), so a slow render
// drops a frame instead of slowing the clip down. The viewer runs that timer only
// while some video is playing.
export const VIDEO_FPS = 10;
export const stopped = () => ({ i: 0, playing: false, t0: 0 });

// Playing from the last frame starts over (unless a time was given).
function play(st, on, n, now, rewind = true) {
  const i = on && rewind && st.i >= n - 1 ? 0 : st.i;
  return { i, playing: on, t0: now - i * 1000 / VIDEO_FPS };
}

// A command from the viewer (Enter, a click, mdh video): { state: toggle|play|pause|seek, t? }.
// `n` is the clip's frame count. Returns the new state.
export function command(st, c, n, now) {
  if (!n) return st;
  let s = st;
  if (typeof c.t === "number") s = { ...s, i: Math.max(0, Math.min(n - 1, Math.round(c.t * VIDEO_FPS))) };
  if (c.state === "toggle") return play(s, !s.playing, n, now);
  if (c.state === "play") return play(s, true, n, now, typeof c.t !== "number");
  if (c.state === "pause") return { ...s, playing: false };
  if (c.state === "seek") return play(s, s.playing, n, now, false);
  return s;
}

// One poll of the clock: the state to show now, or the same object when nothing changed.
// Reaching the last frame stops.
export function tick(st, n, now) {
  if (!st.playing || !n) return st;
  const i = Math.min(n - 1, Math.floor((now - st.t0) * VIDEO_FPS / 1000));
  if (i === st.i && i < n - 1) return st;
  return { ...st, i, playing: i < n - 1 };
}
