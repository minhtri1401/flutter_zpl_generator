import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import '../editor_controller.dart';
import '../model/label_document.dart';
import 'grid_overlay_painter.dart';
import 'ruler_overlay_painter.dart';
import 'selection_overlay_painter.dart';

/// Zoomable, pannable label canvas with selection, drag and resize.
///
/// Layers (bottom to top): [ZplNativePreview] of the document, dot grid,
/// selection overlay, gesture surface. Gestures are attached to the
/// transformed child, so their local positions are already in dots.
class ZplLabelCanvas extends StatefulWidget {
  final EditorController controller;

  /// Handle size in screen pixels (converted to dots using the zoom).
  final double handleScreenSize;
  final bool showGrid;

  /// Optional external zoom/pan controller (tests, fit-to-view buttons).
  final TransformationController? transformationController;

  /// Scale and centre the label to the viewport on first layout and whenever
  /// the label size changes. Off in tests that reason in raw dots.
  final bool fitOnLayout;

  /// Key of the gesture surface (tests target it directly).
  static const gestureKey = ValueKey('zpl-label-canvas-gestures');

  const ZplLabelCanvas({
    super.key,
    required this.controller,
    this.handleScreenSize = 12,
    this.showGrid = true,
    this.transformationController,
    this.fitOnLayout = true,
  });

  @override
  State<ZplLabelCanvas> createState() => _ZplLabelCanvasState();
}

class _ZplLabelCanvasState extends State<ZplLabelCanvas> {
  late final TransformationController _transform =
      widget.transformationController ?? TransformationController();
  bool get _ownsTransform => widget.transformationController == null;

  /// What an in-progress single-pointer drag is doing.
  _DragMode _mode = _DragMode.none;

  /// Multi-select toggle or a held shift key makes taps/drags additive.
  bool get _additive =>
      widget.controller.multiSelectMode ||
      HardwareKeyboard.instance.isShiftPressed;

  // The generator is rebuilt only when the document instance changes, so
  // zoom/selection repaints reuse the painter's per-command caches.
  LabelDocument? _lastDoc;
  ZplGenerator? _generator;

  Size? _fittedFor;
  Size? _viewport;

  double get _zoom => _transform.value.getMaxScaleOnAxis();
  double get _handleDots => widget.handleScreenSize / _zoom;

  /// Zoom so the whole label is visible with a small margin, centred.
  void fitToViewport() {
    final view = _viewport;
    if (view == null || view.isEmpty) return;
    final doc = widget.controller.document;
    final w = doc.width.toDouble();
    final h = doc.height.toDouble();
    final fitX = view.width / w;
    final fitY = view.height / h;
    final s = (fitX < fitY ? fitX : fitY) * 0.94;
    _transform.value = Matrix4.translationValues(
      (view.width - w * s) / 2,
      (view.height - h * s) / 2,
      0,
    )..multiply(Matrix4.diagonal3Values(s, s, s));
  }

  void _maybeFit(Size viewport, Size label) {
    _viewport = viewport;
    if (!widget.fitOnLayout || _fittedFor == label) return;
    _fittedFor = label;
    // Layout is in progress; apply the transform right after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) fitToViewport();
    });
  }

  ZplGenerator _generatorFor(LabelDocument doc) {
    if (!identical(doc, _lastDoc)) {
      _lastDoc = doc;
      _generator = doc.toGenerator();
    }
    return _generator!;
  }

  @override
  void dispose() {
    if (_ownsTransform) _transform.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d) {
    final c = widget.controller;
    if (c.hitTestHandle(d.localPosition, _handleDots) != null) return;
    final hit = c.hitTest(d.localPosition);
    if (hit == null) {
      if (!_additive) c.select(null);
    } else if (_additive) {
      c.toggleSelect(hit.id);
    } else {
      c.select(hit.id);
    }
  }

  void _onPanStart(DragStartDetails d) {
    final c = widget.controller;
    final additive = _additive;
    if (c.beginDrag(
      d.localPosition,
      handleSize: _handleDots,
      additive: additive,
    )) {
      _mode = _DragMode.element;
    } else if (additive) {
      _mode = _DragMode.marquee;
      c.beginMarquee(d.localPosition);
    } else {
      _mode = _DragMode.pan;
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    switch (_mode) {
      case _DragMode.pan:
        // Delta is in child (dot) space, so translate after the current scale.
        _transform.value = _transform.value.clone()
          ..translateByDouble(d.delta.dx, d.delta.dy, 0, 1);
      case _DragMode.marquee:
        widget.controller.updateMarquee(d.localPosition);
      case _DragMode.element:
        widget.controller.updateDrag(d.localPosition);
      case _DragMode.none:
        break;
    }
  }

  void _onPanEnd() {
    final c = widget.controller;
    switch (_mode) {
      case _DragMode.marquee:
        c.endMarquee(additive: HardwareKeyboard.instance.isShiftPressed);
      case _DragMode.element:
        c.endDrag();
      case _DragMode.pan || _DragMode.none:
        break;
    }
    _mode = _DragMode.none;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, _transform]),
      builder: (context, _) {
        final c = widget.controller;
        final doc = c.document;
        final size = Size(doc.width.toDouble(), doc.height.toDouble());
        return LayoutBuilder(
          builder: (context, constraints) {
            _maybeFit(constraints.biggest, size);
            return Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transform,
                  minScale: 0.05,
                  maxScale: 8,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  // Unconstrained so the label keeps its true dot size; the
                  // transform (see fitToViewport) brings it into view.
                  constrained: false,
                  // The gesture surface below wins single-pointer drags; empty-space
                  // drags pan manually in _onPanUpdate, trackpad/pinch stay native.
                  panEnabled: true,
                  child: SizedBox.fromSize(
                    size: size,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RepaintBoundary(
                          child: ColoredBox(
                            color: Colors.white,
                            child: ZplNativePreview(
                              generator: _generatorFor(doc),
                            ),
                          ),
                        ),
                        if (widget.showGrid)
                          IgnorePointer(
                            child: CustomPaint(
                              painter: GridOverlayPainter(step: c.snapGrid),
                            ),
                          ),
                        IgnorePointer(
                          child: CustomPaint(
                            painter: RulerOverlayPainter(
                              dpmm: c.dpmm,
                              units: c.units,
                              zoom: _zoom,
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: CustomPaint(
                            painter: SelectionOverlayPainter(
                              selection: c.selectedBounds,
                              others: [
                                for (final e in c.selectedElements)
                                  if (e.id != c.selectedId) e.bounds(c.config),
                              ],
                              showHandles: !c.hasMultipleSelected,
                              marquee: c.marquee,
                              handleSize: _handleDots,
                              guidesX: c.activeGuidesX,
                              guidesY: c.activeGuidesY,
                            ),
                          ),
                        ),
                        GestureDetector(
                          key: ZplLabelCanvas.gestureKey,
                          behavior: HitTestBehavior.opaque,
                          dragStartBehavior: DragStartBehavior.down,
                          onTapDown: _onTapDown,
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: (_) => _onPanEnd(),
                          onPanCancel: _onPanEnd,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: IconButton.filledTonal(
                    tooltip: 'Fit to screen',
                    icon: const Icon(Icons.fit_screen),
                    onPressed: fitToViewport,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

enum _DragMode { none, element, pan, marquee }
