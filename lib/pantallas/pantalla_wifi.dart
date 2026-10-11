import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import '../controladores/controlador_wifi.dart';
import '../modelos/estado_wifi.dart';
import '../tema/colores.dart';
import '../utilidades/radio_wifi.dart';
import '../widgets/encabezado_pantalla.dart';
import '../widgets/etiqueta_nivel.dart';
import '../widgets/tarjeta_informacion.dart';
import '../widgets/tarjeta_red_wifi.dart';
import '../widgets/tarjeta_verificacion.dart';

class PantallaWifi extends StatelessWidget {
  const PantallaWifi({super.key, required this.controlador});

  final ControladorWifi controlador;

  List<Widget> _construirContenido() {
    switch (controlador.estado) {
      case EstadoAnalisis.inactivo:
        return const [
          TarjetaInformacion(
            titulo: 'Escaneo',
            filas: [FilaInformacion('Estado', 'Sin escanear')],
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
            titulo: 'Escaneo',
            filas: [FilaInformacion('Estado', 'Con error')],
          ),
          const SizedBox(height: 12),
          Text(
            controlador.mensajeError ?? 'No se pudo escanear las redes.',
            style: const TextStyle(fontSize: 14, color: Colores.textoSecundario),
          ),
        ];
      case EstadoAnalisis.completado:
        return _construirResultado();
    }
  }

  List<Widget> _construirResultado() {
    final datos = controlador.datos;
    if (datos == null) return const [];
    final conexion = datos.conexion;

    return [
      if (conexion != null) ...[
        const _TituloSeccion('Conectado actualmente'),
        const SizedBox(height: 12),
        _TarjetaConexion(conexion: conexion),
        const SizedBox(height: 24),
      ],
      const _TituloSeccion('Análisis de seguridad'),
      const SizedBox(height: 12),
      for (final verificacion in controlador.verificaciones) ...[
        TarjetaVerificacion(verificacion: verificacion),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 14),
      _TituloSeccion('Redes cercanas (${datos.redes.length})'),
      const SizedBox(height: 12),
      for (final red in datos.redes) ...[
        TarjetaRedWifi(red: red),
        const SizedBox(height: 10),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controlador,
      builder: (context, _) {
        final escaneando = controlador.estado == EstadoAnalisis.analizando;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const EncabezadoPantalla(
              titulo: 'Redes WiFi',
              subtitulo: 'Escaneo y análisis de red',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: escaneando ? null : controlador.escanear,
              child: Text(escaneando ? 'Escaneando...' : 'Escanear redes'),
            ),
            const SizedBox(height: 24),
            ..._construirContenido(),
          ],
        );
      },
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colores.textoPrincipal,
      ),
    );
  }
}

class _TarjetaConexion extends StatelessWidget {
  const _TarjetaConexion({required this.conexion});

  final ConexionWifi conexion;

  @override
  Widget build(BuildContext context) {
    final seguridad = conexion.seguridad;
    final velocidad = conexion.velocidadEnlace > 0
        ? '${conexion.velocidadEnlace} Mbps'
        : 'No disponible';
    final canal = RadioWifi.canalDesdeFrecuencia(conexion.frecuencia);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colores.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colores.primario, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  conexion.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colores.textoPrincipal,
                  ),
                ),
              ),
              if (seguridad != null) ...[
                const SizedBox(width: 10),
                EtiquetaNivel(nivel: seguridad.nivel, texto: seguridad.etiqueta),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DatoConexion(
                etiqueta: 'Señal',
                valor: RadioWifi.calidadSenal(conexion.senal),
              ),
              _DatoConexion(etiqueta: 'Enlace', valor: velocidad),
              _DatoConexion(etiqueta: 'Canal', valor: '$canal'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatoConexion extends StatelessWidget {
  const _DatoConexion({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(fontSize: 13, color: Colores.textoSecundario),
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colores.textoPrincipal,
          ),
        ),
      ],
    );
  }
}