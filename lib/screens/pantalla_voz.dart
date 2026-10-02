import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class PantallaVoz extends StatefulWidget {
  const PantallaVoz({Key? key}) : super(key: key);

  @override
  State<PantallaVoz> createState() => _PantallaVozState();
}

class _PantallaVozState extends State<PantallaVoz> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _textoTranscrito = "Presiona el botón y comienza a hablar...";
  double _nivelConfianza = 1.0;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isListening) {
          _animationController.reverse();
        }
      } else if (status == AnimationStatus.dismissed) {
        if (_isListening) {
          _animationController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _iniciarEscucha() async {
    if (!_isListening) {
      bool disponible = await _speech.initialize(
        onStatus: (val) => print('ESTADO ACTUAL DEL RECONOCIMIENTO: $val'),
        onError: (val) => print('ERROR DETECTADO: ${val.errorMsg} - Permanente: ${val.permanent}'),
      );
      if (disponible) {
        setState(() {
          _isListening = true;
        });
        
        _animationController.forward();
        
        _speech.listen(
          onResult: (val) => setState(() {
            _textoTranscrito = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _nivelConfianza = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() {
        _isListening = false;
      });
      
      _animationController.stop();
      _animationController.value = 0.0; // Fuerza el tamaño normal al instante
      
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de Voz')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isListening ? "Escuchando..." : "Micrófono en pausa",
              style: TextStyle(
                fontSize: 20, 
                color: _isListening ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _textoTranscrito,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            ScaleTransition(
              scale: _scaleAnimation,
              child: FloatingActionButton(
                onPressed: _iniciarEscucha,
                backgroundColor: _isListening ? Colors.red : Colors.blue,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}