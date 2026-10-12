import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'screens/pantalla_formulario.dart';

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
      home: const PantallaSplash(),
    );
  }
}

// ==========================================
// PANTALLA DE INICIO (SPLASH)
// ==========================================
class PantallaSplash extends StatefulWidget {
  const PantallaSplash({super.key});

  @override
  State<PantallaSplash> createState() => _PantallaSplashState();
}

class _PantallaSplashState extends State<PantallaSplash> {
  String _versionApp = '';

  @override
  void initState() {
    super.initState();
    _obtenerVersion();

    // Espera 2 segundos y pasa automáticamente a la pantalla del formulario
    Future.delayed(const Duration(milliseconds: 2000), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaFormulario()),
      );
    });
  }

  Future<void> _obtenerVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _versionApp = 'Versión ${packageInfo.version}';
      });
    } catch (e) {
      setState(() {
        _versionApp = 'Versión 1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Contenido central (Título de la app y versión)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.flight_takeoff,
                  size: 70,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Planilla de Servicio",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Aeropuerto",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Versión dinámica cargada desde el pubspec.yaml
                Text(
                  _versionApp,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Correo fijo abajo a la derecha
          Positioned(
            bottom: 24,
            right: 24,
            child: Text(
              "javimac@neurall.net",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}