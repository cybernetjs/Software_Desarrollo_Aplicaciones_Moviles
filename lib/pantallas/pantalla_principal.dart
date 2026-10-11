import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import 'pantalla_aplicaciones.dart';
import 'pantalla_dispositivo.dart';
import 'pantalla_inicio.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _EstadoPantallaPrincipal();
}

class _EstadoPantallaPrincipal extends State<PantallaPrincipal> {
  late final ControladorAnalisis _controlador;
  int _indiceActual = 0;

  @override
  void initState() {
    super.initState();
    _controlador = ControladorAnalisis();
  }

  @override
  void dispose() {
    _controlador.dispose();
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
              controlador: _controlador,
              alVerResultados: _irAAplicaciones,
            ),
            PantallaAplicaciones(controlador: _controlador),
            const PantallaDispositivo(),
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
        ],
      ),
    );
  }
}