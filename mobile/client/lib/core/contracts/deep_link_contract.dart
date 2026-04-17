/// Contract pour la gestion des deep links
abstract class DeepLinkContract {
  /// Stream des deep links entrants (app au premier plan)
  Stream<DeepLinkData> get deepLinkStream;

  /// Initialiser le service
  Future<void> init();

  /// Dispose des ressources
  void dispose();

  /// Deep link initial (cold start)
  Future<DeepLinkData?> getInitialDeepLink();

  /// Traiter un deep link
  Future<DeepLinkResult> handleDeepLink(Uri uri);

  /// Stocker un deep link pour traitement après login
  Future<void> storePendingDeepLink(DeepLinkData data);

  /// Récupérer et effacer le deep link en attente
  Future<DeepLinkData?> consumePendingDeepLink();

  /// Vérifier si un deep link nécessite l'authentification
  bool requiresAuth(DeepLinkData data);
}

/// Données d'un deep link
class DeepLinkData {
  final Uri uri;
  final String path;
  final Map<String, String> queryParams;
  final Map<String, dynamic>? extra;
  final DateTime receivedAt;

  const DeepLinkData({
    required this.uri,
    required this.path,
    required this.queryParams,
    this.extra,
    required this.receivedAt,
  });

  factory DeepLinkData.fromUri(Uri uri) {
    return DeepLinkData(
      uri: uri,
      path: uri.path.isEmpty ? '/' : uri.path,
      queryParams: uri.queryParameters,
      receivedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uri': uri.toString(),
        'path': path,
        'queryParams': queryParams,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory DeepLinkData.fromJson(Map<String, dynamic> json) {
    return DeepLinkData(
      uri: Uri.parse(json['uri'] as String),
      path: json['path'] as String,
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      receivedAt: DateTime.parse(json['receivedAt'] as String),
    );
  }

  @override
  String toString() => 'DeepLinkData(path: $path, params: $queryParams)';
}

/// Résultat du traitement d'un deep link
enum DeepLinkResult {
  /// Navigué avec succès
  handled,

  /// Nécessite authentification, stocké pour après login
  requiresAuth,

  /// Route inconnue
  invalid,

  /// Erreur de traitement
  error,
}
