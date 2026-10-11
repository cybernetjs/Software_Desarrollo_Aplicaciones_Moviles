import 'package:flutter/material.dart';

import '../modelos/nivel_riesgo.dart';
import '../tema/colores.dart';

class ContadorNivel extends StatelessWidget {
  const ContadorNivel({super.key, required this.nivel, required this.cantidad});

  final NivelRiesgo nivel;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: nivel.color.withAlpha(28),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$cantidad',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: nivel.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Riesgo ${nivel.etiqueta.toLowerCase()}',
            style: const TextStyle(fontSize: 12, color: Colores.textoSecundario),
          ),
        ],
      ),
    );
  }
}