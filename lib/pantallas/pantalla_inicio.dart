import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
import '../controladores/controlador_completo.dart';
import '../controladores/controlador_vigilancia.dart';
import '../modelos/nivel_riesgo.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';
import '../widgets/encabezado_pantalla.dart';
import '../widgets/escudo_estado.dart';
import '../widgets/tarjeta_informacion.dart';
import '../widgets/tarjeta_modulo.dart';
import '../widgets/tarjeta_vigilancia.dart';

typedef _DescripcionEstado = ({
  Color color,
  IconData icono,
  String titulo,
  String subtitulo,
});

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({
    super.key,
    required this.completo,
    required this.vigilancia,
    required this.alVerResultados,
    required this.alAbrirArchivos,
    required this.alAbrirStalkerware,
    required this.alAbrirDescargas,
    required this.alRevisarNuevas,
  });

  final ControladorCompleto completo;
  final ControladorVigilancia vigilancia;
  final VoidCallback alVerResultados;
  final VoidCallback alAbrirArchivos;
  final VoidCallback alAbrirStalkerware;
  final VoidCallback alAbrirDescargas;
  final VoidCallback alRevisarNuevas;

  _DescripcionEstado _describirEstado() {
    switch (completo.estado) {
      case EstadoAnalisis.inactivo:
        return (
          color: Colores.primarioClaro,
          icono: Icons.shield_outlined,
          titulo: 'Listo para analizar',
          subtitulo: 'Revisa tus apps, el stalkerware y la seguridad del equipo',
        );
      case EstadoAnalisis.analizando:
        return (
          color: Colores.primarioClaro,
          icono: Icons.shield_outlined,
          titulo: 'Analizando',
          subtitulo:
              'Paso ${completo.etapa + 1} de ${ControladorCompleto.etapas.length}: ${ControladorCompleto.etapas[completo.etapa]}',
        );
      case EstadoAnalisis.error:
        return (
          color: Colores.advertencia,
          icono: Icons.error_outline,
          titulo: 'No se pudo analizar',
          subtitulo: completo.mensajeError ?? 'Intenta nuevamente',
        );
      case EstadoAnalisis.completado:
        return _describirResultado();
    }
  }

  _DescripcionEstado _describirResultado() {
    final total = completo.totalPorRevisar;
    final atencion = total == 1
        ? '1 elemento requiere tu atención'
        : '$total elementos requieren tu atención';

    switch (completo.nivelGeneral) {
      case NivelRiesgo.bajo:
        return (
          color: Colores.seguro,
          icono: Icons.verified_user,
          titulo: 'Sin riesgos detectados',
          subtitulo:
              'Se revisaron ${completo.totalAplicacionesRevisadas} apps, el stalkerware y el equipo',
        );
      case NivelRiesgo.medio:
        return (
          color: Colores.advertencia,
          icono: Icons.warning_amber_rounded,
          titulo: 'Hay elementos por revisar',
          subtitulo: atencion,
        );
      case NivelRiesgo.alto:
        return (
          color: Colores.peligro,
          icono: Icons.gpp_bad,
          titulo: 'Se detectaron riesgos altos',
          subtitulo: atencion,
        );
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Nunca';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes $hora:$minuto';
  }

  String _describirConteo(
    int? valor, {
    required String vacio,
    required String singular,
    required String plural,
  }) {
    if (valor == null) return 'Sin datos';
    if (valor == 0) return vacio;
    return valor == 1 ? '1 $singular' : '$valor $plural';
  }

  String _textoBoton(bool analizando, bool completado) {
    if (analizando) return 'Analizando...';
    if (completado) return 'Analizar de nuevo';
    return 'Análisis completo';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([completo, vigilancia]),
      builder: (context, _) {
        final estado = _describirEstado();
        final analizando = completo.estado == EstadoAnalisis.analizando;
        final completado = completo.estado == EstadoAnalisis.completado;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const EncabezadoPantalla(
              titulo: 'Antivirus',
              subtitulo: 'Protección de tu dispositivo',
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: TemaAplicacion.decoracionTarjeta,
              child: Column(
                children: [
                  EscudoEstado(
                    color: estado.color,
                    icono: estado.icono,
                    analizando: analizando,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    estado.titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colores.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    estado.subtitulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colores.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: analizando ? null : completo.ejecutar,
              child: Text(_textoBoton(analizando, completado)),
            ),
            if (completado)
              TextButton(
                onPressed: alVerResultados,
                child: const Text('Ver resultados'),
              ),
            const SizedBox(height: 16),
            TarjetaInformacion(
              titulo: 'Resumen',
              filas: [
                FilaInformacion(
                  'Última revisión',
                  _formatearFecha(completo.ultimaRevision),
                ),
                FilaInformacion(
                  'Aplicaciones',
                  _describirConteo(
                    completo.aplicacionesPorRevisar,
                    vacio: 'Sin riesgos',
                    singular: 'por revisar',
                    plural: 'por revisar',
                  ),
                ),
                FilaInformacion(
                  'Stalkerware',
                  _describirConteo(
                    completo.stalkerwareSospechosas,
                    vacio: 'Sin señales',
                    singular: 'sospechosa',
                    plural: 'sospechosas',
                  ),
                ),
                FilaInformacion(
                  'Dispositivo',
                  _describirConteo(
                    completo.alertasDispositivo,
                    vacio: 'Sin alertas',
                    singular: 'alerta',
                    plural: 'alertas',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TarjetaVigilancia(
              controlador: vigilancia,
              alRevisar: alRevisarNuevas,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TarjetaModulo(
                    icono: Icons.folder_open,
                    titulo: 'Archivos',
                    descripcion: 'Escáner de APK',
                    alPulsar: alAbrirArchivos,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TarjetaModulo(
                    icono: Icons.visibility_off,
                    titulo: 'Stalkerware',
                    descripcion: 'Detector de apps espía',
                    alPulsar: alAbrirStalkerware,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TarjetaModulo(
                    icono: Icons.download,
                    titulo: 'Descargas',
                    descripcion: 'Revisar APK bajados',
                    alPulsar: alAbrirDescargas,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        );
      },
    );
  }
}