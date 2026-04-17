import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/promo_item.dart';

/// Slider horizontal premium avec effet parallax pour les promotions
class PromoSlider extends StatefulWidget {
  final List<PromoItem> items;
  final PageController controller;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int>? onPageChanged;

  const PromoSlider({
    super.key,
    required this.items,
    required this.controller,
    required this.currentIndex,
    this.isDark = false,
    this.onPageChanged,
  });

  @override
  State<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<PromoSlider> {
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageScroll);
    super.dispose();
  }

  void _onPageScroll() {
    if (widget.controller.hasClients && widget.controller.page != null) {
      setState(() => _currentPageValue = widget.controller.page!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: widget.controller,
            itemCount: widget.items.length,
            onPageChanged: widget.onPageChanged,
            itemBuilder: (context, index) {
              final item = widget.items[index];

              // Calcul parallax
              final diff = index - _currentPageValue;
              final parallaxOffset = diff * 30;
              final scale = (1 - (diff.abs() * 0.15)).clamp(0.85, 1.0);
              final opacity = (1 - (diff.abs() * 0.4)).clamp(0.6, 1.0);

              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: _PromoCard(
                      item: item,
                      isDark: widget.isDark,
                      parallaxOffset: parallaxOffset,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Indicateurs de page premium
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (index) {
            final isActive = index == widget.currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      )
                    : null,
                color: isActive
                    ? null
                    : (widget.isDark ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromoItem item;
  final bool isDark;
  final double parallaxOffset;

  const _PromoCard({
    required this.item,
    required this.isDark,
    required this.parallaxOffset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = item.gradientColorValues;
    final gradient = colors != null && colors.length >= 2
        ? LinearGradient(
            colors: colors.map((c) => Color(c)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                (colors != null && colors.isNotEmpty
                        ? Color(colors.first)
                        : AppColors.primary)
                    .withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Motif décoratif avec parallax
            Positioned(
              right: -30 + parallaxOffset,
              top: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 40 + parallaxOffset,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  // Bouton d'action
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Découvrir',
                          style: TextStyle(
                            color: (colors != null && colors.isNotEmpty)
                                ? Color(colors.first)
                                : AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: (colors != null && colors.isNotEmpty)
                              ? Color(colors.first)
                              : AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
