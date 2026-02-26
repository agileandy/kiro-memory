# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2026-02-26

### Added
- **Probability Threshold System**: Memory creation now uses probability-based threshold (default: 20%)
  - Add `KIRO_MEMORY_THRESHOLD` environment variable to control sensitivity
  - Structured probability checklist with 6 categories (0-100% scores)
  - `future_usefulness` field added to all insights for filtering and pruning
  - Documentation: `docs/probability-threshold.md`
  
- **Enhanced Stop Hook**: More assertive memory capture prompts
  - Shows probability checklist at end of each turn
  - Displays current threshold setting
  - Requires explicit acknowledgment (created N memories or none)
  - Includes keyword quality reminder
  
- **Verbose Memory Check**: Transparency into memory decisions
  - Shows `💭 Memory check: [reason]` at end of every response (when verbose=true)
  - Includes probability scores when memories are created
  - Helps users understand what is/isn't being remembered
  - Updated documentation: `docs/verbose-mode.md`

### Changed
- Backfilled all existing insights with `future_usefulness` scores based on category
- Enhanced agent prompt with structured memory evaluation process
- Improved memory-capture.sh hook to be more directive
- Renamed all documentation files to lowercase (kebab-case)

### Testing
- Added `test-probability-threshold.sh` - validates threshold system
- Added `test-enhanced-stop-hook.sh` - validates hook improvements  
- Added `test-verbose-memory-check.sh` - validates verbose mode enhancements

## [1.3.0] - 2026-02-26

### Added
- Config-based memory file selection via `.kiro/settings/config.json`
- Protection from repo updates: user's `insights.json` is now gitignored
- `import-samples` command to copy sample insights to user's memory file
- Sample insights file (`sample-insights.json`) tracked in git for reference
- Comprehensive setup guide (SETUP-GUIDE.md)
- Protection implementation documentation (PROTECTION-IMPLEMENTATION.md)

### Changed
- Renamed `insights.json` to `sample-insights.json` (tracked in git)
- User's memory file (`insights.json`) is now gitignored and never overwritten on pull
- Memory file location is now configurable in `.kiro/settings/config.json`
- `memory.sh` now reads memory file location from config
- `init` command now mentions sample insights and import command
- `help` command now shows current memory file location

### Fixed
- User insights are now protected from being overwritten when pulling repo updates

## [1.2.0] - 2026-02-26

### Added
- Verbose mode controlled by `KIRO_MEMORY_VERBOSE` environment variable (default: true)
- Memory creation summary showing ID, category, summary, and tags when verbose=true
- Auto-increment for duplicate IDs (appends -2, -3, etc. instead of rejecting)
- Notification when ID is adjusted to avoid duplicates
- Documentation for verbose mode (VERBOSE-MODE.md)

### Changed
- Duplicate IDs now auto-increment with counter suffix instead of being rejected
- `add` command now shows detailed summary when verbose mode is enabled
- Silent mode available by setting `KIRO_MEMORY_VERBOSE=false`

### Fixed
- No insights are lost due to duplicate IDs - all are saved with auto-incremented IDs

## [1.1.0] - 2026-02-26

### Added
- `list [category]` command for compact view of insights (ID + summary only)
- `remove <id>` command to delete insights with confirmation prompt
- `edit <id>` command to interactively modify existing insights
- Improved `search` command now searches summary, content, AND tags (not just summary)
- Duplicate ID validation in `add` command (later changed to auto-increment in v1.2.0)
- Comprehensive improvements documentation (IMPROVEMENTS.md)

### Changed
- `search` command now uses jq filtering to search across all fields
- `help` command updated with new commands
- Better error messages and user feedback

### Fixed
- Search now finds insights by content and tags, not just summary

## [1.0.0] - 2026-02-24

### Added
- Memory keyword quality improvements and retrievability enhancements
- Enhanced memory capture hook with keyword guidance
- Critical warnings about grep-based search requirements
- Detailed instructions for writing searchable memories
- Examples of good vs bad memory formatting

### Changed
- Memory capture prompt now emphasizes keyword quality
- Agent instructions updated with retrievability testing guidance
- Improved documentation on tag usage and search term inclusion

## [0.1.0] - 2026-02-16

### Added
- Initial release of Kiro Memory System
- Core memory management CLI (`memory.sh`)
- Commands: `init`, `status`, `show`, `search`, `add`, `test`, `clear`
- Memory categories: conventions, architecture, patterns, decisions, gotchas
- Memory capture hook for automatic insight creation
- Default agent configuration with memory system integration
- Comprehensive README with installation and usage instructions
- Sample insights for testing and learning
- Memory test script for validating retrievability
- Support for jq 1.5 and 1.6 compatibility

### Documentation
- README.md with complete setup and usage guide
- why-memory.md explaining the problem and solution
- agents.md with agent instructions
- Installation instructions for jq and ripgrep
- Troubleshooting section

---

## Version History Summary

- **v1.3.0** (2026-02-26): Config-based memory files + protection from repo updates
- **v1.2.0** (2026-02-26): Verbose mode + auto-increment duplicate IDs
- **v1.1.0** (2026-02-26): List/edit/remove commands + improved search
- **v1.0.0** (2026-02-24): Memory keyword quality improvements
- **v0.1.0** (2026-02-16): Initial release
