import 'package:flutter/material.dart';
import 'pantalla_formulario.dart';

class PantallaVoz extends StatefulWidget {
  const PantallaVoz({super.key});

  @override
  State<PantallaVoz> createState() => _PantallaVozState();
}

class _PantallaVozState extends State<PantallaVoz> {
  final TextEditingController _textoController = TextEditingController();
  bool _isListening = false;

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        // Simulación temporal; luego aquí activaremos el micrófono real
        _textoController.text = "Servicio aeropuerto Eldorado, pasajero Juan Pérez, vuelo AV123, recogida a las 08:00 AM";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1. Captura de Servicio'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dicta los detalles del servicio o escribe la información:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _textoController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Ej: Pasajero, hora, vuelo, observaciones...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _toggleListening,
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              label: Text(_isListening ? 'Escuchando...' : 'Iniciar Dictado por Voz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _isListening ? Colors.redAccent : null,
                foregroundColor: _isListening ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantallaFormulario(datosCapturados: _textoController.text),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Continuar al Formulario ->', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}