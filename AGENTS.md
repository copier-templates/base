# AGENTS.md

Copier template repo (no app code). `copier.yaml` renders `template/` to new projects; only `*.jinja` is rendered. See `README.md` for usage and layout.

## Commands

| Task | What it does |
|---|---|
| `mise run install` | Install pinned tools + init prek git hooks |
| `mise run check` | Run all prek hooks on every file (same as CI) |
| `mise run validate` | Check Jinja leftovers + answers file, then `check` |
| `mise run format` | Format shell scripts with shfmt |

Test rendering (use `--vcs-ref=HEAD` so copier uses working HEAD, not the cached tag):

```bash
rm -rf /tmp/copier-test && copier copy --trust --defaults --skip-tasks --vcs-ref=HEAD . /tmp/copier-test
```

Then run `mise run check` inside `/tmp/copier-test`.

## GitHub Issues & Branch Workflow

- Every change starts from a GitHub issue. Pull it with the `gh` CLI:
  ```bash
  gh issue view <number> --json title,body,labels,state
  ```
- If the issue does not exist, stop and prompt the user to create the GitHub issue first. Do not invent scope.
- Create branches as `<type>/<issue-number>-<slug>` (type matches the conventional-commit type), e.g. `chore/1-migrate-to-prek`.
- Implementation tasks require a PRD plus its GitHub issue before coding starts. Minor changes (typo, single-file docs tweak) may proceed with just the issue, no PRD.
- Reference the issue in the PR body with `Closes #<number>`.

## Rules

- Conventional commits required (`conventional-pre-commit` hook).
- Shell: `bash`, 2-space `shfmt`, `shellcheck enable=all` except `SC1091`; shebang + executable bit + `.sh` extension.
- Markdown: two trailing spaces are a hard break, not dirt (`trim_trailing_whitespace = false`, `--markdown-linebreak-ext=md`).
- `.env` (mise-loaded) is never committed; commit only `.env.example`.
- Root hygiene files are duplicated into `template/` — keep both copies in sync.
- `copier update --trust` overwrites template-owned files — no per-project customization there.
