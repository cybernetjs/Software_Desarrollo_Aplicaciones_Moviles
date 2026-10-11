import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import '../modelos/nivel_riesgo.dart';
import '../tema/colores.dart';
import '../widgets/contador_nivel.dart';
import '../widgets/encabezado_pantalla.dart';
import '../widgets/tarjeta_informacion.dart';
import '../widgets/tarjeta_resultado.dart';

class PantallaAplicaciones extends StatelessWidget {
  const PantallaAplicaciones({super.key, required this.controlador});

  final ControladorAnalisis controlador;

  List<Widget> _construirContenido() {
    switch (controlador.estado) {
      case EstadoAnalisis.inactivo:
        return [
          const TarjetaInformacion(
            titulo: 'Análisis',
            filas: [FilaInformacion('Estado', 'Sin analizar')],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: controlador.analizar,
            child: const Text('Analizar ahora'),
          ),
        ];
      case EstadoAnalisis.analizando:
        return const [
          Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case EstadoAnalisis.error:
        return [
          const TarjetaInformacion(
            titulo: 'Análisis',
            filas: [FilaInformacion('Estado', 'Con error')],
          ),
          const SizedBox(height: 12),
          Text(
            controlador.mensajeError ?? 'No se pudo completar el análisis.',
            style: const TextStyle(fontSize: 14, color: Colores.textoSecundario),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: controlador.analizar,
            child: const Text('Intentar de nuevo'),
          ),
        ];
      case EstadoAnalisis.completado:
        return _construirResultados();
    }
  }

  List<Widget> _construirResultados() {
    if (controlador.resultados.isEmpty) {
      return const [
        TarjetaInformacion(
          titulo: 'Resultado',
          filas: [FilaInformacion('Aplicaciones instaladas por ti', '0')],
        ),
      ];
    }

    return [
      Row(
        children: [
          for (final nivel in NivelRiesgo.values.reversed) ...[
            Expanded(
              child: ContadorNivel(
                nivel: nivel,
                cantidad: controlador.contarPorNivel(nivel),
              ),
            ),
            if (nivel != NivelRiesgo.bajo) const SizedBox(width: 10),
          ],
        ],
      ),
      const SizedBox(height: 20),
      for (final resultado in controlador.resultados) ...[
        TarjetaResultado(resultado: resultado),
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
              titulo: 'Aplicaciones',
              subtitulo: 'Permisos y riesgos de lo instalado',
            ),
            const SizedBox(height: 20),
            ..._construirContenido(),
          ],
        );
      },
    );
  }
}