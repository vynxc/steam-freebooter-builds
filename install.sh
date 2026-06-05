#!/usr/bin/env bash
# steam-freebooter installer.
#
# Downloads the latest release from GitHub and sets up Steam injection.
# Works on most Linux desktops and SteamOS (Steam Deck).
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/vynxc/steam-freebooter-builds/main/install.sh | bash
#
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────
REPO="vynxc/steam-freebooter-builds"
API_URL="https://api.github.com/repos/${REPO}"
DATA_DIR="${HOME}/.local/share/steam-freebooter"
LAUNCHER="${DATA_DIR}/steam-freebooter-steam"
OLD_ENV_FILE="${HOME}/.config/environment.d/10-steam-freebooter.conf"
DESKTOP_DIR="${HOME}/.local/share/applications"
DESKTOP_FILE="${DESKTOP_DIR}/steam.desktop"
STOCK_DESKTOP="/usr/share/applications/steam.desktop"

# ── Helpers ────────────────────────────────────────────────────────
die()  { echo "error: $*" >&2; exit 1; }
info() { echo "==> $*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

need_cmd curl

USE_BETA=0
if [[ "${1:-}" == "--beta" ]]; then
  USE_BETA=1
fi

# ── Download from latest release ──────────────────────────────────
if [[ "${USE_BETA}" == "1" ]]; then
  info "Fetching latest beta release from ${REPO}..."
  RELEASE_JSON=$(curl -sSL "${API_URL}/releases") || die "Failed to fetch releases"
else
  info "Fetching latest stable release from ${REPO}..."
  RELEASE_JSON=$(curl -sSL "${API_URL}/releases/latest") || die "Failed to fetch latest release"
fi

# Find the i686 injector asset download URL.
DOWNLOAD_URL_32=$(echo "${RELEASE_JSON}" | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*sf-injector-i686\.so"' | head -1 | grep -o 'https://[^"]*')

if [[ -z "${DOWNLOAD_URL_32}" ]]; then
  die "Could not find sf-injector-i686.so in the latest release"
fi

TAG_NAME=$(echo "${RELEASE_JSON}" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
info "Installing steam-freebooter ${TAG_NAME}..."

TMP_SO_32=$(mktemp)
trap 'rm -f "${TMP_SO_32}"' EXIT

curl -sSL -f -o "${TMP_SO_32}" "${DOWNLOAD_URL_32}" || die "Failed to download sf-injector-i686.so"

# ── Install ───────────────────────────────────────────────────────
mkdir -p "${DATA_DIR}"

install -Dm755 "${TMP_SO_32}" "${DATA_DIR}/lib32/sf-injector.so"
rm -rf "${DATA_DIR}/lib64"
info "Installed ${DATA_DIR}/lib32/sf-injector.so ($(stat -c%s "${DATA_DIR}/lib32/sf-injector.so") bytes)"

cat > "${LAUNCHER}" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${HOME}/.local/share/steam-freebooter"
PRELOAD_32="${DATA_DIR}/lib32/sf-injector.so"

unset LD_AUDIT
export SF_INJECTOR_PRELOAD_32="${PRELOAD_32}"
export LD_PRELOAD="${PRELOAD_32}"

if [[ "$#" -gt 0 ]]; then
  exec "$@"
else
  exec steam
fi
SH
chmod 755 "${LAUNCHER}"
info "Installed ${LAUNCHER}"

# Remove the old global session injection if a previous installer created it.
if [[ -f "${OLD_ENV_FILE}" ]]; then
  rm -f "${OLD_ENV_FILE}"
  info "Removed old global environment injection at ${OLD_ENV_FILE}"
fi

# ── System Integration ────────────────────────────────────────────
if [[ -f "${STOCK_DESKTOP}" ]]; then
  mkdir -p "${DESKTOP_DIR}"
  WRAP_PREFIX="\"${LAUNCHER}\""
  sed -E "s|^Exec=(.+)$|Exec=${WRAP_PREFIX} \1|" \
      "${STOCK_DESKTOP}" > "${DESKTOP_FILE}.tmp"
  mv "${DESKTOP_FILE}.tmp" "${DESKTOP_FILE}"
  info "Wrapped ${DESKTOP_FILE}"

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
  fi
else
  echo "warn: no stock steam.desktop at ${STOCK_DESKTOP}; skipping launcher wrap" >&2
fi

# ── Config dir ────────────────────────────────────────────────────
mkdir -p "${HOME}/.config/steam-freebooter"

echo
echo "Done. steam-freebooter ${TAG_NAME} installed successfully."
echo "  1. Make sure Steam is closed."
echo "  2. Edit ~/.config/steam-freebooter/config.yaml if needed."
echo "  3. Launch Steam from your app menu."
