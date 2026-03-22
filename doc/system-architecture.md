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
```

**Key Change (v2.0):** The `toZpl()` method now accepts `ZplConfiguration context` as a parameter. Previously, configuration was set via a separate `setConfiguration()` call. This change decouples configuration from command state and makes the command signature explicit.

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

Central class that aggregates commands and produces the final ZPL script. Uses named parameters in v2.0:

```dart
ZplGenerator({
  this.config = const ZplConfiguration(),
  required this.commands,
  this.fonts = const [],
  this.assetService,
})
```

**Workflow:**
1. Wraps output with `^XA` (start) and `^XZ` (end)
2. Uploads custom fonts via `~DY` commands (if provided)
3. Emits configuration (`config.toZpl()`)
4. Generates all command ZPL strings via `command.toZpl(config)`

**Font Upload:**
- If `fonts` list is provided, converts each `ZplFontAsset` to a ZPL `~DY` command
- Uses `assetService` (defaults to new `ZplAssetService()`) to handle font asset loading
- Fonts are uploaded to the printer's E: drive before label printing

### Layout System

Layout commands are containers that automatically position their children using a grid-based system.

#### ZplGridRow (Horizontal Layout)

**File:** `lib/src/zpl_grid_row.dart`

Primary horizontal layout container (replaces `ZplRow` from v1.0):

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
  final ZplFontAsset? customFont;
  final int? maxWidth;               // Set by layout containers
  final bool reversePrint;           // v2.0: white on black
}
```

**v2.0 Changes:**
- `maxWidth` property: allows layout containers to constrain width
- `reversePrint` property: inverts print colors

#### ZplBarcode

```dart
class ZplBarcode extends ZplCommand {
  final int x, y;
  final String data;
  final ZplBarcodeType type;
  final int height;
  final ZplOrientation orientation;
  final bool printInterpretationLine;
  final bool printInterpretationLineAbove;
  final int? moduleWidth;
  final double? wideBarToNarrowBarRatio;
  final ZplAlignment? alignment;
  final int? maxWidth;
}
```

**v2.0 Barcode Types:**
- `code128`, `code39`, `qrCode` (v1.0)
- `dataMatrix` (2D, `^BX` command)
- `ean13` (`^BE` command)
- `upcA` (`^BU` command)

#### ZplBox

```dart
class ZplBox extends ZplCommand {
  final int x, y;
  final int width, height;
  final int lineThickness;
  final int? cornerRadius;
  final bool reversePrint;           // v2.0
}
```

#### ZplImage

Renders raster images as ZPL hex-encoded graphics.

#### ZplSeparator

Horizontal or vertical separator lines with customizable style (box or character-based).

### New Graphics Components (v2.0)

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

**v2.0 Changes:**
- `renderFromGeneratorSimple()` uses `generator.config` directly (config no longer in command list)
- API calls respect config properties for density, page size, etc.

### ZplAssetService

**File:** `lib/src/zpl_asset_service.dart`

Converts Flutter assets to ZPL font upload commands:

```dart
/// Get a complete ~DY font upload command for a ZplFontAsset
Future<String> getFontUploadCommand(ZplFontAsset font)
```

- Loads TTF asset from Flutter asset bundle
- Converts binary font data to hex-encoded ZPL `~DY` command
- Command stores font on printer's E: (flash) drive
- Font can be referenced in `ZplText` via `fontAlias` (A-Z identifier)

## Font System

### ZplFontAsset

**File:** `lib/src/zpl_font_asset.dart`

Value class for custom font configuration:

```dart
class ZplFontAsset {
  /// Single character identifier (A-Z)
  final String id;

  /// Path to TTF asset in pubspec.yaml
  final String assetPath;
}
```

### Workflow

1. Define font asset: `ZplFontAsset(id: 'A', assetPath: 'assets/MyFont.ttf')`
2. Pass to `ZplGenerator`: `ZplGenerator(fonts: [fontAsset], ...)`
3. During build, `ZplAssetService.getFontUploadCommand()` generates `~DY` upload command
4. Use font in text: `ZplText(fontAlias: 'A', ...)`

## Data Flow

```
┌─────────────────────────────────────────┐
│      ZplGenerator.build() called        │
└──────────────┬──────────────────────────┘
               │
               ├─ Emit "^XA" (start)
               │
               ├─ Upload fonts (if provided)
               │  ├─ For each ZplFontAsset
               │  └─ Get ~DY command from ZplAssetService
               │
               ├─ Emit config.toZpl()
               │  └─ Density, darkness, encoding settings
               │
               ├─ Generate commands
               │  ├─ For each ZplCommand
               │  ├─ Call command.toZpl(config)
               │  └─ Handle layout containers (propagate maxWidth to children)
               │
               └─ Emit "^XZ" (end)
                  │
                  └─ Return complete ZPL script
```

## Widget Layer

### ZplPreview

**File:** `lib/widgets/zpl_preview.dart`

Flutter widget for live label preview:

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
- **v2.0 Change:** Implements `didUpdateWidget()` for reactive re-rendering when generator changes
  - Detects when `generator` property changes
  - Automatically triggers re-render with new generator

## Module Organization

```
lib/
├── flutter_zpl_generator.dart       # Barrel export (public API)
├── src/
│   ├── zpl_command_base.dart        # Abstract ZplCommand class
│   ├── zpl_configuration.dart       # Configuration value class
│   ├── zpl_generator.dart           # Main orchestrator
│   ├── enums.dart                   # ZplFont, ZplOrientation, ZplBarcodeType, etc.
│   ├── zpl_font_asset.dart          # Custom font descriptor
│   ├── zpl_asset_service.dart       # Asset-to-ZPL converter
│   ├── labelary_service.dart        # Labelary API integration
│   │
│   ├── zpl_text.dart                # Text rendering
│   ├── zpl_barcode.dart             # Barcode rendering
│   ├── zpl_box.dart                 # Box drawing
│   ├── zpl_image.dart               # Image rendering
│   ├── zpl_separator.dart           # Separator lines
│   ├── zpl_raw.dart                 # Raw ZPL injection (v2.0)
│   │
│   ├── zpl_graphic_circle.dart      # Circle drawing (v2.0)
│   ├── zpl_graphic_ellipse.dart     # Ellipse drawing (v2.0)
│   ├── zpl_graphic_diagonal_line.dart # Diagonal line (v2.0)
│   │
│   ├── zpl_column.dart              # Vertical layout
│   ├── zpl_grid_row.dart            # Horizontal layout (replaces ZplRow)
│   ├── zpl_grid_col.dart            # Grid column definition
│   └── zpl_table.dart               # Advanced table layout
│
└── widgets/
    └── zpl_preview.dart             # Preview widget
```

## ZPL Domain Knowledge

- **Coordinates/Dimensions:** All values in dots (not inches/mm). Common density: 203 DPI (8 dpmm)
- **Label Structure:** `^XA` (start) → config → field commands → `^XZ` (end)
- **Field Commands:** `^FO` (field origin), `^FD` (field data), `^FS` (separator), `^A` (font), `^FB` (field block with alignment)
- **Font Command:** `^A` with font letter or `^A@` with custom font alias
- **Barcode:** `^BC` (Code128), `^B3` (Code39), `^BQ` (QR), `^BX` (DataMatrix), `^BE` (EAN13), `^BU` (UPC-A)

## Version History

**v2.0 (Current)**
- `toZpl()` signature changed to accept `ZplConfiguration context`
- `ZplGenerator` uses named parameters with config decoupling
- `ZplRow` removed; `ZplGridRow` is sole horizontal layout
- `maxWidth` property on leaf commands for layout integration
- `reversePrint` property on `ZplText` and `ZplBox`
- New barcode types: `dataMatrix`, `ean13`, `upcA`
- New graphics: `ZplRaw`, `ZplGraphicCircle`, `ZplGraphicEllipse`, `ZplGraphicDiagonalLine`
- `ZplPreview` implements reactive `didUpdateWidget()`

**v1.0**
- Initial command-based architecture
- Configuration as command in list
- `ZplRow` for horizontal layout
- Basic barcode types (Code128, Code39, QR)
