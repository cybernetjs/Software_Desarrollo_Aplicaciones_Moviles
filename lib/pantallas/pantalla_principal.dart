import 'package:flutter/material.dart';

import 'pantalla_aplicaciones.dart';
import 'pantalla_dispositivo.dart';
import 'pantalla_inicio.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _EstadoPantallaPrincipal();
}

class _EstadoPantallaPrincipal extends State<PantallaPrincipal> {
  int _indiceActual = 0;

  static const List<Widget> _pantallas = [
    PantallaInicio(),
    PantallaAplicaciones(),
    PantallaDispositivo(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _indiceActual, children: _pantallas),
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