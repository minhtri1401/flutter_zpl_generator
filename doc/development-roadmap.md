# Development Roadmap

## Project Vision

Create a comprehensive, production-ready Dart/Flutter package for ZPL (Zebra Programming Language) label generation with support for all major printer features, custom fonts, image rendering, and live preview capabilities.

## Release History

### v1.1.0 (March 2026) - Architecture Refactor
**Status:** Complete

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

### Phase 1: Bug Fixes & Stability (Q2 2026)
**Status:** In Progress

#### Objectives
- Monitor pub.dev user feedback and issue reports
- Fix any edge cases in layout system
- Improve ZPL generation for complex label scenarios
- Enhance documentation based on real-world usage

#### Key Tasks
- [ ] Review and address GitHub issues
- [ ] Performance profiling for large labels
- [ ] Test on all Flutter platforms (iOS, Android, Web, Desktop)
- [ ] Update README with v1.1.0 migration guide

#### Success Metrics
- Zero critical bugs
- Average issue resolution time < 3 days
- Documentation coverage > 90%

### Phase 2: Advanced Features (Q3 2026)
**Status:** Planned

#### Proposed Features

##### A. Advanced Layout System
- `ZplWrap` component for automatic line wrapping
- `ZplAlignedBox` for proportional spacing
- Nested layout validation and error reporting

##### B. Font Enhancements
- Support for font scaling/sizing alternatives
- Font fallback mechanism for missing fonts
- Pre-built font asset library (common fonts)

##### C. Image Processing
- Advanced image dithering options
- Image cropping and resizing before conversion
- Support for multi-color label images

##### D. Barcode Enhancements
- GS1-128 support
- PDF417 (2D barcode)
- Aztec code support
- Barcode validation before rendering

##### E. Labelary API Extensions
- Support for label rotation
- PDF output support
- Batch rendering optimization

#### Estimated Timeline
- Design & Specification: 2 weeks
- Implementation: 6 weeks
- Testing & Refinement: 2 weeks
- Release: End of Q3 2026

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
         │ Phase 1: Bug Fixes & Stability (Current)
         │
2026 Q3  │ Phase 2: Advanced Features (Planned)
         │
2026 Q4  │ Phase 3: Performance & Scale (Planned)
         │
2027 Q1  │ Phase 4: Ecosystem Integration (Planned)
         │
2027+    │ Long-Term Vision: Visual Designer, Templates, Analytics
```
