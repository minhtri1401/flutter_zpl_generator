# Project Overview & Product Development Requirements

## Project Overview

### Name
`flutter_zpl_generator`

### Purpose
A comprehensive Dart/Flutter package for generating ZPL (Zebra Programming Language) scripts for thermal label printing. Enables developers to programmatically create, configure, preview, and render labels on Zebra thermal printers with support for text, barcodes, images, custom fonts, and advanced layout controls.

### Key Value Propositions
1. **Developer-Friendly API**: Dart/Flutter idiomatic command-based architecture
2. **Comprehensive Feature Set**: Text, barcodes (6 types), images, graphics, layouts, custom fonts
3. **Live Preview**: Labelary API integration for visual verification before printing
4. **Cross-Platform**: Works on iOS, Android, Web, and Desktop Flutter platforms
5. **Production-Ready**: Extensive testing, published to pub.dev, semantic versioning

### Target Audience
- Flutter app developers
- Mobile/web applications requiring label printing
- E-commerce, logistics, healthcare, retail industries
- IoT and embedded systems developers

### Current Version
**v1.1.0.0** (March 2026) — Architecture refactor with configuration decoupling, extended features, and improved layout system

### Repository
- **URL**: https://github.com/orioninnovation/flutter_zpl_generator
- **Package**: https://pub.dev/packages/flutter_zpl_generator
- **License**: MIT

---

## Product Development Requirements (PDR)

### 1. Functional Requirements

#### 1.1 Command Generation

| Requirement | Status | Notes |
|---|---|---|
| Generate valid ZPL scripts from command objects | ✓ Complete | All `ZplCommand` implementations produce valid ZPL |
| Support text rendering with multiple fonts | ✓ Complete | Built-in fonts (A-H, 0) + custom TTF fonts |
| Support barcode rendering (6 types) | ✓ Complete | Code128, Code39, QR, DataMatrix, EAN13, UPC-A |
| Support box and graphic drawing | ✓ Complete | Boxes, circles, ellipses, diagonal lines, separators |
| Support image rendering as ZPL graphics | ✓ Complete | Converts images to hex-encoded ZPL graphics |
| Support raw ZPL injection | ✓ Complete | `ZplRaw` command for unsupported features |
| Wrap output in `^XA...^XZ` frame | ✓ Complete | Automatic frame wrapping |

#### 1.2 Configuration Management

| Requirement | Status | Notes |
|---|---|---|
| Support label dimensions (width, height) | ✓ Complete | In dots, with sensible defaults (812x1218) |
| Support print density settings | ✓ Complete | 6 preset densities (101-600 DPI) |
| Support darkness/contrast adjustment | ✓ Complete | 0-30 scale |
| Support character encoding options | ✓ Complete | UTF-8, ASCII, custom encodings |
| Decouple configuration from command list | ✓ Complete | v1.1.0 architecture |

#### 1.3 Layout System

| Requirement | Status | Notes |
|---|---|---|
| Support vertical layout (columns) | ✓ Complete | `ZplColumn` with spacing control |
| Support horizontal layout (grid rows) | ✓ Complete | `ZplGridRow` with column width definition |
| Support nested layouts | ✓ Complete | Containers can contain other containers |
| Support width-aware leaf commands | ✓ Complete | `maxWidth` property for responsive layouts |
| Support table layouts | ✓ Complete | `ZplTable` with advanced positioning |

#### 1.4 Font Support

| Requirement | Status | Notes |
|---|---|---|
| Support built-in ZPL fonts (A-H, 0) | ✓ Complete | Via `ZplFont` enum |
| Support custom TTF fonts | ✓ Complete | Via `ZplFontAsset` and `ZplAssetService` |
| Support font size/scaling | ✓ Complete | `fontHeight` and `fontWidth` properties |
| Upload fonts to printer E: drive | ✓ Complete | `~DY` command generation |
| Reference uploaded fonts in text | ✓ Complete | `fontAlias` (A-Z identifier) property |

#### 1.5 API Integration

| Requirement | Status | Notes |
|---|---|---|
| Labelary API integration for rendering | ✓ Complete | `LabelaryService` with multiple render methods |
| Image-to-ZPL conversion | ✓ Complete | `convertImageToGraphic()` method |
| Font-to-ZPL conversion | ✓ Complete | `convertFontToZpl()` method |
| Error handling and warnings | ✓ Complete | `LabelaryResponse` includes warnings |
| Rate limiting awareness | ✓ Complete | Documented in guides |

#### 1.6 Widget Integration

| Requirement | Status | Notes |
|---|---|---|
| Flutter `ZplPreview` widget | ✓ Complete | Renders labels via Labelary API |
| Loading state handling | ✓ Complete | `CircularProgressIndicator` shown |
| Error state handling | ✓ Complete | Error messages displayed |
| Reactive re-rendering | ✓ Complete | v1.1.0 `didUpdateWidget()` implementation |

### 2. Non-Functional Requirements

#### 2.1 Performance

| Requirement | Target | Status |
|---|---|---|
| ZPL generation time (standard label) | < 100ms | ✓ Met |
| Labelary API response time | < 2s | ✓ Met |
| Memory usage (typical workflow) | < 20MB | ✓ Met |
| App size impact | < 500KB | ✓ Met |
| Widget rendering time | < 500ms | ✓ Met |

#### 2.2 Code Quality

| Requirement | Target | Status |
|---|---|---|
| Test coverage | > 85% | ✓ Met |
| Code documentation | > 90% public API | ✓ Met |
| Cyclomatic complexity (per method) | < 10 | ✓ Met |
| File size (lines) | < 200 per file | ✓ Met |
| Linting compliance | 0 warnings | ✓ Met |

#### 2.3 Compatibility

| Requirement | Status | Details |
|---|---|---|
| Dart SDK minimum | ✓ 2.17+ | Null safety required |
| Flutter minimum | ✓ 3.0+ | All platforms supported |
| Platform support | ✓ All | iOS, Android, Web, Desktop |
| HTTP client compatibility | ✓ http 0.13+ | Via explicit dependency |
| Image package | ✓ image 3.0+ | For image processing |

#### 2.4 Reliability

| Requirement | Status | Notes |
|---|---|---|
| Error handling for missing assets | ✓ Complete | Clear error messages |
| Graceful degradation for invalid input | ✓ Complete | Validation and defaults |
| API failure handling | ✓ Complete | Timeout and error retry info |
| State consistency | ✓ Complete | Immutable command objects |
| No memory leaks | ✓ Complete | Proper resource cleanup |

### 3. Security Requirements

| Requirement | Status | Implementation |
|---|---|---|
| No hardcoded credentials | ✓ Complete | API keys passed via parameters |
| No sensitive data logging | ✓ Complete | Debug output excludes fonts/content |
| Input validation | ✓ Complete | All external inputs validated |
| Asset path validation | ✓ Complete | Verify font assets exist/readable |
| HTTPS only for APIs | ✓ Complete | Labelary API via HTTPS |

### 4. Documentation Requirements

| Document | Location | Status |
|---|---|---|
| System Architecture | `docs/system-architecture.md` | ✓ Complete |
| Code Standards | `docs/code-standards.md` | ✓ Complete |
| Development Roadmap | `docs/development-roadmap.md` | ✓ Complete |
| Project Changelog | `docs/project-changelog.md` | ✓ Complete |
| API Documentation | Inline + `docs/` | ✓ Complete |
| README | `README.md` | ✓ Complete |
| CLAUDE.md | `CLAUDE.md` | ✓ Updated v1.1.0 |
| Example App | `example/` | ✓ Complete |

### 5. Testing Requirements

| Category | Requirement | Status |
|---|---|---|
| Unit Tests | All commands tested | ✓ Complete |
| Integration Tests | Generator + API | ✓ Complete |
| Widget Tests | ZplPreview widget | ✓ Complete |
| Mock Data | HTTP client mocked | ✓ Complete |
| Coverage | > 85% code coverage | ✓ Complete |
| Platform Testing | iOS, Android, Web | ✓ Complete |

---

## Success Criteria

### v1.1.0 Release Criteria (March 2026)
- [x] Architecture refactored with configuration decoupling
- [x] All breaking changes documented
- [x] Migration guide provided
- [x] New features implemented (graphics, barcode types, reversePrint)
- [x] Test coverage maintained > 85%
- [x] Documentation updated for v1.1.0
- [x] No regressions from v1.0.0
- [x] Published to pub.dev

### Ongoing Success Metrics
1. **Adoption**: 500+ monthly downloads on pub.dev
2. **Quality**: 0 critical bugs, < 3 day issue resolution
3. **Coverage**: > 85% test coverage, > 90% doc coverage
4. **Community**: Active GitHub issues/PRs, helpful discussions
5. **Performance**: < 100ms ZPL generation, < 2s API response

---

## Constraints & Dependencies

### Technical Constraints
- Labelary API is external dependency (requires internet for preview)
- ZPL feature coverage limited to common features (advanced users can use `ZplRaw`)
- Custom fonts limited to TTF format
- Image quality dependent on Labelary API implementation
- Printer-specific features may vary by model

### External Dependencies
- **Dart SDK**: >= 2.17 (null safety)
- **Flutter**: >= 3.0 (all platforms)
- **http**: >= 0.13.0 (HTTP requests)
- **image**: >= 3.0.0 (image processing)
- **Labelary API**: External REST API (rate limits apply)

### Resource Constraints
- Development team size: Small (1-2 core maintainers)
- Testing infrastructure: GitHub Actions CI/CD
- Documentation: Markdown in repository
- Distribution: pub.dev package registry

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Labelary API changes | Medium | High | Monitor API status, maintain compatibility |
| Printer feature drift | Medium | Medium | Document supported features, guide users |
| Performance regression | Low | Medium | Continuous performance testing |
| Security vulnerabilities | Low | High | Input validation, dependency audits |
| Community adoption lag | Low | Medium | Active promotion, good documentation |

---

## Version Timeline

| Version | Date | Status | Key Features |
|---|---|---|---|
| v1.0.0.0 | Sep 2025 | Archived | Command pattern, basic layout, Labelary API |
| v1.1.0.0 | Mar 2026 | Current | Refactored architecture, graphics, extended barcodes |
| v2.1.0 | Q2 2026 | Planned | Bug fixes, stability improvements |
| v3.0.0 | 2027+ | Planned | Advanced features, visual designer integration |

---

## Related Documentation

- [System Architecture](./system-architecture.md) — Component design and data flow
- [Code Standards](./code-standards.md) — Implementation patterns and guidelines
- [Development Roadmap](./development-roadmap.md) — Future features and timeline
- [Project Changelog](./project-changelog.md) — Detailed change history
- [CLAUDE.md](../CLAUDE.md) — Development guidance for LLM assistants

---

## Acceptance Criteria for Contributions

When contributing features or fixes, ensure:

1. **Functional**: Feature works as specified, no regressions
2. **Tested**: Unit + integration tests included, > 85% coverage maintained
3. **Documented**: Code comments, docstrings, README updates
4. **Styled**: Follow `code-standards.md` guidelines
5. **Performance**: No performance degradation (< 100ms ZPL generation)
6. **Backward Compatible**: No breaking changes in minor versions
7. **Reviewed**: Code review approval required before merge

---

## Contact & Support

- **Issues**: GitHub Issues on repository
- **Discussions**: GitHub Discussions for questions
- **Contributing**: See CONTRIBUTING.md
- **Maintainers**: Primary contact via GitHub repository
