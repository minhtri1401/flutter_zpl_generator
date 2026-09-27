# System Architecture

## Overview

`flutter_zpl_generator` is a Dart/Flutter package that generates ZPL (Zebra Programming Language) scripts for thermal label printing. The library uses a command-based architecture where all label elements extend a common `ZplCommand` base class and are collected by `ZplGenerator` to produce the final ZPL script.

## Core Architecture Pattern: Command Pattern

### ZplCommand Base Class

All ZPL elements implement the abstract `ZplCommand` base class (`lib/src/zpl_command_base.dart`):

```dart
abstract class ZplCommand {
  const ZplCommand();

  /// Converts the command to its ZPL representation.
  /// The [context] provides label configuration (dimensions, density, etc.).
  String toZpl(ZplConfiguration context);

  /// Calculates the approximate width of this command in dots.
  int calculateWidth(ZplConfiguration config);
}

/// Subclass for tilde-prefixed control commands (~DG, ~DY, ~JI, ~JQ, ~HQ, ~NC, ~NR, ~NT).
/// These are processed immediately by the printer's comms processor and MUST emit
/// BEFORE the ^XA that opens the active format (Zebra best practice; required on Link-OS).
abstract class ZplControlCommand extends ZplCommand {
  const ZplControlCommand();

  @override
  int calculateWidth(ZplConfiguration config) => 0; // Control commands have no layout footprint
}
```

**Architecture (v2.0.0+):** `ZplGenerator.build()` uses a two-pass approach:
- **Pass 1:** Emit all `ZplControlCommand` instances before `^XA`
- **Pass 2:** Emit `^XA`, config, regular commands, `^XZ`

### ZplConfiguration

`ZplConfiguration` is a standalone value class (not a `ZplCommand`) that holds label-level settings:

```dart
class ZplConfiguration {
  /// Label width in dots (default: 812 for 4" at 203 DPI)
  final int? printWidth;

  /// Label height in dots (default: 1218 for 6" at 203 DPI)
  final int? printHeight;

  /// Print density (resolution)
  final ZplPrintDensity density;

  /// Darkness level (0-30)
  final int darkness;

  /// Character set encoding
  final String encoding;

  /// Additional ZPL commands to execute before printing
  final String? preamble;
}
```

Configuration flows to commands during generation via the `build()` method's `context` parameter.

## Key Components

### ZplGenerator (Orchestrator)

**File:** `lib/src/zpl_generator.dart`

Central class that aggregates commands and produces the final ZPL script (v2.0.0+). Uses named parameters:

```dart
ZplGenerator({
  ZplConfiguration config = const ZplConfiguration(),
  required List<ZplCommand> commands,
  bool autoLabelLengthFromFirstImage = false,
})
```

**Two-Pass Build Workflow:**
1. **Phase 1 (Pre-format):** Emit all `ZplControlCommand` subclasses BEFORE `^XA`
   - `ZplFontUpload` (~DY font uploads)
   - `ZplImageDownload` (~DG graphic downloads)
   - Network/hardware commands (~JI, ~JQ, ~HQ, ~NC, ~NR, ~NT)
2. **Phase 2 (Format block):** Emit `^XA` → config → regular commands → `^XZ`

This two-pass approach is required on Link-OS firmware (e.g., ZQ620) where tilde commands inside an active format cause job failure.

### Layout System

Layout commands are containers that automatically position their children using a grid-based system.

#### ZplGridRow (Horizontal Layout)

**File:** `lib/src/zpl_grid_row.dart`

Primary horizontal layout container (replaces `ZplRow` from v1.0.0):

```dart
class ZplGridRow extends ZplCommand {
  /// Column definitions with optional widths (in dots or percentage)
  final List<int?> columnWidths;

  /// Child commands to arrange horizontally
  final List<ZplCommand> children;

  /// Spacing between columns (in dots)
  final int spacing;
}
```

**Behavior:**
- Distributes available width among children based on `columnWidths`
- Sets `maxWidth` on leaf commands to enable width-aware alignment
- Handles child configuration internally

#### ZplColumn (Vertical Layout)

**File:** `lib/src/zpl_column.dart`

Vertical layout container:

```dart
class ZplColumn extends ZplCommand {
  /// Child commands to arrange vertically
  final List<ZplCommand> children;

  /// Spacing between rows (in dots)
  final int spacing;
}
```

#### ZplGridCol & ZplTable

- **ZplGridCol:** Defines a column in a grid layout
- **ZplTable:** Advanced layout combining row/column structures with configurable borders and spacing

### Leaf Commands (Label Elements)

Individual elements that render as single ZPL field commands:

#### ZplText

```dart
class ZplText extends ZplCommand {
  final int x, y;
  final String text;
  final ZplFont? font;
  final String? fontAlias;           // A-Z alias for custom fonts
  final int? fontHeight;
  final int? fontWidth;
  final ZplOrientation orientation;
  final ZplAlignment? alignment;
  final int paddingLeft, paddingRight;
  final int maxLines;
  final int lineSpacing;
  final ZplFontUpload? customFont;   // v2.0: await ZplFontUpload.fromAsset(...)
  final int? maxWidth;               // Set by layout containers
  final bool reversePrint;           // white on black
}
```

**Custom Font Usage (v2.0.0+):**
```dart
final roboto = await ZplFontUpload.fromAsset('assets/fonts/Roboto.ttf', 'R');
final gen = ZplGenerator(commands: [
  roboto,  // Emitted in Phase 1 before ^XA
  ZplText(text: 'Hello', customFont: roboto, fontAlias: 'R'),
]);
```

#### ZplBarcode (v2.1.0: 13 Symbologies)

```dart
class ZplBarcode extends ZplCommand {
  final int x, y;
  final String data;
  final ZplBarcodeType type;
  final int height;                    // Module/row height in dots (QR/Aztec ignore)
  final ZplOrientation orientation;
  final bool printInterpretationLine;
  final bool printInterpretationLineAbove;
  final int? moduleWidth;              // Bar width (1D only)
  final double? wideBarToNarrowBarRatio; // Ratio (v2.0+)
  final ZplAlignment? alignment;
  final int? maxWidth;
  
  // v2.1.0: QR Code parameters
  final int? magnification;            // 1–10 (also for Aztec)
  final ZplQrErrorCorrection? qrErrorCorrection; // low/medium/quartile/high
  
  // v2.1.0: PDF417 parameters
  final int? pdf417SecurityLevel;      // 0–5
  final int? pdf417Columns;            // 1–30
}
```

**v2.1.0 Supported Symbologies (13 total):**
- **1D (9):** `code128`, `code39`, `code93`, `interleaved2of5`, `ean8`, `ean13`, `upcA`, `upcE`, `gs1_128` (Code 128 with FNC1)
- **2D (4):** `qrCode` (with error correction & magnification), `dataMatrix`, `aztec` (with magnification), `pdf417` (with security level & columns)

**Implementation Details (v2.1.0+):**
- Main logic split into separate modules (<200 LOC each):
  - `zpl_barcode_symbology_emitter.dart` — Symbol-specific ZPL generation
  - `zpl_barcode_width_estimator.dart` — Symbol-specific width calculation
  - `zpl_barcode_enums.dart` — `ZplBarcodeType`, `ZplQrErrorCorrection` enums
- `ZplBarcode.toZpl()` delegates to symbology emitter
- `ZplNativePreview` uses `zpl_barcode_preview_mapping.dart` for barcode library parameters

#### ZplBox

```dart
class ZplBox extends ZplCommand {
  final int x, y;
  final int width, height;
  final int lineThickness;
  final int? cornerRadius;
  final bool reversePrint;           // v1.1.0
}
```

#### Image Commands (v2.0.0+, v2.1.0: Z64/B64 Compression)

Three image strategies to match use cases:

**ZplImageDownload** (extends `ZplControlCommand`)
- Emits `~DG` command to download/cache image on printer before format opens
- Pair with `ZplImageRecall` to position and render cached image
- Best for multi-print or archival scenarios
- **v2.1.0:** `compression: ZplImageCompression` parameter (default `acs`)

**ZplImageRecall** (extends `ZplCommand`)
- Emits `^XG` to recall previously-downloaded image at position (x, y)
- Must pair with `ZplImageDownload` (same `graphicName`)
- Reduces label script size when printing same image multiple times

**ZplImageInline** (extends `ZplCommand`)
- Emits `^GFA` directly inside format
- No separate `~DG` download step
- Best for one-shot images; bitmap travels inside the format
- **v2.1.0:** `compression: ZplImageCompression` parameter (default `acs`)

**v2.1.0 Compression Modes (ZplImageCompression enum):**
- `none` — Raw ASCII hex (100% overhead, maximum compatibility)
- `acs` — ACS run-length encoding (70–90% reduction, universal support)
- `b64` — Base64 + CRC-16 (33% overhead, requires modern firmware)
- `z64` — Zlib-deflated base64 + CRC-16 (70–90% reduction, requires modern firmware)

**Compression Implementation (v2.1.0):**
- Module: `zpl_graphic_compression_encoder.dart` (pure-Dart)
- Uses `package:archive` for zlib deflate (works on web, no `dart:io` needed)
- `crc16Xmodem()` — CRC-16 per Zebra spec (polynomial 0x1021, no final XOR)
- Auto-selects compression based on `ZplImageCompression` enum; emits `:B64:` or `:Z64:` bodies

#### Image Enums (v2.1.0)

**zpl_image_enums.dart** provides:
- `ZplImageCompression` — none, acs, b64, z64
- `ZplDitheringAlgorithm` — threshold, floydSteinberg (default), atkinson

#### ZplSeparator

Horizontal or vertical separator lines with customizable style (box or character-based).

### New Graphics Components (v1.1.0)

#### ZplRaw

```dart
class ZplRaw extends ZplCommand {
  /// Raw ZPL command string to inject directly
  final String zplCode;
}
```

Allows direct ZPL injection for unsupported features.

#### ZplGraphicCircle

```dart
class ZplGraphicCircle extends ZplCommand {
  final int x, y;
  final int diameter;
  final int lineThickness;
  final bool filled;
}
```

Renders circles using `^GC` command.

#### ZplGraphicEllipse

```dart
class ZplGraphicEllipse extends ZplCommand {
  final int x, y;
  final int width, height;
  final int lineThickness;
  final bool filled;
}
```

Renders ellipses using `^GE` command.

#### ZplGraphicDiagonalLine

```dart
class ZplGraphicDiagonalLine extends ZplCommand {
  final int x1, y1, x2, y2;
  final int lineThickness;
}
```

Renders diagonal lines using `^GD` command.

## Service Layer

### LabelaryService

**File:** `lib/src/labelary_service.dart`

Static methods for Labelary API integration (REST API for ZPL rendering):

```dart
// Render raw ZPL string
static Future<LabelaryResponse> renderZpl(String zpl)

// Render from multipart file
static Future<LabelaryResponse> renderZplFile(File file)

// Convert image to ZPL graphic
static Future<String> convertImageToGraphic(File imageFile)

// Convert TTF font to ZPL format
static Future<String> convertFontToZpl(File fontFile, String fontId)

// Convenience method: render directly from ZplGenerator
static Future<Uint8List> renderFromGeneratorSimple(ZplGenerator generator)
```

**v1.1.0 Changes:**
- `renderFromGeneratorSimple()` uses `generator.config` directly (config no longer in command list)
- API calls respect config properties for density, page size, etc.

### ZplAssetService

**File:** `lib/src/zpl_asset_service.dart`

Helper for loading binary assets (primarily fonts) from Flutter's asset bundle:

```dart
Future<Uint8List> loadFontBytes(String assetPath)
```

In v2.0.0, the `~DY` emission moved to `ZplFontUpload.toZpl()`. This service now provides low-level asset reading only, consumed by `ZplFontUpload.fromAsset()`.

## Font System (v2.0.0+)

### ZplFontUpload

**File:** `lib/src/zpl_font_upload.dart`

Control command that uploads a TrueType font via `~DY` before the format opens:

```dart
class ZplFontUpload extends ZplControlCommand {
  final String identifier;  // A-Z
  final Uint8List fontBytes;

  /// Factory: load from Flutter asset
  static Future<ZplFontUpload> fromAsset(String assetPath, String identifier) async
}
```

### Workflow (v2.0.0+)

```dart
final roboto = await ZplFontUpload.fromAsset('assets/Roboto.ttf', 'R');
final gen = ZplGenerator(
  commands: [
    roboto,  // Emitted Phase 1 before ^XA
    ZplText(text: 'Hello', customFont: roboto, fontAlias: 'R'),
  ],
);
```

Font is uploaded to printer's E: drive before label prints; can be referenced via `fontAlias` identifier.

## Data Flow (v2.0.0+)

```
┌───────────────────────────────────────────┐
│   ZplGenerator.build() (async) called     │
└─────────────┬─────────────────────────────┘
              │
        ┌─────┴─────────────┐
        │                   │
    PHASE 1              PHASE 2
    (Pre-format)         (Format block)
        │                   │
        ├─ For each         ├─ Emit "^XA" (start)
        │   ZplControlCommand│
        │   (ZplFontUpload,  ├─ Emit config.toZpl()
        │    ZplImageDownload)│  └─ Density, darkness
        │   emit to buffer   │
        │                    ├─ For each non-control command
        │                    │  ├─ Call toZpl(config)
        │                    │  └─ Handle layout propagation
        │                    │
        │                    └─ Emit "^XZ" (end)
        │
        └─→ Concatenate: PHASE1 + ^XA + PHASE2 data + ^XZ
            Return complete ZPL script
```

Key: Control commands (tilde-prefixed) **must** emit before `^XA` on Link-OS.

## Widget Layer

### ZplPreview (Legacy Labelary)

**File:** `lib/widgets/zpl_preview.dart`

Flutter widget for live label preview via Labelary API:

```dart
class ZplPreview extends StatefulWidget {
  final ZplGenerator generator;
  const ZplPreview({required this.generator});
}
```

**Behavior:**
- Renders label via `LabelaryService.renderFromGeneratorSimple()`
- Displays loading state while rendering
- Shows error message if rendering fails
- **v1.1.0:** Implements `didUpdateWidget()` for reactive re-rendering

### ZplNativePreview (Offline Canvas, v1.5.0+)

**Files:**
- `lib/src/preview/zpl_native_preview.dart` — Main widget
- `lib/src/preview/zpl_canvas_painter.dart` — Canvas rendering delegation (v2.1.0: now delegates to painters)
- `lib/src/preview/zpl_barcode_painter.dart` — Barcode rendering with calibrated module metrics (v2.1.0)
- `lib/src/preview/zpl_text_painter.dart` — Text rendering with Archivo Narrow font (v2.1.0)
- `lib/src/preview/zpl_barcode_symbol_metrics.dart` — Symbol-specific dimension calculations (v2.1.0)
- `lib/src/preview/zpl_code128_zebra_encoder.dart` — Zebra Code 128 subset replication (v2.1.0)
- `lib/src/preview/zpl_barcode_preview_mapping.dart` — Barcode params mapping (v2.1.0)

**Features:**
- Offline rendering (no network required)
- High-performance Flutter canvas with anti-aliasing
- All 13 barcode symbologies (native barcode library)
- Image dithering (Floyd-Steinberg, Atkinson algorithms)
- QR code error correction & magnification support
- Module-width distortion correction for barcode parity with firmware

**v2.1.0 Calibration & Fidelity:**
- 1D barcodes measured against Labelary: encode real module count, apply `^BY` width, position interpretation line below (7·mw+6, not carved from bars). Code 128 reproduces Zebra's automatic subset switching; Code 39/I2of5 apply `^BY` ratio (default 3:1). Barcode overlap with Labelary: 90–95% (was 29–34%).
- QR Code uses numeric/alphanumeric/byte mode selection, printer's "strongest ECC that fits" rule, 10-dot vertical offset from origin. Data Matrix scales by `^BX` module height (100%).
- Text drawn with bundled Archivo Narrow (SIL OFL 1.1) in `fonts/` dir, cap height 75% of `^A` height, width defaults to height for font 0, `^FB` alignment mirrors generator. Bounding boxes within 2–3 dots of Labelary.
- Regression tool: `test/native_preview_fidelity_harness_test.dart` renders both Labelary and native, compares bitmaps; run with `FIDELITY_OUT=path --dart-define=SKIP_INTEGRATION_TESTS=false`.

**Calibration Constants (v2.1.0):**
All numeric constants in preview modules cite Labelary measurements:
- `capHeightRatio = 0.75` — Text cap height is 75% of `^A` font height (measured on Labelary)
- `interpretationLineFormula = 7 * moduleWidth + 6` — 1D barcode HRI below bars, 7 dots per module + 6 baseline (Labelary spec)
- `qrVerticalOffset = 10` — QR position offset from Y origin in dots (ZQ620 firmware measurement)
- `code39Ratio = 3.0` — Default wide/narrow bar ratio (ZPL spec)
- `eccUpgradeThreshold` — When QR data requires upgrade from lower to higher ECC level (ISO/IEC 18004)

## Module Organization

```
lib/
├── flutter_zpl_generator.dart       # Barrel export (public API)
├── src/
│   ├── zpl_command_base.dart        # Abstract ZplCommand & ZplControlCommand
│   ├── zpl_configuration.dart       # Configuration value class
│   ├── zpl_generator.dart           # Main orchestrator (two-pass build)
│   ├── enums.dart                   # ZplFont, ZplOrientation, ZplBarcodeType, etc.
│   ├── zpl_font_upload.dart         # Font upload control command (~DY)
│   ├── zpl_asset_service.dart       # Asset loader helper
│   ├── labelary_service.dart        # Labelary API integration
│   │
│   ├── zpl_text.dart                # Text rendering
│   ├── zpl_text_block.dart          # Text block (^TB)
│   ├── zpl_barcode.dart             # Barcode rendering (13 types, v2.1.0)
│   ├── zpl_barcode_enums.dart       # Barcode type & parameter enums (v2.1.0)
│   ├── zpl_barcode_symbology_emitter.dart # Barcode ZPL generation (v2.1.0)
│   ├── zpl_barcode_width_estimator.dart   # Barcode width calculation (v2.1.0)
│   ├── zpl_box.dart                 # Box drawing
│   ├── zpl_image_download.dart      # Image download control (~DG, v2.1.0: Z64/B64)
│   ├── zpl_image_recall.dart        # Image recall (^XG)
│   ├── zpl_image_inline.dart        # Inline image (^GFA, v2.1.0: Z64/B64)
│   ├── zpl_image_enums.dart         # Image compression & dithering enums (v2.1.0)
│   ├── zpl_graphic_compression_encoder.dart # Z64/B64 compression (v2.1.0)
│   ├── zpl_separator.dart           # Separator lines
│   ├── zpl_raw.dart                 # Raw ZPL injection
│   │
│   ├── zpl_graphic_circle.dart      # Circle drawing (^GC)
│   ├── zpl_graphic_ellipse.dart     # Ellipse drawing (^GE)
│   ├── zpl_graphic_diagonal_line.dart # Diagonal line (^GD)
│   ├── zpl_graphic_symbol.dart      # Hardware symbols (®, ©, UL, CSA, VDE)
│   │
│   ├── zpl_column.dart              # Vertical layout
│   ├── zpl_grid_row.dart            # Horizontal layout
│   ├── zpl_grid_col.dart            # Grid column definition
│   ├── zpl_table.dart               # Advanced table layout
│   ├── zpl_conditional.dart         # Conditional layout wrapper
│   │
│   ├── zpl_rfid_setup.dart          # RFID setup (^RS)
│   ├── zpl_rfid_write.dart          # RFID write (^RF)
│   ├── zpl_network.dart             # Network configuration commands
│   ├── zpl_hardware.dart            # ZBI & transparency commands
│   ├── zpl_print_quantity.dart      # Batch quantity (^PQ)
│   ├── zpl_serial_config.dart       # Auto-serialization (^SN)
│   ├── zpl_template.dart            # Templating engine
│   ├── zpl_advanced_text_properties.dart # Advanced text (^PA)
│   │
│   └── preview/
│       ├── zpl_native_preview.dart  # Offline Flutter preview widget
│       ├── zpl_canvas_painter.dart  # Canvas rendering logic
│       └── zpl_barcode_preview_mapping.dart # Barcode preview params (v2.1.0)
│
├── widgets/
│   └── zpl_preview.dart             # Legacy Labelary preview widget
│
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                   # Format, analyze, test, publish (v2.1.0)
│   │   └── security-scan.yml        # OSV, gitleaks, Dependabot (v2.1.0)
│   └── dependabot.yml               # Automated updates (v2.1.0)
│
└── doc/
    └── ... (documentation files)
```

## ZPL Domain Knowledge

- **Coordinates/Dimensions:** All values in dots (not inches/mm). Common density: 203 DPI (8 dpmm)
- **Label Structure:** `^XA` (start) → config → field commands → `^XZ` (end)
- **Field Commands:** `^FO` (field origin), `^FD` (field data), `^FS` (separator), `^A` (font), `^FB` (field block with alignment)
- **Font Command:** `^A` with font letter or `^A@` with custom font alias
- **Barcode Commands (v2.1.0):**
  - 1D: `^BC` (Code128), `^B3` (Code39), `^BA` (Code93), `^B2` (I2of5), `^B8` (EAN8), `^BE` (EAN13), `^BU` (UPC-A), `^B9` (UPC-E), `^BC` mode D (GS1-128)
  - 2D: `^BQ` (QR), `^BX` (DataMatrix), `^BO` (Aztec), `^B7` (PDF417)
- **Image Commands:**
  - `~DG` / `~DX` — Download/cache image (~300 dots max per header; split large images)
  - `^GFA` — Inline ACS-encoded image (v1.3.0+)
  - `^GF` / `^GH` — Z64/B64 compressed graphics (v2.1.0+)
- **Tilde (Control) Commands:** Must emit BEFORE `^XA` on Link-OS firmware:
  - `~DY` (font upload), `~DG` (image download), `~JI`/`~JQ`/`~HQ` (ZBI), `~NC`/`~NR`/`~NT` (network)

## Version History

**v2.1.0 (2026-09-27 - Compression & Barcode Expansion)**
- **Z64/B64 Image Compression:** `ZplImageCompression` enum (none, acs, b64, z64); 70–90% reduction via pure-Dart `package:archive`
- **13 Barcode Symbologies:** 9 linear (Code93, I2of5, EAN8, UPC-E, GS1-128) + 2D (Aztec, PDF417) added; split logic into emitter/estimator/enums modules
- **QR/PDF417 Parameters:** `magnification` (1–10), `qrErrorCorrection`, `pdf417SecurityLevel`, `pdf417Columns`
- **CI/Security:** GitHub Actions `ci.yml` (format, analyze, test, publish dry-run) + `security-scan.yml` (OSV, gitleaks, SARIF); Dependabot
- **Testing:** 125+ unit tests (>90% coverage); all barcode symbologies, compression encoder, preview widgets tested
- **Stability:** Flutter 3.47.5 pinned; tilde-command ordering fixes; `.pubignore` reduces package from 15MB to <1MB

**v2.0.0 (2026-04-20 - Link-OS Compatible)**
- Two-pass `build()`: control commands Phase 1 (before `^XA`), format block Phase 2
- `ZplControlCommand` base class for tilde-prefixed commands (~DG, ~DY, etc.)
- `ZplFontUpload` (control command) replaces `ZplFontAsset`; uses `await fromAsset()`
- `ZplImageDownload` (~DG), `ZplImageRecall` (^XG), `ZplImageInline` (^GFA) replace monolithic `ZplImage`
- `ZplGenerator` constructor simplified: `{config, required commands, autoLabelLengthFromFirstImage}`
- Removed: `fonts`, `assetService` parameters (now added as commands directly)

**v1.1.0**
- `toZpl()` accepts `ZplConfiguration context` parameter
- `ZplRow` removed; `ZplGridRow` sole horizontal layout
- `maxWidth` property on leaf commands
- `reversePrint` property on `ZplText` and `ZplBox`
- New barcode types: `dataMatrix`, `ean13`, `upcA`
- New graphics: `ZplRaw`, `ZplGraphicCircle`, `ZplGraphicEllipse`, `ZplGraphicDiagonalLine`

**v1.0.0**
- Initial command-based architecture
