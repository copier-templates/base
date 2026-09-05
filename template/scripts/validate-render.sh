#!/usr/bin/env bash
# Validate a rendered project: no leftover Jinja delimiters and a sane answers file.
# Exits nonzero on any problem (fail fast). Run via `mise run validate`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

echo "==> Checking for leftover Jinja delimiters..."
# The pattern is written with character classes so this script never matches itself.
# Allowlist (copied verbatim, never Jinja-rendered): cliff.toml uses Tera block
# syntax, workflows may use dollar-brace expressions, and template-authoring
# files (template/, copier.yaml) only exist in the template repo, not in output.
if grep -rnI -E '[{][{]|[}][}]|[{]%|%[}]' "${ROOT}" --exclude-dir=.git --exclude-dir=.github --exclude-dir=template --exclude=cliff.toml --exclude=copier.yaml --exclude=copier.yml; then
  echo "ERROR: leftover Jinja delimiters found (see above)." >&2
  fail=1
else
  echo "OK: no leftover Jinja delimiters."
fi

echo "==> Checking answers file..."
answers="${ROOT}/.copier-answers.yml"
# The template repo itself ships no answers file; validate it in a rendered
# copy instead. Rendered projects never contain copier.yaml (only template/
# contents are copied), so its presence reliably detects template context.
if [[ -f "${ROOT}/copier.yaml" ]] || [[ -f "${ROOT}/copier.yml" ]]; then
  echo "SKIP: template context, no answers file expected here."
elif [[ ! -f "${answers}" ]]; then
  echo "ERROR: ${answers} is missing." >&2
  fail=1
else
  for key in _commit _src_path project_name project_slug; do
    if ! grep -q "^${key}:" "${answers}"; then
      echo "ERROR: ${answers} is missing key '${key}:...'." >&2
      fail=1
    fi
  done
  # Exactly one trailing newline (end-of-file-fixer also enforces this).
  tail_bytes=$(tail -c 2 "${answers}" | od -An -tx1 | tr -d ' \n')
  case "${tail_bytes}" in
  *0a0a)
    echo "ERROR: ${answers} ends with multiple newlines." >&2
    fail=1
    ;;
  *0a)
    echo "OK: answers file has a single trailing newline."
    ;;
  *)
    echo "ERROR: ${answers} is missing its trailing newline." >&2
    fail=1
    ;;
  esac
fi

if [[ "${fail}" -ne 0 ]]; then
  echo "validate-render: FAILED." >&2
  exit 1
fi
echo "validate-render: OK."
