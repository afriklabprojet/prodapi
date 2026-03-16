import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/simple_html_text.dart';

void main() {
  group('SimpleHtmlText widget', () {
    testWidgets('renders plain text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleHtmlText(data: 'Bonjour le monde'),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
      // RichText contains our text
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Bonjour le monde');
    });

    testWidgets('renders bold text with <b> tags', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleHtmlText(data: 'Prendre la direction <b>nord-est</b> sur <b>Boulevard</b>'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final spans = (richText.text as TextSpan).children!;

      // Should have: "Prendre la direction " + "nord-est" (bold) + " sur " + "Boulevard" (bold)
      expect(spans.length, 4);
      expect((spans[0] as TextSpan).text, 'Prendre la direction');
      expect((spans[1] as TextSpan).text, 'nord-est');
      expect((spans[1] as TextSpan).style!.fontWeight, FontWeight.bold);
      expect((spans[3] as TextSpan).text, 'Boulevard');
      expect((spans[3] as TextSpan).style!.fontWeight, FontWeight.bold);
    });

    testWidgets('renders <strong> same as <b>', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleHtmlText(data: 'Texte <strong>gras</strong> ici'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final spans = (richText.text as TextSpan).children!;
      expect(spans.length, 3);
      expect((spans[1] as TextSpan).text, 'gras');
      expect((spans[1] as TextSpan).style!.fontWeight, FontWeight.bold);
    });

    testWidgets('decodes HTML entities', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleHtmlText(data: 'A &amp; B &lt; C &gt; D &quot;E&quot; F&#39;G'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'A & B < C > D "E" F\'G');
    });

    testWidgets('strips unknown HTML tags', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleHtmlText(data: '<span class="test">Hello</span> <i>world</i>'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Hello world');
    });

    testWidgets('handles empty string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleHtmlText(data: ''),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('applies custom style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleHtmlText(
              data: 'Styled text',
              style: TextStyle(fontSize: 20, color: Colors.red),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final style = (richText.text as TextSpan).style!;
      expect(style.fontSize, 20);
      expect(style.color, Colors.red);
    });

    testWidgets('converts <br> to newlines', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleHtmlText(data: 'Ligne 1<br>Ligne 2<br/>Ligne 3'),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final text = richText.text.toPlainText();
      expect(text, contains('Ligne 1'));
      expect(text, contains('Ligne 2'));
      expect(text, contains('Ligne 3'));
    });

    testWidgets('handles Google Directions API typical output', (tester) async {
      const googleHtml =
          'Prendre la direction <b>nord-est</b> sur <b>Rue des Jardins</b><div style="font-size:0.9em">Continuer sur 200&nbsp;m</div>';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SimpleHtmlText(data: googleHtml),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final text = richText.text.toPlainText();
      expect(text, contains('nord-est'));
      expect(text, contains('Rue des Jardins'));
      expect(text, contains('200'));
    });
  });
}
