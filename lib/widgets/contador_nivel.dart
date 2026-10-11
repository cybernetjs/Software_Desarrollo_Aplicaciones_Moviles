import 'package:flutter/material.dart';

import '../modelos/nivel_riesgo.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';

class ContadorNivel extends StatelessWidget {
  const ContadorNivel({super.key, required this.nivel, required this.cantidad});

  final NivelRiesgo nivel;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: nivel.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(nivel.icono, size: 20, color: Colores.fondo),
          ),
          const SizedBox(height: 14),
          Text(
            '$cantidad',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colores.textoPrincipal,
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