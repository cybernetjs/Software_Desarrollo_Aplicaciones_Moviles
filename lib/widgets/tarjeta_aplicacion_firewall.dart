import 'package:flutter/material.dart';

import '../modelos/aplicacion_instalada.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';

class TarjetaAplicacionFirewall extends StatelessWidget {
  const TarjetaAplicacionFirewall({
    super.key,
    required this.aplicacion,
    required this.bloqueada,
    required this.alCambiar,
  });

  final AplicacionInstalada aplicacion;
  final bool bloqueada;
  final VoidCallback alCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bloqueada ? Colores.peligro : Colores.superficieElevada,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              bloqueada ? Icons.block : Icons.public,
              size: 22,
              color: bloqueada ? Colores.fondo : Colores.textoSecundario,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aplicacion.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bloqueada ? 'Sin internet' : aplicacion.paquete,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colores.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: bloqueada, onChanged: (_) => alCambiar()),
        ],
      ),
    );
  }
}