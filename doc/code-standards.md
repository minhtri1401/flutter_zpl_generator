# Code Standards

## File Organization

### Naming Conventions

- **File Names:** Use kebab-case with descriptive names (e.g., `zpl-command-base.dart`, `labelary-service.dart`)
  - This enables LLM tools to understand file purpose immediately
- **Class Names:** Use PascalCase (e.g., `ZplText`, `ZplGenerator`)
- **Method/Function Names:** Use camelCase (e.g., `toZpl()`, `calculateWidth()`)
- **Constants:** Use camelCase (e.g., `defaultWidth = 812`)
- **Enum Values:** Use camelCase (e.g., `code128`, `printFromBottomUp270`)

### File Size Management

- Keep individual code files under 200 lines for optimal context management
- Split large files into smaller, focused components
- Extract utility functions into separate modules
- Create dedicated service classes for business logic

### Directory Structure

```
lib/
├── flutter_zpl_generator.dart           # Barrel export (public API)
├── src/
│   ├── Commands
│   │   ├── zpl-command-base.dart       # Abstract base class
│   │   ├── zpl-text.dart
│   │   ├── zpl-barcode.dart
│   │   └── ...
│   │
│   ├── Layout
│   │   ├── zpl-column.dart
│   │   ├── zpl-grid-row.dart
│   │   └── zpl-table.dart
│   │
│   ├── Services
│   │   ├── labelary-service.dart
│   │   ├── zpl-asset-service.dart
│   │   └── ...
│   │
│   ├── Config
│   │   ├── zpl-configuration.dart
│   │   └── enums.dart
│   │
│   └── Models
│       └── zpl-font-asset.dart
│
└── widgets/
    └── zpl-preview.dart
```

## Code Quality Standards

### General Principles

- **Readability First:** Prioritize code clarity over brevity
- **Self-Documenting:** Class and method names should clearly express intent
- **Error Handling:** Use try-catch for external APIs (Labelary, asset loading)
- **Security:** Never log sensitive data; validate all external inputs
- **No Mocks:** Tests use real implementations or verified mock data

### Documentation Standards

#### Class Documentation

Every public class must have a doc comment:

```dart
/// A class to handle text-related commands (^FO, ^A, ^FD, ^FS).
///
/// [ZplText] supports multiple fonts, alignment options, and custom TTF fonts.
/// When used within a layout container like [ZplGridRow], the container
/// sets [maxWidth] to enable width-aware alignment and wrapping.
class ZplText extends ZplCommand {
  // ...
}
```

#### Method Documentation

Public methods require documentation:

```dart
/// Converts the command to its ZPL representation.
///
/// The [context] parameter provides label configuration (dimensions, density)
/// needed for width calculations and coordinate positioning.
@override
String toZpl(ZplConfiguration context) {
  // ...
}
```

#### Property Documentation

Document properties that have non-obvious behavior:

```dart
/// The text content to be printed.
final String text;

/// Maximum width constraint (set by layout containers like [ZplGridRow]).
/// When set, alignment uses this width instead of the full label width.
final int? maxWidth;

/// Whether to invert the print colors (white on black).
/// Corresponds to the ^FR command in ZPL.
final bool reversePrint;
```

### Constructor Patterns

- Use named parameters for flexibility
- Default parameter values when sensible
- Required parameters for essential data (marked with `required`)

```dart
ZplText({
  this.x = 0,
  this.y = 0,
  required this.text,
  this.font = ZplFont.zero,
  this.fontHeight,
  this.alignment,
  this.maxWidth,
  this.reversePrint = false,
});
```

### Command Implementation Pattern

All `ZplCommand` implementations must follow this structure:

1. **Properties:** Field definitions with documentation
2. **Constructor:** Named parameters with defaults
3. **toZpl() Method:** Convert to ZPL string with config context
4. **calculateWidth() Method:** Return width in dots
5. **Helper Methods:** Private `_` prefixed methods for internal logic

```dart
class ZplText extends ZplCommand {
  // 1. Properties
  final int x;
  final String text;
  final int? maxWidth;

  // 2. Constructor
  ZplText({
    this.x = 0,
    required this.text,
    this.maxWidth,
  });

  // 3. toZpl() - signature: String toZpl(ZplConfiguration context)
  @override
  String toZpl(ZplConfiguration context) {
    final effectiveWidth = maxWidth ?? context.printWidth ?? 812;
    return '^FO$x,0^A0N,30^FB${effectiveWidth},1,0,L^FD$text^FS';
  }

  // 4. calculateWidth()
  @override
  int calculateWidth(ZplConfiguration config) {
    // Return estimated width in dots
    return text.length * 10;
  }

  // 5. Helper methods (private)
  int _estimateTextWidth() {
    // Implementation
  }
}
```

### Error Handling

Use try-catch for external operations:

```dart
Future<String> getFontUploadCommand(ZplFontAsset font) async {
  try {
    final byteData = await rootBundle.load(font.assetPath);
    final hexData = _bytesToHex(byteData.buffer.asUint8List());
    return '~DY${font.id},${hexData.length}^XA$hexData^XZ';
  } catch (e) {
    throw Exception('Failed to load font asset ${font.assetPath}: $e');
  }
}
```

### Type Safety

- Avoid nullable types when possible; use default values instead
- Use `final` for immutable properties (all command properties are final)
- Use `late` only when initialization order is complex
- Prefer concrete types over `dynamic`

```dart
// Good: Clear types, nullable only when necessary
final int x;
final String text;
final int? maxWidth;     // Nullable because set by parent container

// Avoid: Unclear type usage
final dynamic config;
var result;
```

### Testing Patterns

#### Unit Test Structure

```dart
void main() {
  group('ZplText', () {
    group('toZpl', () {
      test('should generate valid ZPL with basic properties', () {
        final text = ZplText(x: 10, y: 20, text: 'Hello');
        final config = const ZplConfiguration();

        final zpl = text.toZpl(config);

        expect(zpl, contains('^FO10,20'));
        expect(zpl, contains('^FDHello^FS'));
      });

      test('should respect reversePrint property', () {
        final text = ZplText(text: 'Test', reversePrint: true);
        final config = const ZplConfiguration();

        final zpl = text.toZpl(config);

        expect(zpl, contains('^FR'));
      });
    });

    group('calculateWidth', () {
      test('should return proportional width to text length', () {
        final text = ZplText(text: 'Hello World');
        final config = const ZplConfiguration();

        final width = text.calculateWidth(config);

        expect(width, greaterThan(0));
        expect(width, greaterThan(ZplText(text: 'Hi').calculateWidth(config)));
      });
    });
  });
}
```

#### Test Helpers

Use `normalizeZpl()` helper for comparing ZPL output:

```dart
String normalizeZpl(String zpl) {
  return zpl.trim().replaceAll(RegExp(r'\s+'), '');
}

// Usage
expect(normalizeZpl(zpl), contains('^FO10,20^FDHello^FS'));
```

### Configuration Pattern

`ZplConfiguration` is passed as context to all commands:

```dart
// v2.0: Configuration is decoupled from command list
final config = ZplConfiguration(
  printWidth: 812,
  printHeight: 1218,
  density: ZplPrintDensity.d8,
  darkness: 15,
);

final generator = ZplGenerator(
  config: config,
  commands: [
    ZplText(text: 'Label'),
    ZplBarcode(data: '123456', height: 50),
  ],
);

// Each command receives config via toZpl(context) parameter
```

### Layout Container Pattern

Layout containers (e.g., `ZplGridRow`) manage child positioning and set `maxWidth`:

```dart
class ZplGridRow extends ZplCommand {
  final List<int?> columnWidths;
  final List<ZplCommand> children;

  @override
  String toZpl(ZplConfiguration context) {
    final sb = StringBuffer();
    var xOffset = 0;

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final width = columnWidths[i];

      // Inject maxWidth into child if it supports it
      // This enables width-aware alignment and wrapping
      final zpl = _applyMaxWidth(child, width, context);
      sb.writeln(zpl);

      xOffset += width ?? 100;
    }

    return sb.toString();
  }
}
```

## Import Organization

```dart
// 1. Dart imports
import 'dart:typed_data';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports (alphabetical)
import 'package:mockito/mockito.dart';

// 4. Relative imports (alphabetical)
import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
```

## Naming Specific to ZPL Domain

- **Commands:** `Zpl` prefix (e.g., `ZplText`, `ZplBarcode`)
- **Enums:** `Zpl` prefix (e.g., `ZplFont`, `ZplOrientation`, `ZplBarcodeType`)
- **Services:** Suffix with `Service` (e.g., `LabelaryService`, `ZplAssetService`)
- **Configuration:** `ZplConfiguration` (no command suffix)
- **Coordinates:** Use `x`, `y` for position; `width`, `height` for dimensions
- **ZPL Commands:** When referencing raw ZPL, use full notation (e.g., "^FO field origin", "^FD field data")

## Property Naming

For rectangular elements, use standard dimension names:

```dart
class ZplBox extends ZplCommand {
  final int x;        // Left edge position
  final int y;        // Top edge position
  final int width;    // Horizontal size
  final int height;   // Vertical size
}
```

For text fields with wrapping:

```dart
class ZplText extends ZplCommand {
  final int? maxLines;     // Line limit for wrapping
  final int lineSpacing;   // Vertical space between lines
  final int? maxWidth;     // Width constraint from layout
}
```

## Performance Considerations

- **String Building:** Use `StringBuffer` for concatenating ZPL output (not string addition)
- **Width Calculations:** Cache calculated widths when used multiple times
- **Asset Loading:** Load fonts asynchronously via `ZplAssetService`
- **API Calls:** Labelary API calls are asynchronous; use `Future` appropriately

## Security Guidelines

- **No Sensitive Data Logging:** Never log API keys, font data, or label content in debug mode
- **Input Validation:** Validate all external inputs (barcode data, text content)
- **Font Assets:** Verify font files exist and are valid before processing
- **API Responses:** Check for errors and warnings in `LabelaryResponse`

## Version Compatibility

- **Dart:** Minimum 2.17 (null safety required)
- **Flutter:** Minimum 3.0
- **Platform:** All Flutter platforms (iOS, Android, Web, Desktop)

## v2.0 Breaking Changes

These changes affect how code is structured:

1. **`toZpl()` Signature:** Now requires `ZplConfiguration context` parameter
   - Old: `String toZpl()`
   - New: `String toZpl(ZplConfiguration context)`

2. **`ZplGenerator` Constructor:** Named parameters with config decoupling
   - Old: Commands list included configuration
   - New: Configuration is separate `config` property

3. **`ZplRow` Removed:** Use `ZplGridRow` for horizontal layouts
   - Existing: `ZplRow(children: [...])`
   - New: `ZplGridRow(columnWidths: [...], children: [...])`

4. **Layout Width Constraint:** `maxWidth` property on leaf commands
   - Allows layout containers to constrain child width
   - Enables responsive alignment and wrapping

## Migration Checklist

When updating code for v2.0:

- [ ] Change `toZpl()` calls to pass `ZplConfiguration context`
- [ ] Update `ZplGenerator` instantiation to use named parameters
- [ ] Move configuration from command list to `config` parameter
- [ ] Replace `ZplRow` with `ZplGridRow`
- [ ] Update test assertions to match new ZPL output format
- [ ] Test layout containers with `maxWidth` constraints
- [ ] Verify all barcode types (check for new types: `dataMatrix`, `ean13`, `upcA`)
