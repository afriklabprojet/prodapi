import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

/// Barre de recherche premium avec animation et design glassmorphism
/// Avec historique de recherche et navigation vers AllProductsPage
class HomeSearchBar extends ConsumerStatefulWidget {
  final bool isDark;

  const HomeSearchBar({super.key, required this.isDark});

  @override
  ConsumerState<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends ConsumerState<HomeSearchBar>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showHistory = false;
  bool _isFocused = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        _showHistory = _focusNode.hasFocus && _controller.text.isEmpty;
      });
      if (_focusNode.hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
    _controller.addListener(() {
      setState(
        () => _showHistory = _focusNode.hasFocus && _controller.text.isEmpty,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _submitSearch(String? query) {
    final q = (query ?? _controller.text).trim();
    _focusNode.unfocus();
    if (q.length >= 2) {
      ref.read(searchHistoryServiceProvider).addSearch(q);
      context.goToProductsSearch(q);
      _controller.clear();
    } else {
      context.goToProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(searchHistoryServiceProvider).getHistory();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar avec animation
        ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: _isFocused ? 0.12 : 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isFocused
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppColors.border),
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : (widget.isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ]),
            ),
            child: Row(
              children: [
                // Icône de recherche animée
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isFocused
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un médicament...',
                      hintStyle: TextStyle(
                        color: widget.isDark
                            ? Colors.white54
                            : AppColors.textHint,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      color: widget.isDark
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _submitSearch(null),
                  ),
                ),
                // Bouton filtre avec badge
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.goToProducts(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.12),
                            AppColors.primaryLight.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recent searches dropdown avec animation
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _showHistory && history.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFF2C2C2C)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 16,
                                  color: widget.isDark
                                      ? Colors.grey[500]
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Recherches récentes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: widget.isDark
                                        ? Colors.grey[400]
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  ref
                                      .read(searchHistoryServiceProvider)
                                      .clearHistory();
                                  setState(() {});
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Effacer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...history.map(
                        (query) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _submitSearch(query),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: widget.isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.search_rounded,
                                      size: 16,
                                      color: widget.isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      query,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: widget.isDark
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        ref
                                            .read(searchHistoryServiceProvider)
                                            .removeSearch(query);
                                        setState(() {});
                                      },
                                      customBorder: const CircleBorder(),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
