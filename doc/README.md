# Documentation Index

Complete documentation for the `flutter_zpl_generator` package v2.0.0.

## Quick Navigation

### For First-Time Users
1. Start with [Project Overview & PDR](./project-overview-pdr.md) for project goals and requirements
2. Read [System Architecture](./system-architecture.md) to understand the design
3. Check the examples in the [repository](../example/) to see code in action

### For Developers
1. Review [Code Standards](./code-standards.md) for implementation patterns
2. Study [System Architecture](./system-architecture.md) for design details
3. Reference [Codebase Summary](./codebase-summary.md) for module details

### For Maintainers
1. Check [Development Roadmap](./development-roadmap.md) for feature planning
2. Reference [Project Changelog](./project-changelog.md) for version history
3. Review [Project Overview & PDR](./project-overview-pdr.md) for requirements tracking

### For Migration from v1.0
1. Read [Project Changelog](./project-changelog.md) "Upgrade Guide" section
2. Follow the step-by-step migration instructions
3. Use the migration checklist to ensure nothing is missed

---

## Documentation Files

### [System Architecture](./system-architecture.md)
**Complete architectural overview of the library**

- Command pattern explanation
- Key components (generator, configuration, layout system, services)
- Font system workflow
- Data flow diagrams
- Module organization
- ZPL domain knowledge reference

**Best for**: Understanding how the library works, architectural decisions, component interactions.

---

### [Code Standards](./code-standards.md)
**Implementation guidelines and patterns**

- File naming and organization
- Code quality principles
- Documentation standards
- Constructor patterns
- Command implementation template (5-step)
- Error handling guidelines
- Testing patterns with examples
- Configuration and layout patterns
- v2.0 breaking changes checklist

**Best for**: Writing code in the library, contributing features, following project conventions.

---

### [System Architecture](./system-architecture.md)
**Detailed architecture documentation**

- Overview of command pattern and design
- ZplCommand base class explanation
- Configuration context passing (v2.0)
- Layout system containers
- Leaf command types (text, barcode, graphics)
- Service layer (Labelary API, asset conversion)
- Font system architecture
- Complete module organization
- Version history

**Best for**: Deep understanding of architecture, extending the library, architectural discussions.

---

### [Development Roadmap](./development-roadmap.md)
**Feature roadmap and project timeline**

- Project vision statement
- Release history (v1.0, v2.0)
- Current phase status
- Planned phases (Q2-Q4 2026, 2027+)
- Proposed advanced features
- Long-term vision
- Dependencies and constraints
- Success metrics
- Community contribution guidelines

**Best for**: Understanding future direction, planning features, project planning.

---

### [Project Changelog](./project-changelog.md)
**Detailed change history and upgrade guide**

- v2.0.0 release notes
  - Breaking changes with impact assessment
  - New features and enhancements
  - Bug fixes and improvements
- v1.0.0 archive
- **Upgrade Guide (v1.0 → v2.0)**
  - Step-by-step migration instructions
  - Code examples for each change
  - Complete migration checklist
- Future roadmap reference
- Version numbering scheme

**Best for**: Understanding what changed, migrating from v1.0, version history.

---

### [Project Overview & PDR](./project-overview-pdr.md)
**Product Development Requirements and specifications**

- Project overview and value propositions
- Target audience
- Functional requirements matrix
- Non-functional requirements (performance, quality, compatibility)
- Security requirements
- Testing requirements
- Documentation requirements
- Success criteria
- Constraints and dependencies
- Risk assessment
- Version timeline
- Acceptance criteria for contributions

**Best for**: Understanding requirements, project goals, contribution guidelines, success metrics.

---

### [Codebase Summary](./codebase-summary.md)
**Comprehensive codebase overview and reference**

- Project statistics
- Complete directory structure
- 13+ core modules with detailed descriptions
  - Properties, methods, key behaviors
  - Workflow explanations
- Widget layer overview
- Barrel export documentation
- Architectural patterns
- Code organization principles
- Dependencies (direct and transitive)
- Testing infrastructure
- Performance characteristics
- Security considerations
- Extension points for developers
- Maintenance notes

**Best for**: Module reference, code review, understanding implementations, extending the library.

---

## v2.0 Key Changes

### Major Breaking Changes

1. **`ZplCommand.toZpl()` signature** — Now requires `ZplConfiguration context`
2. **`ZplGenerator` constructor** — Uses named parameters, config decoupled
3. **`ZplConfiguration` decoupling** — No longer a command in the list
4. **`ZplRow` removal** — Use `ZplGridRow` instead
5. **`_PositionWrapper` removal** — Internal refactoring

### New Features

1. **Graphics components** — `ZplRaw`, `ZplGraphicCircle`, `ZplGraphicEllipse`, `ZplGraphicDiagonalLine`
2. **Extended barcodes** — `dataMatrix`, `ean13`, `upcA`
3. **Enhanced text/box** — `reversePrint` property (white on black)
4. **Reactive widgets** — `ZplPreview` implements `didUpdateWidget()`
5. **Layout improvements** — `maxWidth` property on leaf commands

**See [Project Changelog](./project-changelog.md) for complete migration guide.**

---

## Related Files

### Project Root
- [CLAUDE.md](../CLAUDE.md) — Development guidance (updated for v2.0)
- [README.md](../README.md) — User guide and quick start
- [CHANGELOG.md](../CHANGELOG.md) — Version history
- [pubspec.yaml](../pubspec.yaml) — Package metadata

### Example App
- [example/lib/main.dart](../example/lib/main.dart) — Working example application

### Tests
- [test/flutter_zpl_generator_test.dart](../test/flutter_zpl_generator_test.dart) — Test suite

---

## Search Guide

### By Topic

| Topic | Files |
|---|---|
| Architecture & Design | system-architecture.md, codebase-summary.md |
| Implementation Patterns | code-standards.md, codebase-summary.md |
| Features & Capabilities | project-overview-pdr.md, development-roadmap.md |
| Changes & Migration | project-changelog.md |
| Project Management | development-roadmap.md, project-overview-pdr.md |
| Module Details | codebase-summary.md |
| Requirements & Success | project-overview-pdr.md |

### By Use Case

| Use Case | Start With | Then Read |
|---|---|---|
| First-time learning | project-overview-pdr.md | system-architecture.md |
| Writing code | code-standards.md | codebase-summary.md |
| Contributing | project-overview-pdr.md | code-standards.md |
| Migrating from v1.0 | project-changelog.md | code-standards.md |
| Maintaining project | development-roadmap.md | project-overview-pdr.md |
| Understanding architecture | system-architecture.md | codebase-summary.md |
| Planning features | development-roadmap.md | project-overview-pdr.md |

---

## Key Concepts

### Command Pattern
All ZPL elements extend `ZplCommand` base class. See [System Architecture](./system-architecture.md) for details.

### Configuration Context
v2.0 passes `ZplConfiguration` to all commands via `toZpl(context)` parameter. See [System Architecture](./system-architecture.md#configuration-decoupling) and [Code Standards](./code-standards.md#configuration-pattern).

### Layout System
Containers (`ZplGridRow`, `ZplColumn`) manage child positioning and set `maxWidth` constraints. See [System Architecture](./system-architecture.md#layout-system) and [Code Standards](./code-standards.md#layout-container-pattern).

### Service Layer
External operations abstracted via `LabelaryService` (API) and `ZplAssetService` (assets). See [Codebase Summary](./codebase-summary.md#services).

### Immutability
All command properties are `final`. See [Code Standards](./code-standards.md#type-safety).

---

## Code Examples

Quick reference for common patterns:

### Basic Label Generation
```dart
final config = const ZplConfiguration(
  printWidth: 812,
  printHeight: 1218,
);

final generator = ZplGenerator(
  config: config,
  commands: [
    ZplText(x: 10, y: 10, text: 'Hello World'),
    ZplBarcode(x: 10, y: 50, data: '123456', height: 50),
  ],
);

final zpl = await generator.build();
```

### Command Implementation (v2.0)
```dart
@override
String toZpl(ZplConfiguration context) {
  final effectiveWidth = maxWidth ?? context.printWidth ?? 812;
  return '^FO$x,0^A0N,30^FB${effectiveWidth},1,0,L^FD$text^FS';
}
```

### Layout with Grid
```dart
final grid = ZplGridRow(
  columnWidths: [200, 300, 200],
  children: [
    ZplText(text: 'Col1'),
    ZplText(text: 'Col2'),
    ZplText(text: 'Col3'),
  ],
);
```

See [Code Standards](./code-standards.md) for complete examples and patterns.

---

## FAQ

**Q: Where do I start if I'm new to this library?**
A: Read [Project Overview & PDR](./project-overview-pdr.md) first, then [System Architecture](./system-architecture.md).

**Q: How do I migrate from v1.0 to v2.0?**
A: Follow the 5-step guide in [Project Changelog](./project-changelog.md#upgrade-guide).

**Q: What are the breaking changes in v2.0?**
A: See the "Breaking Changes" section in [Project Changelog](./project-changelog.md).

**Q: How do I implement a custom command?**
A: Follow the 5-step pattern in [Code Standards](./code-standards.md#command-implementation-pattern).

**Q: What's the performance target for ZPL generation?**
A: < 100ms for standard labels. See [Codebase Summary](./codebase-summary.md#performance-characteristics).

**Q: How do I extend the library?**
A: See "Extension Points" in [Codebase Summary](./codebase-summary.md#extension-points).

**Q: What are the testing requirements?**
A: See [Project Overview & PDR](./project-overview-pdr.md#5-testing-requirements).

---

## Maintenance

### Documentation Updates
- Update [Project Changelog](./project-changelog.md) with each release
- Update [Development Roadmap](./development-roadmap.md) quarterly
- Keep [Code Standards](./code-standards.md) synchronized with actual patterns
- Review [System Architecture](./system-architecture.md) for any major refactors

### File Organization
- Keep documentation files in `/docs/` directory
- Use `.md` extension for all markdown files
- Maintain consistent formatting and cross-references
- Update README.md when adding new documentation

---

## Version Information

- **Current Version**: 2.0.0 (March 2026)
- **Documentation Version**: 2.0.0
- **Last Updated**: March 22, 2026
- **Status**: Complete and verified

---

## Contact & Support

- **Issues**: Report on GitHub Issues
- **Discussions**: GitHub Discussions for questions
- **Contributing**: See project-overview-pdr.md Acceptance Criteria
- **Feedback**: Comments welcome in documentation PRs

---

## Document Map

```
docs/
├── README.md                    (This file - Navigation index)
├── system-architecture.md       (Architecture & design)
├── code-standards.md            (Implementation guidelines)
├── codebase-summary.md          (Module reference)
├── development-roadmap.md       (Feature roadmap)
├── project-changelog.md         (Version history + migration)
└── project-overview-pdr.md      (Requirements & specs)
```

---

**Happy developing! For questions, refer to the appropriate documentation file or check the example app.**
