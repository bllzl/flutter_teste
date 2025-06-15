import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_apps/device_apps.dart';

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
        await _executarAcao(intent, comando);
      } else {
        await abrirAppPorNomeFalado(comando);
      }
    } else {
      await flutterTts.speak("Erro ao conectar com o servidor.");
    }
  }

  Future<void> _executarAcao(String intent, String comandoOriginal) async {
    switch (intent) {
      case 'abrir_tutorial':
        Navigator.pushNamed(context, 'TutorialWidget');
        break;
      case 'falar_hora':
        final hora = DateFormat('HH:mm').format(DateTime.now());
        await flutterTts.speak("Agora são $hora");
        break;
      case 'abrir_whatsapp':
        await _abrirApp('com.whatsapp', 'Abrindo o WhatsApp');
        break;
      case 'abrir_youtube':
        await _abrirApp('com.google.android.youtube', 'Abrindo o YouTube');
        break;
      case 'abrir_google_maps':
        await _abrirApp('com.google.android.apps.maps', 'Abrindo o Google Maps');
        break;
      case 'abrir_camera':
        await _abrirApp('com.android.camera', 'Abrindo a câmera');
        break;
      case 'ligar_telefone':
        final uri = Uri.parse("tel:11999999999");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          await flutterTts.speak("Ligando para o número");
        } else {
          await flutterTts.speak("Não consegui fazer a ligação.");
        }
        break;
      case 'abrir_navegador':
        final uri = Uri.parse("https://www.google.com");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          await flutterTts.speak("Abrindo o navegador");
        } else {
          await flutterTts.speak("Não consegui abrir o navegador.");
        }
        break;
      default:
        await abrirAppPorNomeFalado(comandoOriginal);
        break;
    }
  }

  Future<void> abrirAppPorNomeFalado(String nomeFalado) async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: false,
      includeSystemApps: false,
    );

    final nomeLimpo = nomeFalado.toLowerCase().replaceAll("abrir", "").trim();

    Application? appEncontrado;
    for (var app in apps) {
      if (app.appName.toLowerCase().contains(nomeLimpo)) {
        appEncontrado = app;
        break;
      }
    }

    if (appEncontrado != null) {
      await flutterTts.speak("Abrindo ${appEncontrado.appName}");
      await DeviceApps.openApp(appEncontrado.packageName);
    } else {
      await flutterTts.speak("Não encontrei o aplicativo chamado $nomeLimpo");
    }
  }

  Future<void> _abrirApp(String packageName, String mensagem) async {
    final isInstalled = await DeviceApps.isAppInstalled(packageName);
    if (isInstalled) {
      await DeviceApps.openApp(packageName);
      await flutterTts.speak(mensagem);
    } else {
      await flutterTts.speak("Não consegui abrir o aplicativo.");
    }
  }

  Future<void> _speakAndListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          localeId: "pt_BR",
          listenFor: const Duration(seconds: 6),
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
