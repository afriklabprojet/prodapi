import 'package:flutter/material.dart';

/// Helper léger pour convertir du HTML simple en [TextSpan].
///
/// Remplace le package `flutter_html` (lourd, obsolète) pour des cas simples
/// comme les `html_instructions` de Google Directions API qui ne contiennent
/// que des balises `<b>`, `<div>`, `<br>`, etc.
///
/// Usage :
/// ```dart
/// SimpleHtmlText(
///   data: '<b>Nord</b> sur <b>Boulevard de la Paix</b>',
///   style: TextStyle(fontSize: 14),
/// )
/// ```
class SimpleHtmlText extends StatelessWidget {
  const SimpleHtmlText({
    super.key,
    required this.data,
    this.style,
    this.boldStyle,
  });

  /// Le texte HTML à afficher.
  final String data;

  /// Style de base du texte.
  final TextStyle? style;

  /// Style pour le texte en gras (balises <b>). Si null, utilise le style de base + bold.
  final TextStyle? boldStyle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = style ?? TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87);
    final defaultBoldStyle = boldStyle ??
        defaultStyle.copyWith(fontWeight: FontWeight.bold);

    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: _parseHtml(data, defaultStyle, defaultBoldStyle),
      ),
    );
  }

  /// Parse un HTML simple et retourne une liste de [TextSpan].
  ///
  /// Gère les balises : <b>, <strong>, <br>, <div>, <wbr>.
  /// Toutes les autres balises sont simplement supprimées.
  static List<TextSpan> _parseHtml(
    String html,
    TextStyle normalStyle,
    TextStyle boldStyle,
  ) {
    final spans = <TextSpan>[];

    // Remplacer <br>, <br/>, <div>, </div> par des sauts de ligne
    // Note : les entités HTML sont décodées APRÈS le stripping des tags
    // pour éviter que &lt;X&gt; devienne <X> et soit supprimé comme un tag.
    var processed = html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</?div[^>]*>'), '\n')
        .replaceAll(RegExp(r'<wbr\s*/?>'), '')
        .replaceAll('&nbsp;', ' ');

    // Parser les balises <b> et <strong>
    final pattern = RegExp(r'<(b|strong)>(.*?)</\1>', dotAll: true);
    int lastEnd = 0;

    for (final match in pattern.allMatches(processed)) {
      // Texte avant la balise bold
      if (match.start > lastEnd) {
        final text = _stripRemainingTags(processed.substring(lastEnd, match.start));
        if (text.isNotEmpty) {
          spans.add(TextSpan(text: text, style: normalStyle));
        }
      }

      // Texte en gras
      final boldText = _stripRemainingTags(match.group(2) ?? '');
      if (boldText.isNotEmpty) {
        spans.add(TextSpan(text: boldText, style: boldStyle));
      }

      lastEnd = match.end;
    }

    // Texte restant après le dernier match
    if (lastEnd < processed.length) {
      final text = _stripRemainingTags(processed.substring(lastEnd));
      if (text.isNotEmpty) {
        spans.add(TextSpan(text: text, style: normalStyle));
      }
    }

    // Nettoyer les sauts de ligne multiples
    return spans;
  }

  /// Supprime toutes les balises HTML restantes, puis décode les entités.
  static String _stripRemainingTags(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')  // Max 2 sauts de ligne consécutifs
        .trim();
  }
}
