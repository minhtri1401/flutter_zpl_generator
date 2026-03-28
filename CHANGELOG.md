# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2026-03-28

The "Enterprise Networking & Hardware Integrations" Release.

### Added
- **Hardware Network Configuration**: Comprehensive suite of commands for configuring ZPL printer networks natively.
  - `ZplNetworkSettings` (`^ND`): Interface for changing primary IP, subnet, gateway, resolving timeouts for a device.
  - `ZplNetworkWiredSettings` (`^NS`): Wired-specific network configurations matching dynamic addressing.
  - `ZplNetworkSnmp` (`^NN`): Full configuration of Simple Network Management Protocol parameters (community strings, location, contact, traps).
  - `ZplNetworkSmtp` (`^NT`): Define printer SMTP email routing server details.
  - Operations for device connection limits (`^NC`, `~NC`, `^NP`), ID assignment (`^NI`), firmware boot server routines (`^NB`), and password timeouts (`^NW`).
- **Printer Transparency Management**: Address downstream printers linked off a primary printer port using `ZplNetworkPrintersTransparentAll` (`~NR`) and `ZplNetworkPrinterTransparentCurrent` (`~NT`).
- **Graphic Symbols (`^GS`)**: Added `ZplGraphicSymbol` utility allowing for hardware-native validation and rendering of standard registered trademark (®), copyright (©), UL, CSA, and VDE symbols.

## [1.3.0] - 2026-03-26

The "Enterprise Print Batching & Compression" Release.

### Added
- **Native Print Quantity (`^PQ`)**: Control batches dynamically with `ZplPrintQuantity`. Set quantity counts, overrides, pausing, and cut intervals mathematically outside of strings.
- **Auto-Increment Serialization (`^SN`)**: Embed native hardware serialization with `ZplSerialization` mapping `start`, `increment`, and `pad` controls natively into ZPL blocks.
- **ACS Image Compression (`^GFA`)**: Greatly optimized print times by compressing binary string images natively into `acs` run-length encoded `ZplImageCompression` outputs. Drops image payload payload size by 60-90%.
- **Conditional Layout Support (`ZplConditional`)**: Drop-in wrapper that renders layout elements recursively conditionally based on a `bool`. Works natively inside `ZplGridRow` and `ZplColumn` gracefully mapping mathematical zeroes preventing spacing gaps!

## [1.2.0] - 2026-03-26

The "Enterprise RFID & Smart Imaging" Release.

### Added
- **Enterprise RFID Tag Encoding**: New `ZplRfidSetup` (`^RS`) and `ZplRfidWrite` (`^RF`) commands for simultaneous print-and-encode workflows on Zebra RFID printers (e.g., ZT411 RFID).
  - Supports all Gen 2 memory banks: Reserved, EPC, TID, User.
  - Full operation set: Write, Write with Lock, Read, Read Password, Specify Password, Encode.
  - Data formats: ASCII, Hexadecimal, EPC.
  - Runtime `ArgumentError` validation for hex payloads to prevent silent printer failures.
- **Advanced Image Dithering**: `ZplImage` now supports `ZplDitheringAlgorithm` with three modes:
  - `floydSteinberg` (new default) — smooth error diffusion for natural-looking gradients.
  - `atkinson` — high contrast dot patterns with a vintage newspaper print aesthetic.
  - `threshold` — legacy hard black/white clipping behavior.
- **Templating & Data Binding Engine**: New `ZplTemplate` class for high-performance mass-label generation.
  - Define layouts with `{{variable}}` placeholders in any `ZplText`, `ZplBarcode`, etc.
  - `init()` pre-compiles the layout once (fonts, images, grid math).
  - `bindSync()` enables zero-overhead synchronous label stamping in tight loops.

### Changed
- Default image dithering algorithm changed from `threshold` to `floydSteinberg` for significantly better print quality out of the box.

## [1.1.1] - 2026-03-22

### Fixed
- Fixed placeholder **yourusername** GitHub URLs in `pubspec.yaml` and pointed them correctly to **minhtri1401**.

## [1.1.0] - 2026-03-22

The "Library Finalization & Layout Redux" Release.

### Added
- **12-Unit Grid Layout Engine**: Overhauled horizontal layouts by introducing `ZplGridRow` and `ZplGridCol` for robust proportional layouts and offsets without requiring string hacks.
- **Graphic Shapes**: Added `ZplGraphicCircle` (`^GC`), `ZplGraphicEllipse` (`^GE`), and `ZplGraphicDiagonalLine` (`^GD`).
- **Raw Escape Hatch**: Added `ZplRaw` command allowing developers to inject arbitrary raw ZPL string segments cleanly into the hierarchy.
- **Advanced Barcode Formats**: Upgraded `ZplBarcodeType` with native support for `DataMatrix` (`^BX`), European Article Number `ean13` (`^BE`), and Universal Product Code `upcA` (`^BU`).
- **Reverse Colors**: Added `reversePrint` parameter to display standard white-on-black inverse patterns (`^FR`) in `ZplText` and `ZplBox`.

### Changed
- **BREAKING**: `ZplConfiguration` is no longer passed as a fake object inside the `commands` array. It is now passed directly as a root parameter to the generator: `ZplGenerator(config: ..., commands: [...])`. 
- **ZplPreview Reactivity**: `ZplPreview` widget is now fully reactive and correctly implements Flutter's `didUpdateWidget()`, automatically rerendering images optimally when configurations or properties change.
- **Networking Compliance**: `LabelaryService` REST network calls were updated to enforce proper `Content-Type` headers ensuring better proxy network pass-throughs.
- Internal layout rendering logic entirely rewritten. `toZpl()` now takes a `ZplConfiguration context`, enforcing parent bound limits like `maxWidth` implicitly down through children layers.

### Removed
- **BREAKING**: Completely deleted the outdated and brittle `ZplRow` component. Use the superior mathematically driven `ZplGridRow` instead.

## [1.0.0] - 2024-03-15

### Added

#### Core Features
- **ZPL Command Support**: Complete implementation of essential ZPL commands
  - `ZplConfiguration`: Label setup with print width, length, density, and orientation
  - `ZplText`: Text rendering with font selection, sizing, and positioning
  - `ZplBarcode`: Comprehensive barcode support (Code128, QR Code, UPC, EAN, etc.)
  - `ZplImage`: Image embedding with PNG and other format support
  - `ZplBox`: Rectangle and border drawing with customizable thickness
  - `ZplRow` and `ZplColumn`: Layout helpers for organized label design

#### Labelary API Integration
- **Complete API Support**: Full integration with Labelary rendering service
  - Basic ZPL rendering to PNG, PDF, and other formats
  - Advanced features: label rotation, PDF customization, print quality control
  - ZPL linting with detailed error reporting
  - Response metadata including label count and warnings
- **Image Conversion**: Convert images to ZPL graphics commands
- **Font Conversion**: Convert TrueType fonts to ZPL font commands
- **Multiple Content Types**: Support for both raw ZPL strings and file uploads

#### Flutter Integration
- **ZplPreview Widget**: Live preview widget for Flutter applications
  - Automatic rendering using Labelary API
  - Loading, success, and error state handling
  - Easy integration with any Flutter app
- **Type Safety**: Strongly typed enums and classes for all ZPL parameters
- **Cross-Platform**: Support for iOS, Android, Web, macOS, Windows, and Linux

#### Developer Experience
- **Comprehensive Examples**: Multiple example files demonstrating usage patterns
- **Extensive Testing**: Unit tests and integration tests with Labelary API
- **Documentation**: Detailed API documentation and usage examples
- **Error Handling**: Descriptive error messages and graceful failure handling

### Technical Details

#### Supported ZPL Commands
- `^XA` / `^XZ`: Label start and end
- `^LL`: Label length configuration
- `^PR`: Print rate/density settings
- `^JM`: Memory allocation mode
- `^FO`: Field origin positioning
- `^A0N`, `^AAN`, `^ABN`: Font selection and sizing
- `^FD` / `^FS`: Field data definition
- `^GB`: Graphic box drawing
- `^BY`: Barcode element width
- `^BCN`, `^B3N`, `^BQN`: Various barcode types
- Custom font loading and usage

#### Supported Barcode Types
- Code 128 (most common)
- QR Code with error correction
- UPC-A and UPC-E
- EAN-8 and EAN-13
- Code 39
- Interleaved 2 of 5
- And many more standard formats

#### Labelary API Features
- Label rendering in multiple formats (PNG, PDF, EPL, IPL, DPL, SBPL, PCL)
- Label rotation (0°, 90°, 180°, 270°)
- PDF page customization (size, orientation, layout, borders)
- Print quality control (grayscale vs bitonal)
- ZPL linting and validation
- Multiple labels per request support
- Image and font conversion services

#### Package Architecture
- Clean separation between ZPL generation and rendering
- Modular command-based design for easy extension
- Backward compatibility with simple method variants
- Efficient memory usage and network handling
- Comprehensive error handling and validation

### Dependencies
- `flutter`: Flutter SDK
- `image`: ^4.2.0 for image processing
- `http`: ^1.1.0 for API communication

### Development Dependencies
- `flutter_test`: Testing framework
- `flutter_lints`: Code quality and style enforcement
- `mockito`: Mock testing for API calls
- `build_runner`: Code generation support

### Platform Support
- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

### Breaking Changes
None - this is the initial release.

### Migration Guide
This is the first stable release. No migration needed.

### Known Issues
None at release time.

### Contributors
- Initial development and design
- Comprehensive testing and documentation
- Community feedback and suggestions welcomed

---

**Note**: This package provides ZPL generation and rendering capabilities for Flutter applications. It integrates with the Labelary.com service for label preview and rendering, but does not require it for basic ZPL string generation.