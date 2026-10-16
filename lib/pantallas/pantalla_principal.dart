import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import '../controladores/controlador_apk.dart';
import '../controladores/controlador_completo.dart';
import '../controladores/controlador_descargas.dart';
import '../controladores/controlador_dispositivo.dart';
import '../controladores/controlador_filtro_dns.dart';
import '../controladores/controlador_firewall.dart';
import '../controladores/controlador_stalkerware.dart';
import '../controladores/controlador_vigilancia.dart';
import '../controladores/controlador_wifi.dart';
import 'pantalla_aplicaciones.dart';
import 'pantalla_descargas.dart';
import 'pantalla_dispositivo.dart';
import 'pantalla_escaner_apk.dart';
import 'pantalla_filtro_dns.dart';
import 'pantalla_firewall.dart';
import 'pantalla_inicio.dart';
import 'pantalla_stalkerware.dart';
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
  late final ControladorStalkerware _controladorStalkerware;
  late final ControladorDescargas _controladorDescargas;
  late final ControladorFiltroDns _controladorFiltroDns;
  late final ControladorCompleto _controladorCompleto;
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
    _controladorStalkerware = ControladorStalkerware();
    _controladorDescargas = ControladorDescargas();
    _controladorFiltroDns = ControladorFiltroDns(
      alCambiarModo: _controladorFirewall.sincronizarEstado,
    );
    _controladorCompleto = ControladorCompleto(
      analisis: _controladorAnalisis,
      stalkerware: _controladorStalkerware,
      dispositivo: _controladorDispositivo,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controladorCompleto.dispose();
    _controladorAnalisis.dispose();
    _controladorDispositivo.dispose();
    _controladorWifi.dispose();
    _controladorFirewall.dispose();
    _controladorApk.dispose();
    _controladorVigilancia.dispose();
    _controladorStalkerware.dispose();
    _controladorDescargas.dispose();
    _controladorFiltroDns.dispose();
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

  void _abrirStalkerware() {
    _controladorStalkerware.cargarLista();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PantallaStalkerware(controlador: _controladorStalkerware),
      ),
    );
  }

  void _abrirDescargas() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaDescargas(controlador: _controladorDescargas),
      ),
    );
  }

  void _abrirFiltroDns() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaFiltroDns(controlador: _controladorFiltroDns),
      ),
    );
  }

  Future<void> _revisarNuevas() async {
    await _controladorCompleto.ejecutar();
    if (_controladorCompleto.estado != EstadoAnalisis.completado) return;

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
              completo: _controladorCompleto,
              vigilancia: _controladorVigilancia,
              alVerResultados: _irAAplicaciones,
              alAbrirArchivos: _abrirEscanerApk,
              alAbrirStalkerware: _abrirStalkerware,
              alAbrirDescargas: _abrirDescargas,
              alAbrirFiltroDns: _abrirFiltroDns,
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