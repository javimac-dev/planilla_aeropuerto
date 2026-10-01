import 'package:flutter/material.dart';
import 'screens/pantalla_voz.dart';

void main() {
  runApp(const PlanillaAeropuertoApp());
}

class PlanillaAeropuertoApp extends StatelessWidget {
  const PlanillaAeropuertoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planilla Aeropuerto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const PantallaVoz(),
    );
  }
}