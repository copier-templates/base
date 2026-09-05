# AGENTS.md

Copier template repo (no app code). `copier.yaml` renders `template/` to new projects; only `*.jinja` is rendered. See `README.md` for usage and layout.

## Commands

```bash
mise run install   # install tools + init hooks
mise run check     # pre-commit run --all-files (same as CI)
mise run format    # shfmt --list --write .
mise run changelog # git-cliff --output CHANGELOG.md
```

Test rendering:

```bash
rm -rf /tmp/copier-test && copier copy --trust --defaults --skip-tasks . /tmp/copier-test
```

Then run `mise run check` inside `/tmp/copier-test`.

## Rules

- Conventional commits required (`conventional-pre-commit` hook).
- Shell: `bash`, 2-space `shfmt`, `shellcheck enable=all` except `SC1091`; shebang + executable bit + `.sh` extension.
- Markdown: two trailing spaces are a hard break, not dirt (`trim_trailing_whitespace = false`, `--markdown-linebreak-ext=md`).
- `.env` (mise-loaded) is never committed; commit only `.env.example`.
- Root hygiene files are duplicated into `template/` — keep both copies in sync.
- `copier update --trust` overwrites template-owned files — no per-project customization there.
