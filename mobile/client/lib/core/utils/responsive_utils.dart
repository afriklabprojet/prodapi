import 'package:flutter/material.dart';

/// Breakpoints pour différentes tailles d'écran
class Breakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;
}

/// Types d'écran
enum ScreenType {
  mobile,
  tablet,
  desktop,
  desktopLarge,
}

/// Orientation de l'écran
enum ScreenOrientation {
  portrait,
  landscape,
}

/// Classe utilitaire pour le responsive design
class ResponsiveUtils {
  final BuildContext context;
  
  ResponsiveUtils(this.context);
  
  /// Obtenir la taille de l'écran
  Size get screenSize => MediaQuery.of(context).size;
  
  /// Largeur de l'écran
  double get width => screenSize.width;
  
  /// Hauteur de l'écran
  double get height => screenSize.height;
  
  /// Ratio de l'écran
  double get aspectRatio => width / height;
  
  /// Densité de pixels
  double get pixelRatio => MediaQuery.of(context).devicePixelRatio;
  
  /// Scale du texte
  double get textScale => MediaQuery.of(context).textScaler.scale(1.0);
  
  /// Safe area padding
  EdgeInsets get safePadding => MediaQuery.of(context).padding;
  
  /// View insets (keyboard, etc.)
  EdgeInsets get viewInsets => MediaQuery.of(context).viewInsets;
  
  /// Type d'écran actuel
  ScreenType get screenType {
    if (width < Breakpoints.mobile) return ScreenType.mobile;
    if (width < Breakpoints.tablet) return ScreenType.mobile;
    if (width < Breakpoints.desktop) return ScreenType.tablet;
    if (width < Breakpoints.desktopLarge) return ScreenType.desktop;
    return ScreenType.desktopLarge;
  }
  
  /// Orientation de l'écran
  ScreenOrientation get orientation {
    return width > height ? ScreenOrientation.landscape : ScreenOrientation.portrait;
  }
  
  /// Est-ce un mobile ?
  bool get isMobile => screenType == ScreenType.mobile;
  
  /// Est-ce une tablette ?
  bool get isTablet => screenType == ScreenType.tablet;
  
  /// Est-ce un desktop ?
  bool get isDesktop => screenType == ScreenType.desktop || screenType == ScreenType.desktopLarge;
  
  /// Est-ce en mode portrait ?
  bool get isPortrait => orientation == ScreenOrientation.portrait;
  
  /// Est-ce en mode paysage ?
  bool get isLandscape => orientation == ScreenOrientation.landscape;
  
  /// Pourcentage de la largeur
  double wp(double percentage) => width * (percentage / 100);
  
  /// Pourcentage de la hauteur
  double hp(double percentage) => height * (percentage / 100);
  
  /// Valeur adaptative basée sur la largeur (base 375 - iPhone SE)
  double sw(double value) => value * (width / 375);
  
  /// Valeur adaptative basée sur la hauteur (base 812 - iPhone X)
  double sh(double value) => value * (height / 812);
  
  /// Taille de police adaptative
  double sp(double fontSize) {
    final scaleFactor = width / 375;
    return fontSize * scaleFactor.clamp(0.8, 1.3);
  }
  
  /// Padding horizontal adaptatif
  double get horizontalPadding {
    if (isMobile) return 16;
    if (isTablet) return 24;
    return 32;
  }
  
  /// Padding vertical adaptatif
  double get verticalPadding {
    if (isMobile) return 16;
    if (isTablet) return 20;
    return 24;
  }
  
  /// Largeur maximale du contenu
  double get maxContentWidth {
    if (isMobile) return width;
    if (isTablet) return 600;
    return 800;
  }
  
  /// Nombre de colonnes pour une grille
  int get gridColumns {
    if (isMobile) return isLandscape ? 3 : 2;
    if (isTablet) return isLandscape ? 4 : 3;
    return isLandscape ? 6 : 4;
  }
  
  /// Espacement de grille
  double get gridSpacing {
    if (isMobile) return 12;
    if (isTablet) return 16;
    return 20;
  }
  
  /// Taille d'icône adaptative
  double iconSize([double base = 24]) {
    if (isMobile) return base;
    if (isTablet) return base * 1.2;
    return base * 1.4;
  }
  
  /// Rayon de bordure adaptatif
  double borderRadius([double base = 12]) {
    if (isMobile) return base;
    if (isTablet) return base * 1.1;
    return base * 1.2;
  }
  
  /// Valeur conditionnelle selon le type d'écran
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
      case ScreenType.desktopLarge:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Extension pour accéder facilement aux utilitaires responsive
extension ResponsiveExtension on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
  
  /// Raccourcis pratiques
  bool get isMobile => responsive.isMobile;
  bool get isTablet => responsive.isTablet;
  bool get isDesktop => responsive.isDesktop;
  bool get isPortrait => responsive.isPortrait;
  bool get isLandscape => responsive.isLandscape;
  
  double wp(double percentage) => responsive.wp(percentage);
  double hp(double percentage) => responsive.hp(percentage);
  double sw(double value) => responsive.sw(value);
  double sh(double value) => responsive.sh(value);
  double sp(double fontSize) => responsive.sp(fontSize);
}

/// Widget responsive qui s'adapte selon la taille d'écran
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveUtils responsive) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, ResponsiveUtils(context));
      },
    );
  }
}

/// Widget qui affiche différents widgets selon le type d'écran
class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    final r = ResponsiveUtils(context);
    
    switch (r.screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
      case ScreenType.desktopLarge:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Container avec largeur maximale centrée
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final r = ResponsiveUtils(context);
    final effectiveMaxWidth = maxWidth ?? r.maxContentWidth;
    
    return Container(
      color: backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: Padding(
            padding: padding ?? EdgeInsets.symmetric(
              horizontal: r.horizontalPadding,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Scaffold responsive avec gestion automatique du layout
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final double? maxContentWidth;
  
  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.maxContentWidth,
  });
  
  @override
  Widget build(BuildContext context) {
    final r = ResponsiveUtils(context);
    final effectiveMaxWidth = maxContentWidth ?? r.maxContentWidth;
    
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// Grille responsive
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? columns;
  final double? spacing;
  final double? runSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columns,
    this.spacing,
    this.runSpacing,
    this.childAspectRatio = 1.0,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    final r = ResponsiveUtils(context);
    final effectiveColumns = columns ?? r.gridColumns;
    final effectiveSpacing = spacing ?? r.gridSpacing;
    
    return GridView.builder(
      padding: padding ?? EdgeInsets.all(r.horizontalPadding),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: effectiveColumns,
        crossAxisSpacing: effectiveSpacing,
        mainAxisSpacing: runSpacing ?? effectiveSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Row ou Column selon l'orientation
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool? forceRow;
  final double spacing;
  
  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.forceRow,
    this.spacing = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    final r = ResponsiveUtils(context);
    final useRow = forceRow ?? (r.isLandscape || r.isTablet || r.isDesktop);
    
    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(
          width: useRow ? spacing : 0,
          height: useRow ? 0 : spacing,
        ));
      }
    }
    
    if (useRow) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: spacedChildren,
      );
    }
    
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: spacedChildren,
    );
  }
}

/// Padding responsive
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? horizontal;
  final double? vertical;
  
  const ResponsivePadding({
    super.key,
    required this.child,
    this.padding,
    this.horizontal,
    this.vertical,
  });
  
  @override
  Widget build(BuildContext context) {
    final r = ResponsiveUtils(context);
    
    final effectivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: horizontal ?? r.horizontalPadding,
      vertical: vertical ?? 0,
    );
    
    return Padding(
      padding: effectivePadding,
      child: child,
    );
  }
}

/// SizedBox responsive
class ResponsiveSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;
  
  const ResponsiveSizedBox({
    super.key,
    this.width,
    this.height,
    this.child,
  });
  
  /// Espace horizontal adaptatif
  const ResponsiveSizedBox.horizontal(double size, {super.key})
      : width = size,
        height = null,
        child = null;
  
  /// Espace vertical adaptatif
  const ResponsiveSizedBox.vertical(double size, {super.key})
      : width = null,
        height = size,
        child = null;
  
  @override
  Widget build(BuildContext context) {
    final r = ResponsiveUtils(context);
    
    return SizedBox(
      width: width != null ? r.sw(width!) : null,
      height: height != null ? r.sh(height!) : null,
      child: child,
    );
  }
}
