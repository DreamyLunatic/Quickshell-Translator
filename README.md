## What's in
- Language supported: English, Russian
- Offline mode
- Quickshell interface
- Clipboard paste since start
- Language detection

## Keybinds
- Tab: change direction
- Esc: exit
- Enter: translate
- Shift+enter: new line

## TODO
- Menu
- Multi-language support
- Copy button for translated text

## Requirements

- [Quickshell](https://quickshell.org/)
- `trans` from translate-shell (online translation):

```bash
  sudo pacman -S translate-shell
```

- Argos Translate (offline fallback, optional, see below)

## Offline translation (optional)

The translator uses `trans` when online and falls back to
[Argos Translate](https://github.com/argosopentech/argos-translate) when offline.
Argos always runs on the CPU: translating short phrases is fast enough there,
and it avoids waking up a discrete GPU on laptops.

### 1. Install Argos Translate

```bash
# Arch Linux
sudo pacman -S python-pipx
# Debian/Ubuntu
sudo apt install pipx

pipx ensurepath        # adds ~/.local/bin to PATH, restart your shell afterwards
pipx install argostranslate
```

Then replace the default PyTorch build with the CPU-only one.
By default pipx installs PyTorch with CUDA support, which adds several GB
of NVIDIA libraries. This translator never uses the GPU, so the CPU build
(~200 MB) is all it needs:

```bash
pipx runpip argostranslate install torch --index-url https://download.pytorch.org/whl/cpu --force-reinstall
```

### 2. Install language packages

```bash
argospm update
argospm install translate-en_ru
argospm install translate-ru_en
```

Check what is installed with `argospm list`.

### 3. Configure paths

**Shebang in `argos-daemon`.** The first line of `argos-daemon` must point to
the Python interpreter inside the Argos pipx environment. Find the correct path with:

```bash
head -1 "$(command -v argospm)"
```

Copy that line (for example `#!/home/<user>/.local/share/pipx/venvs/argostranslate/bin/python`)
as the first line of `argos-daemon`, then make the file executable:

```bash
chmod +x argos-daemon
```

**Path in `shell.qml`.** The `command` of the `argos` Process must contain
the absolute path to `argos-daemon`:

```qml
command: ["/home/<user>/path/to/wayland_translator/argos-daemon"]
```

Relative paths like `./argos-daemon` do not work when Quickshell is started
from Hyprland, because the working directory is not the project folder.

### 4. First run must be online

On the first translation Argos downloads a small sentence-splitting model
and caches it. Run one test translation while connected:

```bash
printf 'en\tru\tSome shit\n' | ./argos-daemon
```

## Usage

The translator is designed to **run in the background all the time** and only
show or hide its window when you need it. It is not started anew on every
keypress: this way the offline translation models are loaded into memory once,
and every translation after that is instant.

### 1. Start the translator automatically

Add it to your compositor's autostart. For Hyprland, in `hyprland.conf`:

```ini
exec-once = qs -c translator
```

If you already have an `exec-once` line, you can append it there with `&`.

### 2. Bind a key to show/hide it

```ini
bind = $mainMod, T, exec, qs ipc -c translator call translator toggle
```

When the window opens, the translator reads the current clipboard contents
and translates them immediately. Copy any text, press the shortcut,
and the translation is already there. Press the shortcut again to hide the window.

The translation direction is detected automatically: text containing Cyrillic
is translated into English, everything else into Russian.

### Other compositors

Any compositor works, as long as it can run a command at startup and on a keypress.
Start `qs -c translator` once at login and bind
`qs ipc -c translator call translator toggle` to a key of your choice.fter that, offline translation works without network access.
