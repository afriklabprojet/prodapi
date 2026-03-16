/// Animations et transitions pour l'application DR-PHARMA
/// 
/// Ce module fournit :
/// - Des widgets d'animation réutilisables (fade, slide, scale)
/// - Des transitions de page personnalisées
/// - Des micro-interactions (boutons animés, checkmarks, loading)
/// 
/// Exemple d'utilisation :
/// ```dart
/// // Widget avec animation fade-in
/// Text('Hello').fadeIn(delay: Duration(milliseconds: 100));
/// 
/// // Navigation avec transition slide
/// Navigator.of(context).pushFadeSlide(MyPage());
/// 
/// // Liste avec animation cascade
/// StaggeredListAnimation(children: items.map((i) => ItemWidget(i)).toList());
/// ```

library;

export 'app_animations.dart';
export 'page_transitions.dart';
