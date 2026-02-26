# Version Management Guide

## Overview

The Kiro Memory System uses **Semantic Versioning (SemVer)** and maintains a detailed changelog.

---

## Version Format

**MAJOR.MINOR.PATCH** (e.g., 1.3.0)

- **MAJOR**: Breaking changes, major architecture changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, minor improvements

---

## Files

### Tracked in Git (Committed)

**CHANGELOG.md**
- Complete version history
- All notable changes
- Release dates
- Follows [Keep a Changelog](https://keepachangelog.com/) format

### Local Only (Gitignored)

**.kiro/VERSION**
```
1.3.0
```
- Current version number
- Single source of truth
- Not committed (stays local)

**.kiro/.version-local**
```json
{
  "version": "1.3.0",
  "installed_date": "2026-02-26T01:40:33Z",
  "last_updated": "2026-02-26T01:40:33Z",
  "custom_modifications": false
}
```
- Local installation metadata
- Tracks when installed/updated
- Flags custom modifications
- Not committed (stays local)

---

## Commands

### Check Version

```bash
./.kiro/memory.sh version
```

**Output:**
```
Kiro Memory System
Version: 1.3.0

Local Installation:
  Installed: 2026-02-26T01:40:33Z
  Last Updated: 2026-02-26T01:40:33Z
  Custom Modifications: false

See CHANGELOG.md for version history and changes.
```

### View Changelog

```bash
cat docs/CHANGELOG.md
```

Or view online: [CHANGELOG.md](./CHANGELOG.md)

---

## For Maintainers: Releasing a New Version

### 1. Update CHANGELOG.md

Add new version section:

```markdown
## [1.4.0] - 2026-03-01

### Added
- New feature description

### Changed
- What changed

### Fixed
- Bug fixes
```

### 2. Update VERSION file

```bash
echo "1.4.0" > .kiro/VERSION
```

### 3. Update .version-local

```bash
cat > .kiro/.version-local << EOF
{
  "version": "1.4.0",
  "installed_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "custom_modifications": false
}
EOF
```

### 4. Commit and Tag

```bash
git add docs/CHANGELOG.md
git commit -m "chore: release v1.4.0"
git tag -a v1.4.0 -m "Release v1.4.0"
git push origin main --tags
```

**Note:** VERSION and .version-local are gitignored and won't be committed.

---

## For Users: Checking Your Version

After pulling updates:

```bash
# Check your current version
./.kiro/memory.sh version

# See what's new
cat docs/CHANGELOG.md
```

Your local VERSION and .version-local files stay unchanged (gitignored).

---

## Version History

- **v1.3.0** (2026-02-26): Config-based memory files + protection from repo updates
- **v1.2.0** (2026-02-26): Verbose mode + auto-increment duplicate IDs
- **v1.1.0** (2026-02-26): List/edit/remove commands + improved search
- **v1.0.0** (2026-02-24): Memory keyword quality improvements
- **v0.1.0** (2026-02-16): Initial release

See [CHANGELOG.md](./CHANGELOG.md) for complete details.

---

## FAQ

**Q: Why are VERSION and .version-local gitignored?**

A: They track your local installation state. When you pull updates, your local version info stays intact. The docs/CHANGELOG.md (committed) tells you what's new.

**Q: How do I know what version I have?**

A: Run `./.kiro/memory.sh version`

**Q: How do I see what changed between versions?**

A: Read docs/CHANGELOG.md - it lists all changes for each version.

**Q: Can I modify the system?**

A: Yes! If you make custom modifications, update `.version-local`:
```json
{
  "custom_modifications": true
}
```

This helps you remember you've customized it.
