# Changelog

All notable changes to the Azurite project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-01-20

### Changed

- Upgraded to Crystal 1.19.1 (minimum Crystal version 1.19.0)
- Upgraded `crystal-sqlite3` dependency from ~> 0.22.0 to ~> 0.23.0
- Updated development dependencies including ameba to 1.7.0-dev
- Updated flake.nix to use pkgs.crystal (Crystal 1.19.1) instead of crystal_1_18

### Fixed

- Fixed race conditions and deadlock in Store auto-cleanup fiber
- Fixed integer division in `cleanup_old_entries` retention day calculations
- Fixed non-idiomatic code patterns and magic numbers throughout
- Fixed `get_content` mutex bug that could cause concurrent access issues
- Fixed critical code quality issues identified in review
- Fixed multiple bugs in Store lifecycle and error handling
- Added path traversal protection in spec cleanup helper
- Added thread safety improvements for concurrent database access

### Added

- `StoreInterface` abstract module for dependency injection and testing
- Builder validation for all configuration values (minimum value checks)
- `cleanup_low_quality_content` method for filtering short/trivial content
- `Config` struct shared between Builder and Store for consistent configuration
- Standardized logging via `Log.for("azurite")` with contextual error messages
- SQLite WAL mode and performance pragmas on initialization
- Auto-cleanup interval configuration via Builder
- Content truncation with proper UTF-8 boundary handling
- Documentation updates and code examples in README

### Refactored

- Extracted constants to dedicated `constants.cr` module
- Consolidated `content_type` defaults across all entry points
- Used Crystal's `DB::ResultSet.new` mapping pattern for ArticleContent
- Added `TABLE_NAME` and `ARTICLE_CONTENT_COLUMNS` constants to eliminate SQL duplication
- Standardized error context messages in synchronized database operations

## [0.1.0] - 2025-01-01

### Added

- Initial release
- SQLite-based content storage for RSS/Atom feed articles
- Builder pattern for store configuration
- CRUD operations: `store`, `get_content`, `get_article`, `articles_for_feed`
- Retention-based cleanup with `cleanup_old_entries`
- Database size monitoring with `db_size_mb` and `enforce_size_limits`
- JSON serialization for ArticleContent model
- Content type support (html, text)
- Comprehensive test suite with 38 specs
