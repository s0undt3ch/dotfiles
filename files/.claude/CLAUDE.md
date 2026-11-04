# Personal rules (all repos)

## PRs outside the PaddleHQ org

Before opening or editing a PR, run `git remote get-url origin`. If the owner is not `PaddleHQ`:

- Drop the "Skills used" `<details>` block that `session-report.sh` (from `/paddle-shared:open-pr`) prints.
- Keep the "Self-review findings" block, but strip `paddle-*:` prefixes from reviewer names, so `paddle-go-backend:review-backend-adversarial` becomes `review-backend-adversarial`.
- Never name Paddle plugin skills (`paddle-shared:*`, `paddle-go-backend:*`, etc.) in the title or body.
- Never write "paddle", Paddle repo names or Paddle email addresses in the title or body.
