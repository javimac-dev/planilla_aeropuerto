import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PantallaFormulario extends StatefulWidget {
  const PantallaFormulario({Key? key}) : super(key: key);

  @override
  State<PantallaFormulario> createState() => _PantallaFormularioState();
}

class _PantallaFormularioState extends State<PantallaFormulario> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _campoActivo = "";

  // Controladores de texto para todos los campos
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _expedienteController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _aseguradoController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _soatController = TextEditingController();
  final TextEditingController _efectivoController = TextEditingController();
  final TextEditingController _origenController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _asisteController = TextEditingController();

  // Controlador para el recuadro de firma digital
  final SignatureController _signatureController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 3,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _inicializarDatosAutomaticos();
  }

  void _inicializarDatosAutomaticos() async {
    final ahora = DateTime.now();
    final dia = ahora.day.toString().padLeft(2, '0');
    final mes = ahora.month.toString().padLeft(2, '0');
    final anio = ahora.year.toString();
    _fechaController.text = "$dia-$mes-$anio";

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _marcaController.text = prefs.getString('vehiculo_marca') ?? '';
      _placaController.text = prefs.getString('vehiculo_placa') ?? '';
    });
  }

  Future<void> _guardarDatoPersistente(String clave, String valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(clave, valor);
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _expedienteController.dispose();
    _marcaController.dispose();
    _placaController.dispose();
    _aseguradoController.dispose();
    _celularController.dispose();
    _soatController.dispose();
    _efectivoController.dispose();
    _origenController.dispose();
    _destinoController.dispose();
    _asisteController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  void _escucharParaCampo(TextEditingController controller, String nombreCampo, {Function(String)? onTextChanged}) async {
    bool disponible = await _speech.initialize(
      onStatus: (val) => print('estado: $val'),
      onError: (val) => print('error: $val'),
    );

    if (disponible) {
      setState(() {
        _isListening = true;
        _campoActivo = nombreCampo;
      });

      _speech.listen(
        onResult: (val) {
          setState(() {
            controller.text = val.recognizedWords;
            if (onTextChanged != null) {
              onTextChanged(val.recognizedWords);
            }
          });
        },
      );
    }
  }

  void _detenerEscucha() {
    setState(() {
      _isListening = false;
      _campoActivo = "";
    });
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planilla de Servicio - Aeropuerto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (_isListening)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.red[100],
                child: Text(
                  "Escuchando para: $_campoActivo...",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

            // 1. Fecha (Sistema)
            _construirCampoConMic(
              label: "Fecha (DD-MM-AAAA)",
              controller: _fechaController,
              nombreCampo: "Fecha",
              habilitarMic: false,
            ),
            const SizedBox(height: 14),

            // 2. Expediente
            _construirCampoConMic(
              label: "Expediente",
              controller: _expedienteController,
              nombreCampo: "Expediente",
            ),
            const SizedBox(height: 14),

            // 3. Marca (Persistente)
            _construirCampoConMic(
              label: "Marca del Vehículo",
              controller: _marcaController,
              nombreCampo: "Marca",
              onChanged: (valor) => _guardarDatoPersistente('vehiculo_marca', valor),
            ),
            const SizedBox(height: 14),

            // 4. Placa (Persistente)
            _construirCampoConMic(
              label: "Placa",
              controller: _placaController,
              nombreCampo: "Placa",
              onChanged: (valor) => _guardarDatoPersistente('vehiculo_placa', valor),
            ),
            const SizedBox(height: 14),

            // 5. Asegurado
            _construirCampoConMic(
              label: "Asegurado",
              controller: _aseguradoController,
              nombreCampo: "Asegurado",
            ),
            const SizedBox(height: 14),

            // 6. Celular
            _construirCampoConMic(
              label: "Celular",
              controller: _celularController,
              nombreCampo: "Celular",
            ),
            const SizedBox(height: 14),

            // 7. Vencimiento SOAT
            _construirCampoConMic(
              label: "Vencimiento SOAT (DD-MM-AAAA)",
              controller: _soatController,
              nombreCampo: "SOAT",
            ),
            const SizedBox(height: 14),

            // 8. Efectivo (Sí/No)
            _construirCampoConMic(
              label: "Efectivo (SI / NO)",
              controller: _efectivoController,
              nombreCampo: "Efectivo",
            ),
            const SizedBox(height: 14),

            // 9. Origen
            _construirCampoConMic(
              label: "Origen",
              controller: _origenController,
              nombreCampo: "Origen",
            ),
            const SizedBox(height: 14),

            // 10. Destino
            _construirCampoConMic(
              label: "Destino",
              controller: _destinoController,
              nombreCampo: "Destino",
            ),
            const SizedBox(height: 14),

            // 11. Asiste
            _construirCampoConMic(
              label: "Asiste",
              controller: _asisteController,
              nombreCampo: "Asiste",
            ),
            
            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            // SECCIÓN DE FIRMA DIGITAL
            const Text(
              "Firma del Pasajero",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: _signatureController,
                  height: 150,
                  backgroundColor: Colors.grey[200]!,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _signatureController.clear(),
              icon: const Icon(Icons.clear, size: 18),
              label: const Text("Limpiar firma"),
            ),

            const SizedBox(height: 20),

            // Botón de guardar planilla y generar PDF
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // 1. Validar firma obligatoria
                if (_signatureController.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor solicite la firma del pasajero')),
                  );
                  return;
                }

                // 2. Obtener la imagen de la firma en bytes
                final signatureBytes = await _signatureController.toPngBytes();
                if (signatureBytes == null) return;

                // 3. Formatear la fecha ingresada (DD-MM-AAAA) a AAMMDD para el nombre del archivo
                String fechaTexto = _fechaController.text.trim();
                String fechaAAMMDD = "000000";
                try {
                  List<String> partes = fechaTexto.split('-');
                  if (partes.length == 3) {
                    String dia = partes[0];
                    String mes = partes[1];
                    String anio = partes[2];
                    if (anio.length == 4) {
                      anio = anio.substring(2);
                    }
                    fechaAAMMDD = "$anio$mes$dia";
                  }
                } catch (e) {
                  print("Error formateando fecha para el archivo: $e");
                }

                // 4. Obtener número de expediente
                String expedienteTexto = _expedienteController.text.trim();
                if (expedienteTexto.isEmpty) expedienteTexto = "SinuNumero";

                // 5. Construir nombre del archivo: planilla_aeropuerto_AAMMDD_ex12345.pdf
                final String nombreArchivo = "planilla_aeropuerto_${fechaAAMMDD}_ex$expedienteTexto.pdf";

                // 6. Diseñar el contenido del documento PDF
                final pdf = pw.Document();
                pdf.addPage(
                  pw.Page(
                    build: (pw.Context context) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "PLANILLA DE SERVICIO - AEROPUERTO",
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 15),
                          pw.Divider(),
                          pw.SizedBox(height: 10),
                          
                          _construirFilaPdf("Fecha:", _fechaController.text),
                          _construirFilaPdf("Expediente:", _expedienteController.text),
                          _construirFilaPdf("Marca del Vehículo:", _marcaController.text),
                          _construirFilaPdf("Placa:", _placaController.text),
                          _construirFilaPdf("Asegurado:", _aseguradoController.text),
                          _construirFilaPdf("Celular:", _celularController.text),
                          _construirFilaPdf("Vencimiento SOAT:", _soatController.text),
                          _construirFilaPdf("Efectivo:", _efectivoController.text),
                          _construirFilaPdf("Origen:", _origenController.text),
                          _construirFilaPdf("Destino:", _destinoController.text),
                          _construirFilaPdf("Asiste:", _asisteController.text),

                          pw.SizedBox(height: 25),
                          pw.Text("Firma del Pasajero:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 10),
                          
                          pw.Container(
                            height: 100,
                            width: 200,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey),
                            ),
                            child: pw.Image(
                              pw.MemoryImage(signatureBytes),
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );

                // 7. Lanzar el diálogo nativo para guardar o compartir el PDF
                await Printing.sharePdf(
                  bytes: await pdf.save(),
                  filename: nombreArchivo,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Generando PDF: $nombreArchivo')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text("Guardar Planilla", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _construirCampoConMic({
    required String label,
    required TextEditingController controller,
    required String nombreCampo,
    bool habilitarMic = true,
    Function(String)? onChanged,
  }) {
    bool esteCampoEstaEscuchando = _isListening && _campoActivo == nombreCampo;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: habilitarMic
            ? IconButton(
                icon: Icon(
                  esteCampoEstaEscuchando ? Icons.mic : Icons.mic_none,
                  color: esteCampoEstaEscuchando ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  if (esteCampoEstaEscuchando) {
                    _detenerEscucha();
                  } else {
                    _escucharParaCampo(
                      controller, 
                      nombreCampo, 
                      onTextChanged: onChanged,
                    );
                  }
                },
              )
            : null,
      ),
    );
  }

  // Método auxiliar para estructurar las filas dentro del PDF
  pw.Widget _construirFilaPdf(String etiqueta, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(etiqueta, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(valor.isEmpty ? "-" : valor),
          ),
        ],
      ),
    );
  }
}
