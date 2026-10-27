import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../shared/design_system/liga_widgets.dart';

/// Documentos legais que o responsável aceita ao criar a conta. O texto fica
/// em assets/legal, em Markdown simples, para servir também como a página
/// pública exigida pela Play Store.
enum LegalDocument {
  privacy('Política de Privacidade', 'assets/legal/politica_de_privacidade.md'),
  terms('Termos de Uso', 'assets/legal/termos_de_uso.md');

  const LegalDocument(this.title, this.assetPath);

  /// Versão gravada em `responsaveis.termos_versao` no aceite. Troque junto
  /// com o texto dos dois arquivos quando houver mudança importante.
  static const version = '2026-10-27';

  final String title;
  final String assetPath;
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  static Future<void> open(BuildContext context, LegalDocument document) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: LigaBackground(
        child: SafeArea(
          top: false,
          child: FutureBuilder<String>(
            future: rootBundle.loadString(document.assetPath),
            builder: (context, snapshot) {
              final text = snapshot.data;
              if (text == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [LigaPanel(child: _MarkdownText(text))],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Mostra o Markdown dos documentos legais: só títulos (`#`, `##`), itens de
/// lista (`- `) e parágrafos, que é tudo o que eles usam.
class _MarkdownText extends StatelessWidget {
  const _MarkdownText(this.markdown);

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final body = textTheme.bodyMedium?.copyWith(color: LigaColors.ink);
    final children = <Widget>[];

    for (final line in markdown.split('\n')) {
      final text = line.trim();
      if (text.isEmpty) continue;
      if (text.startsWith('# ')) {
        children.add(Text(text.substring(2), style: textTheme.titleLarge));
      } else if (text.startsWith('## ')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(text.substring(3), style: textTheme.titleMedium),
          ),
        );
      } else if (text.startsWith('- ')) {
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: body),
              Expanded(child: Text(text.substring(2), style: body)),
            ],
          ),
        );
      } else {
        children.add(Text(text, style: body));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final child in children)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
      ],
    );
  }
}
