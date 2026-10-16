import 'package:flutter/material.dart';

import '../modelos/entrada_dns.dart';
import '../modelos/nivel_riesgo.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';
import 'etiqueta_nivel.dart';

class TarjetaConsultaDns extends StatelessWidget {
  const TarjetaConsultaDns({
    super.key,
    required this.entrada,
    required this.sospechosa,
  });

  final EntradaDns entrada;
  final bool sospechosa;

  @override
  Widget build(BuildContext context) {
    final bloqueada = entrada.fueBloqueada;
    final colorIcono = bloqueada
        ? Colores.peligro
        : sospechosa
            ? Colores.advertencia
            : Colores.superficieElevada;
    final iconoFondo = bloqueada || sospechosa
        ? Colores.fondo
        : Colores.textoSecundario;
    final icono = bloqueada ? Icons.block : Icons.language;
    final textoConsultas =
        entrada.consultas == 1 ? '1 consulta' : '${entrada.consultas} consultas';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorIcono,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, size: 22, color: iconoFondo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entrada.dominio,
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
                  '${entrada.nombreMostrado} · $textoConsultas',
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
          if (bloqueada || sospechosa) ...[
            const SizedBox(width: 10),
            EtiquetaNivel(
              nivel: bloqueada ? NivelRiesgo.alto : NivelRiesgo.medio,
              texto: bloqueada ? 'Bloqueado' : 'Sospechoso',
            ),
          ],
        ],
      ),
    );
  }
}