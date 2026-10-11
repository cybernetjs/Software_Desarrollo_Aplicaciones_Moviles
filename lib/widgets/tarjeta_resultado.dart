import 'package:flutter/material.dart';

import '../modelos/resultado_analisis.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';

class TarjetaResultado extends StatelessWidget {
  const TarjetaResultado({super.key, required this.resultado});

  final ResultadoAnalisis resultado;

  @override
  Widget build(BuildContext context) {
    final aplicacion = resultado.aplicacion;
    final nivel = resultado.nivel;

    return Container(
      decoration: TemaAplicacion.decoracionTarjeta,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: nivel.color.withAlpha(40),
          child: Icon(Icons.shield, size: 18, color: nivel.color),
        ),
        title: Text(
          aplicacion.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colores.textoPrincipal,
          ),
        ),
        subtitle: Text(
          aplicacion.paquete,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colores.textoSecundario),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nivel.etiqueta,
              style: TextStyle(fontWeight: FontWeight.w600, color: nivel.color),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, color: Colores.textoSecundario),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resultado.motivos.isEmpty)
            const Text(
              'No se encontraron señales de riesgo',
              style: TextStyle(fontSize: 13, color: Colores.textoSecundario),
            )
          else
            for (final motivo in resultado.motivos)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 7, color: nivel.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        motivo,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colores.textoPrincipal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}