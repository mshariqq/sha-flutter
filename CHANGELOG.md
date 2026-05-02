# Changelog

All notable changes to sha-flutter will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] — 2025-05-02

### Added
- `sha-flutter list [channel]` — browse stable / beta / dev versions
- `sha-flutter search <prefix>` — filter versions by prefix
- `sha-flutter install <version>` — download & install a specific Flutter version
- `sha-flutter use <version>` — switch active Flutter version via symlink
- `sha-flutter current` — show active version
- `sha-flutter installed` — list all locally installed versions
- `sha-flutter remove <version>` — delete a specific installed version
- `sha-flutter purge` — remove all versions and manager data
- `sha-flutter self-update` — update the tool itself from GitHub
- `sha-flutter version` — show tool version
- `sha-flutter help` — full help with ASCII banner and command table
- One-line installer via `install.sh`
- Uninstaller via `uninstall.sh`
- GitHub Actions release workflow
- Release cache (1 hour TTL) to avoid repeated network calls
