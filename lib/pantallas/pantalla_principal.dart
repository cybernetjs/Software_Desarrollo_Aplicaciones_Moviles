import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import '../controladores/controlador_apk.dart';
import '../controladores/controlador_dispositivo.dart';
import '../controladores/controlador_firewall.dart';
import '../controladores/controlador_vigilancia.dart';
import '../controladores/controlador_wifi.dart';
import 'pantalla_aplicaciones.dart';
import 'pantalla_dispositivo.dart';
import 'pantalla_escaner_apk.dart';
import 'pantalla_firewall.dart';
import 'pantalla_inicio.dart';
import 'pantalla_wifi.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _EstadoPantallaPrincipal();
}

class _EstadoPantallaPrincipal extends State<PantallaPrincipal>
    with WidgetsBindingObserver {
  late final ControladorAnalisis _controladorAnalisis;
  late final ControladorDispositivo _controladorDispositivo;
  late final ControladorWifi _controladorWifi;
  late final ControladorFirewall _controladorFirewall;
  late final ControladorApk _controladorApk;
  late final ControladorVigilancia _controladorVigilancia;
  int _indiceActual = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controladorAnalisis = ControladorAnalisis();
    _controladorDispositivo = ControladorDispositivo()..revisar();
    _controladorWifi = ControladorWifi();
    _controladorFirewall = ControladorFirewall()..cargar();
    _controladorApk = ControladorApk();
    _controladorVigilancia = ControladorVigilancia()..cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controladorAnalisis.dispose();
    _controladorDispositivo.dispose();
    _controladorWifi.dispose();
    _controladorFirewall.dispose();
    _controladorApk.dispose();
    _controladorVigilancia.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) {
      _controladorVigilancia.cargar();
    }
  }

  void _irAAplicaciones() {
    setState(() => _indiceActual = 1);
  }

  void _abrirEscanerApk() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaEscanerApk(controlador: _controladorApk),
      ),
    );
  }

  Future<void> _revisarNuevas() async {
    await _controladorAnalisis.analizar();
    if (_controladorAnalisis.estado != EstadoAnalisis.completado) return;

    await _controladorVigilancia.marcarRevisadas();
    if (!mounted) return;
    _irAAplicaciones();
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
              vigilancia: _controladorVigilancia,
              alVerResultados: _irAAplicaciones,
              alAbrirArchivos: _abrirEscanerApk,
              alRevisarNuevas: _revisarNuevas,
            ),
            PantallaAplicaciones(controlador: _controladorAnalisis),
            PantallaDispositivo(controlador: _controladorDispositivo),
            PantallaWifi(controlador: _controladorWifi),
            PantallaFirewall(controlador: _controladorFirewall),
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
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Apps'),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_android),
            label: 'Equipo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.wifi), label: 'WiFi'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Firewall',
          ),
        ],
      ),
    );
  }
}