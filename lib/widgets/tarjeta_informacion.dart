import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';

class FilaInformacion {
  const FilaInformacion(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;
}

class TarjetaInformacion extends StatelessWidget {
  const TarjetaInformacion({
    super.key,
    required this.titulo,
    required this.filas,
  });

  final String titulo;
  final List<FilaInformacion> filas;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colores.textoPrincipal,
            ),
          ),
          for (final fila in filas)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    fila.etiqueta,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colores.textoSecundario,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      fila.valor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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