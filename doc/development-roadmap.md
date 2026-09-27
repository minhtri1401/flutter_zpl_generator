# Development Roadmap

## Project Vision

Create a comprehensive, production-ready Dart/Flutter package for ZPL (Zebra Programming Language) label generation with support for all major printer features, custom fonts, image rendering, and live preview capabilities.

## Release History

### v2.0.0 (September 2026) - Link-OS Compatibility
**Status:** Complete

#### Key Improvements
- **Two-Pass Build System:** Control commands (tilde-prefixed) emit BEFORE `^XA`, required on Link-OS mobile printers (ZQ620, etc.)
- **ZplControlCommand Base Class:** New abstract class for `~DG`, `~DY`, `~JI`, `~JQ`, `~HQ`, `~NC`, `~NR`, `~NT` commands
- **Image Refactor:** Replaced monolithic `ZplImage` with three-strategy system:
  - `ZplImageDownload` (control command, `~DG`)
  - `ZplImageRecall` (`^XG` for cached graphics)
  - `ZplImageInline` (`^GFA` for one-shot images)
- **Font System Simplification:** `ZplFontUpload` (control command) replaces `ZplFontAsset`; use `await ZplFontUpload.fromAsset(path, id)`
- **ZplGenerator Constructor Simplified:** Removed `fonts`, `assetService` parameters; add font uploads as commands directly
- **Removed:** `ZplFontAsset`, `ZplAssetService.getFontUploadCommand()` (now `loadFontBytes()`)

#### Breaking Changes
- `ZplGenerator` constructor no longer accepts `fonts` or `assetService` parameters
- `ZplImage` removed entirely (use `ZplImageDownload` + `ZplImageRecall` or `ZplImageInline`)
- `ZplFontAsset` removed (use `await ZplFontUpload.fromAsset()`)
- Code and comments must reflect `ZplConfiguration` passed to all `toZpl()` calls

### v1.1.0 (March 2026) - Architecture Refactor
**Status:** Archived (prerelease to v2.0)

#### Key Improvements
- **Configuration Decoupling:** Separated `ZplConfiguration` from command list, passed as context parameter to all commands
- **Method Signature Update:** `toZpl()` now accepts `ZplConfiguration context` for explicit configuration handling
- **Constructor Improvements:** `ZplGenerator` now uses named parameters for clarity
- **Layout System Refinement:**
  - Removed `ZplRow` (replaced by `ZplGridRow`)
  - Removed `_PositionWrapper` internal class
  - Added `maxWidth` property to leaf commands for layout integration
- **New Graphics Support:**
  - `ZplRaw` for direct ZPL injection
  - `ZplGraphicCircle` for circle drawing
  - `ZplGraphicEllipse` for ellipse drawing
  - `ZplGraphicDiagonalLine` for diagonal lines
- **Extended Barcode Types:**
  - `dataMatrix` (2D barcode, `^BX` command)
  - `ean13` (13-digit barcode, `^BE` command)
  - `upcA` (UPC-A barcode, `^BU` command)
- **Enhanced Text/Box Rendering:**
  - Added `reversePrint` property (white on black)
- **Widget Improvements:**
  - `ZplPreview` now implements `didUpdateWidget()` for reactive rendering

#### Breaking Changes
- `ZplCommand.toZpl()` signature changed (requires config context)
- `ZplGenerator` constructor uses named parameters
- `ZplConfiguration` no longer extends `ZplCommand`
- `ZplRow` removed (use `ZplGridRow`)
- Internal `_PositionWrapper` class removed

#### Testing
- All v1.0.0 tests updated to use v1.1.0 signatures
- New tests for graphics components and barcode types
- Test coverage maintained at >85%

### v1.0.0 (September 2025) - Production Release
**Status:** Archived

#### Features
- Command-based architecture with `ZplCommand` pattern
- Configuration as command in list
- Basic layout system (`ZplRow`, `ZplColumn`, `ZplTable`)
- Text, barcode (Code128, Code39, QR), box, separator, image rendering
- Custom TTF font support via `ZplFontAsset`
- Labelary API integration for rendering
- Flutter `ZplPreview` widget
- Published to pub.dev

## Current Phase

### v2.1.0 (Hygiene, Compression & Barcode Expansion) — September 2026
**Status:** Complete

#### Delivered Features
- **Z64/B64 Image Compression:** `ZplImageCompression.z64` (70–90% reduction) and `.b64` (base64) for `ZplImageDownload` and `ZplImageInline` with `compression:` parameter. Pure-Dart deflate (works on web).
- **Barcode Symbologies (13 total):** Added `pdf417`, `aztec`, `code93`, `interleaved2of5`, `ean8`, `upcE`, `gs1_128` to existing Code128, Code39, EAN13, UPC-A, QR, Data Matrix.
- **QR/PDF417 Parameters:** `magnification` (1–10), `qrErrorCorrection` (low/medium/quartile/high), `pdf417SecurityLevel`, `pdf417Columns`.
- **Stability:** Tilde-command ordering fixed (ZBI, host-query, network commands now emit before `^XA`). Flutter 3.47.5 pinned. `.pubignore` reduces package from 15MB to <1MB.
- **Testing & CI:** Comprehensive unit tests (125+), GitHub Actions `ci.yml` and `security-scan.yml` with Dependabot, OSV/SARIF scanning.
- **Documentation:** Updated all `doc/` and `CLAUDE.md` to v2.0 API.

### v2.2.0 (Advanced Features) — Q1 2027
**Status:** Planned (formerly listed as "Compression & Barcode Expansion", now delivered in v2.1.0)

##### C. Advanced Features (TBD)
- Label rotation support
- Advanced image dithering options
- Font fallback mechanism

## Next Candidates (Exploration Phase)

Short-listed features for future releases, prioritized by community feedback and use-case impact:

1. **QR mask selection parity with Zebra** — Implement Zebra's mask evaluation algorithm (ISO/IEC 18004:2015 §8.8.4) in `ZplNativePreview` to eliminate 1–2% edge-case mismatches in high-density QR codes and ensure 100% pixel-identical preview/firmware output.
2. **Physical-printer verification of Z64 ^GFA and preview calibration** — Validate Z64 compressed images on real Link-OS printer (ZQ620, ZM400); measure barcode/text/image output against physical hardcopy to finalize calibration constants and document any firmware-specific deviations.
3. **ZPL Parser / Decompiler** — Reverse-engineer existing ZPL labels into Flutter `ZplGenerator` calls. Enables label import/refactoring workflows.
4. **JSON Label Template Schema** — Define labels as JSON/YAML, auto-generate Flutter code or render via `ZplGenerator.fromJson()`. Unlock no-code / low-code design tools.
5. **Labelary PDF Export + Linter** — Render to PDF via Labelary; validate ZPL output (undefined fonts, bounds, performance warnings).
6. **End-to-End Example with flutter_zpl_printer** — Demonstrate full workflow: design in `flutter_zpl_generator`, print via `flutter_zpl_printer` plugin; test on real ZQ620 hardware.

### Phase 2: Advanced Features
**Status:** Archived (subsumed into v2.1.0)

### Phase 3: Performance & Scale (Q4 2026)
**Status:** Planned

#### Objectives
- Optimize for high-volume label generation
- Support for large label libraries
- Caching mechanisms for repeated elements
- Memory profiling for mobile platforms

#### Key Tasks
- [ ] Implement caching for frequently used commands
- [ ] Batch rendering API
- [ ] Memory usage profiling
- [ ] Performance benchmarking suite

### Phase 4: Ecosystem Integration (Q1 2027)
**Status:** Planned

#### Proposed Integrations
- Print server integration
- Database label template storage
- Design tool plugins (Figma, Adobe XD)
- Mobile app templates for common use cases

## Long-Term Vision (2027+)

### Planned Capabilities
1. **Visual Label Designer**: Web-based drag-and-drop interface
2. **Label Template Library**: Pre-built templates for common industries
3. **Advanced Analytics**: Label generation metrics and reporting
4. **Enterprise Features**: User management, audit logs, API key management
5. **Custom Printer Support**: Beyond Zebra (Honeywell, Datamax, etc.)

## Dependencies & Constraints

### Technical Dependencies
- **Dart SDK:** >= 2.17 (null safety required)
- **Flutter:** >= 3.0 (all platforms)
- **Labelary API:** External dependency for rendering preview
- **http:** HTTP client for API calls
- **image:** Image processing and conversion

### Constraints
- Labelary API has rate limits (typically 100 requests/min)
- Some ZPL features may not be supported by all printer models
- Custom fonts require TTF format (not all font formats supported)
- Image conversion quality depends on Labelary API implementation

## Success Metrics

### Quality Metrics
- Code coverage: >85%
- Documentation completeness: >90% of public API
- Test pass rate: 100%
- Zero critical bugs in production

### Adoption Metrics
- Monthly active downloads on pub.dev
- GitHub stars and community engagement
- Issue response time (target: < 3 days)
- Community contributions (PRs)

### Performance Metrics
- ZPL generation time: < 100ms for standard labels
- Labelary API response time: < 2s
- Memory usage: < 20MB for typical workflows
- Build size impact: < 500KB added to Flutter app

## Known Limitations

1. **Labelary API Dependency:** Label preview requires internet connectivity
2. **ZPL Feature Coverage:** Not all ZPL commands are wrapped (advanced users can use `ZplRaw`)
3. **Font Storage:** Custom fonts stored on printer E: drive (limited capacity)
4. **Image Quality:** Barcode/image rendering quality depends on Labelary API
5. **Platform-Specific Features:** Some printer features may not work on all platforms

## Backward Compatibility

### v1.1.0 Compatibility
- **Not backward compatible** with v1.0.0 (breaking API changes)
- Migration guide available in documentation
- v1.0.0 code requires updates to work with v1.1.0

### Future Versions
- Target: Maintain API stability in v2.x releases
- Major version increments only for significant refactors
- Deprecation warnings at least one minor version before removal

## Community & Contribution

### How to Contribute
1. Fork the repository on GitHub
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Write tests for new functionality
4. Follow code standards (see `code-standards.md`)
5. Submit a pull request with clear description

### Reporting Issues
- Use GitHub Issues for bugs and feature requests
- Include minimal reproducible example
- Attach ZPL output and expected vs actual rendering

### Code Review Process
1. Automated tests must pass (100% pass rate)
2. Code review by at least one maintainer
3. Documentation updates required
4. Changelog entry required

## Maintenance Schedule

- **Bug Fixes:** Released within 1 week of confirmation
- **Minor Features:** Released monthly
- **Major Releases:** Annual timeline (or as needed)
- **Security Updates:** Released immediately as patches

## Related Documentation

- [System Architecture](./system-architecture.md) - Component design and data flow
- [Code Standards](./code-standards.md) - Implementation guidelines and patterns
- [Project Changelog](./project-changelog.md) - Detailed change history
- [Labelary Docs Summary](../labelary_docs_summary.md) - ZPL API reference

## Timeline Summary

```
2025 Q3  │ v1.0.0 Release
         │
2026 Q1  │ Planning for v1.1.0
         │
2026 Q2  │ v1.1.0 Architecture Refactor ✓
         │
2026 Q3  │ v2.0.0 Link-OS Compatibility ✓
         │
2026 Q4  │ v2.1.0 Hygiene, Compression & Barcodes ✓ (2026-09-27)
         │ ├─ Z64/B64 compression (70–90% reduction)
         │ ├─ 7 barcode symbologies + QR/PDF417 params
         │ ├─ Flutter 3.47.5, .pubignore, tilde-cmd fixes
         │ ├─ GitHub Actions CI + security scanning
         │ └─ 125+ unit tests, comprehensive coverage
         │
2027 Q1  │ v2.2.0 Advanced Features (Planned)
         │ ├─ Label rotation & multi-color dithering
         │ ├─ Font fallback & scaling options
         │ └─ Performance optimizations
         │
2027 Q2+ │ Next Candidates: ZPL parser, JSON schema, PDF export, flutter_zpl_printer integration
```
