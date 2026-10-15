import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import '../controladores/controlador_descargas.dart';
import '../modelos/nivel_riesgo.dart';
import '../tema/colores.dart';
import '../widgets/contador_nivel.dart';
import '../widgets/encabezado_pantalla.dart';
import '../widgets/tarjeta_informacion.dart';
import '../widgets/tarjeta_resultado_apk.dart';
import '../widgets/titulo_seccion.dart';

class PantallaDescargas extends StatefulWidget {
  const PantallaDescargas({super.key, required this.controlador});

  final ControladorDescargas controlador;

  @override
  State<PantallaDescargas> createState() => _EstadoPantallaDescargas();
}

class _EstadoPantallaDescargas extends State<PantallaDescargas>
    with WidgetsBindingObserver {
  ControladorDescargas get _controlador => widget.controlador;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controlador.consultarPermiso();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) {
      _controlador.consultarPermiso();
    }
  }

  List<Widget> _construirAccion() {
    if (!_controlador.soportado) {
      return const [
        _Nota('Esta función necesita Android 11 o superior.'),
        SizedBox(height: 24),
      ];
    }

    if (!_controlador.concedido) {
      return [
        FilledButton(
          onPressed: _controlador.abrirAjustes,
          child: const Text('Conceder acceso a archivos'),
        ),
        const SizedBox(height: 12),
        const _Nota(
          'Android pide un permiso especial para leer la carpeta Descargas. En la pantalla que se abre, activa el acceso para esta app y vuelve aquí.',
        ),
        const SizedBox(height: 24),
      ];
    }

    final revisando = _controlador.estado == EstadoAnalisis.analizando;
    return [
      FilledButton(
        onPressed: revisando ? null : _controlador.revisar,
        child: Text(revisando ? 'Revisando...' : 'Revisar descargas'),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _construirContenido() {
    if (!_controlador.soportado || !_controlador.concedido) return const [];

    switch (_controlador.estado) {
      case EstadoAnalisis.inactivo:
        return const [
          TarjetaInformacion(
            titulo: 'Carpeta',
            filas: [
              FilaInformacion('Ubicación', 'Descargas'),
              FilaInformacion('Estado', 'Sin revisar'),
            ],
          ),
          SizedBox(height: 12),
          _Nota(
            'Analiza hasta 100 archivos APK de la carpeta Descargas, incluidas sus subcarpetas, sin enviarlos a ningún servidor.',
          ),
        ];
      case EstadoAnalisis.analizando:
        return [_construirProgreso()];
      case EstadoAnalisis.error:
        return [
          const TarjetaInformacion(
            titulo: 'Carpeta',
            filas: [FilaInformacion('Estado', 'Con error')],
          ),
          const SizedBox(height: 12),
          _Nota(_controlador.mensajeError ?? 'No se pudo completar la revisión.'),
        ];
      case EstadoAnalisis.completado:
        return _construirResultado();
    }
  }

  Widget _construirProgreso() {
    final total = _controlador.total;
    final valor = total == 0 ? null : _controlador.revisados / total;

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          LinearProgressIndicator(value: valor, minHeight: 6),
          const SizedBox(height: 14),
          Text(
            total == 0
                ? 'Buscando archivos APK...'
                : 'Revisando ${_controlador.revisados} de $total',
            style: const TextStyle(fontSize: 14, color: Colores.textoSecundario),
          ),
        ],
      ),
    );
  }

  List<Widget> _construirResultado() {
    final resultados = _controlador.resultados;
    final omitidos = _controlador.omitidos;

    if (resultados.isEmpty && omitidos == 0) {
      return const [
        TarjetaInformacion(
          titulo: 'Resultado',
          filas: [FilaInformacion('Archivos APK encontrados', '0')],
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
                cantidad: _controlador.contarPorNivel(nivel),
              ),
            ),
            if (nivel != NivelRiesgo.bajo) const SizedBox(width: 10),
          ],
        ],
      ),
      if (omitidos > 0) ...[
        const SizedBox(height: 12),
        _Nota('No se pudieron leer $omitidos archivos.'),
      ],
      const SizedBox(height: 24),
      TituloSeccion('Archivos revisados (${resultados.length})'),
      const SizedBox(height: 12),
      for (final resultado in resultados) ...[
        TarjetaResultadoApk(resultado: resultado),
        const SizedBox(height: 10),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descargas')),
      body: ListenableBuilder(
        listenable: _controlador,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const EncabezadoPantalla(
                titulo: 'Revisar descargas',
                subtitulo: 'Analiza los APK que bajaste a tu teléfono',
              ),
              const SizedBox(height: 20),
              ..._construirAccion(),
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