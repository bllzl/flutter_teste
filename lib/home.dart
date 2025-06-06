import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final FlutterTts flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _textoReconhecido = 'Olá!\nAperte para falar';
  final String witToken = '5L3YLJ2FJEPTO5MZOWS7UPAQMBANZSD6'; // substitua pelo seu token

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeechRecognizer();
  }

  Future<void> _initSpeechRecognizer() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
          _textoReconhecido = 'Erro ao ouvir: ${error.errorMsg}';
        });
      },
    );

    setState(() {
      _textoReconhecido = available
          ? 'Olá!\nAperte para falar'
          : 'Reconhecimento de voz indisponível';
    });
  }

  Future<void> _interpretarComando(String comando) async {
    final response = await http.post(
      Uri.parse(
        'https://api.wit.ai/message?v=20240606&q=${Uri.encodeComponent(comando)}',
      ),
      headers: {
        'Authorization': 'Bearer $witToken',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    final intent =
        data['intents'].isNotEmpty ? data['intents'][0]['name'] : null;

    if (intent != null) {
      switch (intent) {
        case 'abrir_tutorial':
          Navigator.pushNamed(context, 'TutorialWidget');
          break;
        case 'falar_hora':
          final hora = DateFormat('HH:mm').format(DateTime.now());
          await flutterTts.speak("Agora são $hora");
          break;
        default:
          await flutterTts.speak("Comando não reconhecido.");
      }
    } else {
      await flutterTts.speak("Desculpe, não entendi.");
    }
  }

  Future<void> _speakAndListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          localeId: "pt_BR",
          listenFor: const Duration(seconds: 5),
          onResult: (result) async {
            setState(() {
              _textoReconhecido = result.recognizedWords;
            });
            if (result.finalResult) {
              await _interpretarComando(result.recognizedWords);
            }
          },
        );
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
                onPressed: () =>
                    Navigator.pushNamed(context, 'TutorialWidget'),
                icon: const Icon(Icons.info_outline, size: 28),
                label: const Text(
                  'Como Usar',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7D85FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _textoReconhecido,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 32,
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
