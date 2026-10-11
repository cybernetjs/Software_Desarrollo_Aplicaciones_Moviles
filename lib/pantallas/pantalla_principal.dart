import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import '../controladores/controlador_dispositivo.dart';
import '../controladores/controlador_wifi.dart';
import 'pantalla_aplicaciones.dart';
import 'pantalla_dispositivo.dart';
import 'pantalla_inicio.dart';
import 'pantalla_wifi.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _EstadoPantallaPrincipal();
}

class _EstadoPantallaPrincipal extends State<PantallaPrincipal> {
  late final ControladorAnalisis _controladorAnalisis;
  late final ControladorDispositivo _controladorDispositivo;
  late final ControladorWifi _controladorWifi;
  int _indiceActual = 0;

  @override
  void initState() {
    super.initState();
    _controladorAnalisis = ControladorAnalisis();
    _controladorDispositivo = ControladorDispositivo()..revisar();
    _controladorWifi = ControladorWifi();
  }

  @override
  void dispose() {
    _controladorAnalisis.dispose();
    _controladorDispositivo.dispose();
    _controladorWifi.dispose();
    super.dispose();
  }

  void _irAAplicaciones() {
    setState(() => _indiceActual = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _indiceActual,
          children: [
            PantallaInicio(
              controlador: _controladorAnalisis,
              alVerResultados: _irAAplicaciones,
            ),
            PantallaAplicaciones(controlador: _controladorAnalisis),
            PantallaDispositivo(controlador: _controladorDispositivo),
            PantallaWifi(controlador: _controladorWifi),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (indice) => setState(() => _indiceActual = indice),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Aplicaciones'),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_android),
            label: 'Dispositivo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.wifi), label: 'WiFi'),
        ],
      ),
    );
  }
}