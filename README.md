<div align="center">

[![copier](https://img.shields.io/badge/copier-template-orange)](https://copier.readthedocs.io/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![mise](https://mise-versions.jdx.dev/badge.svg)](https://mise.jdx.dev)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)

# Base Template
</div>

This Copier template bootstraps baseline repository hygiene for language-agnostic projects. It is intentionally small: the goal is to give every new repository a consistent starting point for line endings, ignore rules, and local quality checks without imposing a language stack.

## What It Adds

The generated repository includes:

- `.gitignore` with GitHub's `macOS` and `mise` templates
- `.editorconfig` with LF, UTF-8, final newline, and per-language indent rules
- `.gitattributes` rendered from `.gitattributes.jinja` to normalize text files and mark common binaries
- `.pre-commit-config.yaml` with basic repository safety and shell linting hooks
- `mise.toml` to pin the tools used to maintain the template and generated repositories

## Included Tooling

Tool versions are managed with `mise`.

- `git-cliff` for changelog generation
- `pre-commit` for local hook execution
- `shellcheck` for shell script linting

## Usage

Create a new repository from this template with Copier:

```bash
copier copy gh:copier-templates/base path/to/new-repo
```

After generation, install the managed tools, install hooks, and run the configured checks:

```bash
mise install
mise run hooks
mise run check
```

## Notes

- This template currently has no prompts and is intended to be a low-friction base layer.
- If you extend it with language-specific templates later, keep this template focused on shared repository conventions.
