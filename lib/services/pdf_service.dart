import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfPlanillaService {
  static Future<Uint8List> generarPlanillaPDF({
    required String fecha,
    required String expediente,
    required String placa,
    required String marca,
    required String soat,
    required String asegurado,
    required String celular,
    required String origen,
    required String destino,
    required String estadoServicio,
    required Uint8List firmaBytes,
  }) async {
    final pdf = pw.Document();

    final ByteData bytes = await rootBundle.load('assets/images/PLANILLAS DE SATISFACCION.jpg');
    final Uint8List imageBytes = bytes.buffer.asUint8List();
    final pw.MemoryImage fondoPlantilla = pw.MemoryImage(imageBytes);
    
    // Solo cargamos la imagen de la firma si hay bytes y el servicio es efectivo con firma válida
    pw.MemoryImage? firmaImagen;
    if (firmaBytes.isNotEmpty && estadoServicio == "Efectivo") {
      firmaImagen = pw.MemoryImage(firmaBytes);
    }

    // Determinamos la posición horizontal (left) para la "X" según el estado del servicio.
    // (Nota: Estos valores de 'left' aproximados se ajustarán según la ubicación de las casillas en tu plantilla, 
    // partiendo de la referencia central que tenías en top: 197).
    double xPositionLeft = 340; // Valor por defecto (ej. Fallido al centro)
    if (estadoServicio == "Efectivo") {
      xPositionLeft = 280; // Ajusta este valor hacia la izquierda si la casilla de efectivo está más allá
    } else if (estadoServicio == "Cancelado") {
      xPositionLeft = 400; // Ajusta este valor hacia la derecha si la casilla de cancelado está más acá
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: pw.EdgeInsets.zero, 
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: pw.Image(fondoPlantilla, fit: pw.BoxFit.fill),
              ),

              // --- Fecha y Expediente ---
              pw.Positioned(
                left: 193,
                top: 142,
                child: pw.Text(fecha, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Positioned(
                left: 340,
                top: 127,
                child: pw.Text(expediente, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),

              // --- Datos del Vehículo y Asegurado ---
              pw.Positioned(
                left: 340,  
                top: 141,
                child: pw.Text(placa, style: pw.TextStyle(fontSize: 10)),
              ),
              pw.Positioned(
                left: 163,
                top: 156, 
                child: pw.Text(marca, style: pw.TextStyle(fontSize: 10)),
              ),
              pw.Positioned(
                left: 193,
                top: 197,
                child: pw.Text(soat, style: pw.TextStyle(fontSize: 10)),
              ),
              
              // --- X del Estado del Servicio (Efectivo / Fallido / Cancelado) ---
              pw.Positioned(
                left: xPositionLeft,
                top: 197, // Misma altura de la línea del SOAT
                child: pw.Text(
                  "X", 
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),

              pw.Positioned(
                left: 163,
                top: 170,
                child: pw.Text(asegurado, style: pw.TextStyle(fontSize: 10)),
              ),
              pw.Positioned(
                left: 340,
                top: 157,
                child: pw.Text(celular, style: pw.TextStyle(fontSize: 10)),
              ),

              // --- Ruta ---
              pw.Positioned(
                left: 163,
                top: 216,
                child: pw.Text(origen, style: pw.TextStyle(fontSize: 10)),
              ),
              pw.Positioned(
                left: 163,
                top: 230,
                child: pw.Text(destino, style: pw.TextStyle(fontSize: 10)),
              ),

              // --- Firma del Pasajero/Asegurado (Solo si existe imagen y es efectivo) ---
              if (firmaImagen != null)
                pw.Positioned(
                  left: 150,
                  top: 490,
                  child: pw.SizedBox(
                    width: 180,
                    height: 70,
                    child: pw.Image(firmaImagen, fit: pw.BoxFit.contain),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}

