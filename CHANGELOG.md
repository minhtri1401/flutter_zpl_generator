# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- GS1 helpers: an application identifier registry (AIs 01, 10, 11, 13, 15, 17, 21, 37, 3103) with per-value validation, the GS1 mod-10 check digit, and parsing, formatting and FNC1 conversion of element strings such as `(01)09501101530003(17)261231(10)A1`.
- `ZplBarcode.gs1`: GS1 Data Matrix. With the flag set on a Data Matrix, parenthesised element-string data is sent as FNC1 plus AI codes and values, with a group separator after each variable-length value that another AI follows (`^BX` escape parameter `~`: `~1` and `~d029`). The offline preview encodes the same FNC1 symbol. Other symbologies ignore the flag; non-GS1 output is unchanged.
- GS1 helpers reject `~` and `^` in values, check the day against the month (leap years included), and throw on a repeated AI.

## [2.4.1] - 2026-10-22

### Fixed

- The native preview now draws all 13 digits of an EAN-13 interpretation line: the leading digit sits left of the start guard, as Zebra prints it ("5 901234 123457"). The bars still start at the field origin. UPC-A and EAN-8 are unchanged.

## [2.4.0] - 2026-10-20

### Added

- `ZplRasterizer.render(scale:)` draws the label at `scale` pixels per dot
  (default 1.0, the old output). `width` and `height` are then pixel sizes,
  the dot size times `scale` rounded, at least one pixel. A `scale` that is
  not finite or not greater than 0 throws an `ArgumentError`.
- `ZplRaster.scale` reports the pixels per dot the raster was drawn at.

## [2.3.0] - 2026-10-16

### Removed

- Unused `barcode_widget` dependency. Apps that use `BarcodeWidget` must now
  depend on `barcode_widget` themselves.

### Added

- `measureZplText` and `ZplTextFit` measure a `ZplText` against its `^FB`
  block with the preview painter's font, scale and wrap width and no line
  limit. `ZplTextFit.overflows` is true when the text needs more lines than
  `maxLines` or a line is wider than the block, which the preview truncates or
  draws unwrapped and the printer overprints. `drawZplText` is unchanged.
- `ZplRasterizer.render` draws a `ZplGenerator` offscreen into a `ZplRaster`
  (PNG at one pixel per dot, width, height and `inkRatio`), with the same
  painter as `ZplNativePreview` and no widget tree or network. It needs the
  Flutter binding, so tests call `TestWidgetsFlutterBinding.ensureInitialized()`.
  Width and height default to the configuration's `printWidth` and
  `labelLength`, else 406 x 609.
- `ZplFieldDataEscaper` (`needsHex`, `hexEscape`) is exported so hosts that
  fill `{{placeholders}}` into finished ZPL can escape values in `^FH` fields
  the same way; `{{name}}` placeholders are left unescaped.

### Fixed

- `ZplNativePreview` and `ZplRasterizer` drew a wide `^GE` ellipse whose
  border covers half of its height as a thin outline with a hole. It is now
  filled, as on the printer.
- `ZplNativePreview` and `ZplRasterizer` drew a wide `^GB` bar whose border
  covers its short side (such as a full-width bar behind `^FR` reverse-print
  text) cropped to its inset length, with white margins at both ends. The bar
  now stays solid across its full width, and the reverse-print text is knocked
  out white, as on Labelary and the printer.
- `ZplNativePreview` and `ZplRasterizer` drew a `^GB` whose width or height is
  below its border thickness (such as `^GB10,100,30`) at the size it was
  given. The printer and Labelary take the border thickness as the least width
  and height, so the box is now widened to it.
- `ZplRasterizer.render` disposed its `Picture` only after `toImage` had
  succeeded, so a render that threw (an empty size) leaked the native
  picture. The picture is now disposed on every path.
- `ZplSeparator` with `ZplSeparatorType.box` now emits `^GB…,t,t` (border
  thickness equal to the rule thickness), so rules 3 dots or thicker print
  solid instead of as a 1-dot outline. 1- and 2-dot rules look the same; their
  border parameter now equals the thickness.
- `ZplText` field data: inside a `^FB` block a backslash is now written `\\`,
  so a literal `\&` no longer prints as a line break. Text holding `^` or `~`
  is now written behind `^FH` with `_5E`/`_7E` (and `_5F` for `_`) escapes,
  so the printer no longer reads them as commands. Text without these
  characters is byte-identical to before.
- `ZplTemplate` does not hex-escape bound values; callers filling `^FH` fields
  use `ZplFieldDataEscaper.hexEscape`.

## [2.2.1] - 2026-10-02

### Documentation

- New **Print to a Zebra printer** section: send labels with
  [`flutter_zpl_printer`](https://pub.dev/packages/flutter_zpl_printer) (Bluetooth LE, Wi-Fi, USB),
  which includes this package.
- The templating example now shows a real `printer.printZpl(...)` call instead of a placeholder.
- Example app: **Send to printer** button on every demo (Wi-Fi; native platforms only).
- README opens with a plain definition and adds an **FAQ** (generating and printing ZPL, offline
  preview, supported barcodes, units, web and desktop support).
- New `llms.txt` summarizing the API, units, and guides for AI coding assistants.
- Sharper pubspec description and library-level dartdoc.

## [2.2.0] - 2026-09-27

### Added

- `ZplText`: line breaks in `text` are now emitted as the `\&` field-block
  escape when a `^FB` block is present, so multi-line strings print on
  separate lines instead of running together. Outside a block the break is
  dropped, matching printer behaviour; the native preview mirrors both.
  Use `ZplText.renderedText` to see the text as the printer lays it out.

## [2.1.2] - 2026-09-27

### Fixed

- **ACS image compression produced corrupted graphics on the printer.**
  The run-length letters were off by one (the encoder wrote `G` for a run
  of 2, but `G` means 1 in ZPL, `H` is 2, … `Y` is 19), so every 2–19
  nibble run came out one nibble short and rows drifted right. Affected
  `ZplImageInline` (ACS by default) since 1.3.0 and `ZplImageDownload`
  with `compression: acs`. Verified against Labelary: ACS output is now
  pixel-identical to the raw-hex output. `none`, `b64` and `z64` were
  never affected.
- Native preview: UPC-A/UPC-E print their system and check digits outside
  the bars (only EAN-13 drops its leading digit); GS1-128 interpretation
  line keeps the `(AI)` parentheses; PDF417 size now follows
  `pdf417Columns` and `pdf417SecurityLevel` instead of the encoder's own
  aspect-driven layout, so it no longer overflows neighbouring fields.

## [2.1.1] - 2026-09-27

### Fixed
- `ZplText`: when `maxWidth` is set together with `maxLines > 1` and a
  non-zero `x`, the left-aligned `^FB` width was `maxWidth - x` (negative for
  offset children inside containers). It is now `maxWidth - paddingRight`,
  matching the justified branch. Output changes for affected labels.
- `ZplNativePreview` mirrors the same wrap width for wrapped text inside
  containers, so the preview and the printed `^FB` block agree.

### Changed

- Example app gains web, Windows and Linux runners, matching the package's
  declared platform support (pub.dev tags all six platforms and wasm-ready).

## [2.1.0] - 2026-09-27

Toolchain refresh, package hygiene, Z64/B64 graphic compression and seven
new barcode symbologies.

### Added

- **Z64 / B64 graphic compression.** `ZplImageCompression.z64` (zlib +
  base64 + CRC-16) and `.b64` for both `ZplImageDownload` (`~DG`) and
  `ZplImageInline` (`^GFA`). Z64 typically cuts image payloads by 70–90 %
  versus raw hex. `ZplImageInline` gains a `compression:` parameter
  (default `acs`, output unchanged). Pure-Dart deflate via
  `package:archive`, so it works on web.
- **Barcode symbologies:** `pdf417` (`^B7`), `aztec` (`^BO`), `code93`
  (`^BA`), `interleaved2of5` (`^B2`), `ean8` (`^B8`), `upcE` (`^B9`) and
  `gs1_128` (`^BC` mode D). All render in `ZplNativePreview`.
- **QR parameters:** `magnification` (also used by Aztec) and
  `qrErrorCorrection` (`ZplQrErrorCorrection.low/medium/quartile/high`).
- **PDF417 parameters:** `pdf417SecurityLevel`, `pdf417Columns`.
- GitHub Actions: `ci.yml` (format, analyze, test, publish dry-run) and
  `security-scan.yml` (OSV vulnerability/malware scan with SARIF upload,
  dependency review on PRs, gitleaks secret scan, weekly schedule) plus
  Dependabot for pub and actions.
- Unit tests for previously untested modules: `ZplTable`, `ZplTextBlock`,
  `ZplAdvancedTextProperties`, `ZplSeparator`, ZBI/host-query commands,
  control-command ordering, both preview widgets, the compression encoder
  and every barcode symbology.

### Native preview accuracy

`ZplNativePreview` was rendering barcodes 20–45 % too wide, QR/Data Matrix
at guessed sizes, and text in the platform font at the wrong size. It is
now measured against Labelary (see
`test/native_preview_fidelity_harness_test.dart`, which renders both and
diffs the bitmaps):

- 1D barcodes use the real encoded module count times `^BY` module width,
  with the interpretation line below the bars (7 dots per module + 6) rather
  than carved out of them. Code 128 reproduces Zebra's automatic subset
  switching; Code 39 / I 2 of 5 apply the `^BY` ratio (default 3:1); EAN/UPC
  omit the leading digit like the printer. Overlap with Labelary went from
  29–34 % to 90–95 %.
- QR uses numeric/alphanumeric/byte mode selection, the printer's
  "strongest error correction that fits" rule and the 10-dot vertical
  offset, so size and version match exactly (alphanumeric payloads are
  pixel-identical). Data Matrix scales by the `^BX` module height (100 %).
- Text is drawn with a bundled condensed bold face (Archivo Narrow, SIL
  OFL 1.1, `fonts/`) sized so caps are 75 % of the `^A` height with the cap
  top on the origin, width defaults to height for font 0, and `^FB`
  alignment mirrors the generator. Bounding boxes now land within 2–3
  dots of Labelary.
- Field rotation (`R`, `I`, `B`) is honoured for text and barcodes;
  `ZplConditional` children and `ZplGraphicSymbol` are drawn; `^TB` blocks
  clip to their box.
- Layout: `ZplBarcode.width` (used for centre/right alignment in the
  generated ZPL) is now the printed width, so aligned barcodes print where
  the preview shows them. Previously a centred Code 128 printed ~30 dots
  off-centre.

### Fixed

- **QR Code field data now carries the required `^FD<ecc>A,` prefix**
  (e.g. `^FDMA,https://…`). Without it real printers consume the first
  characters of your data as parameters. `^BQ` now also emits the
  error-correction level. Output for existing QR labels changes.

- `ZplZbiStart` (`~JI`), `ZplZbiStop` (`~JQ`), `ZplHostQuery` (`~HQ`),
  `ZplNetworkConnect` (`~NC`), `ZplNetworkPrintersTransparentAll` (`~NR`)
  and `ZplNetworkPrinterTransparentCurrent` (`~NT`) now extend
  `ZplControlCommand`, so `ZplGenerator` emits them before `^XA` like
  `~DG`/`~DY`. Previously they were embedded inside the format block, which
  strict Link-OS firmware rejects. **Output order changes** for labels that
  use these commands; the ZPL is otherwise identical.
- README image-conversion snippet referenced a non-existent
  `LabelaryGraphicOutputFormat`; corrected to `LabelaryOutputFormat`.

### Changed

- Project pinned to Flutter 3.47.5 / Dart 3.13 via fvm; dependencies
  upgraded (`image` 4.10, `mockito` 5.6.4, `build_runner` 2.15).
- Added `.pubignore`: the pub archive no longer ships the 15 MB ZPL manual
  PDFs, plans, or local fonts (13 MB → well under 1 MB).
- `CLAUDE.md` and `doc/` rewritten to match the v2 API (`ZplImage`,
  `ZplFontAsset`, `ZplRow` and other removed names purged).
- `ZplBarcode` internals split into `zpl_barcode_symbology_emitter.dart`
  and `zpl_barcode_width_estimator.dart`; public API unchanged apart from
  the additions above.
- QR Code width estimate now scales with `magnification` (module count +
  quiet zone, times magnification) instead of fixed buckets. Centred or
  right-aligned QR codes may shift by a few dots.
- `ZplImageInline` accepts `compression: none` (raw hex inside `^GFA`);
  verified on Labelary only.

## [2.0.0] - 2026-04-20

### BREAKING CHANGES

- Deleted `ZplImage` — replaced by three explicit commands:
  - `ZplImageDownload` (emits `~DG`; new `ZplControlCommand` base).
  - `ZplImageRecall` (emits `^FO` + `^XG`).
  - `ZplImageInline` (emits `^FO` + `^GFA`, one-shot ACS).
- Deleted `ZplFontAsset` — replaced by `ZplFontUpload` (also a
  `ZplControlCommand`). Load via `await ZplFontUpload.fromAsset(...)`.
- Removed `ZplGenerator.fonts` and `ZplGenerator.assetService`
  parameters. Pass `ZplFontUpload` instances inline in `commands:`.
- Removed `ZplAssetService.getFontUploadCommand()`. `loadFontBytes()`
  replaces its role as the low-level asset read.
- `ZplText.customFont` type changed from `ZplFontAsset?` to
  `ZplFontUpload?`.

See `doc/migration-v1-to-v2.md` for per-pattern migration recipes.

### Fixed

- **Bug 1 (critical):** `~DG` and `~DY` now emit before `^XA` as
  Zebra's ZPL II Programming Guide recommends. Link-OS mobile printers
  (ZQ620 V85.20 etc.) print reliably; previously the tilde-inside-
  format layout caused blank labels or silently discarded jobs.
- **Bug 2:** `ZplImageDownload.width` / `.height` (and matching getters
  on `ZplImageInline`) now return POST-resize dimensions, including
  aspect-preserving scale when only one axis is specified. Unblocks
  `^LL = image.height` for every caller.
- **Bug 4:** ACS run-length encoder dropped the trailing `1` count after
  a multi-of-20 chunk (runs of 21, 41, …, 401). Fix localised in
  `image_payload_builder.dart::compressRow`.

### Added

- `ZplControlCommand` abstract subclass of `ZplCommand`; subclass it
  to author any tilde-prefixed command.
- `ZplGenerator.autoLabelLengthFromFirstImage: bool` — when enabled
  and no explicit `ZplConfiguration.labelLength` is set, emits
  `^LL<firstDownload.height>` inside the format. (Bug 3)
- ACS encoder round-trip test suite with boundary and fuzz coverage.
- `doc/migration-v1-to-v2.md`.
- `doc/mobile-printer-guide.md` — Link-OS firmware caveats, thermal
  protection advisory, observed-working ZPL reference.

## [1.5.1] - 2026-03-28

### Fixed
- **Native Preview Fixes**: Stabilized anti-aliasing artifacts on `ZplCanvasPainter` that resulted in edge-bleeding in scannable offline barcode widgets. Corrected module-width distortion calculation for 1D and 2D barcodes ensuring perfect native preview parity to printer firmware output.
- **Native Preview Images**: Upgraded offline native preview to now physically dither and render image payloads directly within the Flutter canvas securely, rather than just displaying a blue placeholder bounds.

## [1.5.0] - 2026-03-28

The "Native Preview & Advanced Typography" Release.

### Added
- **Native Offline Canvas Preview**: Added `ZplNativePreview` and `ZplCanvasPainter` for high-performance offline rendering of ZPL layouts in Flutter without relying on external network calls.
- **Advanced Typography (`^PA`)**: Added `ZplAdvancedTextProperties` for fine-grained control over text alignment and styling.
- **Text Blocks (`^TB`)**: Added `ZplTextBlock` support, natively integrated into `ZplGridRow` and `ZplColumn` for complex rich-text layouts.
- **Zebra BASIC Interpreter (ZBI) Commands**: Implemented `ZplZbiStart` (`~JI`), `ZplZbiStop` (`~JQ`), `ZplHostQuery` (`~HQ`), and `ZplEarlyWarning` (`^JH`) for programmatic printer control and bidirectional host querying.

### Dependencies
- Added `barcode: ^2.2.9` to support native offline barcode generation.

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