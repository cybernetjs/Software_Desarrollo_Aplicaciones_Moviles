import 'package:flutter/material.dart';

import '../tema/colores.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Antivirus',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colores.textoPrincipal,
          ),
        ),
      ),
    );
  }
}