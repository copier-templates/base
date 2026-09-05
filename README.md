<p align="center">
  <a href="https://copier.readthedocs.io/"><img src="https://img.shields.io/badge/copier-template-orange" alt="copier"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT"></a>
  <a href="https://mise.jdx.dev"><img src="https://mise-versions.jdx.dev/badge.svg" alt="mise"></a>
  <a href="https://github.com/pre-commit/pre-commit"><img src="https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit" alt="pre-commit"></a>
</p>

# Base Template

Copier template for baseline repository hygiene on language-agnostic projects. Small base layer: line endings, ignore rules, and local quality checks — no language stack.

## What's included

| File | Purpose |
|---|---|
| `.editorconfig` | LF, UTF-8, final newline, per-language indents |
| `.gitattributes` | Text normalization, binary marking |
| `.gitignore` | `macOS` + `mise` + `.env` ignores |
| `.pre-commit-config.yaml` | Safety checks, secrets scanning, shell lint/format, conventional commits |
| `.shellcheckrc` | Bash dialect, extra checks |
| `mise.toml` | Pinned tools (`git-cliff`, `gitleaks`, `pre-commit`, `shellcheck`, `shfmt`); `install` / `check` / `format` / `changelog` tasks |
| `cliff.toml` | Conventional-commit changelog config |
| `.github/workflows/check.yml` | CI running `mise run check` on push/PR |
| `.env.example` | Committed example for mise-loaded `.env` |
| `scripts/` | Shell scripts (shebang + `.sh` extension enforced) |
| `README.md` | Templated from answers |
| `LICENSE` | Templated from answers |
| `.copier-answers.yml` | Committed answers, required for `copier update` |

## Requirements

- Copier >= 9
- Git and [mise](https://mise.jdx.dev) (skippable with `--skip-tasks`, but then setup tasks don't run)

## Quickstart

```bash
copier copy --trust gh:copier-templates/base path/to/new-repo
```

With defaults (no prompts), or without auto-setup (CI / no mise):

```bash
copier copy --trust --defaults gh:copier-templates/base path/to/new-repo
copier copy --skip-tasks gh:copier-templates/base path/to/new-repo
```

`--trust` is required: setup tasks run `git init` and `mise run install` (installs tools, initializes hooks), then commit everything as `chore: Bootstrapping project from copier template`. Then verify:

```bash
mise run check
```

## Template variables

| Variable | Default | Description |
|---|---|---|
| `project_name` | `my base project` | Human-readable project name |
| `project_slug` | derived from `project_name` | URL/filesystem-safe slug (lowercase, dashes) |
| `description` | `A new base project.` | One-line project description |
| `author` | `Patryk` | Copyright holder / author name |
| `email` | `8299306+kpatryk@users.noreply.github.com` | Author contact email |
| `copyright_year` | `2026` | Copyright year for LICENSE |

## Updating

Answers live in `.copier-answers.yml` (committed). To pull in later template changes:

```bash
copier update --trust
```

Updates overwrite template-owned files — never store per-project customization there.

## Development

- `copier.yaml` — questions, `_subdirectory: template`, `_templates_suffix: .jinja`, tasks
- `template/` — files copied to output (`*.jinja` rendered, rest verbatim), including the answers-file template that renders `.copier-answers.yml`
- Root hygiene files (`.editorconfig`, `.gitattributes`, `.gitignore`, `.pre-commit-config.yaml`, `mise.toml`, `cliff.toml`, `scripts/validate-render.sh`) are duplicated into `template/` — keep both copies in sync
- `CHANGELOG.md` — template's own changelog (not copied)

Test a change by rendering to a clean dir (`--skip-tasks` for a fast render-only test), then verify:

```bash
rm -rf /tmp/copier-test && copier copy --trust --defaults --skip-tasks . /tmp/copier-test
cd /tmp/copier-test && mise run check
```

For full test:
```bash
rm -rf /tmp/copier-test-full && copier copy --trust --defaults . /tmp/copier-test-full
cd /tmp/copier-test-full && mise run check
```

## License

MIT — see [LICENSE](LICENSE).
