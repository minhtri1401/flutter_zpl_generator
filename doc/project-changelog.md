# Project Changelog

All notable changes to the `flutter_zpl_generator` package are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v1.1.0.0.html).

## [1.1.0] - 2026-03-22

### Breaking Changes

#### API Signature Changes
- **`ZplCommand.toZpl()` method signature updated**
  - Old: `String toZpl()`
  - New: `String toZpl(ZplConfiguration context)`
  - Impact: All command implementations and callers must be updated
  - Reason: Explicit configuration passing eliminates implicit state and makes requirements clear

#### Constructor Changes
- **`ZplGenerator` now uses named parameters**
  - Old: `ZplGenerator(config, commands, fonts, assetService)`
  - New: `ZplGenerator({config:, required commands:, fonts:, assetService:})`
  - Impact: Code using positional arguments will break
  - Migration: Add parameter names to constructor calls

#### Configuration Decoupling
- **`ZplConfiguration` is no longer a `ZplCommand`**
  - Old: Configuration included in command list
  - New: Configuration passed via `config` property to `ZplGenerator`
  - Impact: Existing code that treats config as command will fail
  - Migration: Move config from command list to `ZplGenerator` constructor

#### Layout System Changes
- **`ZplRow` component removed**
  - Old: `ZplRow(children: [...])`
  - New: Use `ZplGridRow(columnWidths: [...], children: [...])`
  - Impact: Horizontal layouts must migrate to grid-based approach
  - Reason: More flexible and powerful layout control

- **`_PositionWrapper` internal class removed**
  - Impact: Internal refactoring; no public API affected
  - Reason: Replaced by `maxWidth` property mechanism

### Added

#### New Graphics Components
- **`ZplRaw`** - Direct ZPL command injection
  - Allows using unsupported ZPL features directly
  - Example: `ZplRaw(zplCode: '^GC50,50,10')`

- **`ZplGraphicCircle`** - Circle drawing
  - Properties: `x`, `y`, `diameter`, `lineThickness`, `filled`
  - Generates `^GC` command

- **`ZplGraphicEllipse`** - Ellipse drawing
  - Properties: `x`, `y`, `width`, `height`, `lineThickness`, `filled`
  - Generates `^GE` command

- **`ZplGraphicDiagonalLine`** - Diagonal line drawing
  - Properties: `x1`, `y1`, `x2`, `y2`, `lineThickness`
  - Generates `^GD` command

#### Extended Barcode Support
- **New barcode types in `ZplBarcodeType` enum:**
  - `dataMatrix` - 2D Data Matrix barcode (`^BX` command)
    - Supports up to 1500+ characters
    - Common use: medical, automotive industries
  - `ean13` - European Article Number 13-digit barcode (`^BE` command)
    - Fixed 13-digit format
    - Common use: retail product labeling
  - `upcA` - Universal Product Code Type A barcode (`^BU` command)
    - Fixed 12-digit format
    - Common use: North American retail

#### Layout System Enhancements
- **`maxWidth` property on leaf commands**
  - Added to: `ZplText`, `ZplBarcode`, `ZplImage`
  - Purpose: Allows layout containers to constrain child width
  - Benefit: Enables responsive alignment and text wrapping in grid layouts

#### Text Rendering Enhancements
- **`reversePrint` property on `ZplText`**
  - Boolean flag for inverted colors (white on black)
  - Generates `^FR` command when true
  - Example: Labels, warnings, important notices

- **`reversePrint` property on `ZplBox`**
  - Boolean flag for inverted box colors
  - Generates `^FR` command when true
  - Example: Highlighted regions on labels

#### Widget Improvements
- **`ZplPreview` now reactive to generator changes**
  - Implemented `didUpdateWidget()` lifecycle method
  - Automatically re-renders when `generator` property changes
  - Benefit: Live updates in responsive UIs

### Changed

#### Configuration Context Passing
- Configuration now passed as explicit context parameter
- All `toZpl()` implementations receive `ZplConfiguration context`
- Improves code clarity and reduces hidden state

#### Layout Container Behavior
- Layout containers now propagate `maxWidth` to children
- Enables width-aware alignment and responsive layouts
- Improves usability of nested layouts

#### Code Organization
- File names updated to kebab-case for consistency
- Better module organization for maintainability
- Improved documentation throughout

### Fixed

#### Layout Calculation Issues
- Fixed width calculation in nested layouts
- Corrected alignment calculations when using `maxWidth`
- Improved spacing consistency in grid rows

#### Barcode Rendering
- Improved width estimation for variable-length barcodes
- Fixed module width calculations for barcode types
- Better handling of interpretation line spacing

#### Font Asset Handling
- Improved error messages when font assets fail to load
- Better validation of font asset paths
- Cleaner font upload command generation

### Deprecated

- None (first stable release with this architecture)

### Security

- No new security issues identified
- Maintained input validation for external APIs
- Continued prevention of sensitive data logging

### Performance

- Reduced memory overhead by decoupling configuration
- Improved ZPL string generation efficiency
- Optimized layout container calculations

### Documentation

- Complete rewrite of architecture documentation
- Added code standards and patterns guide
- Updated all code examples to v1.1.0 API
- Created comprehensive migration guide

### Known Issues

- None at release

### Internal

- Refactored command base class for context-aware generation
- Improved test coverage for graphics components
- Added comprehensive integration tests for layout system
- Updated mock files via `build_runner`

## [1.0.0] - 2025-09-20

### Added

#### Core Features
- **Command-based architecture** with abstract `ZplCommand` base class
- **Configuration as command** in the command list
- **Layout system** with `ZplRow`, `ZplColumn`, `ZplTable` containers
- **Text rendering** with font support (built-in and custom)
- **Barcode support** - Code 128, Code 39, QR Code
- **Box drawing** with configurable line thickness
- **Separator lines** - horizontal and vertical
- **Image rendering** with ZPL graphic conversion
- **Custom TTF font support** via `ZplFontAsset`

#### Services
- **Labelary API integration** (`LabelaryService`)
  - `renderZpl()` - render raw ZPL strings
  - `renderZplFile()` - render from file multipart upload
  - `convertImageToGraphic()` - convert images to ZPL graphics
  - `convertFontToZpl()` - convert TTF fonts to ZPL format

- **Asset service** (`ZplAssetService`)
  - Load Flutter assets
  - Convert fonts to ZPL upload commands
  - Support for font storage on printer's E: drive

#### Widgets
- **`ZplPreview` Flutter widget**
  - Live label rendering via Labelary API
  - Loading and error state handling
  - Image display of rendered labels

#### Configuration
- **`ZplConfiguration` command** with properties:
  - Print dimensions (width, height)
  - Print density (203 DPI default)
  - Darkness level
  - Character encoding
  - Custom preamble commands

#### Testing
- Comprehensive unit test suite
- Mock HTTP client for API testing
- Test helpers for ZPL normalization
- 85%+ code coverage

### Documentation
- Complete README with usage examples
- CLAUDE.md with architecture overview
- Inline code documentation
- Example application

### Publishing
- Published to pub.dev
- Ready for production use
- Semantic versioning adopted

## Upgrade Guide

### From v1.0.0 to v1.1.0

#### Step 1: Update Command Signatures
All `toZpl()` calls must now include configuration context:

```dart
// v1.0.0
final zpl = text.toZpl();

// v1.1.0
final zpl = text.toZpl(config);
```

#### Step 2: Move Configuration
Configuration moves from command list to generator:

```dart
// v1.0.0
final generator = ZplGenerator(
  [
    ZplConfiguration(...),
    ZplText(text: 'Label'),
  ],
);

// v1.1.0
final generator = ZplGenerator(
  config: ZplConfiguration(...),
  commands: [
    ZplText(text: 'Label'),
  ],
);
```

#### Step 3: Replace ZplRow
Horizontal layouts now use `ZplGridRow`:

```dart
// v1.0.0
final row = ZplRow(children: [
  ZplText(text: 'Col1'),
  ZplText(text: 'Col2'),
]);

// v1.1.0
final row = ZplGridRow(
  columnWidths: [200, 300],
  children: [
    ZplText(text: 'Col1'),
    ZplText(text: 'Col2'),
  ],
);
```

#### Step 4: Update Tests
Test assertions must account for new ZPL format:

```dart
// v1.0.0
test('renders text', () {
  final zpl = ZplText(text: 'Hello').toZpl();
  expect(zpl, contains('^FDHello^FS'));
});

// v1.1.0
test('renders text', () {
  final config = const ZplConfiguration();
  final zpl = ZplText(text: 'Hello').toZpl(config);
  expect(zpl, contains('^FDHello^FS'));
});
```

#### Step 5: Update ZplGenerator Calls
Use named parameters:

```dart
// v1.0.0 (positional)
final generator = ZplGenerator(config, [text, barcode]);

// v1.1.0 (named)
final generator = ZplGenerator(
  config: config,
  commands: [text, barcode],
);
```

#### Complete Migration Checklist
- [ ] Update all `toZpl()` method calls to pass `ZplConfiguration context`
- [ ] Move `ZplConfiguration` from command list to `config` property
- [ ] Replace all `ZplRow` with `ZplGridRow`
- [ ] Update `ZplGenerator` constructor calls to use named parameters
- [ ] Verify test assertions match new ZPL format
- [ ] Test on all target platforms
- [ ] Review layout behavior with new `maxWidth` constraints

## Future Roadmap

See [development-roadmap.md](./development-roadmap.md) for planned features and timeline.

## Version Numbering

- **Major**: Breaking API changes, significant refactors
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, documentation updates

## Support & Feedback

- Report issues on GitHub
- Submit feature requests with use cases
- Share feedback and improvements
- Contribute via pull requests
