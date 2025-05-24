import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) { 
     // TODO: Load dotenv in a more appropriate place like main() or app startup or use FutureBuilder
    DotEnv().load(fileName: '.secret.json');

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
  // Lista para armazenar os snippets (inicialmente vazia)
  List<SnippetCardData> snippets = [];

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
                 _saveSnippet();
              },
              child: const Text('Salvar Snippet'),
            ),
            SizedBox(height: 16.0),

            // Área para a lista de cards de snippets
            Expanded(
              flex: 2, // Ocupa 2 partes do espaço disponível
              child: ListView.builder(
                itemCount: snippets.length,
                itemBuilder: (context, index) {
                  // TODO: Criar o SnippetCard Widget
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Implementar a lógica para salvar o snippet
  void _saveSnippet() async {
    final code = _codeController.text;
    if (code.isEmpty) {
      // Optionally show a message to the user
      return;
    }

    // TODO: Handle potential errors during Gist creation
    final dartpadUrl = await createGist(code);

    setState(() {
      snippets.add(SnippetCardData(
        code,
        _selectedCategory,
 dartpadUrl!, // Assuming dartpadUrl is not null if createGist succeeds
      ));
      _codeController.clear(); // Clear the text field after saving
    });
  }
}

Future<String?> createGist(String code) async {
  // Load dotenv - TODO: Load this once at app startup
  // TODO: Load this once at app startup
  try {
    await DotEnv().load(fileName: '.secret.json');
  } catch (e) {
    print('Error loading .secret.json: $e');
    return null; // Return null or indicate error loading
  }
  final githubPat = DotEnv().get('GITHUB_PAT');

  const url = 'https://api.github.com/gists';
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Authorization': 'token $githubPat',
      'Content-Type': 'application/json',
    },
    body: '{"files": {"snippet.dart": {"content": ${
        // Escape newlines and quotes in the code
        code.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n')
      }}}, "public": true, "description": "Flutter Snippet"}',
  );

  if (response.statusCode == 201) {
    // Gist created successfully
    final gistId = (response.bodyBytes as dynamic)['id']; // Assuming response is JSON and has 'id'
    return 'https://dartpad.dev/embed-dart.html?id=$gistId&run=true&split=50';
  } else {
    // Handle errors - TODO: More robust error handling
    print('Failed to create Gist: ${response.body}');
    return 'Error creating Gist'; // Or return a default URL
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
// TODO: Ensure this is called once per viewType and not in the build method
void _registerIframeFactory(String viewType, String dartpadUrl) {
  if (ui_web.platformViewRegistry.getViewFactory(viewType) == null) {
     ui_web.platformViewRegistry.registerViewFactory(
       viewType,
       (int viewId) {
         final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
         iframe.src = dartpadUrl;
         iframe.style.border = 'none'; // Optional: remove iframe border
         // You might need to set other attributes based on DartPad embed requirements
         // e.g., allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
         return iframe;
       },
     );
  }
}

// Widget para exibir um Snippet em formato de card (Simplificado por enquanto)
class SnippetCard extends StatelessWidget {
  final SnippetCardData data;
  const SnippetCard({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    // Generate a unique viewType for each card based on the snippet data
    final String viewType = 'iframe-${data.hashCode}';

    // Register the view factory if it hasn't been registered yet
    // TODO: Consider a better place to call this registration, e.g., outside the build method
    _registerIframeFactory(viewType, data.dartpadUrl);

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
            if (kIsWeb && data.dartpadUrl.isNotEmpty && data.dartpadUrl != 'Error creating Gist') // Check for error URL
              SizedBox(
                height: 200, // Defina uma altura para o iframe
                child: HtmlElementView(viewType: viewType),
              ),
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
            // You might want to use a syntax highlighter here instead of plain Text
            // Text(data.code), // Removed duplicate display of code
            SizedBox(height: 8.0),
            // TODO: Adicionar botão de copiar
            // TODO: Adicionar área para pré-visualização no card - This is now handled by the DartPad embed
          ],
        ),
      ),
    );
  }

}

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