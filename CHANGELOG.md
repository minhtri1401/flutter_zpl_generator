# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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