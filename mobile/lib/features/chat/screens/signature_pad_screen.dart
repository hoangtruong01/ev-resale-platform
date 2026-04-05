import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/theme/app_theme.dart';

/// A full-screen digital signature pad.
/// Returns a base64-encoded PNG string when the user confirms.
class SignaturePadScreen extends StatefulWidget {
  const SignaturePadScreen({super.key});

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  final List<List<Offset?>> _strokes = [];
  List<Offset?> _currentStroke = [];
  final GlobalKey _repaintKey = GlobalKey();
  bool _hasDrawn = false;

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _currentStroke = [d.localPosition];
      _hasDrawn = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _currentStroke.add(d.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _strokes.add(List.from(_currentStroke));
      _currentStroke = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _hasDrawn = false;
    });
  }

  Future<void> _confirm() async {
    if (!_hasDrawn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng ký tên trước khi xác nhận.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final base64Str = base64Encode(pngBytes);

      if (mounted) {
        Navigator.pop(context, base64Str);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xử lý chữ ký: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey900,
      appBar: AppBar(
        title: const Text('Ký tên xác nhận'),
        backgroundColor: AppTheme.grey900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
            label: const Text('Xóa',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: AppTheme.grey900,
            child: const Text(
              'Vui lòng ký tên của bạn trong khung trắng bên dưới. Chữ ký sẽ được gắn vào hợp đồng.',
              style: TextStyle(color: Colors.white60, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

          // Canvas
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: _SignaturePainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom hint
          if (!_hasDrawn)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '[ Vuốt để ký tên ]',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: ElevatedButton.icon(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor:
                    _hasDrawn ? AppTheme.primaryGreen : AppTheme.grey600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 20),
              label: const Text(
                'Xác nhận chữ ký',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset?>> strokes;
  final List<Offset?> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  final _paint = Paint()
    ..color = const Color(0xFF0D2E1A)
    ..strokeWidth = 2.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw guide line
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.65),
      Offset(size.width * 0.9, size.height * 0.65),
      Paint()
        ..color = AppTheme.grey200
        ..strokeWidth = 1,
    );

    void drawStroke(List<Offset?> stroke) {
      for (int i = 0; i < stroke.length - 1; i++) {
        final a = stroke[i];
        final b = stroke[i + 1];
        if (a != null && b != null) {
          canvas.drawLine(a, b, _paint);
        }
      }
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
