import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import '../controladores/controlador_stalkerware.dart';
import '../modelos/nivel_riesgo.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';
import '../widgets/encabezado_pantalla.dart';
import '../widgets/etiqueta_nivel.dart';
import '../widgets/tarjeta_informacion.dart';
import '../widgets/tarjeta_resultado.dart';
import '../widgets/titulo_seccion.dart';

class PantallaStalkerware extends StatelessWidget {
  const PantallaStalkerware({super.key, required this.controlador});

  final ControladorStalkerware controlador;

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes $hora:$minuto';
  }

  List<Widget> _construirLista() {
    final actualizando = controlador.actualizando;
    final aviso = controlador.avisoLista;
    final fecha = controlador.fechaLista;

    return [
      TarjetaInformacion(
        titulo: 'Lista de referencia',
        filas: [
          FilaInformacion(
            'Apps conocidas',
            controlador.listaCargada
                ? '${controlador.totalIndicadores}'
                : 'No disponible',
          ),
          FilaInformacion(
            'Actualizada',
            fecha == null ? 'Incluida en la app' : _formatearFecha(fecha),
          ),
          const FilaInformacion('Fuente', 'Echap · CC BY 4.0'),
        ],
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: actualizando ? null : controlador.actualizarLista,
        icon: const Icon(Icons.sync, size: 18),
        label: Text(actualizando ? 'Actualizando...' : 'Actualizar lista'),
      ),
      if (aviso != null) ...[
        const SizedBox(height: 10),
        _Nota(aviso),
      ],
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _construirContenido() {
    switch (controlador.estado) {
      case EstadoAnalisis.inactivo:
        return const [
          TarjetaInformacion(
            titulo: 'Revisión',
            filas: [FilaInformacion('Estado', 'Sin revisar')],
          ),
          SizedBox(height: 12),
          _Nota(
            'Compara tus apps con una lista pública de stalkerware conocido y busca apps ocultas con acceso a ubicación, mensajes, micrófono o administración del dispositivo.',
          ),
        ];
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
            titulo: 'Revisión',
            filas: [FilaInformacion('Estado', 'Con error')],
          ),
          const SizedBox(height: 12),
          _Nota(controlador.mensajeError ?? 'No se pudo completar la revisión.'),
        ];
      case EstadoAnalisis.completado:
        return _construirResultado();
    }
  }

  List<Widget> _construirResultado() {
    final hallazgos = controlador.hallazgos;

    return [
      _TarjetaVeredicto(
        total: hallazgos.length,
        nivel: controlador.nivelGeneral,
      ),
      const SizedBox(height: 12),
      TarjetaInformacion(
        titulo: 'Revisión',
        filas: [
          FilaInformacion(
            'Apps revisadas',
            '${controlador.aplicacionesRevisadas}',
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (hallazgos.isEmpty)
        const _Nota(
          'Esto no garantiza que tu teléfono esté libre de stalkerware: la lista de referencia no es completa.',
        )
      else ...[
        const _AvisoSeguridad(),
        const SizedBox(height: 24),
        TituloSeccion('Apps sospechosas (${hallazgos.length})'),
        const SizedBox(height: 12),
        for (final hallazgo in hallazgos) ...[
          TarjetaResultado(resultado: hallazgo),
          const SizedBox(height: 10),
        ],
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stalkerware')),
      body: ListenableBuilder(
        listenable: controlador,
        builder: (context, _) {
          final revisando = controlador.estado == EstadoAnalisis.analizando;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const EncabezadoPantalla(
                titulo: 'Detector de stalkerware',
                subtitulo: 'Busca apps espía instaladas sin tu permiso',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: revisando ? null : controlador.revisar,
                child: Text(revisando ? 'Revisando...' : 'Revisar ahora'),
              ),
              const SizedBox(height: 16),
              ..._construirLista(),
              ..._construirContenido(),
            ],
          );
        },
      ),
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 13,
        height: 1.4,
        color: Colores.textoSecundario,
      ),
    );
  }
}

class _TarjetaVeredicto extends StatelessWidget {
  const _TarjetaVeredicto({required this.total, required this.nivel});

  final int total;
  final NivelRiesgo nivel;

  String get _titulo {
    if (total == 0) return 'Sin señales de stalkerware';
    return total == 1 ? '1 app sospechosa' : '$total apps sospechosas';
  }

  String get _detalle {
    if (total == 0) {
      return 'No hay coincidencias ni apps ocultas con poderes de espionaje';
    }
    return 'Revisa cada una antes de actuar';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: nivel.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(nivel.icono, size: 28, color: Colores.fondo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _detalle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colores.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          EtiquetaNivel(nivel: nivel),
        ],
      ),
    );
  }
}

class _AvisoSeguridad extends StatelessWidget {
  const _AvisoSeguridad();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 22, color: Colores.advertencia),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antes de desinstalar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colores.textoPrincipal,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Si crees que alguien te vigila, borrar la app puede avisarle. Piensa si es seguro hacerlo y, si estás en riesgo, busca apoyo de una organización especializada o de las autoridades.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colores.textoSecundario,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Si no te deja desinstalarla, desactiva primero su permiso de administrador del dispositivo en Ajustes > Seguridad.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colores.textoSecundario,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Información para personas afectadas: stopstalkerware.org',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colores.textoSecundario,
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