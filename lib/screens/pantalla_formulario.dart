import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Controlador para el recuadro de firma digital (con exportBackgroundColor transparente para evitar cajas)
  final SignatureController _signatureController = SignatureController(
    penColor: Colors.black,
    penStrokeWidth: 3,
    exportBackgroundColor: Colors.transparent,
  );

  final String _textoDisclaimer = 
      "Recibo a plena satisfacción y de acuerdo con las condiciones aquí señaladas el automotor identificado en el presente documento y "
      "que en consecuencia renuncio expresamente a presentar cualquier reclamación y objeción relacionada a la inexactitud de la "
      "información aquí indicada. De igual manera declaro que se ha examinado detalladamente la información suministrada en el presente "
      "documento por el cual asumo plena responsabilidad en lo entendido que la información que se indica con respecto al vehículo es "
      "precisa, completa y corresponde a la realidad del momento";

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
      _soatController.text = prefs.getString('vehiculo_soat') ?? '';
      _asisteController.text = prefs.getString('servicio_asiste') ?? '';
    });

    _evaluarEfectivoSegunSoat();
  }

  Future<void> _guardarDatosPrestador() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vehiculo_marca', _marcaController.text.trim());
    await prefs.setString('vehiculo_placa', _placaController.text.trim());
    await prefs.setString('vehiculo_soat', _soatController.text.trim());
    await prefs.setString('servicio_asiste', _asisteController.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos del prestador guardados correctamente')),
    );
  }

  void _evaluarEfectivoSegunSoat() {
    String fechaServicioTexto = _fechaController.text.trim();
    String soatTexto = _soatController.text.trim();
    
    if (fechaServicioTexto.isEmpty || soatTexto.isEmpty) return;

    try {
      List<String> partesFecha = fechaServicioTexto.split('-');
      DateTime fechaServicio = DateTime(
        int.parse(partesFecha[2]),
        int.parse(partesFecha[1]),
        int.parse(partesFecha[0]),
      );
      DateTime fechaServicioLimpia = DateTime(fechaServicio.year, fechaServicio.month, fechaServicio.day);

      List<String> partesSoat = soatTexto.split('-');
      DateTime fechaSoat = DateTime(
        int.parse(partesSoat[2]),
        int.parse(partesSoat[1]),
        int.parse(partesSoat[0]),
      );
      DateTime fechaSoatLimpia = DateTime(fechaSoat.year, fechaSoat.month, fechaSoat.day);

      bool esEfectivo = fechaSoatLimpia.isAfter(fechaServicioLimpia) || fechaSoatLimpia.isAtSameMomentAs(fechaServicioLimpia);

      setState(() {
        _efectivoController.text = esEfectivo ? "SI" : "NO";
      });
    } catch (e) {
      print("Error evaluando fechas para efectivo: $e");
    }
  }

  Future<void> _seleccionarFecha(BuildContext context, TextEditingController controller) async {
    DateTime fechaActual = DateTime.now();
    
    try {
      List<String> partes = controller.text.split('-');
      if (partes.length == 3) {
        fechaActual = DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );
      }
    } catch (_) {}

    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaActual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (fechaSeleccionada != null) {
      final dia = fechaSeleccionada.day.toString().padLeft(2, '0');
      final mes = fechaSeleccionada.month.toString().padLeft(2, '0');
      final anio = fechaSeleccionada.year.toString();
      
      setState(() {
        controller.text = "$dia-$mes-$anio";
      });

      _evaluarEfectivoSegunSoat();
    }
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
        title: const Text(
          'Planilla de Servicio - Aeropuerto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.indigo.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            const SizedBox(height: 16),

            if (_isListening)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Escuchando para: $_campoActivo...",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

            // GRUPO 1: DATOS DEL PRESTADOR
            _construirTituloSeccion("Datos del Prestador"),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _construirCampoConMic(
                      label: "Marca del Vehículo",
                      controller: _marcaController,
                      nombreCampo: "Marca",
                    ),
                    const SizedBox(height: 14),
                    _construirCampoConMic(
                      label: "Placa",
                      controller: _placaController,
                      nombreCampo: "Placa",
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _soatController,
                      readOnly: true,
                      onTap: () => _seleccionarFecha(context, _soatController),
                      decoration: InputDecoration(
                        labelText: "Vencimiento SOAT (DD-MM-AAAA)",
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today, color: Colors.indigo.shade700),
                          onPressed: () => _seleccionarFecha(context, _soatController),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _construirCampoConMic(
                      label: "Efectivo (SI / NO)",
                      controller: _efectivoController,
                      nombreCampo: "Efectivo",
                      habilitarMic: false,
                    ),
                    const SizedBox(height: 14),
                    _construirCampoConMic(
                      label: "Asiste",
                      controller: _asisteController,
                      nombreCampo: "Asiste",
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.indigo.shade50,
                          foregroundColor: Colors.indigo.shade800,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.indigo.shade300),
                          ),
                        ),
                        onPressed: _guardarDatosPrestador,
                        icon: const Icon(Icons.save_alt, size: 20),
                        label: const Text(
                          "Guardar Datos del Prestador",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // GRUPO 2: DATOS DEL SERVICIO
            _construirTituloSeccion("Datos del Servicio"),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _fechaController,
                      readOnly: true,
                      onTap: () => _seleccionarFecha(context, _fechaController),
                      decoration: InputDecoration(
                        labelText: "Fecha (DD-MM-AAAA)",
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today, color: Colors.indigo.shade700),
                          onPressed: () => _seleccionarFecha(context, _fechaController),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _construirCampoConMic(
                      label: "Expediente",
                      controller: _expedienteController,
                      nombreCampo: "Expediente",
                    ),
                    const SizedBox(height: 14),
                    _construirCampoConMic(
                      label: "Asegurado",
                      controller: _aseguradoController,
                      nombreCampo: "Asegurado",
                    ),
                    const SizedBox(height: 14),
                    _construirCampoConMic(
                      label: "Celular",
                      controller: _celularController,
                      nombreCampo: "Celular",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _construirCampoConMic(
                      label: "Origen",
                      controller: _origenController,
                      nombreCampo: "Origen",
                    ),
                    const SizedBox(height: 14),
                    _construirCampoConMic(
                      label: "Destino",
                      controller: _destinoController,
                      nombreCampo: "Destino",
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            // SECCIÓN DE FIRMA Y DISCLAIMER
            const Text(
              "Firma del Pasajero",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _textoDisclaimer,
              style: const TextStyle(fontSize: 9, color: Colors.grey, height: 1.2),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 10),
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

            // BOTÓN GUARDAR PLANILLA Y GENERAR PDF MAQUETADO
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (_signatureController.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor solicite la firma del pasajero')),
                  );
                  return;
                }

                final signatureBytes = await _signatureController.toPngBytes();
                if (signatureBytes == null) return;

                String fechaTexto = _fechaController.text.trim();
                String fechaAAMMDD = "000000";
                try {
                  List<String> partes = fechaTexto.split('-');
                  if (partes.length == 3) {
                    String dia = partes[0];
                    String mes = partes[1];
                    String anio = partes[2];
                    if (anio.length == 4) anio = anio.substring(2);
                    fechaAAMMDD = "$anio$mes$dia";
                  }
                } catch (e) {
                  print("Error formateando fecha: $e");
                }

                String expedienteTexto = _expedienteController.text.trim();
                if (expedienteTexto.isEmpty) expedienteTexto = "SinuNumero";

                final String nombreArchivo = "planilla_aeropuerto_${fechaAAMMDD}_ex$expedienteTexto.pdf";

                // CARGAR LOGO DESDE ASSETS
                pw.ImageProvider? logoImage;
                try {
                  final imageByteData = await rootBundle.load('assets/images/logo_2m.png');
                  logoImage = pw.MemoryImage(imageByteData.buffer.asUint8List());
                } catch (e) {
                  print("No se pudo cargar el logo de assets: $e");
                }

                final pdf = pw.Document();
                pdf.addPage(
                  pw.Page(
                    pageFormat: PdfPageFormat.letter,
                    margin: const pw.EdgeInsets.all(32),
                    build: (pw.Context context) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // ================= ENCABEZADO CON LOGO Y TÍTULO =================
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              if (logoImage != null)
                                pw.Container(
                                  width: 70,
                                  height: 70,
                                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                                )
                              else
                                pw.Container(width: 70, height: 70, child: pw.Text("2M Global", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
                              
                              pw.Expanded(
                                child: pw.Center(
                                  child: pw.Text(
                                    "SATISFACCIÓN DEL CLIENTE",
                                    style: pw.TextStyle(
                                      fontSize: 18,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.indigo800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 15),
                          pw.Divider(thickness: 1.5, color: PdfColors.indigo800),
                          pw.SizedBox(height: 15),

                          // ================= TABLA DE DATOS =================
                          pw.Table(
                            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                            columnWidths: {
                              0: const pw.FlexColumnWidth(1.2),
                              1: const pw.FlexColumnWidth(2),
                            },
                            children: [
                              _construirFilaTablaPdf("Fecha del Servicio", _fechaController.text),
                              _construirFilaTablaPdf("Expediente", _expedienteController.text),
                              _construirFilaTablaPdf("Asegurado", _aseguradoController.text),
                              _construirFilaTablaPdf("Celular", _celularController.text),
                              _construirFilaTablaPdf("Origen", _origenController.text),
                              _construirFilaTablaPdf("Destino", _destinoController.text),
                              _construirFilaTablaPdf("Marca del Vehículo", _marcaController.text),
                              _construirFilaTablaPdf("Placa", _placaController.text),
                              _construirFilaTablaPdf("Vencimiento SOAT", _soatController.text),
                              _construirFilaTablaPdf("Efectivo", _efectivoController.text),
                              _construirFilaTablaPdf("Asistente / Conductor", _asisteController.text),
                            ],
                          ),

                          pw.SizedBox(height: 15),

                          // ================= SECCIÓN DE FIRMA Y DISCLAIMER EN EL PDF =================
                          pw.Text(
                            "Firma del Pasajero:",
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            _textoDisclaimer,
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey700,
                              lineSpacing: 1.2,
                            ),
                            textAlign: pw.TextAlign.justify,
                          ),
                          pw.SizedBox(height: 15),
                          
                          // Imagen limpia sin cajas ni bordes
                          pw.SizedBox(
                            height: 60,
                            width: 160,
                            child: pw.Image(
                              pw.MemoryImage(signatureBytes),
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                          
                          // Línea guía tradicional inferior
                          pw.Text(
                            "________________________________________",
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Firma / Aceptado",
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                          ),
                        ],
                      );
                    },
                  ),
                );

                await Printing.sharePdf(
                  bytes: await pdf.save(),
                  filename: nombreArchivo,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Generando PDF: $nombreArchivo')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text("Guardار Planilla", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _construirTituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0, left: 4.0),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.indigo.shade800,
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    bool esteCampoEstaEscuchando = _isListening && _campoActivo == nombreCampo;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
        ),
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

  pw.TableRow _construirFilaTablaPdf(String etiqueta, String valor) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            etiqueta,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(
            valor.isEmpty ? "-" : valor,
            style: pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }
}
