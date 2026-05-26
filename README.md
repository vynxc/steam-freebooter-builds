# steam-freebooter-builds

Pre-compiled releases and installation script for [steam-freebooter](https://github.com/vynxc/steam-freebooter).

## Install

Paste this into your terminal to install steam-freebooter. Works on most Linux desktops and **SteamOS / Steam Deck**:

```bash
curl -sSL https://raw.githubusercontent.com/vynxc/steam-freebooter-builds/main/install.sh | bash
```

### What does this do?

1. Downloads the latest `sf-injector.so` from [GitHub Releases](https://github.com/vynxc/steam-freebooter-builds/releases).
2. Places it in `~/.local/share/steam-freebooter/sf-injector.so`.
3. Configures automatic injection via:
   - **SteamOS Game Mode**: `environment.d` drop-in (`~/.config/environment.d/10-steam-freebooter.conf`)
   - **Desktop Linux**: Wrapped `steam.desktop` launcher

## Manual Installation

1. Download `sf-injector.so` from the [latest release](https://github.com/vynxc/steam-freebooter-builds/releases/latest).
2. Place it somewhere permanent and make it executable (`chmod +x`).
3. Run Steam with:
   ```bash
   LD_AUDIT=/path/to/sf-injector.so steam
   ```

## Uninstall

```bash
rm ~/.local/share/steam-freebooter/sf-injector.so
rm ~/.config/environment.d/10-steam-freebooter.conf
rm ~/.local/share/applications/steam.desktop
```

## Source Code

The main codebase is at [vynxc/steam-freebooter](https://github.com/vynxc/steam-freebooter).
