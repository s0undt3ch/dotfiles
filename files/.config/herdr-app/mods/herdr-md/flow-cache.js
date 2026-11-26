export const FLOW_CACHE_MAX_ENTRIES = 96;
export const FLOW_CACHE_MAX_CHARS = 64 * 1024;

// Keep the inline-layout cache useful without letting a long document or its
// edits retain every rendered line for the lifetime of the viewer.
export function cacheFlow(cache, source, build, limits = {}) {
  const maxEntries = limits.maxEntries ?? FLOW_CACHE_MAX_ENTRIES;
  const maxChars = limits.maxChars ?? FLOW_CACHE_MAX_CHARS;
  if (cache.has(source)) {
    const value = cache.get(source);
    cache.delete(source);
    cache.set(source, value);
    return value;
  }

  const value = build();
  if (source.length > maxChars) return value;
  cache.set(source, value);
  let chars = [...cache.keys()].reduce((n, key) => n + key.length, 0);
  while (cache.size > maxEntries || chars > maxChars) {
    const oldest = cache.keys().next().value;
    cache.delete(oldest);
    chars -= oldest.length;
  }
  return value;
}
