import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/Home',
      routes: {
        '/Home': (context) => const HomePageWidget(),
        'TutorialWidget': (context) => const PlaceholderWidget('Tutorial'),
        'ListaDeContatosWidget': (context) =>
            const PlaceholderWidget('Lista de Contatos'),
      },
    );
  }
}

// Tela temporária de exemplo
class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Tela: $title')),
    );
  }
}
