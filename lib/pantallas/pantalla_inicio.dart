import 'package:flutter/material.dart';

import '../controladores/controlador_analisis.dart';
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
    required this.controlador,
    required this.vigilancia,
    required this.alVerResultados,
    required this.alAbrirArchivos,
    required this.alRevisarNuevas,
  });

  final ControladorAnalisis controlador;
  final ControladorVigilancia vigilancia;
  final VoidCallback alVerResultados;
  final VoidCallback alAbrirArchivos;
  final VoidCallback alRevisarNuevas;

  _DescripcionEstado _describirEstado() {
    switch (controlador.estado) {
      case EstadoAnalisis.inactivo:
        return (
          color: Colores.primarioClaro,
          icono: Icons.shield_outlined,
          titulo: 'Listo para analizar',
          subtitulo: 'Revisa las aplicaciones instaladas en tu dispositivo',
        );
      case EstadoAnalisis.analizando:
        return (
          color: Colores.primarioClaro,
          icono: Icons.shield_outlined,
          titulo: 'Analizando',
          subtitulo: 'Revisando permisos y comportamiento de las aplicaciones',
        );
      case EstadoAnalisis.error:
        return (
          color: Colores.advertencia,
          icono: Icons.error_outline,
          titulo: 'No se pudo analizar',
          subtitulo: controlador.mensajeError ?? 'Intenta nuevamente',
        );
      case EstadoAnalisis.completado:
        return _describirResultado();
    }
  }

  _DescripcionEstado _describirResultado() {
    final porRevisar = controlador.totalPorRevisar;
    switch (controlador.nivelGeneral) {
      case NivelRiesgo.bajo:
        return (
          color: Colores.seguro,
          icono: Icons.verified_user,
          titulo: 'Sin riesgos detectados',
          subtitulo: 'Se analizaron ${controlador.resultados.length} aplicaciones',
        );
      case NivelRiesgo.medio:
        return (
          color: Colores.advertencia,
          icono: Icons.warning_amber_rounded,
          titulo: 'Hay aplicaciones por revisar',
          subtitulo: '$porRevisar aplicaciones requieren tu atención',
        );
      case NivelRiesgo.alto:
        return (
          color: Colores.peligro,
          icono: Icons.gpp_bad,
          titulo: 'Se detectaron riesgos altos',
          subtitulo: '$porRevisar aplicaciones requieren tu atención',
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

  String _textoBoton(bool analizando, bool completado) {
    if (analizando) return 'Analizando...';
    if (completado) return 'Analizar de nuevo';
    return 'Analizar ahora';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controlador, vigilancia]),
      builder: (context, _) {
        final estado = _describirEstado();
        final analizando = controlador.estado == EstadoAnalisis.analizando;
        final completado = controlador.estado == EstadoAnalisis.completado;

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
              onPressed: analizando ? null : controlador.analizar,
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
                  _formatearFecha(controlador.ultimaRevision),
                ),
                FilaInformacion(
                  'Aplicaciones analizadas',
                  '${controlador.resultados.length}',
                ),
                FilaInformacion(
                  'Riesgos detectados',
                  '${controlador.totalPorRevisar}',
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
                const Expanded(
                  child: TarjetaModulo(
                    icono: Icons.public,
                    titulo: 'Navegación',
                    descripcion: 'Próximamente',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}