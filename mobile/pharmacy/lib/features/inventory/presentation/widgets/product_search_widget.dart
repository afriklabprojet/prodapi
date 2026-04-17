import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/inventory_di_providers.dart';

/// Widget de recherche de produits avancée avec filtres et suggestions
class ProductSearchWidget extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic> product)? onProductSelected;
  final bool showFilters;
  final bool autoFocus;

  const ProductSearchWidget({
    super.key,
    this.onProductSelected,
    this.showFilters = true,
    this.autoFocus = false,
  });

  @override
  ConsumerState<ProductSearchWidget> createState() =>
      _ProductSearchWidgetState();
}

class _ProductSearchWidgetState extends ConsumerState<ProductSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isSearching = false;
  bool _showFilters = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _searchHistory = [];
  List<String> _suggestions = [];

  // Filtres
  String? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 50000);
  bool _inStockOnly = false;
  String _sortBy = 'name';

  final List<String> _categories = [
    'Tous',
    'Médicaments',
    'Parapharmacie',
    'Hygiène',
    'Bébé & Maman',
    'Nutrition',
    'Matériel médical',
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  static const String _searchHistoryKey = 'product_search_history';

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_searchHistoryKey);
      if (history != null && history.isNotEmpty) {
        setState(() {
          _searchHistory = history;
        });
      } else {
        // Default suggestions for new users
        setState(() {
          _searchHistory = [
            'Paracétamol',
            'Doliprane 1000mg',
            'Vitamine C',
            'Masques chirurgicaux',
          ];
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading search history: $e');
      setState(() {
        _searchHistory = [];
      });
    }
  }

  Future<void> _saveSearchToHistory(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, _searchHistory);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving search history: $e');
    }
  }

  Future<void> _clearSearchHistory() async {
    setState(() {
      _searchHistory = [];
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      if (kDebugMode) debugPrint('Error clearing search history: $e');
    }
  }

  Future<void> _removeFromHistory(String query) async {
    setState(() {
      _searchHistory.remove(query);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, _searchHistory);
    } catch (e) {
      if (kDebugMode) debugPrint('Error removing from search history: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    // Generate suggestions from search terms
    _generateSuggestions(query);

    // Debounce search to avoid excessive API calls
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _searchController.text == query) {
        _performSearch(query);
      }
    });
  }

  void _generateSuggestions(String query) {
    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _suggestions = _searchHistory
          .where((h) => h.toLowerCase().contains(lowercaseQuery))
          .take(3)
          .toList();
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final result = await ref.read(inventoryRepositoryProvider).getProducts();

      if (!mounted || _searchController.text != query) return;

      result.fold(
        (failure) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        },
        (products) {
          final lowQuery = query.toLowerCase();
          // Map ProductEntity to Map<String, dynamic> and filter by query
          var filtered = products
              .where((p) {
                return p.name.toLowerCase().contains(lowQuery) ||
                    (p.activeIngredient?.toLowerCase().contains(lowQuery) ??
                        false) ||
                    p.category.toLowerCase().contains(lowQuery);
              })
              .map(
                (p) => <String, dynamic>{
                  'id': p.id.toString(),
                  'name': p.name,
                  'genericName': p.activeIngredient ?? '',
                  'category': p.category,
                  'price': p.price.toInt(),
                  'stock': p.stockQuantity,
                  'image': p.imageUrl,
                  'barcode': p.barcode ?? '',
                },
              )
              .toList();

          // Apply filters
          filtered = filtered.where((p) {
            if (_selectedCategory != null &&
                _selectedCategory != 'Tous' &&
                p['category'] != _selectedCategory) {
              return false;
            }
            if (_inStockOnly && (p['stock'] as int) == 0) {
              return false;
            }
            final price = p['price'] as int;
            if (price < _priceRange.start || price > _priceRange.end) {
              return false;
            }
            return true;
          }).toList();

          // Sort
          filtered.sort((a, b) {
            switch (_sortBy) {
              case 'price_asc':
                return (a['price'] as int).compareTo(b['price'] as int);
              case 'price_desc':
                return (b['price'] as int).compareTo(a['price'] as int);
              case 'stock':
                return (b['stock'] as int).compareTo(a['stock'] as int);
              default:
                return (a['name'] as String).compareTo(b['name'] as String);
            }
          });

          setState(() {
            _searchResults = filtered;
            _isSearching = false;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _suggestions = [];
      _isSearching = false;
    });
  }

  void _selectProduct(Map<String, dynamic> product) {
    _saveSearchToHistory(product['name'] as String);
    widget.onProductSelected?.call(product);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        _buildSearchBar(),

        // Filters (if enabled)
        if (widget.showFilters && _showFilters) ...[
          const SizedBox(height: 12),
          _buildFilters(),
        ],

        // Suggestions or Results
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _clearSearch,
                          tooltip: 'Effacer la recherche',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          if (widget.showFilters) ...[
            const SizedBox(width: 12),
            _FilterButton(
              isActive: _showFilters || _hasActiveFilters,
              onTap: () => setState(() => _showFilters = !_showFilters),
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasActiveFilters {
    return _selectedCategory != null && _selectedCategory != 'Tous' ||
        _inStockOnly ||
        _priceRange != const RangeValues(0, 50000) ||
        _sortBy != 'name';
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = cat == (_selectedCategory ?? 'Tous');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? cat : null;
                      });
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(_searchController.text);
                      }
                    },
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Additional filters
          Row(
            children: [
              // In stock only toggle
              Expanded(
                child: _FilterToggle(
                  label: 'En stock uniquement',
                  value: _inStockOnly,
                  onChanged: (value) {
                    setState(() => _inStockOnly = value);
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Sort dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, size: 20),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Nom')),
                    DropdownMenuItem(value: 'price_asc', child: Text('Prix ↑')),
                    DropdownMenuItem(
                      value: 'price_desc',
                      child: Text('Prix ↓'),
                    ),
                    DropdownMenuItem(value: 'stock', child: Text('Stock')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                      if (_searchController.text.isNotEmpty) {
                        _performSearch(_searchController.text);
                      }
                    }
                  },
                ),
              ),
            ],
          ),

          // Price range slider
          const SizedBox(height: 12),
          Text(
            'Prix: ${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} FCFA',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 50000,
            divisions: 50,
            activeColor: Theme.of(context).colorScheme.primary,
            labels: RangeLabels(
              '${_priceRange.start.toInt()}',
              '${_priceRange.end.toInt()}',
            ),
            onChanged: (values) {
              setState(() => _priceRange = values);
            },
            onChangeEnd: (values) {
              if (_searchController.text.isNotEmpty) {
                _performSearch(_searchController.text);
              }
            },
          ),

          // Reset filters button
          if (_hasActiveFilters)
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réinitialiser les filtres'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _inStockOnly = false;
      _priceRange = const RangeValues(0, 50000);
      _sortBy = 'name';
    });
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  Widget _buildContent() {
    // Show loading
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show search history when empty
    if (_searchController.text.isEmpty) {
      return _buildSearchHistory();
    }

    // Show suggestions
    if (_suggestions.isNotEmpty && _searchResults.isEmpty) {
      return _buildSuggestions();
    }

    // Show results
    if (_searchResults.isNotEmpty) {
      return _buildResults();
    }

    // No results
    return _buildNoResults();
  }

  Widget _buildSearchHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.history, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Recherches récentes',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            if (_searchHistory.isNotEmpty)
              TextButton(
                onPressed: _clearSearchHistory,
                child: const Text('Effacer'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...ListTile.divideTiles(
          context: context,
          tiles: _searchHistory.map(
            (query) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(query),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    onPressed: () => _removeFromHistory(query),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Retirer de l\'historique',
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.north_west, size: 16, color: Colors.grey),
                ],
              ),
              onTap: () {
                _searchController.text = query;
                _onSearchChanged(query);
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Popular searches
        Row(
          children: [
            Icon(Icons.trending_up, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Recherches populaires',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                    'Paracétamol',
                    'Ibuprofène',
                    'Vitamine D',
                    'Masques',
                    'Gel hydroalcoolique',
                  ]
                  .map(
                    (tag) => ActionChip(
                      label: Text(tag),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      onPressed: () {
                        _searchController.text = tag;
                        _onSearchChanged(tag);
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search),
          title: _highlightMatch(suggestion, _searchController.text),
          trailing: const Icon(Icons.north_west, size: 16),
          onTap: () {
            _searchController.text = suggestion;
            _onSearchChanged(suggestion);
          },
        );
      },
    );
  }

  Widget _highlightMatch(String text, String query) {
    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final startIndex = lowercaseText.indexOf(lowercaseQuery);

    if (startIndex == -1) {
      return Text(text);
    }

    final endIndex = startIndex + query.length;
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87),
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_searchResults.length} résultat(s)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final product = _searchResults[index - 1];
        return _ProductSearchCard(
          product: product,
          onTap: () => _selectProduct(product),
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat pour "${_searchController.text}"',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres termes ou vérifiez l\'orthographe',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// Filter button
class _FilterButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.tune,
          color: isActive ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }
}

/// Filter toggle
class _FilterToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: value
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
          color: value
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: value
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product search result card
class _ProductSearchCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _ProductSearchCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stock = product['stock'] as int;
    final isInStock = stock > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product['image'] as String,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                        ),
                      )
                    : const Icon(Icons.medication, color: Colors.grey),
              ),
              const SizedBox(width: 12),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['genericName'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${product['price']} FCFA',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isInStock
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isInStock ? 'Stock: $stock' : 'Rupture',
                            style: TextStyle(
                              fontSize: 11,
                              color: isInStock ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action icon
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page de recherche complète
class ProductSearchPage extends StatelessWidget {
  const ProductSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher un produit'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ProductSearchWidget(
        autoFocus: true,
        onProductSelected: (product) {
          Navigator.of(context).pop(product);
        },
      ),
    );
  }
}
