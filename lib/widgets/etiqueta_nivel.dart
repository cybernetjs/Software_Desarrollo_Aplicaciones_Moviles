import 'package:flutter/material.dart';

import '../modelos/nivel_riesgo.dart';
import '../tema/colores.dart';

class EtiquetaNivel extends StatelessWidget {
  const EtiquetaNivel({super.key, required this.nivel, this.texto});

  final NivelRiesgo nivel;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: nivel.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto ?? nivel.etiqueta,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colores.fondo,
        ),
      ),
    );
  }
}