# Migrating from flutter_zpl_generator 1.x to 2.0

v2.0 fixes Link-OS mobile-printer compatibility. The public API for image
and font commands changed. Same `^XA…^XZ` output model, but tilde commands
(`~DG`, `~DY`) now emit BEFORE `^XA` as the Zebra ZPL II Programming Guide
recommends — required on ZQ620 and other Link-OS mobile printers.

## At a glance

| v1.x | v2.0 |
|---|---|
| `ZplImage(image: b)` | `ZplImageDownload(image: b) + ZplImageRecall(graphicName: 'IMG')` |
| `ZplImage(image: b, compression: acs)` | `ZplImageInline(image: b)` |
| `ZplFontAsset(assetPath: p, identifier: 'A')` | `await ZplFontUpload.fromAsset(p, 'A')` |
| `ZplGenerator(fonts: [f], commands: [...])` | `ZplGenerator(commands: [f, ...])` |
| `ZplGenerator(assetService: s, …)` | Parameter removed; pass a service to `ZplFontUpload.fromAsset` |
| `ZplText(customFont: ZplFontAsset(...))` | `ZplText(customFont: zplFontUpload)` |

## Step-by-step

### 1. One-shot compressed image (desktop / stationary firmware)

```dart
// v1.x
commands: [
  ZplImage(image: bytes, compression: ZplImageCompression.acs),
]

// v2.0
commands: [
  ZplImageInline(image: bytes),
]
```

### 2. Link-OS mobile (ZQ620 etc.)

```dart
// v2.0 — REQUIRED pattern on Link-OS mobile firmware
commands: [
  ZplImageDownload(image: bytes, graphicName: 'LOGO'),
  ZplImageRecall(graphicName: 'LOGO', x: 0, y: 0),
]
```

### 3. Auto label length (new in v2.0)

```dart
final zpl = await ZplGenerator(
  autoLabelLengthFromFirstImage: true,
  commands: [
    ZplImageDownload(image: bytes, targetWidth: 576),
    const ZplImageRecall(graphicName: 'IMG'),
  ],
).build();
// Emits ^LL<rendered image height> inside the format automatically.
// Explicit ZplConfiguration.labelLength still wins when set.
```

### 4. Custom fonts

```dart
// v1.x
final font = ZplFontAsset(
  assetPath: 'assets/fonts/Roboto.ttf',
  identifier: 'R',
);
final zpl = await ZplGenerator(
  fonts: [font],
  commands: [ZplText(customFont: font, text: 'Hi')],
).build();

// v2.0
final font = await ZplFontUpload.fromAsset(
  'assets/fonts/Roboto.ttf',
  'R',
);
final zpl = await ZplGenerator(
  commands: [
    font,
    ZplText(customFont: font, text: 'Hi'),
  ],
).build();
```

## Behavioural fixes

- `ZplImageDownload.width` / `.height` (and matching getters on
  `ZplImageInline`) now return POST-resize dimensions, including
  aspect-preserving scaling when only one axis is given. v1.x returned
  pre-resize dimensions, which broke `^LL` callers.
- `~DG` and `~DY` no longer appear inside `^XA…^XZ`. On strict Link-OS
  firmware this prevented printing; the v2.0 order is also Zebra's
  documented recommendation for all firmware.
- The ACS run-length encoder dropped the trailing `1` count after a
  multi-of-20 chunk (runs of 21, 41, …, 401). Fixed.

## Removed API

`ZplImage`, `ZplFontAsset`, `ZplGenerator.fonts`, `ZplGenerator.assetService`
and `ZplAssetService.getFontUploadCommand()` are deleted. Importing them
will fail to compile — that's how you find every call site that needs
migration.
