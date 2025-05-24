import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snippet Library App', // Título da aplicação
      theme: ThemeData(
        primarySwatch: Colors.blue, // Tema padrão
      ),
      home: SnippetListPage(), // Nossa nova tela principal
    );
  }
}

class SnippetListPage extends StatefulWidget {
  const SnippetListPage({super.key});

  @override
  SnippetListPageState createState() => SnippetListPageState();
}

class SnippetListPageState extends State<SnippetListPage> {
  // Controlador para o campo de texto onde o usuário inserirá o código
  final TextEditingController _codeController = TextEditingController();
  // Lista para armazenar os snippets (inicialmente vazia)
  List<SnippetCardData> snippets = [];
  String _selectedCategory = 'Geral'; // Default category
  final List<String> _categories = ['Geral', 'Widgets', 'Layout']; // Example categories

  @override
  void dispose() {
    // Lembre-se de descartar o controlador quando o widget for removido
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Snippet Library'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Área para inserir o código
            TextField(
              controller: _codeController,
              maxLines: 10, // Permite múltiplas linhas para o código
              decoration: InputDecoration(
                hintText: 'Cole seu código Flutter aqui...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0), // Espaço entre os elementos

            // Área para a pré-visualização (Placeholder por enquanto)
            Expanded(
              flex: 1, // Ocupa 1 parte do espaço disponível
              child: Container(
                color: Colors.grey[200], // Cor de fundo para diferenciar
                child: Center(
                  child: Text('Pré-visualização do Snippet'),
                ),
              ),
            ),
            SizedBox(height: 16.0),

            // Dropdown para selecionar a categoria
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
            SizedBox(height: 16.0),

            // Botão para salvar o snippet
            ElevatedButton(
              onPressed: () {
                // TODO: Implementar a lógica para salvar o snippet
                print('Código a ser salvo: ${_codeController.text}');
                // For now, let's just add a dummy snippet to the list
                setState(() {
                  snippets.add(SnippetCardData(
                    _codeController.text,
                    _selectedCategory,
                    'https://dartpad.dev/embed-flutter.html?code=${Uri.encodeComponent(_codeController.text)}', // Dummy URL
                  ));
                });
              },
              child: Text('Salvar Snippet'),
            ),
            SizedBox(height: 16.0),

            // Área para a lista de cards de snippets
            Expanded(
              flex: 2, // Ocupa 2 partes do espaço disponível
              child: ListView.builder(
                itemCount: snippets.length,
                itemBuilder: (context, index) {
                  // TODO: Criar o SnippetCard Widget
                  return SnippetCard(data: snippets[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modelo de dados para um Snippet (ainda simples)
class SnippetCardData {
  final String code;
  final String category;
  final String dartpadUrl; // Adicionar campo para o URL do DartPad

  SnippetCardData(this.code, this.category, this.dartpadUrl);
}

// Function to register the iframe view factory
void _registerIframeFactory(String viewType, String dartpadUrl) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.src = dartpadUrl;
      iframe.style.border = 'none'; // Optional: remove iframe border
      return iframe;
    },
  );
}

// Widget para exibir um Snippet em formato de card (Simplificado por enquanto)
class SnippetCard extends StatelessWidget {
  final SnippetCardData data;
  const SnippetCard({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snippet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8.0),
            // Display category
            Text('Categoria: ${data.category}'),
            SizedBox(height: 8.0),
            // Display the DartPad embed
            if (kIsWeb && data.dartpadUrl.isNotEmpty)
              SizedBox(
                height: 200, // Defina uma altura para o iframe
                child: Builder(
                  builder: (BuildContext context) {
                    _registerIframeFactory('iframe-${data.hashCode}', data.dartpadUrl);
                    return HtmlElementView(viewType: 'iframe-${data.hashCode}');                  },                ),              ),
            SizedBox(height: 8.0),
            Text(
              'Código Fonte:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8.0),
            // Você pode usar um package para realce de sintaxe aqui
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[200],
              child: Text(data.code),
            ),
            // Exibindo o código (Pode ser necessário formatação futuramente)
            Text(data.code),
            SizedBox(height: 8.0),
            // TODO: Adicionar botão de copiar
            // TODO: Adicionar área para pré-visualização no card
          ],
        ),
      ),
    );
  }

}