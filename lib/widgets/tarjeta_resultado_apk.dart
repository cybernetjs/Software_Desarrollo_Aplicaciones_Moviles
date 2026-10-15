import 'package:flutter/material.dart';

import '../modelos/resultado_apk.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';
import 'etiqueta_nivel.dart';

class TarjetaResultadoApk extends StatelessWidget {
  const TarjetaResultadoApk({super.key, required this.resultado});

  final ResultadoApk resultado;

  @override
  Widget build(BuildContext context) {
    final informacion = resultado.informacion;
    final nivel = resultado.nivel;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: TemaAplicacion.decoracionTarjeta,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: nivel.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(nivel.icono, size: 22, color: Colores.fondo),
        ),
        title: Text(
          informacion.nombreMostrado,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colores.textoPrincipal,
          ),
        ),
        subtitle: Text(
          '${informacion.nombreArchivo} · ${informacion.tamanoLegible}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colores.textoSecundario),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EtiquetaNivel(nivel: nivel),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, color: Colores.textoSecundario),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resultado.motivos.isEmpty)
            const Row(
              children: [
                Icon(Icons.verified_user, size: 20, color: Colores.seguro),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No se encontraron señales de riesgo',
                    style: TextStyle(fontSize: 13, color: Colores.textoPrincipal),
                  ),
                ),
              ],
            )
          else
            for (final motivo in resultado.motivos)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(motivo.icono, size: 20, color: Colores.primarioClaro),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        motivo.descripcion,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colores.textoPrincipal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          const Text(
            'SHA-256',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colores.textoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            informacion.sha256,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              fontFamily: 'monospace',
              color: Colores.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}