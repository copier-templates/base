#!/usr/bin/env bash
# Bump pinned tools in mise.toml to the latest stable fixed versions.
# Writes fixed versions (e.g. git-cliff = "2.14.2"), never "latest".
#
# Bump level (default: patch):
#   patch  only the last version component may move (4.6.2 -> newest 4.6.x)
#   minor  minor + patch may move, never major (4.6.2 -> newest 4.x)
#   major  bump to the newest stable release overall (explicit opt-in)
#
# Usage: bash scripts/bump-mise-tools.sh [--level <patch|minor|major>] [--dry-run] [--check] [--yes]
# (bare --patch/--minor/--major are accepted as shorthand for --level)
# Run via `mise run bump` (extra args are forwarded, e.g. `mise run bump --level minor`).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIMARY="${ROOT}/mise.toml"
LEVEL="patch"
LEVEL_SET=0
YES=0
DRY_RUN=0
CHECK=0

die() {
  local message=$1
  gum style --foreground 196 "Error: ${message}" >&2
  exit 1
}

warn() {
  gum style --foreground 214 "Warning: $1" >&2
}

step() {
  gum style --foreground 81 --bold "$1"
}

success() {
  gum style --foreground 42 "$1"
}

is_interactive() {
  [[ -t 0 && -t 1 ]]
}

require_cmd() {
  local name=$1 hint=$2
  command -v "${name}" >/dev/null 2>&1 || die "${name} is required. ${hint}"
}

usage() {
  cat <<'USAGE'
Usage: bump-mise-tools.sh [--level <patch|minor|major>] [--dry-run] [--check] [--yes] [-h|--help]

  --level <patch|minor|major>
                          Bump level; --patch, --minor, --major work as shorthand.
                          patch (default): only the last version component moves.
                          minor: also allow minor bumps, never major.
                          major: newest stable release overall.
  --dry-run   Show what would change without changing anything.
  --check     Exit 1 if any pinned tool is outdated (for CI); changes nothing.
  --yes, -y   Apply without asking (implied when not running in a terminal).
  -h, --help  Show this help.
USAGE
}

set_level() {
  case "$1" in
  patch | minor | major)
    LEVEL="$1"
    LEVEL_SET=1
    ;;
  *)
    echo "ERROR: unknown level: $1 (expected one of: patch, minor, major)" >&2
    usage >&2
    exit 2
    ;;
  esac
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --patch | --minor | --major)
      set_level "${1#--}"
      shift
      ;;
    --level)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --level requires an argument (one of: patch, minor, major)" >&2
        usage >&2
        exit 2
      fi
      set_level "$2"
      shift 2
      ;;
    --level=*)
      set_level "${1#--level=}"
      shift
      ;;
    --dry-run | -n)
      DRY_RUN=1
      shift
      ;;
    --check | -c)
      CHECK=1
      shift
      ;;
    --yes | -y)
      YES=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
    esac
  done
}

pick_level() {
  if [[ "${LEVEL_SET}" -eq 1 || "${YES}" -eq 1 ]]; then
    return 0
  fi
  # shellcheck disable=SC2310 # is_interactive is a safe predicate; suspension of set -e in condition is intended
  if is_interactive; then
    LEVEL="$(gum choose --header "Select bump level" patch minor major)" || die "Cancelled."
  fi
}

# Resolve the newest stable version per pinned tool and write
# "<tool>\t<current>\t<candidate>" rows to PLAN_FILE (empty candidate = failed).
# Runs inside `gum spin`, so it must stay safe without `set -e`.
resolve_plan() {
  local tools_tsv tool current prefix request candidate line
  tools_tsv="$(awk '/^\[tools\]/{t=1; next} /^\[.*\]/{t=0} t && /=/{print}' "${PRIMARY}")"
  while IFS= read -r line; do
    [[ -n "${line}" ]] || continue
    if [[ "${line}" =~ ${ENTRY_RE} ]]; then
      tool="${BASH_REMATCH[1]}"
      current="${BASH_REMATCH[2]}"
    else
      warn "skipping unparsable tools entry: ${line}"
      continue
    fi
    case "${LEVEL}" in
    patch)
      if [[ "${current}" == *.* ]]; then
        prefix="${current%.*}"
      else
        prefix="${current}"
      fi
      ;;
    minor)
      prefix="${current%%.*}"
      ;;
    major)
      prefix=""
      ;;
    *)
      die "Unknown level: ${LEVEL}"
      ;;
    esac
    if [[ -n "${prefix}" ]]; then
      request="${tool}@${prefix}"
    else
      request="${tool}"
    fi
    candidate=""
    if candidate="$(mise -C "${ROOT}" latest "${request}" 2>/dev/null)"; then
      candidate="${candidate%%$'\n'*}"
    else
      candidate=""
    fi
    printf '%s\t%s\t%s\n' "${tool}" "${current}" "${candidate}" >>"${PLAN_FILE}"
  done <<<"${tools_tsv}"
  return 0
}

maybe_confirm() {
  local prompt=$1
  if [[ "${YES}" -eq 1 ]]; then
    return 0
  fi
  # shellcheck disable=SC2310 # is_interactive is a safe predicate; suspension of set -e in condition is intended
  if is_interactive; then
    gum confirm "${prompt}" || die "Cancelled."
  fi
}

main() {
  parse_args "$@"

  require_cmd gum "Run 'mise install' (gum is pinned in mise.toml) or 'brew install gum'."
  require_cmd mise "Install mise: https://mise.jdx.dev/getting-started.html"

  [[ -f "${PRIMARY}" ]] || die "${PRIMARY} not found."

  pick_level

  step "Resolving ${LEVEL} bumps (stable releases)..."

  PLAN_FILE="$(mktemp)"
  trap 'rm -f "${PLAN_FILE}"' EXIT
  # ENTRY_RE is ERE syntax for `[[ =~ ]]` (quotes must stay literal)
  # and must cross into the spinner child via export.
  # shellcheck disable=SC2089,SC2090
  export ENTRY_RE='^[[:space:]]*([A-Za-z0-9_.+/:~-]+)[[:space:]]*=[[:space:]]*"([^"]+)"[[:space:]]*$'
  export ROOT PRIMARY LEVEL PLAN_FILE
  export -f resolve_plan warn
  gum spin --title "Querying registries..." -- bash -c resolve_plan

  [[ -f "${PLAN_FILE}" ]] || die "version resolution failed (no plan produced)."

  local tool current candidate status
  local -a table_rows=()
  local bumped=0 failures=0
  local -a bump_tools=() bump_versions=()
  while IFS=$'\t' read -r tool current candidate || [[ -n "${tool}" ]]; do
    [[ -n "${tool}" ]] || continue
    if [[ -z "${candidate}" ]]; then
      status="unresolved"
      failures=$((failures + 1))
      candidate="-"
    elif [[ "${candidate}" == "${current}" ]]; then
      status="up to date"
    else
      status="bump"
      bumped=$((bumped + 1))
      bump_tools+=("${tool}")
      bump_versions+=("${candidate}")
    fi
    table_rows+=("${tool},${current},${candidate},${status}")
  done <"${PLAN_FILE}"

  printf '%s\n' "${table_rows[@]}" | gum table --print --columns "Tool,Current,New,Status"

  if [[ "${failures}" -gt 0 ]]; then
    die "${failures} tool(s) could not be resolved."
  fi

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    success "Dry run done (no files changed)."
    return 0
  fi

  if [[ "${CHECK}" -eq 1 ]]; then
    if [[ "${bumped}" -gt 0 ]]; then
      die "tools are outdated (run 'mise run bump')."
    fi
    success "All tools up to date."
    return 0
  fi

  if [[ "${bumped}" -eq 0 ]]; then
    success "All tools up to date."
    return 0
  fi

  maybe_confirm "Apply ${bumped} ${LEVEL} bump(s)?"

  local i
  for i in "${!bump_tools[@]}"; do
    mise -C "${ROOT}" use --path "${PRIMARY}" "${bump_tools[${i}]}@${bump_versions[${i}]}"
  done

  # Guard: never leave a floating "latest" request behind; pin exact versions.
  if grep -Eq '^[[:space:]]*[A-Za-z0-9_.-]+[[:space:]]*=[[:space:]]*"latest"' "${PRIMARY}"; then
    die "${PRIMARY} still contains a floating \"latest\" version. Pin it instead, e.g.: mise use --pin <tool>@<version>"
  fi

  # Root mise.toml is duplicated into template/mise.toml (kept in sync by hand);
  # sync them here so one bump updates both.
  local mirror="${ROOT}/template/mise.toml"
  if [[ -f "${mirror}" ]] && ! [[ "${PRIMARY}" -ef "${mirror}" ]]; then
    cp "${PRIMARY}" "${mirror}"
    step "Synced ${mirror}."
  fi

  success "bump-mise-tools: OK."
}

main "$@"
