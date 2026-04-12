import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// Métrique héro animée - première chose visible sur le dashboard.
/// Affiche LE chiffre important du moment avec animation de comptage.
class HeroMetricCard extends StatefulWidget {
  final String label;
  final double value;
  final String suffix;
  final List<double>? trendData;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  const HeroMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.suffix = ' FCFA',
    this.trendData,
    this.icon = Icons.trending_up_rounded,
    this.accentColor,
    this.onTap,
  });

  @override
  State<HeroMetricCard> createState() => _HeroMetricCardState();
}

class _HeroMetricCardState extends State<HeroMetricCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _countAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _countAnimation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Démarrer l'animation après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void didUpdateWidget(HeroMetricCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _countAnimation = Tween<double>(
        begin: oldWidget.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
        ),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primary = widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Semantics(
        label: '${widget.label}: ${_formatNumber(widget.value)}${widget.suffix}',
        button: widget.onTap != null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap != null ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            } : null,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          primary.withValues(alpha: 0.3),
                          primaryContainer.withValues(alpha: 0.2),
                        ]
                      : [
                          primary,
                          primary.withValues(alpha: 0.8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: icône + label
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (widget.onTap != null)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Valeur animée
                AnimatedBuilder(
                  animation: _countAnimation,
                  builder: (context, _) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatNumber(_countAnimation.value),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                          child: Text(
                            widget.suffix,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // Mini sparkline trend
                if (widget.trendData != null && widget.trendData!.length >= 2) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: _MiniSparkline(
                      data: widget.trendData!,
                      color: Colors.white.withValues(alpha: 0.6),
                      fillColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini graphique sparkline pour visualiser le trend.
class _MiniSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final Color fillColor;

  const _MiniSparkline({
    required this.data,
    required this.color,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        data: data,
        lineColor: color,
        fillColor: fillColor,
      ),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    if (range == 0) return;

    final path = Path();
    final fillPath = Path();
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = (data[i] - minValue) / range;
      final y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}

/// Provider pour la métrique héro du jour.
/// Sélectionne automatiquement la métrique la plus pertinente.
class HeroMetricData {
  final String label;
  final double value;
  final String suffix;
  final IconData icon;
  final List<double>? weekTrend;

  const HeroMetricData({
    required this.label,
    required this.value,
    this.suffix = ' FCFA',
    this.icon = Icons.trending_up_rounded,
    this.weekTrend,
  });
}
