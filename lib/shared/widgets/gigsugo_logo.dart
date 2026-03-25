import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class GigSugoLogo extends StatelessWidget {
  final double size;
  final bool isDarkOnLight;

  const GigSugoLogo({
    super.key,
    this.size = 24,
    this.isDarkOnLight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.amber,
            AppColors.copper,
          ],
        ),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.6, size * 0.6),
          painter: _GigSugoLogoPainter(
            isDarkOnLight: isDarkOnLight,
          ),
        ),
      ),
    );
  }
}

class _GigSugoLogoPainter extends CustomPainter {
  final bool isDarkOnLight;

  _GigSugoLogoPainter({required this.isDarkOnLight});

  @override
  void paint(Canvas canvas, Size size) {
    final barColor = AppColors.bg;
    final strokeWidth = size.width / 25;
    final spacing = size.width / 7;
    final startX = (size.width - spacing * 5) / 2;
    
    // Define bar positions and heights
    final bars = [
      {'x': startX, 'height': size.height * 0.4, 'opacity': 0.45},
      {'x': startX + spacing, 'height': size.height * 0.6, 'opacity': 0.70},
      {'x': startX + spacing * 2, 'height': size.height * 0.8, 'opacity': 1.0, 'thick': true}, // Center bar
      {'x': startX + spacing * 3, 'height': size.height * 0.6, 'opacity': 0.70},
      {'x': startX + spacing * 4, 'height': size.height * 0.4, 'opacity': 0.45},
    ];

    for (final bar in bars) {
      final paint = Paint()
        ..color = barColor.withOpacity(bar['opacity'] as double)
        ..strokeWidth = bar['thick'] == true ? strokeWidth * 1.5 : strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final x = bar['x'] as double;
      final height = bar['height'] as double;
      final startY = (size.height - height) / 2;

      canvas.drawLine(
        Offset(x, startY + height),
        Offset(x, startY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
