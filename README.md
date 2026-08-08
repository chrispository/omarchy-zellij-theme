<!-- space between -->
<h1>
  omarchy-zellij-theme &nbsp;&nbsp; <img src="https://raw.githubusercontent.com/skvggor/omarchy-zellij-theme/refs/heads/develop/assets/star.svg" alt="Star" height="30" style="vertical-align: middle;" />
</h1>

Syncs your [Zellij](https://zellij.dev/) theme with your [Omarchy](https://omarchy.org/) system theme automatically.

<p align="center">
  
https://github.com/user-attachments/assets/0be5f3c9-fbba-479c-9f52-bd312aed5a8c

</p>

Every time you change your Omarchy theme, Zellij picks up the same color palette in real time.

## How it works

The integration renders `zellij.kdl.tpl` from the active theme's `colors.toml`, converts RGB values to Zellij's space-separated format, and atomically updates the `omarchy {}` theme inside the existing `themes {}` block in `~/.config/zellij/config.kdl`. If no theme block exists, it creates one. Since Zellij watches its config file, existing sessions hot-reload the new theme without reading a partially written config.

```
colors.toml ──> zellij.kdl.tpl ──> rendered theme (R,G,B)
                                      │
                                theme-set hook
                              (RGB conversion + atomic update)
                                                     │
                                                     ▼
                                      ~/.config/zellij/config.kdl
                                      (omarchy node inside themes {})
                                                     │
                                                     ▼
                                          Zellij hot-reloads ✓
```

### Color mapping

| Zellij component         | Omarchy color                                            |
| ------------------------ | -------------------------------------------------------- |
| Text base                | `foreground`                                             |
| Backgrounds              | `background`, `color0` (selected)                        |
| Ribbon selected          | `accent` bg, `background` text                           |
| Ribbon unselected        | `accent` bg, `background` text                           |
| Frame selected           | `accent`                                                 |
| Frame unselected         | `color8`                                                 |
| Frame highlight          | `color3`                                                 |
| Emphases                 | `color1`..`color5` distributed across emphasis_0..3      |
| Exit success / error     | `color2` / `color1`                                      |

## Install

```bash
git clone https://github.com/skvggor/omarchy-zellij-theme.git
cd omarchy-zellij-theme
./install.sh
```

The installer:

1. Symlinks `zellij.kdl.tpl` into `~/.config/omarchy/themed/`
2. Installs a standalone hook at `~/.config/omarchy/hooks/theme-set.d/omarchy-zellij-theme`
3. Adds `theme "omarchy"` to `~/.config/zellij/config.kdl` (creates a timestamped backup first)
4. Cleans up old theme file from previous approach if present
5. Renders and updates the current `omarchy {}` theme node inside `config.kdl`

It is safe to re-run -- the script is idempotent.

The hook uses Omarchy's `theme-set.d` directory, so it does not overwrite or modify another `theme-set` hook.

## Uninstall

```bash
./uninstall.sh
```

This reverts everything:

1. Removes the template symlink from `~/.config/omarchy/themed/`
2. Removes the integration hook from `~/.config/omarchy/hooks/theme-set.d/`
3. Comments out `theme "omarchy"` in `~/.config/zellij/config.kdl`
4. Removes the generated `omarchy {}` theme node from `config.kdl`
5. Cleans up old theme file if present

Zellij returns to its default theme on the next session.

## Files

| File              | Purpose                                                              |
| ----------------- | -------------------------------------------------------------------- |
| `zellij.kdl.tpl`  | Zellij theme template using `{{ key_rgb }}` placeholders             |
| `theme-set`        | Hook script -- renders, converts, and atomically updates the theme node in config.kdl |
| `theme-notify`     | Floating pane notification shown on theme change                     |
| `install.sh`       | Installer (symlink, hook, config, initial apply)                     |
| `uninstall.sh`     | Uninstaller (reverts all changes)                                    |

## Requirements

- [Omarchy](https://omarchy.org/) with the template/hook system (`omarchy theme set`, `omarchy-theme-set-templates`)
- [Zellij](https://zellij.dev/) with config at `~/.config/zellij/config.kdl`

## Usage

After installing, just use Omarchy as usual:

```bash
omarchy theme set tokyo-night   # Zellij theme updates instantly (all sessions)
omarchy theme set catppuccin    # same
```

All Zellij sessions -- including ones already running -- pick up the new theme in real time.
