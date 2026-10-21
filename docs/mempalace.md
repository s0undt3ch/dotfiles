# MemPalace on Qdrant

MemPalace stores vectors in a local Qdrant server instead of Chroma. Chroma
allows one writer process per palace, so parallel Claude sessions fought over
the lock. Qdrant is on mempalace's multi-writer list
(`_MULTI_PROCESS_WRITER_BACKENDS` in `mempalace/palace/backend.py`), so every
session's MCP server and hooks can write at once.

## Pieces, all in `home/`

- `dot_config/mise/config.toml.tmpl` pins `github:qdrant/qdrant`. It is one
  binary from the GitHub release, with no Docker.
- `dot_config/qdrant/config.yaml.tmpl` binds to 127.0.0.1 only, keeps data in
  `~/.local/share/qdrant` and turns telemetry off.
- `Library/LaunchAgents/com.pedro.qdrant.plist.tmpl` (macOS) and
  `dot_config/systemd/user/qdrant.service` (Linux) keep Qdrant running.
- `private_dot_mempalace/modify_private_config.json` sets `backend`,
  `qdrant_url`, `qdrant_timeout`, `palace_path` and `write_routing.hooks` in
  `~/.mempalace/config.json`. It leaves every other key alone.
- `com.pedro.mempalace-hub.plist.tmpl` / `mempalace-hub.service` run
  `mempalace serve` on 127.0.0.1:8765. See below.
- `dot_local/bin/executable_mempalace-wings` plus its launchd agent / systemd
  timer runs daily at 03:30. See below.
- `run_onchange_after_start_mempalace_daemon.sh.tmpl` loads the lot. It reruns
  on any change to the mise config, the Qdrant config or the units.

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

The knowledge graph (`~/.mempalace/knowledge_graph.sqlite3`) is SQLite
whatever the backend, and it carries over unchanged.

## What gets mined

- **Projects.** Each dir under `~/projects/{me,paddle,3rd-party}` gets a wing
  named after the dir. The name gets a group prefix (`me-foo`) only when two
  groups hold a dir with the same name.
- **Transcripts.** The mempalace plugin's Stop, PreCompact and SessionEnd hooks
  mine each session's JSONL straight into the project's wing. Mempalace parses
  Claude Code JSONL itself, so there is no markdown conversion step. The daily
  job sweeps `<config dir>/projects/*/*.jsonl` for every Claude profile as a
  backstop. An unchanged transcript is an mtime no-op.

Mining writes no file: the hook normalises the JSONL in memory and files
drawers whose `source_file` is the transcript path. The weekly sync passes each
project dir as its root, so transcript drawers stay out of scope. When Claude
Code prunes an old transcript (`cleanupPeriodDays`), its drawers survive.

## Weekly sync is dry-run

`MEMPALACE_SYNC_APPLY=0` is set in the launchd plist and the systemd service.
Each run writes `~/.mempalace/sync-reports/YYYY-MM-DD.log` and sends a desktop
notification with the path. Read a few reports, then flip the variable to `1` in
the repo and `chezmoi apply`. `--apply` deletes drawers.

## Checks

    curl -s http://127.0.0.1:6333/readyz
    curl -s http://127.0.0.1:8765/healthz
    mempalace status
    launchctl print gui/$(id -u)/com.pedro.qdrant          # macOS
    launchctl print gui/$(id -u)/com.pedro.mempalace-hub   # macOS
    systemctl --user status qdrant mempalace-hub           # Linux

## Known trade-off

The Qdrant backend runs lexical (BM25) search client-side: it scrolls the
matching rows over REST and scores them in Python. On a large palace, hybrid
search may be slower than on Chroma. If calls time out, raise `qdrant_timeout`.
