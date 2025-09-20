import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

/// A widget that takes a [ZplGenerator] instance, renders it using the
/// Labelary API, and displays the resulting label image.
///
/// It handles loading, success, and error states automatically.
class ZplPreview extends StatefulWidget {
  /// The [ZplGenerator] containing the label commands to be rendered.
  final ZplGenerator generator;

  const ZplPreview({super.key, required this.generator});

  @override
  State<ZplPreview> createState() => _ZplPreviewState();
}

class _ZplPreviewState extends State<ZplPreview> {
  late Future<Uint8List> _renderFuture;

  @override
  void initState() {
    super.initState();
    _renderFuture = LabelaryService.renderFromGeneratorSimple(widget.generator);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _renderFuture,
      builder: (context, snapshot) {
        // While loading, show a progress indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // If an error occurred, display the error message
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Failed to render label:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        // If data is available, display the label image
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!);
        }
        // Default empty state
        return const Center(child: Text('No label data.'));
      },
    );
  }
}
