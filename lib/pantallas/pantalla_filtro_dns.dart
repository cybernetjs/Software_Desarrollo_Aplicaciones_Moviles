import 'dart:async';

import 'package:flutter/material.dart';

import '../controladores/controlador_filtro_dns.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';
import '../widgets/encabezado_pantalla.dart';
import '../widgets/tarjeta_consulta_dns.dart';
import '../widgets/tarjeta_informacion.dart';
import '../widgets/titulo_seccion.dart';

class PantallaFiltroDns extends StatefulWidget {
  const PantallaFiltroDns({super.key, required this.controlador});

  final ControladorFiltroDns controlador;

  @override
  State<PantallaFiltroDns> createState() => _EstadoPantallaFiltroDns();
}

class _EstadoPantallaFiltroDns extends State<PantallaFiltroDns>
    with WidgetsBindingObserver {
  static const Duration _intervalo = Duration(seconds: 3);
  static const int _maximoActividad = 100;

  Timer? _temporizador;

  ControladorFiltroDns get _controlador => widget.controlador;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controlador.cargar();
    _temporizador = Timer.periodic(
      _intervalo,
      (_) => _controlador.actualizarRegistro(),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) {
      _controlador.cargar();
    }
  }

  List<Widget> _construirActividad() {
    final alertas = _controlador.alertas;
    final actividad = _controlador.actividad.take(_maximoActividad).toList();

    return [
      TarjetaInformacion(
        titulo: 'Actividad',
        filas: [
          FilaInformacion('Consultas', '${_controlador.totalConsultas}'),
          FilaInformacion('Bloqueadas', '${_controlador.totalBloqueadas}'),
          FilaInformacion('Apps activas', '${_controlador.appsActivas}'),
          FilaInformacion(
            'Dominios en la lista',
            '${_controlador.dominiosBloqueados}',
          ),
        ],
      ),
      if (alertas.isNotEmpty) ...[
        const SizedBox(height: 24),
        TituloSeccion('Alertas (${alertas.length})'),
        const SizedBox(height: 12),
        for (final entrada in alertas) ...[
          TarjetaConsultaDns(
            entrada: entrada,
            sospechosa: _controlador.esSospechosa(entrada),
          ),
          const SizedBox(height: 10),
        ],
      ],
      if (actividad.isNotEmpty) ...[
        const SizedBox(height: 24),
        const TituloSeccion('Actividad reciente'),
        const SizedBox(height: 12),
        for (final entrada in actividad) ...[
          TarjetaConsultaDns(entrada: entrada, sospechosa: false),
          const SizedBox(height: 10),
        ],
      ],
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: _controlador.ocupado ? null : _controlador.limpiarRegistro,
        icon: const Icon(Icons.delete_outline, size: 18),
        label: const Text('Limpiar registro'),
      ),
      const SizedBox(height: 10),
      const _Nota(
        'El registro se guarda solo en la memoria de la app y se borra al cerrarla.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filtro DNS')),
      body: ListenableBuilder(
        listenable: _controlador,
        builder: (context, _) {
          final mensaje = _controlador.mensaje;
          final hayActividad = _controlador.activo || _controlador.totalConsultas > 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const EncabezadoPantalla(
                titulo: 'Filtro DNS',
                subtitulo: 'Dominios que consulta cada app',
              ),
              const SizedBox(height: 20),
              _TarjetaInterruptor(
                activo: _controlador.activo,
                ocupado: _controlador.ocupado,
                alCambiar: _controlador.alternar,
              ),
              if (mensaje != null) ...[
                const SizedBox(height: 12),
                Text(
                  mensaje,
                  style: const TextStyle(fontSize: 13, color: Colores.advertencia),
                ),
              ],
              if (_controlador.dnsPrivadoEstricto) ...[
                const SizedBox(height: 12),
                const Text(
                  'El DNS privado de Android está en modo estricto: las apps lo usan y se saltan este filtro. Cámbialo a Automático en Ajustes > Red.',
                  style: TextStyle(fontSize: 13, color: Colores.advertencia),
                ),
              ],
              const SizedBox(height: 12),
              const _Nota(
                'Solo puede haber una VPN activa: al encender el filtro, el firewall se apaga.',
              ),
              const SizedBox(height: 24),
              if (hayActividad)
                ..._construirActividad()
              else
                const _Nota(
                  'Enciende el filtro para ver qué dominios consulta cada app y bloquear los de stalkerware conocido.',
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaInterruptor extends StatelessWidget {
  const _TarjetaInterruptor({
    required this.activo,
    required this.ocupado,
    required this.alCambiar,
  });

  final bool activo;
  final bool ocupado;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: activo ? Colores.seguro : Colores.superficieElevada,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.dns,
              size: 26,
              color: activo ? Colores.fondo : Colores.textoSecundario,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtro DNS',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activo ? 'Activo · registrando consultas' : 'Desactivado',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colores.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: activo, onChanged: ocupado ? null : alCambiar),
        ],
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