# steam-freebooter-builds

Pre-compiled releases and installation script for [steam-freebooter](https://github.com/vynxc/steam-freebooter).

## Install

Paste this into your terminal to install steam-freebooter. Works on most Linux desktops and **SteamOS / Steam Deck**:

```bash
curl -sSL https://raw.githubusercontent.com/vynxc/steam-freebooter-builds/main/install.sh | bash
```

### What does this do?

1. Downloads the latest i686 injector asset from [GitHub Releases](https://github.com/vynxc/steam-freebooter-builds/releases).
2. Places it in `~/.local/share/steam-freebooter/lib32/`.
3. Installs a small launcher wrapper and points `steam.desktop` at it.
4. Removes the old global `environment.d` injection file if a previous installer created it.

## Manual Installation

1. Download `sf-injector-i686.so` from the [latest release](https://github.com/vynxc/steam-freebooter-builds/releases/latest).
2. Place it at `~/.local/share/steam-freebooter/lib32/sf-injector.so`.
3. Run Steam through the installed launcher:
   ```bash
   ~/.local/share/steam-freebooter/steam-freebooter-steam steam
   ```

## Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/vynxc/steam-freebooter-builds/main/uninstall.sh | bash
```

This removes the injector, cleans up old environment config, and restores the stock Steam launcher. Your `~/.config/steam-freebooter` config is preserved in case you reinstall.

## Source Code

The main codebase is at [vynxc/steam-freebooter](https://github.com/vynxc/steam-freebooter).
