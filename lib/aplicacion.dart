import 'package:flutter/material.dart';

import 'pantallas/pantalla_inicio.dart';
import 'tema/tema_aplicacion.dart';

class Aplicacion extends StatelessWidget {
  const Aplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antivirus',
      debugShowCheckedModeBanner: false,
      theme: TemaAplicacion.oscuro,
      home: const PantallaInicio(),
    );
  }
}