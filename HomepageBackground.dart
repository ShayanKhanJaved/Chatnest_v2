
import 'package:flutter/material.dart';
import 'dart:math' as math;

class HomePageBackground extends StatefulWidget {
  const HomePageBackground({super.key});

  @override
  _HomePageBackgroundState createState() => _HomePageBackgroundState();
}

class _HomePageBackgroundState extends State<HomePageBackground> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<double> _animation1;
  late Animation<double> _animation2;

  @override
  void initState() {
    super.initState();

    // Slower animations for a more gentle effect
    _controller1 = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      duration: const Duration(seconds: 24),
      vsync: this,
    )..repeat(reverse: true);

    _animation1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller1,
        curve: Curves.easeInOut,
      ),
    );
    
    _animation2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller2,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_animation1, _animation2]),
        builder: (context, child) {
          return CustomPaint(
            isComplex: true,
            painter: OilBlobPainter(
              progress1: _animation1.value,
              progress2: _animation2.value,
            ),
            child: Container(),
          );
        },
      ),
    );
  }
}

class OilBlobPainter extends CustomPainter {
  final double progress1;
  final double progress2;
  final math.Random _rnd = math.Random(42); // Fixed seed for consistent pattern
  
  // Pre-generate noise points for better performance
  final List<double> _noiseFactors = [];
  
  OilBlobPainter({
    required this.progress1,
    required this.progress2,
  }) {
    if (_noiseFactors.isEmpty) {
      for (int i = 0; i < 50; i++) {
        _noiseFactors.add(_rnd.nextDouble());
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final backgroundPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw oil-like blobs with gentle animations
    drawOilBlobs(canvas, size);
  }

  void drawOilBlobs(Canvas canvas, Size size) {
    const blobCount = 12; // Fewer blobs for a less overwhelming effect
    
    // Create blobs with varying opacities and sizes
    for (int i = 0; i < blobCount; i++) {
      // Use animation values to create smooth movement
      final phase1 = 2 * math.pi * (i / blobCount + progress1);
      final phase2 = 2 * math.pi * ((i + 5) / blobCount + progress2);
      
      // Calculate center position with smooth movement
      final xCenter = size.width * (0.2 + 0.6 * (0.5 + 0.4 * math.sin(phase1)));
      final yCenter = size.height * (0.2 + 0.6 * (0.5 + 0.4 * math.cos(phase2)));
      
      // Vary blob size based on position and animation
      final blobBaseSize = math.min(size.width, size.height) * 0.15;
      final blobRadius = blobBaseSize * (0.5 + 0.5 * _noiseFactors[i % _noiseFactors.length]);
      
      // Create dark gray colors with low opacity for subtle effect
      final grayValue = 40 + (i * 8) % 50; // Darker grays
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = Color.fromRGBO(grayValue, grayValue, grayValue, 0.3); // Lower opacity
      
      // Apply slight blur for smoother edges
      if (i % 3 == 0) { // Only apply to some blobs for performance
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      }
      
      // Create organic blob shapes using paths with bezier curves
      final path = Path();
      const pointCount = 8;
      
      for (int j = 0; j <= pointCount; j++) {
        final angle = 2 * math.pi * j / pointCount;
        
        // Create gentle wobble effect
        final wobbleFactor = 1.0 + 0.2 * math.sin(angle * 3 + phase1 * 2);
        final radius = blobRadius * wobbleFactor;
        
        final x = xCenter + radius * math.cos(angle);
        final y = yCenter + radius * math.sin(angle);
        
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          // Use quadratic bezier curves for smoother shapes
          final prevAngle = 2 * math.pi * (j - 1) / pointCount;
          final midAngle = (prevAngle + angle) / 2;
          
          // Control point for the curve
          final ctrlRadius = blobRadius * (1.0 + 0.2 * math.sin(midAngle * 3 + phase1 * 2)) * 0.55;
          final ctrlX = xCenter + ctrlRadius * 2 * math.cos(midAngle);
          final ctrlY = yCenter + ctrlRadius * 2 * math.sin(midAngle);
          
          path.quadraticBezierTo(ctrlX, ctrlY, x, y);
        }
      }
      
      path.close();
      canvas.drawPath(path, paint);
      
      // Add some highlight blobs with lighter colors for contrast
      if (i % 4 == 0) {
        final highlightValue = 70 + (i * 5) % 60;
        final highlightPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Color.fromRGBO(highlightValue, highlightValue, highlightValue, 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        
        // Create smaller highlight blob inside the main blob
        final highlightPath = Path();
        final highlightRadius = blobRadius * 0.6;
        
        for (int j = 0; j <= pointCount; j++) {
          final angle = 2 * math.pi * j / pointCount;
          final wobble = 1.0 + 0.15 * math.sin(angle * 2 + phase2 * 3);
          final radius = highlightRadius * wobble;
          
          final x = xCenter + radius * math.cos(angle);
          final y = yCenter + radius * math.sin(angle);
          
          if (j == 0) {
            highlightPath.moveTo(x, y);
          } else {
            final prevAngle = 2 * math.pi * (j - 1) / pointCount;
            final midAngle = (prevAngle + angle) / 2;
            final ctrlRadius = highlightRadius * (1.0 + 0.15 * math.sin(midAngle * 2 + phase2 * 3)) * 0.55;
            
            final ctrlX = xCenter + ctrlRadius * 2 * math.cos(midAngle);
            final ctrlY = yCenter + ctrlRadius * 2 * math.sin(midAngle);
            
            highlightPath.quadraticBezierTo(ctrlX, ctrlY, x, y);
          }
        }
        
        highlightPath.close();
        canvas.drawPath(highlightPath, highlightPaint);
      }
    }
    
    // Add very subtle distant blobs in background
    for (int i = 0; i < 5; i++) {
      final farPhase1 = 2 * math.pi * (i / 5 + progress1 * 0.5);
      final farPhase2 = 2 * math.pi * ((i + 2) / 5 + progress2 * 0.5);
      
      final xCenter = size.width * (0.1 + 0.8 * _noiseFactors[(i * 2) % _noiseFactors.length]);
      final yCenter = size.height * (0.1 + 0.8 * _noiseFactors[(i * 2 + 1) % _noiseFactors.length]);
      
      final farBlobRadius = math.min(size.width, size.height) * 0.2;
      
      final farPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      
      canvas.drawCircle(
        Offset(xCenter, yCenter),
        farBlobRadius,
        farPaint
      );
    }
  }

  @override
  bool shouldRepaint(OilBlobPainter oldDelegate) {
    return oldDelegate.progress1 != progress1 || oldDelegate.progress2 != progress2;
  }
}