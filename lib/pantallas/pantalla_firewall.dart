import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import '../controladores/controlador_firewall.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';
import '../widgets/encabezado_pantalla.dart';
import '../widgets/tarjeta_aplicacion_firewall.dart';
import '../widgets/tarjeta_informacion.dart';
import '../widgets/tarjeta_interruptor_firewall.dart';
import '../widgets/titulo_seccion.dart';

class PantallaFirewall extends StatelessWidget {
  const PantallaFirewall({super.key, required this.controlador});

  final ControladorFirewall controlador;

  List<Widget> _construirContenido() {
    switch (controlador.estado) {
      case EstadoAnalisis.inactivo:
      case EstadoAnalisis.analizando:
        return const [
          Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case EstadoAnalisis.error:
        return [
          const TarjetaInformacion(
            titulo: 'Firewall',
            filas: [FilaInformacion('Estado', 'Con error')],
          ),
          const SizedBox(height: 12),
          Text(
            controlador.mensaje ?? 'No se pudo cargar el firewall.',
            style: const TextStyle(fontSize: 14, color: Colores.textoSecundario),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: controlador.cargar,
            child: const Text('Intentar de nuevo'),
          ),
        ];
      case EstadoAnalisis.completado:
        return _construirPanel();
    }
  }

  List<Widget> _construirPanel() {
    final aplicaciones = controlador.aplicacionesVisibles;
    final mensaje = controlador.mensaje;

    return [
      TarjetaInterruptorFirewall(
        activo: controlador.activo,
        totalBloqueadas: controlador.totalBloqueadas,
        ocupado: controlador.ocupado,
        alCambiar: controlador.alternarFirewall,
      ),
      if (mensaje != null) ...[
        const SizedBox(height: 12),
        Text(
          mensaje,
          style: const TextStyle(fontSize: 13, color: Colores.advertencia),
        ),
      ],
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
        decoration: TemaAplicacion.decoracionTarjeta,
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Mostrar apps del sistema',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colores.textoPrincipal,
                ),
              ),
            ),
            Switch(
              value: controlador.mostrarSistema,
              onChanged: (_) => controlador.alternarMostrarSistema(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      TituloSeccion('Aplicaciones (${aplicaciones.length})'),
      const SizedBox(height: 12),
      for (final aplicacion in aplicaciones) ...[
        TarjetaAplicacionFirewall(
          aplicacion: aplicacion,
          bloqueada: controlador.estaBloqueada(aplicacion.paquete),
          alCambiar: () => controlador.alternarBloqueo(aplicacion),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controlador,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const EncabezadoPantalla(
              titulo: 'Firewall',
              subtitulo: 'Controla qué apps pueden usar internet',
            ),
            const SizedBox(height: 20),
            ..._construirContenido(),
          ],
        );
      },
    );
  }
}