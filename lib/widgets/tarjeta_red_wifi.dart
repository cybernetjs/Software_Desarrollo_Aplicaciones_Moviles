import 'package:flutter/material.dart';

import '../modelos/red_wifi.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';
import '../utilidades/radio_wifi.dart';
import 'etiqueta_nivel.dart';

class TarjetaRedWifi extends StatelessWidget {
  const TarjetaRedWifi({super.key, required this.red});

  final RedWifi red;

  @override
  Widget build(BuildContext context) {
    final nivel = red.seguridad.nivel;
    final canal = RadioWifi.canalDesdeFrecuencia(red.frecuencia);
    final banda = RadioWifi.banda(red.frecuencia);

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
            child: Icon(
              RadioWifi.iconoSenal(red.senal),
              size: 22,
              color: Colores.fondo,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  red.esOculta ? 'Red oculta' : red.nombre,
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
                  'Canal $canal · $banda · ${red.senal} dBm',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colores.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          EtiquetaNivel(nivel: nivel, texto: red.seguridad.etiqueta),
        ],
      ),
    );
  }
}