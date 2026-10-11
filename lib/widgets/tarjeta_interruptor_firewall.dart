import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';

class TarjetaInterruptorFirewall extends StatelessWidget {
  const TarjetaInterruptorFirewall({
    super.key,
    required this.activo,
    required this.totalBloqueadas,
    required this.ocupado,
    required this.alCambiar,
  });

  final bool activo;
  final int totalBloqueadas;
  final bool ocupado;
  final ValueChanged<bool> alCambiar;

  String _describirEstado() {
    if (!activo) return 'Desactivado';
    if (totalBloqueadas == 0) return 'Activo · ninguna app bloqueada';
    final texto = totalBloqueadas == 1 ? 'app bloqueada' : 'apps bloqueadas';
    return 'Activo · $totalBloqueadas $texto';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: activo ? Colores.seguro : Colores.superficieElevada,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.local_fire_department,
              size: 26,
              color: activo ? Colores.fondo : Colores.textoSecundario,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firewall',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _describirEstado(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colores.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: activo, onChanged: ocupado ? null : alCambiar),
        ],
      ),
    );
  }
}