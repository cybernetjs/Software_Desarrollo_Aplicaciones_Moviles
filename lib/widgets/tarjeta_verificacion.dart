import 'package:flutter/material.dart';

import '../modelos/nivel_riesgo.dart';
import '../modelos/verificacion_seguridad.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';
import 'etiqueta_nivel.dart';

class TarjetaVerificacion extends StatelessWidget {
  const TarjetaVerificacion({super.key, required this.verificacion});

  final VerificacionSeguridad verificacion;

  String _textoEtiqueta() {
    switch (verificacion.nivel) {
      case NivelRiesgo.bajo:
        return 'Correcto';
      case NivelRiesgo.medio:
        return 'Revisar';
      case NivelRiesgo.alto:
        return 'Riesgo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nivel = verificacion.nivel;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: nivel.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(verificacion.icono, size: 22, color: Colores.fondo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verificacion.titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  verificacion.detalle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colores.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          EtiquetaNivel(nivel: nivel, texto: _textoEtiqueta()),
        ],
      ),
    );
  }
}