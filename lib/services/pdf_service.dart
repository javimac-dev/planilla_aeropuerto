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
    required Uint8List firmaBytes,
  }) async {
    final pdf = pw.Document();

    final ByteData bytes = await rootBundle.load('assets/images/PLANILLAS DE SATISFACCION.jpg');
    final Uint8List imageBytes = bytes.buffer.asUint8List();
    final pw.MemoryImage fondoPlantilla = pw.MemoryImage(imageBytes);
    final pw.MemoryImage firmaImagen = pw.MemoryImage(firmaBytes);

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
                //OK
                child: pw.Text(fecha, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Positioned(
                left: 340,
                top: 127,
                //OK
                child: pw.Text(expediente, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),

              // --- Datos del Vehículo y Asegurado ---
              pw.Positioned(
                left: 340,  
                top: 141,
                //OK 
                child: pw.Text(placa, style: pw.TextStyle(fontSize: 10)), //OK
              ),
              pw.Positioned(
                left: 163,
                top: 156, 
                //OK
                child: pw.Text(marca, style: pw.TextStyle(fontSize: 10)), //OK
              ),
              pw.Positioned(
                left: 193,
                top: 197,
                child: pw.Text(soat, style: pw.TextStyle(fontSize: 10)),
              ),
              pw.Positioned(
                left: 163,
                top: 170,
                //OK
                child: pw.Text(asegurado, style: pw.TextStyle(fontSize: 10)),
              ),
              pw.Positioned(
                left: 340,
                top: 157,
                //OK
                child: pw.Text(celular, style: pw.TextStyle(fontSize: 10)),
              ),

              // --- Ruta ---
              pw.Positioned(
                left: 163,
                top: 216,
                //OK
                child: pw.Text(origen, style: pw.TextStyle(fontSize: 10)),
              ),
              pw.Positioned(
                left: 163,
                top: 230,
                //OK
                child: pw.Text(destino, style: pw.TextStyle(fontSize: 10)),
              ),

              // --- Firma del Pasajero/Asegurado ---
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
