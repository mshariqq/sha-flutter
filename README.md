# sha-flutter

> **Flutter version manager for Linux** — install, switch, and remove Flutter versions effortlessly.  
> Like `ondrej/php`, but for Flutter.

[![License: MIT](https://img.shields.io/badge/License-MIT-cyan.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux-blue.svg)]()
[![Shell](https://img.shields.io/badge/shell-bash-green.svg)]()

---

## ✨ Why sha-flutter?

Working across multiple Flutter projects often means needing different Flutter versions simultaneously. `sha-flutter` lets you install any Flutter version side-by-side, switch between them instantly with a single command, and remove them cleanly — no manual PATH juggling.

---

## ⚡ Install

```bash
curl -fsSL https://raw.githubusercontent.com/mshariqq/sha-flutter/main/install.sh | bash
```

The installer will:
- Check and install missing dependencies (`curl`, `tar`, `jq`) via `apt`
- Download `sha-flutter` to `/usr/local/bin/`
- Make it executable and ready to use

---

## 🛠 Commands

| Command | What it does |
|---|---|
| `sha-flutter list` | Browse available stable versions |
| `sha-flutter list beta` | Browse beta / dev versions |
| `sha-flutter search 3.22` | Filter versions by prefix |
| `sha-flutter install 3.22.0` | Download & install a version |
| `sha-flutter use 3.19.6` | Switch active version |
| `sha-flutter current` | Show what's active |
| `sha-flutter installed` | List all installed versions |
| `sha-flutter remove 3.19.6` | Delete a specific version |
| `sha-flutter purge` | Remove ALL versions & manager data |
| `sha-flutter self-update` | Update sha-flutter to latest release |
| `sha-flutter version` | Show sha-flutter version |
| `sha-flutter help` | Show help with full command table |

---

## 🚀 Quick Start

```bash
# 1. See what's available
sha-flutter list

# 2. Install a version
sha-flutter install 3.22.0

# 3. Switch versions instantly
sha-flutter use 3.19.6

# 4. Check what's active
sha-flutter current

# 5. Keep the tool itself up to date
sha-flutter self-update
```

---

## ⚙️ How It Works

```
~/.flutter-versions/
  ├── 3.19.6/        ← full Flutter SDK install
  ├── 3.22.0/        ← another version
  └── .releases_cache.json

~/.local/
  ├── flutter  →  symlink to active version dir
  └── bin/
      ├── flutter  →  symlink to active flutter binary
      └── dart     →  symlink to active dart binary
```

- Each Flutter version is stored **fully isolated** in `~/.flutter-versions/<version>/`
- Switching versions just re-points the symlinks — **instant, no re-download**
- Release metadata is fetched from Google's official releases JSON and **cached for 1 hour**

---

## 🔧 Configuration

| Variable | Default | Description |
|---|---|---|
| `FLUTTER_BASE_DIR` | `~/.flutter-versions` | Override where versions are stored |

```bash
# Example: store versions on a different drive
FLUTTER_BASE_DIR=/mnt/data/flutter sha-flutter install 3.22.0
```

---

## 🗑 Uninstall

To remove the `sha-flutter` tool (keeps your Flutter versions intact):

```bash
curl -fsSL https://raw.githubusercontent.com/mshariqq/sha-flutter/main/uninstall.sh | bash
```

To also delete all Flutter versions:

```bash
rm -rf ~/.flutter-versions
```

---

## 📋 Requirements

- **OS**: Linux (tested on Linux Mint, Ubuntu, Debian)
- **Shell**: Bash 4+
- **Tools**: `curl`, `tar`, `jq` (installer handles these automatically)

---

## 🤝 Contributing

Issues and PRs are welcome!

1. Fork the repo
2. Create a branch: `git checkout -b feature/my-feature`
3. Commit your changes
4. Push and open a Pull Request

---

## 📄 License

[MIT](LICENSE) © Muhammed Shariq Ahmed

---

## 👤 Author

**Muhammed Shariq Ahmed**  
📧 [shariqq.com@gmail.com](mailto:shariqq.com@gmail.com)  
🌐 [mshariqq.github.io/mshariqq](https://mshariqq.github.io/mshariqq/)

If `sha-flutter` saved you time, consider ⭐ **starring the repo** — it helps others find it!
