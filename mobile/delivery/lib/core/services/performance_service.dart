import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service d'optimisation des performances
/// =======================================

/// Cache LRU (Least Recently Used) générique
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  LRUCache({this.maxSize = 100});

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  void put(K key, V value) {
    _cache.remove(key);
    _cache[key] = value;
    
    while (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  void remove(K key) => _cache.remove(key);
  
  void clear() => _cache.clear();
  
  bool containsKey(K key) => _cache.containsKey(key);
  
  int get length => _cache.length;
  
  Iterable<K> get keys => _cache.keys;
  
  Iterable<V> get values => _cache.values;
}

/// Cache pour les données API
class ApiDataCache {
  static final ApiDataCache _instance = ApiDataCache._internal();
  factory ApiDataCache() => _instance;
  ApiDataCache._internal();

  final LRUCache<String, _CacheEntry> _cache = LRUCache(maxSize: 200);
  
  /// Récupérer une donnée du cache
  T? get<T>(String key) {
    final entry = _cache.get(key);
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data as T?;
  }

  /// Stocker une donnée dans le cache
  void put<T>(String key, T data, {Duration ttl = const Duration(minutes: 5)}) {
    _cache.put(key, _CacheEntry(
      data: data,
      expiry: DateTime.now().add(ttl),
    ));
  }

  /// Vérifier si une clé existe et n'est pas expirée
  bool has(String key) {
    final entry = _cache.get(key);
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  /// Invalider une entrée
  void invalidate(String key) => _cache.remove(key);

  /// Invalider toutes les entrées commençant par un préfixe
  void invalidatePrefix(String prefix) {
    final keysToRemove = _cache.keys
        .where((k) => k.startsWith(prefix))
        .toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// Vider tout le cache
  void clear() => _cache.clear();
  
  /// Taille actuelle du cache
  int get size => _cache.length;
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Debouncer pour éviter les appels trop fréquents
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}

/// Throttler pour limiter la fréquence des appels
class Throttler {
  final Duration duration;
  DateTime? _lastRun;
  Timer? _timer;
  VoidCallback? _pendingAction;

  Throttler({this.duration = const Duration(milliseconds: 100)});

  void run(VoidCallback action) {
    final now = DateTime.now();
    
    if (_lastRun == null || now.difference(_lastRun!) >= duration) {
      _lastRun = now;
      action();
    } else {
      _pendingAction = action;
      _timer?.cancel();
      _timer = Timer(
        duration - now.difference(_lastRun!),
        () {
          _lastRun = DateTime.now();
          _pendingAction?.call();
          _pendingAction = null;
        },
      );
    }
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pendingAction = null;
  }

  void dispose() {
    cancel();
  }
}

/// Gestionnaire de mémoire
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final List<WeakReference<Object>> _trackedObjects = [];
  Timer? _cleanupTimer;

  /// Démarrer le nettoyage automatique
  void startAutoCleanup({Duration interval = const Duration(minutes: 5)}) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(interval, (_) => cleanup());
  }

  /// Arrêter le nettoyage automatique
  void stopAutoCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Traquer un objet pour le nettoyage
  void track(Object object) {
    _trackedObjects.add(WeakReference(object));
  }

  /// Nettoyer les références mortes et le cache
  void cleanup() {
    // Nettoyer les références mortes
    _trackedObjects.removeWhere((ref) => ref.target == null);
    
    // Nettoyer le cache API
    ApiDataCache().clear();
    
    // Suggérer un GC (pas garanti)
    if (kDebugMode) {
      debugPrint('🧹 Memory cleanup done. Tracked objects: ${_trackedObjects.length}');
    }
  }

  /// Forcer un nettoyage agressif
  void forceCleanup() {
    _trackedObjects.clear();
    ApiDataCache().clear();
    
    if (kDebugMode) {
      debugPrint('🧹 Force cleanup done');
    }
  }
}

/// Extension pour les listes avec pagination
extension PaginatedList<T> on List<T> {
  /// Récupérer une page de la liste
  List<T> getPage(int page, {int pageSize = 20}) {
    final start = page * pageSize;
    if (start >= length) return [];
    final end = (start + pageSize).clamp(0, length);
    return sublist(start, end);
  }

  /// Nombre total de pages
  int pageCount({int pageSize = 20}) {
    return (length / pageSize).ceil();
  }
}

/// Mixin pour le lazy loading dans les widgets
mixin LazyLoadingMixin<T extends StatefulWidget> on State<T> {
  final ScrollController _lazyScrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  ScrollController get lazyScrollController => _lazyScrollController;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;

  @override
  void initState() {
    super.initState();
    _lazyScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _lazyScrollController.removeListener(_onScroll);
    _lazyScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_lazyScrollController.position.pixels >=
        _lazyScrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        loadMore();
      }
    }
  }

  /// Override this method to implement load more logic
  Future<void> loadMore();

  /// Call this when starting to load more
  void setLoadingMore(bool loading) {
    if (mounted) {
      setState(() {
        _isLoadingMore = loading;
      });
    }
  }

  /// Call this when there's no more data
  void setHasMoreData(bool hasMore) {
    if (mounted) {
      setState(() {
        _hasMoreData = hasMore;
      });
    }
  }
}

/// Widget pour lazy loading d'images
class LazyImage extends StatefulWidget {
  final String? imageUrl;
  final Widget placeholder;
  final Widget errorWidget;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Duration fadeInDuration;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.placeholder = const SizedBox.shrink(),
    this.errorWidget = const Icon(Icons.broken_image),
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return widget.errorWidget;
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: widget.fadeInDuration,
      placeholder: (context, url) => widget.placeholder,
      errorWidget: (context, url, error) => widget.errorWidget,
    );
  }
}

/// Widget optimisé pour les grandes listes
class OptimizedListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? separator;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final bool isLoading;
  final int? cacheExtent;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.separator,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.emptyWidget,
    this.loadingWidget,
    this.isLoading = false,
    this.cacheExtent,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: separator != null ? items.length * 2 - 1 : items.length,
      cacheExtent: cacheExtent?.toDouble() ?? 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        if (separator != null && index.isOdd) {
          return separator!;
        }
        final itemIndex = separator != null ? index ~/ 2 : index;
        return RepaintBoundary(
          child: itemBuilder(context, items[itemIndex], itemIndex),
        );
      },
    );
  }
}

/// Provider pour le cache API
final apiCacheProvider = Provider<ApiDataCache>((ref) {
  return ApiDataCache();
});

/// Provider pour le gestionnaire de mémoire
final memoryManagerProvider = Provider<MemoryManager>((ref) {
  final manager = MemoryManager();
  manager.startAutoCleanup();
  ref.onDispose(() => manager.stopAutoCleanup());
  return manager;
});

/// Extension pour utiliser le cache facilement avec Riverpod
extension CachedAsyncValue<T> on AsyncValue<T> {
  /// Retourne la dernière valeur connue même pendant le chargement
  T? get valueOrPrevious {
    return whenOrNull(
      data: (data) => data,
      loading: () => null,
      error: (_, _) => null,
    );
  }
}
