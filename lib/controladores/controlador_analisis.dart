import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../modelos/nivel_riesgo.dart';
import '../modelos/resultado_analisis.dart';
import '../servicios/analizador_riesgo.dart';
import '../servicios/servicio_aplicaciones.dart';

enum EstadoAnalisis { inactivo, analizando, completado, error }

class ControladorAnalisis extends ChangeNotifier {
  ControladorAnalisis({
    ServicioAplicaciones? servicio,
    AnalizadorRiesgo? analizador,
  })  : _servicio = servicio ?? ServicioAplicaciones(),
        _analizador = analizador ?? AnalizadorRiesgo();

  final ServicioAplicaciones _servicio;
  final AnalizadorRiesgo _analizador;

  EstadoAnalisis _estado = EstadoAnalisis.inactivo;
  List<ResultadoAnalisis> _resultados = const [];
  String? _mensajeError;
  DateTime? _ultimaRevision;

  EstadoAnalisis get estado => _estado;
  List<ResultadoAnalisis> get resultados => _resultados;
  String? get mensajeError => _mensajeError;
  DateTime? get ultimaRevision => _ultimaRevision;

  int get totalPorRevisar =>
      _resultados.where((r) => r.nivel != NivelRiesgo.bajo).length;

  int contarPorNivel(NivelRiesgo nivel) =>
      _resultados.where((r) => r.nivel == nivel).length;

  NivelRiesgo get nivelGeneral {
    if (contarPorNivel(NivelRiesgo.alto) > 0) return NivelRiesgo.alto;
    if (contarPorNivel(NivelRiesgo.medio) > 0) return NivelRiesgo.medio;
    return NivelRiesgo.bajo;
  }

  Future<void> analizar() async {
    if (_estado == EstadoAnalisis.analizando) return;

    _estado = EstadoAnalisis.analizando;
    _mensajeError = null;
    notifyListeners();

    try {
      final instaladas = await _servicio.obtenerInstaladas();
      _resultados = instaladas
          .where((aplicacion) => !aplicacion.esSistema)
          .map(_analizador.analizar)
          .toList()
        ..sort((a, b) => b.puntos.compareTo(a.puntos));
      _ultimaRevision = DateTime.now();
      _estado = EstadoAnalisis.completado;
    } on MissingPluginException {
      _mensajeError = 'El análisis solo está disponible en Android.';
      _estado = EstadoAnalisis.error;
    } on PlatformException catch (error) {
      _mensajeError = error.message ?? 'No se pudo completar el análisis.';
      _estado = EstadoAnalisis.error;
    }

    notifyListeners();
  }
}