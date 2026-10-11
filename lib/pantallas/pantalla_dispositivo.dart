import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import '../controladores/controlador_dispositivo.dart';
import '../tema/colores.dart';
import '../widgets/encabezado_pantalla.dart';
import '../widgets/tarjeta_informacion.dart';
import '../widgets/tarjeta_verificacion.dart';

class PantallaDispositivo extends StatelessWidget {
  const PantallaDispositivo({super.key, required this.controlador});

  final ControladorDispositivo controlador;

  List<Widget> _construirContenido() {
    switch (controlador.estado) {
      case EstadoAnalisis.inactivo:
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
            titulo: 'Revisión',
            filas: [FilaInformacion('Estado', 'Con error')],
          ),
          const SizedBox(height: 12),
          Text(
            controlador.mensajeError ?? 'No se pudo revisar el dispositivo.',
            style: const TextStyle(fontSize: 14, color: Colores.textoSecundario),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: controlador.revisar,
            child: const Text('Intentar de nuevo'),
          ),
        ];
      case EstadoAnalisis.completado:
        return _construirResultado();
    }
  }

  List<Widget> _construirResultado() {
    final datos = controlador.datos;
    if (datos == null) return const [];

    return [
      TarjetaInformacion(
        titulo: 'Sistema',
        filas: [
          FilaInformacion('Versión', 'Android ${datos.versionAndroid}'),
          FilaInformacion(
            'Parche de seguridad',
            datos.parcheSeguridad ?? 'No disponible',
          ),
        ],
      ),
      const SizedBox(height: 20),
      const Text(
        'Seguridad',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colores.textoPrincipal,
        ),
      ),
      const SizedBox(height: 12),
      for (final verificacion in controlador.verificaciones) ...[
        TarjetaVerificacion(verificacion: verificacion),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
      FilledButton(
        onPressed: controlador.revisar,
        child: const Text('Revisar de nuevo'),
      ),
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
              titulo: 'Dispositivo',
              subtitulo: 'Estado de seguridad del equipo',
            ),
            const SizedBox(height: 20),
            ..._construirContenido(),
          ],
        );
      },
    );
  }
}