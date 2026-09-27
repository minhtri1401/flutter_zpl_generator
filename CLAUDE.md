# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter package (`flutter_zpl_generator`) for generating ZPL (Zebra Programming Language) label scripts. Capabilities: ZPL command generation with a container layout engine, TTF font upload, image-to-ZPL conversion with dithering and compression, RFID/network/ZBI printer commands, a templating engine, Labelary API integration, and two preview widgets (Labelary-backed and offline native). Published to pub.dev, targets all Flutter platforms.

Sibling repos: `../flutter_zpl_printer` (Link-OS transport plugin, sends the ZPL) and `../flutter_zpl_builder` (CLI). Printer I/O does not belong in this package.

## Common Commands

Always prefix with `fvm` (project pinned to Flutter 3.47.5 via `.fvm/fvm_config.json`).

```bash
fvm flutter pub get
fvm flutter test                                   # all tests
fvm flutter test test/zpl_table_test.dart          # one file
fvm flutter analyze
fvm dart pub publish --dry-run                     # archive must stay small; see .pubignore
fvm dart run build_runner build --delete-conflicting-outputs   # regenerate mockito mocks
cd example && fvm flutter run
```

## Architecture

### Command model
- `ZplCommand` (`lib/src/zpl_command_base.dart`): abstract, `toZpl(ZplConfiguration context)` + `calculateWidth(config)`.
- `ZplControlCommand`: marker subclass for tilde commands (`~DG`, `~DY`, `~JI`, `~JQ`, `~HQ`, `~NC`, `~NR`, `~NT`). `calculateWidth` is 0. Any new tilde command must extend this.
- `ZplGenerator({config, required commands, autoLabelLengthFromFirstImage})` builds in two passes: all `ZplControlCommand`s first (before `^XA`), then `^XA`, config, format commands, `^XZ`. Required by strict Link-OS firmware.
- `ZplConfiguration`: value class for label-level settings (`^PW ^LL ~SD ^PR ^MM ^MT ^PO ^LH ^CI ^JM`), passed as context to every command.

### Command families (all under `lib/src/`)
- Leaf: `ZplText` (`^A`/`^A@`, `^FB`, `^FR`, `^SN` via `ZplSerialConfig`), `ZplTextBlock` (`^TB`), `ZplAdvancedTextProperties` (`^PA`), `ZplBox` (`^GB`), `ZplSeparator`, `ZplRaw`, `ZplBarcode`.
- Layout: `ZplColumn`, `ZplGridRow`/`ZplGridCol` (12-unit grid), `ZplTable`/`ZplTableHeader`, `ZplConditional`. Containers set `maxWidth` on leaf children.
- Graphics: `ZplGraphicCircle` (`^GC`), `ZplGraphicEllipse` (`^GE`), `ZplGraphicDiagonalLine` (`^GD`), `ZplGraphicSymbol` (`^GS`).
- Images: `ZplImageDownload` (`~DG`, control), `ZplImageRecall` (`^XG`), `ZplImageInline` (`^GFA`). Share the `ImagePayloadBuilder` mixin (decode, resize, dither, encode). Compression modes in `ZplImageCompression`.
- Fonts: `ZplFontUpload` (`~DY`, control; `await ZplFontUpload.fromAsset(...)`). `ZplText.customFont` takes a `ZplFontUpload`.
- Printer control: `ZplPrintQuantity` (`^PQ`), RFID (`ZplRfidSetup` `^RS`, `ZplRfidWrite` `^RF`), networking (`zpl_network.dart`, `^N*`/`~N*`), ZBI/host (`zpl_hardware.dart`).
- Templating: `ZplTemplate` with `{{var}}` placeholders; `init()` then `bind()`/`bindSync()`.

### Services and widgets
- `LabelaryService` (`lib/src/labelary_service.dart`): static Labelary calls (`renderZpl`, `renderZplFile`, `convertImageToGraphic`, `convertFontToZpl`, `renderFromGenerator`, `*Simple` variants). Returns `LabelaryResponse` (data + warnings).
- `ZplAssetService.loadFontBytes()`: low-level asset read.
- `ZplPreview` (`lib/widgets/zpl_preview.dart`): Labelary-backed preview, reactive via `didUpdateWidget`.
- `ZplNativePreview` + `ZplCanvasPainter` (`lib/src/preview/`): offline canvas renderer using `package:barcode`; painter is not exported.

### Barrel export
`lib/flutter_zpl_generator.dart` exports the public `lib/src/` files plus both preview widgets. `image_payload_builder.dart` and `zpl_canvas_painter.dart` stay internal.

## Testing
`mockito` + `@GenerateMocks` for the Labelary HTTP client; mocks generated via `build_runner`. `test/flutter_zpl_generator_test.dart` has a `normalizeZpl()` helper. Labelary integration tests skip when offline. Every command family should have its own `test/zpl_<family>_test.dart`.

## Conventions
- Keep files under ~200 lines; split emitters/estimators into separate files rather than growing one.
- Docs live in `doc/` (pub.dev convention). Plans live in `plans/`. Do not ship dev material: keep `.pubignore` in sync with `.gitignore`.
- Breaking output changes (even bug fixes that move commands) get a CHANGELOG entry.

## ZPL Domain Notes
- All coordinates/dimensions are in **dots**. Common density: 203 DPI (8 dpmm).
- Script structure: tilde control commands → `^XA` → config → fields → `^XZ`.
- `^FO` field origin, `^FD` field data, `^FS` field separator, `^A` font, `^FB` field block, `^BY` barcode defaults.
