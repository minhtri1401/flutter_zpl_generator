# Flutter ZPL Generator Example

This example demonstrates the basic usage of the Flutter ZPL Generator package.

## Features Demonstrated

- Basic label creation with text and barcodes
- Live preview using the `ZplPreview` widget
- Clean, modern UI with Material Design

## Running the Example

1. Ensure you have Flutter installed
2. Clone this repository
3. Navigate to the example directory:
   ```bash
   cd example
   ```
4. Get dependencies:
   ```bash
   flutter pub get
   ```
5. Run the example:
   ```bash
   flutter run
   ```

## What You'll See

The example creates a simple product label with:
- A title "This is a preview!"
- A Code 128 barcode with data "12345"
- Live preview rendered using the Labelary API

## Additional Examples

Check out these files for more advanced usage:
- `zpl_generation_demo.dart` - Command-line ZPL generation examples
- `postman_api_examples.dart` - Direct API usage examples

### Image Dithering Modes
You can test the three different image dithering algorithms in the **Images** tab. Here is how you use each mode natively:

```dart
// 1. Floyd-Steinberg (Default) - Smoothly disperses dots for natural gradients
ZplImage(
  x: 20, y: 20,
  image: myImageBytes,
  ditheringAlgorithm: ZplDitheringAlgorithm.floydSteinberg,
)

// 2. Atkinson - High contrast dot pattern without washing out (excellent for 203 DPI)
ZplImage(
  x: 20, y: 150,
  image: myImageBytes,
  ditheringAlgorithm: ZplDitheringAlgorithm.atkinson,
)

// 3. Threshold - Hard black & white clipping (Legacy behavior)
ZplImage(
  x: 20, y: 280,
  image: myImageBytes,
  ditheringAlgorithm: ZplDitheringAlgorithm.threshold,
)
```

## Learn More

For comprehensive documentation, visit:
- [Package Documentation](https://pub.dev/packages/flutter_zpl_generator)
- [ZPL Programming Guide](https://www.zebra.com/us/en/support-downloads/knowledge-articles/ait/zpl-programming-guide.html)
- [Labelary API Documentation](https://labelary.com/service.html)