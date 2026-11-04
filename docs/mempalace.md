# MemPalace on Qdrant

MemPalace stores vectors in a local Qdrant server instead of Chroma. Chroma
allows one writer process per palace, so parallel Claude sessions fought over
the lock. Qdrant is on mempalace's multi-writer list
(`_MULTI_PROCESS_WRITER_BACKENDS` in `mempalace/palace/backend.py`), so every
session's MCP server and hooks can write at once.

## Pieces, all in `home/`

- `files/.config/mise/config.toml` pins `github:qdrant/qdrant` (the macOS and
  arm64 asset picks live in `config.macos.toml` / `config.linux-arm64.toml`).
  It is one binary from the GitHub release, with no Docker.
- `files/.config/qdrant/config.yaml.tera` binds to 127.0.0.1 only, keeps data in
  `~/.local/share/qdrant` and turns telemetry off.
- `files/.mempalace/config.merge.json.tera` sets `backend`, `qdrant_url`,
  `qdrant_timeout`, `palace_path` and `write_routing.hooks` in
  `~/.mempalace/config.json`, as a mise merge edit. It leaves every other key
  alone.
- The services are mise launchd agents (`config.macos.toml`) and systemd user
  units (`config.linux.toml`), all named `dev.mise.<name>`:
  - `dev.mise.qdrant` keeps Qdrant running.
  - `dev.mise.mempalace-hub` runs `mempalace serve` on 127.0.0.1:8765. See below.
  - `dev.mise.mempalace-wings` runs `files/.local/bin/mempalace-wings` daily at
    03:00 (on Linux through `dev.mise.mempalace-wings-timer.timer`). See below.
- `tasks/mempalace-wake` installs the root `com.pedro.mempalace-wake` job that
  wakes the machine for the 03:00 run: a LaunchDaemon on macOS, a system timer
  on Linux. mise only manages user agents, so this one stays a task. It asks for sudo on the
  `mise bootstrap` that installs or changes it.
- `tasks/restart-mempalace` restarts qdrant and the hub on any change to the mise
  config, the Qdrant config or the wings script. mise itself only restarts a
  service whose definition changed.

## Waking the Mac at 03:00

`pmset repeat` holds a single repeating wake, and obsidiary owns it. So
`com.pedro.mempalace-wake` books a one-off `pmset schedule wake` for the next
02:58, at load and daily at 03:05. Those one-off wakes don't clash with the
repeating one.

The wings job runs under `caffeinate -s`, which keeps the Mac awake for the
whole run on AC power only. If the Mac woke on battery and the keyboard has
been idle for 5 minutes, the job skips the run and calls `pmset sleepnow`. The
next run covers the gap: the transcript sweep goes by its marker, not by date.
If a 03:00 run is missed, launchd runs it at the next wake.

    pmset -g sched                                         # 02:58 wake booked?
    sudo launchctl print system/com.pedro.mempalace-wake

## Waking Linux at 03:00

A user timer can't wake the machine: `WakeSystem=` needs `CAP_WAKE_ALARM`. So
the root `com.pedro.mempalace-wake.timer` wakes it at 03:00 and its service
starts the user's `dev.mise.mempalace-wings.service` through
`systemctl --user -M <user>@`. If that run is already going, it waits on it.

The service holds a `sleep:idle:handle-lid-switch` block inhibitor while it
waits. With the lid shut, logind suspends again about 30s after resume, and
`LidSwitchIgnoreInhibited` means only `handle-lid-switch` stops that. The
service runs on AC power only and drops the inhibitor after 5 hours, so a long
backlog can't keep the lid awake all day. The run itself carries on.

    systemctl list-timers com.pedro.mempalace-wake.timer
    journalctl -u com.pedro.mempalace-wake.service
    systemd-inhibit --list                                 # lock held mid-run?

## Why a hub, not the daemon

Every session's `mempalace-mcp` looks for a live hub on the palace. When it
finds one, it becomes a ~22 MB stdio proxy instead of loading its own embedder
and storage stack. CLI `mine` and `search` forward to the hub as well
(`mempalace/cli/_hub.py`). That covers the transcript hooks, which spawn
`mempalace mine`. One process then holds the embedding model, and nothing
needs the daemon's job queue. `write_routing.hooks` is `direct`, so hooks
don't probe a daemon that isn't there.

If the hub is down, each session falls back to a full local server. That
works, because Qdrant takes concurrent writers, but costs memory per session.

## The palace path

`palace_path` is `~/.mempalace/qdrant-palace`. It holds only a
`qdrant_backend.json` marker and the embedder sidecar, and the vectors live in
Qdrant. The old Chroma palace at `~/projects/.mempalace` stays put as an archive.
Mempalace refuses to open a dir that holds artifacts from another backend, so
the two can't share a path.

The knowledge graph is SQLite whatever the backend. It lives inside the
palace dir, at `~/.mempalace/qdrant-palace/knowledge_graph.sqlite3`. The hub
runs with `--palace`, and mines write there too. The file at
`~/.mempalace/knowledge_graph.sqlite3` belongs to the legacy default palace,
and nothing uses it.

## What gets mined

- **Projects.** Each dir under `~/projects/{me,paddle,3rd-party}` gets a wing
  named after the dir. The name gets a group prefix (`me-foo`) only when two
  groups hold a dir with the same name.
- **Transcripts.** The mempalace plugin's Stop, PreCompact and SessionEnd hooks
  mine each session's JSONL straight into the project's wing. Mempalace parses
  Claude Code JSONL itself, so there is no markdown conversion step. The daily
  job sweeps `<config dir>/projects/*/*.jsonl` for every Claude profile as a
  backstop. It visits only transcripts changed since the last sweep
  (`~/.mempalace/transcript-sweep.last`). The first run has no marker and
  backfills every transcript, one cold CLI start each, so expect it to take
  hours. Kick it off by hand rather than waiting for 03:00:
  `launchctl kickstart gui/$(id -u)/dev.mise.mempalace-wings`.

Mining writes no file: the hook normalises the JSONL in memory and files
drawers whose `source_file` is the transcript path. The weekly sync passes each
project dir as its root, so transcript drawers stay out of scope. When Claude
Code prunes an old transcript (`cleanupPeriodDays`), its drawers survive.

## Weekly maintenance

`dot_local/bin/executable_mempalace-maintain.tmpl` runs after the weekly
mining pass and applies its changes rather than proposing them. Output goes to
the weekly report.

1. Adds keyword indexes on drawer metadata (`wing`, `room`, `source_file`, ...)
   in Qdrant. Mempalace indexes only the document text, so without these,
   faceting fails and every wing or source filter scans the whole collection.
2. Drops hallway spelling artifacts.
3. Prunes generic, dangling and duplicate tunnels, then creates the strongest
   missing entity tunnels. `mempalace tunnels` can't do this on Qdrant: it
   reads the wing list from `chroma.sqlite3`. The helper gets the list from the
   Qdrant facet counts instead.
4. Designs a room set for every wing of 50+ drawers that lacks one, files
   drawers from the generic rooms into it, and maps one-off KG predicates onto
   a closed vocabulary. These steps use the local Ollama model named by
   `[vars] mempalace_llm_model` in `files/.config/mise/config.toml`
   (`qwen3:8b`). The wings job gets it as `MEMPALACE_MAINTAIN_MODEL`, and the
   `ollama-pull` task starts Ollama and pulls it. If the model is missing, the steps are skipped. The helper calls mempalace
   in-process with a 16k context. The CLI leaves Ollama at its 4096-token
   default, which truncates the sampled excerpts and makes every model,
   `gemma4:e4b` and `qwen3:8b` included, answer with junk. Nobody reviews the
   room sets, so a set where fewer than half the rooms match a sampled drawer
   is dropped rather than applied.
5. Scores the palace with `mempalace audit`.

Project mines also rebuild their wing's topic tunnels and hallways as they go.

## Weekly sync is dry-run

`MEMPALACE_SYNC_APPLY=0` is set in the launchd plist and the systemd service.
Each run writes `~/.mempalace/sync-reports/YYYY-MM-DD.log` and sends a desktop
notification with the path. Read a few reports, then flip the variable to `1` in
the repo and run `mise bootstrap`. `--apply` deletes drawers.

## Checks

    curl -s http://127.0.0.1:6333/readyz
    curl -s http://127.0.0.1:8765/healthz
    mempalace status
    launchctl print gui/$(id -u)/dev.mise.qdrant                  # macOS
    launchctl print gui/$(id -u)/dev.mise.mempalace-hub           # macOS
    systemctl --user status dev.mise.qdrant dev.mise.mempalace-hub # Linux

## Known trade-off

The Qdrant backend runs lexical (BM25) search client-side: it scrolls the
matching rows over REST and scores them in Python. On a large palace, hybrid
search may be slower than on Chroma. If calls time out, raise `qdrant_timeout`.
