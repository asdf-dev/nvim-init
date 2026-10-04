# nvim-init

A small, opinionated Neovim configuration with a one-command installer.

The repository contains a single `init.lua` and an installer that puts everything in the correct place, bootstraps `lazy.nvim`, and installs Neovim when the machine does not have a sufficiently recent version.

## Install

### macOS / Linux / WSL

```sh
curl -fsSL https://raw.githubusercontent.com/asdf-dev/nvim-init/main/install.sh | sh
```

Then:

```sh
nvim
```

The first launch lets `lazy.nvim` install the plugins declared by `init.lua`.

## What the installer does

The installer:

1. Detects macOS or Linux/WSL.
2. Checks the installed Neovim version.
3. Requires Neovim `>= 0.11.2`.
4. Installs or upgrades Neovim if necessary.
5. Installs the basic build/runtime dependencies used by the configuration.
6. Backs up an existing `~/.config/nvim` directory instead of deleting it.
7. Downloads this repository's `init.lua`.
8. Installs `lazy.nvim` under Neovim's data directory.
9. Leaves the plugin installation to Neovim/lazy.nvim on first launch.

LazyVim currently requires Neovim `>= 0.11.2`; this configuration itself is a custom `lazy.nvim` configuration rather than the official LazyVim starter. The installer therefore does not replace it with the LazyVim starter configuration.

## Paths

On macOS and Linux the configuration is installed at:

```text
~/.config/nvim/init.lua
```

The installer respects `XDG_CONFIG_HOME` when it is set.

`lazy.nvim` is installed at:

```text
~/.local/share/nvim/lazy/lazy.nvim
```

The installer also respects `XDG_DATA_HOME` for the latter.

If an existing configuration is found, it is renamed to something like:

```text
~/.config/nvim.backup-20261004-111530
```

Nothing in the old configuration is deleted.

## Requirements

The installer needs:

- `curl`
- `git`
- a compiler/build toolchain on Linux for native plugins
- Neovim `>= 0.11.2`

On Linux, the installer can install the basic dependencies using:

- `apt`
- `dnf`
- `pacman`
- `zypper`
- `apk`

On macOS, Homebrew is used when available. Otherwise, `git` and `curl` must already be available (Xcode Command Line Tools provides the usual baseline).

Some plugins have additional requirements. For example, the configuration contains a native `telescope-fzf-native.nvim` component that builds with `make`.

## Updating

Re-run the installer:

```sh
curl -fsSL https://raw.githubusercontent.com/asdf-dev/nvim-init/main/install.sh | sh
```

It is safe to run repeatedly. Existing `lazy.nvim` installations are reused, and the current Neovim configuration is backed up before the repository's `init.lua` is installed.

To update plugins after installation, start Neovim and run:

```vim
:Lazy sync
```

## Check the installation

Inside Neovim:

```vim
:checkhealth
```

You can also verify the versions from your shell:

```sh
nvim --version
git --version
```

## Manual installation

If you do not want to run a remote shell script:

```sh
git clone https://github.com/asdf-dev/nvim-init.git
cd nvim-init
./install.sh
```

Or install only the configuration:

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
curl -fsSL \
  https://raw.githubusercontent.com/asdf-dev/nvim-init/main/init.lua \
  -o "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua"
```

The manual configuration-only method assumes Neovim and `lazy.nvim` are already installed.

## Native Windows

The `.sh` installer is intended for macOS, Linux, and WSL.

For native Windows, use WSL if you want the same installation flow. Neovim also provides native Windows packages and documents installation with `winget`.

## Security

`curl | sh` executes the current `main` branch of this repository.

If you want to inspect the installer before executing it:

```sh
curl -fsSL https://raw.githubusercontent.com/asdf-dev/nvim-init/main/install.sh
```

Then run the downloaded file locally.

For a reproducible installation, use a tagged release/commit rather than `main`:

```sh
curl -fsSL https://raw.githubusercontent.com/asdf-dev/nvim-init/<TAG>/install.sh | sh
```

## License

Add the repository's preferred license here.
