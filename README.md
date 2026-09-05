<div align="center">

[![copier](https://img.shields.io/badge/copier-template-orange)](https://copier.readthedocs.io/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![mise](https://mise-versions.jdx.dev/badge.svg)](https://mise.jdx.dev)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)

# Base Template
</div>

Copier template for baseline repository hygiene on language-agnostic projects. Small base layer: line endings, ignore rules, and local quality checks — no language stack.

Generated projects get (from `template/`):

- `.gitignore` (GitHub `macOS` + `mise` + `.env`)
- `.editorconfig` (LF, UTF-8, final newline, per-language indents)
- `.gitattributes` (text normalization, binary marking)
- `.pre-commit-config.yaml` (safety + shell lint/format + conventional commits)
- `.shellcheckrc` (bash dialect, extra checks)
- `.env.example` (committed example for mise-loaded `.env`)
- `scripts/` (shell scripts; shebang + `.sh` extension enforced)
- `.github/workflows/check.yml` (GitHub Actions: `mise run check`)
- `mise.toml` (`git-cliff`, `pre-commit`, `shellcheck`, `shfmt`; `hooks`/`check`/`format`/`changelog` tasks)
- `cliff.toml` (conventional-commit changelog config)
- `README.md` + `LICENSE` (templated from answers)
- `.copier-answers.yml` (committed, required for `copier update`)

## Usage

Requires Copier >= 9, `--trust` (tasks run `git init`, `mise install`, `mise run hooks`):

```bash
copier copy --trust gh:copier-templates/base path/to/new-repo
# or with defaults, no prompts:
copier copy --trust --defaults gh:copier-templates/base path/to/new-repo
# skip auto-setup (CI / no mise):
copier copy --skip-tasks gh:copier-templates/base path/to/new-repo
```

Then:

```bash
mise run check
```

Update a generated project:

```bash
copier update --trust
```

Note: updates overwrite template-owned files. Answers live in `.copier-answers.yml` (committed).

## Questions

| Name | Default |
|---|---|
| `project_name` | `My Awesome Project` |
| `project_slug` | slugified `project_name` |
| `description` | `A new project from copier-templates/base` |
| `author` | `copier-templates` |
| `email` | `""` |
| `copyright_year` | `2026` |

## Layout

- `copier.yaml` — questions, `_subdirectory: template`, tasks, messages
- `template/` — files copied to output (`*.jinja` rendered, rest verbatim)
- `CHANGELOG.md` — template's own changelog (not copied)

## Test

```bash
copier copy --trust --defaults --skip-tasks . /tmp/copier-test
```
