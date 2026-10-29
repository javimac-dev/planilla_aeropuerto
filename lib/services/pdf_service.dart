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
    double xPositionLeft = 340; 
    if (estadoServicio == "Efectivo") {
      xPositionLeft = 280; 
    } else if (estadoServicio == "Cancelado") {
      xPositionLeft = 400; 
    }

    // Función auxiliar para descomponer una fecha en 6 dígitos (Día: 2, Mes: 2, Año: 2 últimos dígitos)
    List<String> descomponerFecha(String fechaStr) {
      List<String> resultado = ['0', '0', '0', '0', '0', '0'];
      try {
        final partes = fechaStr.split('-');
        if (partes.length == 3) {
          final d = partes[0].padLeft(2, '0');
          final m = partes[1].padLeft(2, '0');
          final a = partes[2];
          final anio2 = a.length >= 2 ? a.substring(a.length - 2) : a.padLeft(2, '0');
          resultado = [
            d[0], d[1],
            m[0], m[1],
            anio2[0], anio2[1]
          ];
        }
      } catch (_) {}
      return resultado;
    }

    final fechaDigitos = descomponerFecha(fecha);
    final soatDigitos = descomponerFecha(soat);

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

              // --- Fecha del Servicio Encajonada ---
              pw.Positioned(left: 172, top: 142, child: pw.Text(fechaDigitos[0], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Positioned(left: 181, top: 142, child: pw.Text(fechaDigitos[1], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              // Mes corrido 5px más a la derecha (202 + 5 = 207, 211 + 5 = 216)
              pw.Positioned(left: 207, top: 142, child: pw.Text(fechaDigitos[2], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Positioned(left: 216, top: 142, child: pw.Text(fechaDigitos[3], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              // Año corrido 20px a la derecha (222 + 20 = 242, 231 + 20 = 251)
              pw.Positioned(left: 242, top: 142, child: pw.Text(fechaDigitos[4], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Positioned(left: 251, top: 142, child: pw.Text(fechaDigitos[5], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),

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

              // --- Vencimiento SOAT Encajonado ---
              pw.Positioned(left: 172, top: 182, child: pw.Text(soatDigitos[0], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Positioned(left: 181, top: 182, child: pw.Text(soatDigitos[1], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Positioned(left: 207, top: 182, child: pw.Text(soatDigitos[2], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Positioned(left: 216, top: 182, child: pw.Text(soatDigitos[3], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Positioned(left: 242, top: 182, child: pw.Text(soatDigitos[4], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Positioned(left: 251, top: 182, child: pw.Text(soatDigitos[5], style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              
              // --- X del Estado del Servicio (Efectivo / Fallido / Cancelado) ---
              pw.Positioned(
                left: xPositionLeft,
                top: 197, 
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