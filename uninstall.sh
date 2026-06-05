#!/usr/bin/env bash
# steam-freebooter uninstaller.
#
# Removes the injector libraries, old environment config, and restores
# the stock Steam desktop launcher.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/vynxc/steam-freebooter-builds/main/uninstall.sh | bash
#
set -euo pipefail

DATA_DIR="${HOME}/.local/share/steam-freebooter"
ENV_FILE="${HOME}/.config/environment.d/10-steam-freebooter.conf"
DESKTOP_FILE="${HOME}/.local/share/applications/steam.desktop"
STOCK_DESKTOP="/usr/share/applications/steam.desktop"
CONFIG_DIR="${HOME}/.config/steam-freebooter"

info() { echo "==> $*"; }

# ── Remove injector library ──────────────────────────────────────
if [[ -d "${DATA_DIR}" ]]; then
  rm -rf "${DATA_DIR}"
  info "Removed ${DATA_DIR}"
else
  info "No injector found at ${DATA_DIR} (already clean)"
fi

# ── Remove environment.d config ──────────────────────────────────
if [[ -f "${ENV_FILE}" ]]; then
  rm -f "${ENV_FILE}"
  info "Removed ${ENV_FILE}"
else
  info "No environment config found (already clean)"
fi

# ── Restore stock Steam desktop launcher ─────────────────────────
if [[ -f "${DESKTOP_FILE}" ]]; then
  if grep -Eq "steam-freebooter|LD_AUDIT|LD_PRELOAD" "${DESKTOP_FILE}" 2>/dev/null; then
    if [[ -f "${STOCK_DESKTOP}" ]]; then
      cp "${STOCK_DESKTOP}" "${DESKTOP_FILE}"
      info "Restored stock Steam launcher at ${DESKTOP_FILE}"
    else
      rm -f "${DESKTOP_FILE}"
      info "Removed wrapped launcher (stock not found, system default will be used)"
    fi

    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
    fi
  else
    info "Steam launcher at ${DESKTOP_FILE} is not wrapped by steam-freebooter (skipping)"
  fi
else
  info "No custom Steam launcher found (already clean)"
fi

echo
echo "Done. steam-freebooter has been uninstalled."
echo "  - Your config at ${CONFIG_DIR} was preserved."
echo "    Remove it manually if you don't plan to reinstall:"
echo "      rm -rf ${CONFIG_DIR}"
echo "  - Restart your session or reboot your Steam Deck to fully clear."
