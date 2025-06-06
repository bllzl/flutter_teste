import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterTts flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _textoReconhecido = 'Olá!\nAperte para falar';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeechRecognizer();
  }

  Future<void> _initSpeechRecognizer() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Status: $status');
        if (status == 'notListening') {
          setState(() {
            _isListening = false;
            if (_textoReconhecido.trim().isEmpty ||
                _textoReconhecido == 'Olá!\nAperte para falar' ||
                _textoReconhecido == 'Reconhecimento de voz indisponível') {
              _textoReconhecido = 'Fale novamente.';
            }
          });
        }
      },
      onError: (error) {
        print('Erro: $error');
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

  Future<void> _speakAndListen() async {
    if (!_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);

      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Status: $status');
          if (status == 'notListening') {
            setState(() {
              _isListening = false;
              if (_textoReconhecido.trim().isEmpty ||
                  _textoReconhecido == 'Olá!\nAperte para falar' ||
                  _textoReconhecido == 'Reconhecimento de voz indisponível') {
                _textoReconhecido = 'Fale novamente.';
              }
            });
          }
        },
        onError: (error) {
          print('Erro: $error');
          setState(() {
            _isListening = false;
            _textoReconhecido = 'Erro ao ouvir: ${error.errorMsg}';
          });
        },
      );

      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          localeId: "pt_BR",
          listenFor: const Duration(seconds: 5),
          onResult: (result) {
            setState(() {
              _textoReconhecido = result.recognizedWords;
            });
          },
        );
      } else {
        setState(() {
          _isListening = false;
          _textoReconhecido = 'Reconhecimento de voz indisponível';
        });
      }
    } else {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _textoReconhecido = 'Olá!\nAperte para falar';
      });
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          automaticallyImplyLeading: false,
          elevation: 0.1,
          toolbarHeight: 1,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFF3B2DBF),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.7),
                      child: ElevatedButton(
                        onPressed: _speakAndListen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7D85FF),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(48),
                          elevation: 4,
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, -0.55),
                      child: Text(
                        _textoReconhecido,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.02, -0.85),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, 'TutorialWidget');
                        },
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
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
