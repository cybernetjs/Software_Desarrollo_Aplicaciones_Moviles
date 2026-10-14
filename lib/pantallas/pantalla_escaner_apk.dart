import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controladores/controlador_analisis.dart';
import '../controladores/controlador_apk.dart';
import '../modelos/nivel_riesgo.dart';
import '../modelos/resultado_apk.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';
import '../widgets/encabezado_pantalla.dart';
import '../widgets/etiqueta_nivel.dart';
import '../widgets/tarjeta_informacion.dart';
import '../widgets/titulo_seccion.dart';

class PantallaEscanerApk extends StatelessWidget {
  const PantallaEscanerApk({super.key, required this.controlador});

  final ControladorApk controlador;

  List<Widget> _construirContenido() {
    switch (controlador.estado) {
      case EstadoAnalisis.inactivo:
        return const [
          TarjetaInformacion(
            titulo: 'Archivo',
            filas: [FilaInformacion('Estado', 'Sin analizar')],
          ),
          SizedBox(height: 12),
          _NotaPrivacidad(),
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
            titulo: 'Archivo',
            filas: [FilaInformacion('Estado', 'Con error')],
          ),
          const SizedBox(height: 12),
          Text(
            controlador.mensajeError ?? 'No se pudo analizar el archivo.',
            style: const TextStyle(fontSize: 14, color: Colores.textoSecundario),
          ),
        ];
      case EstadoAnalisis.completado:
        return _construirResultado();
    }
  }

  List<Widget> _construirResultado() {
    final resultado = controlador.resultado;
    if (resultado == null) return const [];
    final informacion = resultado.informacion;

    return [
      _TarjetaVeredicto(resultado: resultado),
      const SizedBox(height: 12),
      TarjetaInformacion(
        titulo: 'Archivo',
        filas: [
          FilaInformacion('Nombre', informacion.nombreArchivo),
          FilaInformacion('Tamaño', informacion.tamanoLegible),
          FilaInformacion('Paquete', informacion.paquete ?? 'No disponible'),
          FilaInformacion('Versión', informacion.version ?? 'No disponible'),
        ],
      ),
      const SizedBox(height: 12),
      _TarjetaHuella(sha256: informacion.sha256),
      const SizedBox(height: 24),
      const TituloSeccion('Análisis'),
      const SizedBox(height: 12),
      _ListaMotivos(resultado: resultado),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archivos')),
      body: ListenableBuilder(
        listenable: controlador,
        builder: (context, _) {
          final analizando = controlador.estado == EstadoAnalisis.analizando;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const EncabezadoPantalla(
                titulo: 'Escáner de APK',
                subtitulo: 'Analiza un archivo antes de instalarlo',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: analizando ? null : controlador.elegirArchivo,
                child: Text(analizando ? 'Analizando...' : 'Elegir archivo APK'),
              ),
              const SizedBox(height: 24),
              ..._construirContenido(),
            ],
          );
        },
      ),
    );
  }
}

class _NotaPrivacidad extends StatelessWidget {
  const _NotaPrivacidad();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'El archivo se analiza dentro de tu teléfono y no se envía a ningún servidor.',
      style: TextStyle(fontSize: 13, color: Colores.textoSecundario),
    );
  }
}

class _TarjetaVeredicto extends StatelessWidget {
  const _TarjetaVeredicto({required this.resultado});

  final ResultadoApk resultado;

  String _describir(NivelRiesgo nivel) {
    switch (nivel) {
      case NivelRiesgo.bajo:
        return 'Sin señales de riesgo en este análisis';
      case NivelRiesgo.medio:
        return 'Revisa los motivos antes de instalarlo';
      case NivelRiesgo.alto:
        return 'No lo instales si no confías en su origen';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nivel = resultado.nivel;

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
                  resultado.informacion.nombreMostrado,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _describir(nivel),
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

class _TarjetaHuella extends StatelessWidget {
  const _TarjetaHuella({required this.sha256});

  final String sha256;

  Future<void> _copiar(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: sha256));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('SHA-256 copiado')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HUELLA SHA-256',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 14),
          SelectableText(
            sha256,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              fontFamily: 'monospace',
              color: Colores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _copiar(context),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pégala en virustotal.com para ver si otros motores la detectan.',
            style: TextStyle(fontSize: 12, color: Colores.textoSecundario),
          ),
        ],
      ),
    );
  }
}

class _ListaMotivos extends StatelessWidget {
  const _ListaMotivos({required this.resultado});

  final ResultadoApk resultado;

  @override
  Widget build(BuildContext context) {
    final motivos = resultado.motivos;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: motivos.isEmpty
          ? const Row(
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
          : Column(
              children: [
                for (final motivo in motivos)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: motivo == motivos.last ? 0 : 12,
                    ),
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
              ],
            ),
    );
  }
}