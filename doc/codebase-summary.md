# Codebase Summary

A comprehensive overview of the `flutter_zpl_generator` package structure, modules, and key components.

## Project Statistics

- **Language**: Dart/Flutter
- **Package**: flutter_zpl_generator
- **Version**: 2.1.0 (Compression & Barcode Expansion, September 2026)
- **License**: MIT
- **Main Files**: 40+ Dart modules + GitHub Actions workflows
- **Test Coverage**: > 90% (125+ unit tests)
- **Documentation**: Inline comments + external guides + comprehensive doc/ files

## Directory Structure

```
flutter_zpl_generator/
├── lib/
│   ├── flutter_zpl_generator.dart     # Barrel export (public API)
│   ├── src/                           # Internal implementation
│   │   ├── zpl_command_base.dart      # Abstract command base class
│   │   ├── zpl_configuration.dart     # Configuration value class
│   │   ├── zpl_generator.dart         # Main orchestrator
│   │   ├── enums.dart                 # All enum definitions
│   │   ├── zpl_font_upload.dart       # Font upload control (~DY)
│   │   ├── zpl_asset_service.dart     # Asset loader helper
│   │   ├── labelary_service.dart      # API integration
│   │   │
│   │   ├── zpl_text.dart              # Text rendering
│   │   ├── zpl_text_block.dart        # Text block rendering (^TB)
│   │   ├── zpl_barcode.dart           # Barcode rendering (13 types)
│   │   ├── zpl_barcode_enums.dart     # Barcode type & param enums
│   │   ├── zpl_barcode_symbology_emitter.dart # Barcode ZPL generation
│   │   ├── zpl_barcode_width_estimator.dart   # Barcode width calculation
│   │   ├── zpl_box.dart               # Box drawing
│   │   ├── zpl_image_enums.dart       # Image compression & dithering enums
│   │   ├── zpl_graphic_compression_encoder.dart # Z64/B64 compression
│   │   ├── zpl_image_download.dart    # Image download (~DG)
│   │   ├── zpl_image_recall.dart      # Image recall (^XG)
│   │   ├── zpl_image_inline.dart      # Inline image (^GFA)
│   │   ├── zpl_separator.dart         # Separator lines
│   │   ├── zpl_raw.dart               # Raw ZPL injection
│   │   ├── zpl_template.dart          # Templating and data binding
│   │   │
│   │   ├── zpl_graphic_circle.dart    # Circle drawing
│   │   ├── zpl_graphic_ellipse.dart   # Ellipse drawing
│   │   ├── zpl_graphic_diagonal_line.dart # Diagonal lines
│   │   ├── zpl_graphic_symbol.dart    # Native Hardware Symbols
│   │   │
│   │   ├── zpl_column.dart            # Vertical layout
│   │   ├── zpl_grid_row.dart          # Horizontal layout
│   │   ├── zpl_grid_col.dart          # Grid column definition
│   │   ├── zpl_table.dart             # Table layout
│   │   ├── zpl_conditional.dart       # Conditional layout wrapper
│   │   │
│   │   ├── zpl_rfid_setup.dart        # RFID configuration
│   │   ├── zpl_rfid_write.dart        # RFID encoding
│   │   ├── zpl_network.dart           # Network constraints
│   │   ├── zpl_hardware.dart          # ZBI & Hardware transparency
│   │   ├── zpl_print_quantity.dart    # Batch print quantity (^PQ)
│   │   └── zpl_serial_config.dart     # Auto-serialization (^SN)
│   │
│   └── preview/
│       ├── zpl_native_preview.dart       # Offline Flutter Widget preview
│       ├── zpl_canvas_painter.dart       # Core rendering canvas logic
│       └── zpl_barcode_preview_mapping.dart # Barcode preview params mapping
│
└── widgets/
    └── zpl_preview.dart                # Legacy Labelary preview widget
│
├── test/
│   └── flutter_zpl_generator_test.dart # Comprehensive test suite
│
├── example/
│   └── lib/main.dart                  # Example application
│
├── fonts/
│   └── archivo-narrow-variable.ttf         # Condensed bold face (SIL OFL 1.1) for native preview
│
├── pubspec.yaml                       # Package metadata & dependencies
├── pubspec.lock                       # Locked dependency versions
├── CHANGELOG.md                       # Version history
├── README.md                          # User guide
├── CLAUDE.md                          # Development guidance
├── .pubignore                         # Pub publishing exclusions (plans, ZPL manual PDFs, dev files; fonts/ ships)
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                     # Format, analyze, test, publish dry-run
│   │   └── security-scan.yml          # OSV, gitleaks, SARIF, Dependabot
│   └── dependabot.yml                 # Automated dependency updates
└── doc/                               # Documentation
    ├── system-architecture.md         # Architecture overview
    ├── code-standards.md              # Implementation patterns
    ├── development-roadmap.md         # Feature roadmap
    ├── project-changelog.md           # Detailed change history
    ├── project-overview-pdr.md        # PDR & requirements
    ├── codebase-summary.md            # This file
    └── ...                            # Other guides
```

## Core Modules

### 1. zpl_command_base.dart
**Purpose**: Abstract base class for all ZPL commands

```dart
abstract class ZplCommand {
  String toZpl(ZplConfiguration context);
  int calculateWidth(ZplConfiguration config);
}
```

**Key Points**:
- All ZPL elements must extend this class
- `toZpl()` receives configuration as context parameter
- `calculateWidth()` returns width in dots for layout calculations

### 2. zpl_configuration.dart
**Purpose**: Label-level configuration (decoupled from commands in v1.1.0)

**Properties**:
- `printWidth`, `printHeight` — Label dimensions in dots
- `density` — Print resolution (203-600 DPI)
- `darkness` — Contrast level (0-30)
- `encoding` — Character encoding
- `preamble` — Optional ZPL prefix commands

**Key Points**:
- Immutable value class
- Passed as context to all commands
- Not a command itself (v1.1.0 change)

### 3. zpl_generator.dart
**Purpose**: Main orchestrator that aggregates commands and generates ZPL script

**Constructor** (v2.0.0+):
```dart
ZplGenerator({
  ZplConfiguration config = const ZplConfiguration(),
  required List<ZplCommand> commands,
  bool autoLabelLengthFromFirstImage = false,
})
```

**Key Methods**:
- `build()` — Async method using two-pass approach

**Two-Pass Workflow** (Link-OS compatible):
1. **Phase 1:** Emit all `ZplControlCommand` instances (fonts, images, network configs) BEFORE `^XA`
2. **Phase 2:** Emit `^XA` → config → regular commands → `^XZ`

This ordering is required on Link-OS mobile printers (ZQ620, etc.)

### 4. enums.dart
**Purpose**: Central location for all enumeration types

**Enumerations**:
- `ZplAlignment` — left, center, right
- `ZplPrintDensity` — 101-600 DPI options
- `ZplFont` — Built-in fonts (A-H, 0)
- `ZplOrientation` — normal, rotated90, inverted180, readFromBottomUp270
- `ZplBarcodeType` — code128, code39, qrCode, dataMatrix, ean13, upcA
- `ZplPrintMode` — tearOff, peelOff, rewind, applicator, cutter
- `ZplMediaType` — thermalTransfer, directThermal
- `ZplPrintOrientation` — normal, inverted
- `ZplStorage` — dram, flash
- `ZplSeparatorType` — box, character
- `LabelaryPrintDensity` — API-specific densities
- `LabelaryOutputFormat` — png, pdf, zpl, etc.
- `LabelaryRotation` — 0, 90, 180, 270 degrees
- `LabelaryPageSize` — Letter, Legal, A4, A5, A6
- `LabelaryPageOrientation` — Portrait, Landscape
- `LabelaryPageAlign` — Left, Right, Center, Justify
- `LabelaryLabelBorder` — Dashed, Solid, None
- `LabelaryPrintQuality` — Grayscale, Bitonal

### 5. zpl_text.dart
**Purpose**: Text rendering with fonts and alignment

**Key Properties**:
- `x`, `y` — Position in dots
- `text` — Content to print
- `font` — Built-in font selection
- `fontAlias` — Reference to uploaded custom font (A-Z)
- `fontHeight`, `fontWidth` — Font sizing
- `orientation` — Text rotation
- `alignment` — Horizontal alignment (left, center, right)
- `maxLines`, `lineSpacing` — Multi-line support
- `customFont` — `ZplFontUpload` instance (v2.0.0+)
- `maxWidth` — Width constraint from layout container
- `reversePrint` — White on black

**Key Methods**:
- `toZpl(ZplConfiguration context)` — Generates `^FO`, `^A`, `^FB`, `^FD`, `^FS` commands
- `calculateWidth()` — Estimates text width in dots

### 6. zpl_barcode.dart & Related Modules
**Purpose**: Barcode rendering (13 symbologies via v2.1.0)

**Supported Types** (v2.1.0):
- 1D: `code128`, `code39`, `code93`, `interleaved2of5`, `ean8`, `ean13`, `upcA`, `upcE`, `gs1_128`
- 2D: `qrCode` (with error correction & magnification), `dataMatrix`, `aztec`, `pdf417` (with security level & column params)

**Key Properties**:
- `x`, `y` — Position; `data` — Barcode content; `type` — Symbology
- `height` — Module/row height in dots (ignored by QR/Aztec)
- `moduleWidth` — Bar width (1D only)
- `wideBarToNarrowBarRatio` — Wide-to-narrow ratio (v2.0.0+, 1D only)
- `printInterpretationLine`, `printInterpretationLineAbove` — HRI text
- `alignment` — Horizontal alignment; `maxWidth` — Layout constraint
- **QR Parameters (v2.1.0):** `magnification` (1–10), `qrErrorCorrection` (low/medium/quartile/high)
- **PDF417 Parameters (v2.1.0):** `pdf417SecurityLevel` (0–5), `pdf417Columns` (1–30)

**Related Files**:
- `zpl_barcode_enums.dart` — `ZplBarcodeType`, `ZplQrErrorCorrection`, etc.
- `zpl_barcode_symbology_emitter.dart` (~150 LOC) — ZPL generation for each symbology
- `zpl_barcode_width_estimator.dart` (~80 LOC) — Width calculation per symbology

**Key Methods**:
- `toZpl(ZplConfiguration context)` — Delegates to symbology emitter; generates `^B*` commands
- `calculateWidth()` — Width in dots (via estimator)
- `width` getter — Calculated barcode width

### 7. zpl_box.dart
**Purpose**: Rectangular box and line drawing

**Key Properties**:
- `x`, `y` — Top-left position
- `width`, `height` — Box dimensions
- `lineThickness` — Border width
- `cornerRadius` — Optional rounded corners
- `reversePrint` — Inverted colors (v1.1.0)

**Key Methods**:
- `toZpl(ZplConfiguration context)` — Generates `^GB` command
- `calculateWidth()` — Returns box width

### 8. zpl_separator.dart
**Purpose**: Horizontal and vertical separator lines

**Key Properties**:
- `x`, `y` — Position
- `length` — Line length
- `direction` — Horizontal or vertical
- `type` — Box (line) or character (repeated chars)
- `thickness` — Line width

**Key Methods**:
- `toZpl(ZplConfiguration context)` — Generates `^GB` or character repetition
- `calculateWidth()` — Returns separator width

### 10. Graphics Components

#### zpl_raw.dart
Direct ZPL injection for unsupported features.

```dart
class ZplRaw extends ZplCommand {
  final String zplCode;
}
```

#### zpl_graphic_circle.dart
Circle drawing using `^GC` command.

#### zpl_graphic_ellipse.dart
Ellipse drawing using `^GE` command.

#### zpl_graphic_diagonal_line.dart
Diagonal line drawing using `^GD` command.

#### zpl_graphic_symbol.dart
Standard registered trademark (®), copyright (©), UL, CSA, and VDE symbols (`^GS`).

### 11. Enterprise Hardware Features (v1.2.0 - v1.5.0)

#### zpl_rfid_write.dart
Supports simultaneous print-and-encode UHF RFID tags using `^RF`.

#### zpl_network.dart
Configure primary IP, subnet, gateway (`^ND`, `^NS`), and SNMP (`^NN`).

#### zpl_print_quantity.dart
Native print counts, pauses, and overrides (`^PQ`).

#### zpl_template.dart
Zero-overhead synchronous bulk label generator utilizing `{{variables}}` injected natively before runtime.

### 11. Layout Containers

#### zpl_column.dart
**Purpose**: Vertical layout container

**Key Properties**:
- `children` — List of commands
- `spacing` — Vertical gap between children

**Behavior**:
- Stacks children vertically
- Distributes available width equally

#### zpl_grid_row.dart (Replaces v1.0.0 ZplRow)
**Purpose**: Horizontal layout container

**Key Properties**:
- `columnWidths` — Optional width definitions
- `children` — List of commands
- `spacing` — Horizontal gap

**Behavior**:
- Arranges children horizontally
- Sets `maxWidth` on children for width-aware layout
- Supports proportional and fixed column widths

#### zpl_grid_col.dart
**Purpose**: Grid column definition helper

#### zpl_table.dart
**Purpose**: Advanced table layout combining rows and columns

**Key Properties**:
- `rows`, `columns` — Grid structure
- `children` — Cell content
- `spacing` — Inter-cell spacing
- `borders` — Border styling

### 12. Image Commands (v2.0.0+, v2.1.0 compression)

Three strategies for different use cases:

#### zpl_image_download.dart
`ZplImageDownload` extends `ZplControlCommand`, emits `~DG` to cache image before format opens.
**v2.1.0**: Supports `ZplImageCompression` modes (none, acs, b64, z64).

#### zpl_image_recall.dart
`ZplImageRecall` extends `ZplCommand`, emits `^XG` to recall cached image at position (x, y).

#### zpl_image_inline.dart
`ZplImageInline` extends `ZplCommand`, emits `^GFA` inline inside format.
**v2.1.0**: `compression:` parameter (default `acs`); supports none, acs, b64, z64 modes.

#### zpl_image_enums.dart (v2.1.0)
Enumerations for image processing:
- `ZplImageCompression` — none (raw hex), acs (70–90% smaller), b64 (33% overhead), z64 (70–90% reduction)
- `ZplDitheringAlgorithm` — threshold, floydSteinberg (default), atkinson

#### zpl_graphic_compression_encoder.dart (v2.1.0)
Pure-Dart Z64/B64 encoder using `package:archive` for zlib deflate (works on web):
- `crc16Xmodem()` — CRC-16 per Zebra spec (polynomial 0x1021, no XOR)
- `packHexRows()` — Monochrome bitmap packing
- Z64 body generation (`:Z64:<base64>:<crc>`) with ~70–90% reduction
- B64 body generation (`:B64:<base64>:<crc>`) with ~33% reduction

### 13. Font System (v2.0.0+)

#### zpl_font_upload.dart
**Purpose**: Control command for TTF font upload via `~DY`

```dart
class ZplFontUpload extends ZplControlCommand {
  final String identifier;      // A-Z
  final Uint8List fontBytes;

  static Future<ZplFontUpload> fromAsset(String assetPath, String id)
}
```

**Usage**:
```dart
final font = await ZplFontUpload.fromAsset('assets/Roboto.ttf', 'R');
final gen = ZplGenerator(commands: [font, ZplText(..., customFont: font)]);
```

#### zpl_asset_service.dart
**Purpose**: Helper for loading binary assets from Flutter bundle

**Key Methods**:
- `loadFontBytes(String assetPath)` — Load TTF asset (used by `ZplFontUpload.fromAsset()`)
- `validateAssetPath(String assetPath)` — Check asset exists

#### labelary_service.dart
**Purpose**: Labelary API integration for rendering and conversion

**Static Methods**:
- `renderZpl(String zpl)` — Render ZPL string to image
- `renderZplFile(File file)` — Render from file (multipart)
- `convertImageToGraphic(File imageFile)` — Image to ZPL graphic
- `convertFontToZpl(File fontFile, String fontId)` — Font to ZPL format
- `renderFromGeneratorSimple(ZplGenerator)` — Convenience method

**Error Handling**:
- Returns `LabelaryResponse` with data and warnings
- Handles API errors and timeouts
- Provides meaningful error messages

## Preview Layer

### Native Preview (v1.5.0+, v2.1.0: Labelary-Calibrated)

#### zpl_native_preview.dart
Offline Flutter widget rendering without network. Delegates to modular painters.

#### zpl_canvas_painter.dart (v2.1.0: Delegation)
High-performance rendering dispatcher:
- Delegates barcode rendering to `zpl_barcode_painter.dart`
- Delegates text rendering to `zpl_text_painter.dart`
- Manages image dithering (Floyd-Steinberg, Atkinson)
- Anti-aliasing edge-bleeding fixes (v1.5.1)

#### zpl_barcode_painter.dart (v2.1.0)
Barcode rendering with calibrated metrics:
- Uses `zpl_barcode_symbol_metrics.dart` for dimension calcs
- Uses `zpl_code128_zebra_encoder.dart` for Code 128 subset reproduction
- 1D: Real module count × `^BY` width, interpretation line below (formula: 7·mw+6 dots)
- QR: Numeric/alphanumeric/byte mode selection, ECC upgrade rule, 10-dot vertical offset
- Data Matrix: Scales by `^BX` module height
- Barcode-Labelary overlap: 90–95% (measured against Labelary renders)

#### zpl_text_painter.dart (v2.1.0)
Text rendering with bundled font:
- Archivo Narrow (SIL OFL 1.1) from `fonts/` directory
- Cap height = 75% of `^A` height (Labelary measured)
- Width defaults to height for font 0
- `^FB` alignment mirrors `ZplGenerator`
- Bounding boxes within 2–3 dots of Labelary

#### zpl_barcode_symbol_metrics.dart (v2.1.0)
Symbology-specific dimension calculations:
- Module count encoding per symbology
- Width/height estimation for all 13 types
- Interpretation line height formula
- QR version sizing with ECC mode selection

#### zpl_code128_zebra_encoder.dart (v2.1.0)
Zebra Code 128 subset switching replication:
- Reproduces automatic switch between Code Set A/B/C
- Matches firmware behavior for optimal density
- Used by `zpl_barcode_painter.dart` for preview accuracy

#### zpl_barcode_preview_mapping.dart (v2.1.0)
Maps `ZplBarcode` properties to barcode library parameters:
- Symbology → barcode type mapping
- Width/height → module/row sizing
- QR error correction & magnification
- PDF417 security level & columns
- Passes all parameters to barcode library

#### Fidelity Regression Harness (v2.1.0)
**File:** `test/native_preview_fidelity_harness_test.dart`
- Renders same label via Labelary API and native preview
- Compares bitmaps pixel-by-pixel
- Outputs diffs to `FIDELITY_OUT` directory for visual inspection
- Run: `fvm flutter test test/native_preview_fidelity_harness_test.dart --dart-define=SKIP_INTEGRATION_TESTS=false --dart-define FIDELITY_OUT=/path/to/diffs`
- Gates: Barcode overlap >90%, text bounding box <3 dots drift, image dither matching

### Legacy Preview

### zpl_preview.dart
**Purpose**: Flutter widget for live label preview via Labelary API

```dart
class ZplPreview extends StatefulWidget {
  final ZplGenerator generator;
  const ZplPreview({required this.generator});
}
```

**Features**:
- Renders label via Labelary API
- Displays loading indicator
- Shows error messages
- **v1.1.0**: Implements `didUpdateWidget()` for reactive re-rendering
  - Detects generator property changes
  - Automatically triggers re-render

## Barrel Export

### flutter_zpl_generator.dart
Central entry point exporting public API:

```dart
// Core classes
export 'src/zpl_command_base.dart';
export 'src/zpl_configuration.dart';
export 'src/zpl_generator.dart';

// Enums
export 'src/enums.dart';

// Commands
export 'src/zpl_text.dart';
export 'src/zpl_barcode.dart';
export 'src/zpl_box.dart';
export 'src/zpl_image.dart';
export 'src/zpl_separator.dart';
export 'src/zpl_raw.dart';

// Graphics
export 'src/zpl_graphic_circle.dart';
export 'src/zpl_graphic_ellipse.dart';
export 'src/zpl_graphic_diagonal_line.dart';

// Layout
export 'src/zpl_column.dart';
export 'src/zpl_grid_row.dart';
export 'src/zpl_grid_col.dart';
export 'src/zpl_table.dart';

// Services
export 'src/zpl_asset_service.dart';
export 'src/zpl_font_asset.dart';
export 'src/labelary_service.dart';

// Widgets
export 'widgets/zpl_preview.dart';
```

## Key Architectural Patterns

### 1. Command Pattern
All ZPL elements are commands that extend `ZplCommand`, enabling:
- Polymorphic rendering
- Easy extensibility
- Type-safe collections

### 2. Configuration Context
v1.1.0 passes configuration as context parameter:
- Eliminates implicit state
- Makes requirements explicit
- Enables testability

### 3. Layout System
Containers manage child positioning and constraints:
- `ZplGridRow` distributes width
- `maxWidth` enables responsive layouts
- Children receive positioning information

### 4. Service Layer
External operations abstracted:
- `LabelaryService` — API calls
- `ZplAssetService` — Asset processing
- Testable via mocks

### 5. Widget Integration
`ZplPreview` bridges generated ZPL with UI:
- Reactive to generator changes
- Handles async rendering
- State management

## Code Organization Principles

### Immutability
- All command properties are `final`
- Configuration is value class
- No mutable state in commands

### Composition Over Inheritance
- Containers compose children
- Commands don't inherit behavior
- Services encapsulate logic

### Separation of Concerns
- Commands handle ZPL generation
- Services handle external operations
- Widgets handle UI rendering

### Clear Naming
- Kebab-case file names (e.g., `zpl_text.dart`)
- PascalCase class names (e.g., `ZplText`)
- camelCase methods (e.g., `calculateWidth()`)

## Dependencies

### Direct Dependencies
- `flutter` — Framework
- `http` — HTTP client for API
- `image` — Image processing
- `barcode` — Barcode generation (all 13 symbologies)
- `archive` — Pure-Dart zlib deflate for Z64 compression (v2.1.0)

### Bundled Assets
- `fonts/archivo-narrow-variable.ttf` (v2.1.0) — Condensed bold face (SIL OFL 1.1 license) used by `ZplTextPainter` in native preview for accurate text rendering

### Transitive Dependencies
- `dart:async` — Futures, streams
- `dart:convert` — JSON, encoding
- `dart:typed_data` — Binary data
- `flutter/material.dart` — Material design

## Testing Infrastructure

### Test Framework
- `flutter_test` — Widget testing
- `test` — Unit testing
- `mockito` — Mocking HTTP client

### Test Coverage Areas
- Command ZPL generation
- Configuration handling
- Layout calculations
- Widget rendering
- Service integration

### Test Helpers
- `normalizeZpl()` — Compare ZPL output (removes whitespace)
- Mock HTTP client for API testing
- Example generators for widget testing

## Performance Characteristics

| Operation | Time | Notes |
|---|---|---|
| ZPL generation | < 100ms | For typical labels |
| API rendering | < 2s | Labelary API response |
| Widget rendering | < 500ms | On device |
| Text width calc | < 1ms | Per character |
| Layout calculation | < 10ms | Per layout container |

## Security Considerations

1. **Input Validation**: All external inputs validated
2. **Asset Path Validation**: Font paths verified before loading
3. **No Sensitive Logging**: API keys and content not logged
4. **HTTPS Only**: Labelary API via HTTPS
5. **Immutable Commands**: No state mutation attacks

## Extension Points

Developers can extend the package by:

1. **Custom Commands**: Extend `ZplCommand` with new `toZpl()` implementation
2. **Custom Services**: Add new service classes for additional features
3. **Custom Widgets**: Create widgets that wrap `ZplPreview` or use generator directly
4. **Custom Layouts**: Implement new container types extending `ZplCommand`

## Documentation Resources

- **System Architecture** — Component design details
- **Code Standards** — Implementation patterns and guidelines
- **Development Roadmap** — Planned features
- **Project Changelog** — Version history and breaking changes
- **Project Overview/PDR** — Requirements and specifications

## Maintenance Notes

- **Compatibility**: Dart 2.17+, Flutter 3.0+
- **Platforms**: iOS, Android, Web, Desktop
- **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Release Cycle**: Monthly minor releases, annual major releases
- **Support**: GitHub Issues, Discussions on pub.dev
