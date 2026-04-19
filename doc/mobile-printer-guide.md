# Mobile / Link-OS printers

This guide covers the ZPL shape expected by Zebra's mobile printers
(ZQ300, ZQ500, ZQ600 series — including ZQ620) running Link-OS firmware.
The package defaults are Link-OS-safe in 2.0; this document explains why
and lists the known firmware-level caveats.

## Required: `~DG` before `^XA`

Link-OS firmware enforces the "control commands outside a format" rule
strictly. If `~DG` (download graphic) or `~DY` (download font) lands
inside `^XA…^XZ`, one of two things happens:

- The format is accepted but the graphic is recalled before storage
  completes → blank label.
- The parser aborts on the mid-format tilde → nothing prints, no error.

2.0 places all `ZplControlCommand` subclasses before `^XA` automatically.
Use `ZplImageDownload` + `ZplImageRecall`. Do NOT use `ZplImageInline`
on mobile Link-OS — `^GFA` inside the format has been observed silently
failing on ZQ620 V85.20 at high dot coverage.

## Dithering choice for dense sources

Floyd-Steinberg with dense source images (≥ ~60% final black coverage)
can exceed the mobile printhead's thermal-protection budget on ZQ620.
Symptom: format accepted, buffer clears, no paper movement, no error.
This is firmware-level and outside the library's control.

Recommendation: for dense sources on mobile printers, pass
`ditheringAlgorithm: ZplDitheringAlgorithm.threshold`. The output is
visibly less smooth but prints reliably.

## Observed-working ZPL reference

For a 576×575-dot logo, the exact ZPL shape that printed reliably on
ZQ620 V85.20 in the field was:

```
~DGIMG,41400,72,
<hex rows separated by \n>
^XA
^PW576
^LL575
^MMT
^FO0,0
^XGIMG,1,1^FS
^XZ
```

The library's `ZplGenerator` produces this shape when given a
`ZplImageDownload` + `ZplImageRecall` pair with
`autoLabelLengthFromFirstImage: true` and a
`ZplConfiguration(printWidth: 576, printMode: ZplPrintMode.tearOff)`.

## Common silent-failure causes (not library bugs)

- Printer left in `^MM3` (Applicator) mode from a prior user — buffers
  every job without ejecting. Force tear-off via
  `ZplConfiguration(printMode: ZplPrintMode.tearOff)`.
- `^PW` mismatch with `ezpl.print_width` read from the printer —
  causes raster clipping. Read the printer's configured width via the
  Zebra SDK (outside this library's scope) and pass it to
  `ZplConfiguration.printWidth`.
- Firmware thermal protection (above).
