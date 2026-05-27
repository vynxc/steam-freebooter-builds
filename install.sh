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
ENV_DIR="${HOME}/.config/environment.d"
ENV_FILE="${ENV_DIR}/10-steam-freebooter.conf"
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

# Find the sf-injector.so asset download URL
DOWNLOAD_URL=$(echo "${RELEASE_JSON}" | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*sf-injector\.so"' | head -1 | grep -o 'https://[^"]*')

if [[ -z "${DOWNLOAD_URL}" ]]; then
  die "Could not find sf-injector.so in the latest release assets"
fi

TAG_NAME=$(echo "${RELEASE_JSON}" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')
info "Installing steam-freebooter ${TAG_NAME}..."

TMP_SO=$(mktemp)
trap 'rm -f "${TMP_SO}"' EXIT

curl -sSL -f -o "${TMP_SO}" "${DOWNLOAD_URL}" || die "Failed to download sf-injector.so"

# ── Install ───────────────────────────────────────────────────────
mkdir -p "${DATA_DIR}"
AUDIT="${DATA_DIR}/sf-injector.so"

install -Dm755 "${TMP_SO}" "${AUDIT}"
info "Installed ${AUDIT} ($(stat -c%s "${AUDIT}") bytes)"

# ── System Integration (SteamOS & Desktop) ───────────────────────

# 1. SteamOS / systemd user session (Game Mode & general Wayland/X11)
mkdir -p "${ENV_DIR}"
echo "LD_AUDIT=\"${AUDIT}\"" > "${ENV_FILE}"
info "Configured systemd environment injection at ${ENV_FILE} (Supports SteamOS Game Mode)"

# 2. Wrap Steam .desktop (For standalone desktop mode fallback)
if [[ -f "${STOCK_DESKTOP}" ]]; then
  mkdir -p "${DESKTOP_DIR}"
  WRAP_PREFIX="env LD_AUDIT=\"${AUDIT}\""
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
echo "  3. Restart your session or reboot your Steam Deck to apply."
