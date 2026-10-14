import 'informacion_apk.dart';
import 'motivo_riesgo.dart';
import 'nivel_riesgo.dart';

class ResultadoApk {
  const ResultadoApk({
    required this.informacion,
    required this.puntos,
    required this.nivel,
    required this.motivos,
  });

  final InformacionApk informacion;
  final int puntos;
  final NivelRiesgo nivel;
  final List<MotivoRiesgo> motivos;
}