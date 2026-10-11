import 'aplicacion_instalada.dart';
import 'nivel_riesgo.dart';

class ResultadoAnalisis {
  const ResultadoAnalisis({
    required this.aplicacion,
    required this.puntos,
    required this.nivel,
    required this.motivos,
  });

  final AplicacionInstalada aplicacion;
  final int puntos;
  final NivelRiesgo nivel;
  final List<String> motivos;
}