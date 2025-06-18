import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = '/home';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final FlutterTts flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _textoReconhecido = 'Olá!\nAperte para falar';

  final String witToken = 'NR67RNC45HWINHQ4T7MBBNRF2HLRI2FA';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pedirPermissoes().then((_) => _initSpeechRecognizer());
    flutterTts.setLanguage("pt-BR");
    flutterTts.setSpeechRate(0.9);
  }

  Future<void> _pedirPermissoes() async {
    await Permission.microphone.request();
    await Permission.speech.request();
  }

  Future<void> _initSpeechRecognizer() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() {
            _isListening = false;
            _textoReconhecido = 'Erro: ${error.errorMsg}';
          });
        },
      );

      setState(() {
        _textoReconhecido = available
            ? 'Olá!\nAperte para falar'
            : 'Reconhecimento de voz indisponível';
      });
    } catch (e) {
      setState(() {
        _textoReconhecido = 'Erro ao inicializar o microfone';
      });
    }
  }

  Future<void> _interpretarComando(String comando) async {
    final response = await http.get(
      Uri.parse('https://api.wit.ai/message?v=20250606&q=${Uri.encodeComponent(comando)}'),
      headers: {
        'Authorization': 'Bearer $witToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final intents = data['intents'] as List?;
      final intent = (intents != null && intents.isNotEmpty) ? intents[0]['name'] : null;

      if (intent != null) {
        await _executarAcao(intent);
      } else {
        await abrirAppPorNomeFalado(comando);
      }
    } else {
      await flutterTts.speak("Erro ao conectar com o servidor.");
    }
  }

  Future<void> _executarAcao(String intent) async {
    switch (intent) {
      case 'abrir_tutorial':
        Navigator.pushNamed(context, 'TutorialWidget');
        break;
      case 'falar_hora':
        final hora = DateFormat('HH:mm').format(DateTime.now());
        await flutterTts.speak("Agora são $hora");
        break;
      case 'abrir_whatsapp':
        await _abrirUrl('https://wa.me/');
        break;
      case 'abrir_youtube':
        await _abrirUrl('https://www.youtube.com');
        break;
      case 'abrir_google_maps':
        await _abrirUrl('https://maps.google.com');
        break;
      default:
        await flutterTts.speak("Comando não reconhecido");
        break;
    }
  }

  Future<void> abrirAppPorNomeFalado(String nomeFalado) async {
    String nome = nomeFalado.toLowerCase().replaceAll("abrir", "").trim();
    await flutterTts.speak("Tentando abrir o aplicativo $nome");
    await flutterTts.speak("Por favor, tente comandos como abrir YouTube, WhatsApp ou Google Maps.");
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await flutterTts.speak("Não consegui abrir o link.");
    }
  }

  Future<void> _speakAndListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          localeId: "pt_BR",
          listenFor: const Duration(seconds: 10),
          onResult: (result) async {
            setState(() {
              _textoReconhecido = result.recognizedWords;
            });
            if (result.finalResult) {
              await _interpretarComando(result.recognizedWords);
            }
          },
        );
      } else {
        await flutterTts.speak("Não consegui ativar o microfone.");
      }
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2DBF),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, 'TutorialWidget'),
                icon: const Icon(Icons.info_outline, size: 28),
                label: const Text('Como Usar', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7D85FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _textoReconhecido,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _speakAndListen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7D85FF),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(48),
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
