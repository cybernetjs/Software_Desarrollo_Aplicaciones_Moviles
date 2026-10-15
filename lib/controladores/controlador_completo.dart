import 'package:flutter/foundation.dart';

import '../modelos/nivel_riesgo.dart';
import 'controlador_analisis.dart';
import 'controlador_dispositivo.dart';
import 'controlador_stalkerware.dart';

class ControladorCompleto extends ChangeNotifier {
  ControladorCompleto({
    required ControladorAnalisis analisis,
    required ControladorStalkerware stalkerware,
    required ControladorDispositivo dispositivo,
  })  : _analisis = analisis,
        _stalkerware = stalkerware,
        _dispositivo = dispositivo;

  static const List<String> etapas = [
    'Aplicaciones instaladas',
    'Stalkerware',
    'Seguridad del dispositivo',
  ];

  final ControladorAnalisis _analisis;
  final ControladorStalkerware _stalkerware;
  final ControladorDispositivo _dispositivo;

  EstadoAnalisis _estado = EstadoAnalisis.inactivo;
  int _etapa = 0;
  DateTime? _ultimaRevision;

  EstadoAnalisis get estado => _estado;
  int get etapa => _etapa;
  DateTime? get ultimaRevision => _ultimaRevision;
  String? get mensajeError => _analisis.mensajeError;
  int get totalAplicacionesRevisadas => _analisis.resultados.length;

  int? get aplicacionesPorRevisar {
    if (_analisis.estado != EstadoAnalisis.completado) return null;

    final paquetes = <String>{
      for (final resultado in _analisis.resultados)
        if (resultado.nivel != NivelRiesgo.bajo) resultado.aplicacion.paquete,
      if (_stalkerware.estado == EstadoAnalisis.completado)
        for (final hallazgo in _stalkerware.hallazgos)
          hallazgo.aplicacion.paquete,
    };
    return paquetes.length;
  }

  int? get stalkerwareSospechosas {
    if (_stalkerware.estado != EstadoAnalisis.completado) return null;
    return _stalkerware.hallazgos.length;
  }

  int? get alertasDispositivo {
    if (_dispositivo.estado != EstadoAnalisis.completado) return null;
    return _dispositivo.verificaciones
        .where((verificacion) => verificacion.nivel != NivelRiesgo.bajo)
        .length;
  }

  int get totalPorRevisar =>
      (aplicacionesPorRevisar ?? 0) + (alertasDispositivo ?? 0);

  NivelRiesgo get nivelGeneral {
    final niveles = <NivelRiesgo>[
      if (_analisis.estado == EstadoAnalisis.completado) _analisis.nivelGeneral,
      if (_stalkerware.estado == EstadoAnalisis.completado)
        _stalkerware.nivelGeneral,
      if (_dispositivo.estado == EstadoAnalisis.completado)
        ..._dispositivo.verificaciones.map((verificacion) => verificacion.nivel),
    ];

    if (niveles.contains(NivelRiesgo.alto)) return NivelRiesgo.alto;
    if (niveles.contains(NivelRiesgo.medio)) return NivelRiesgo.medio;
    return NivelRiesgo.bajo;
  }

  Future<void> ejecutar() async {
    if (_estado == EstadoAnalisis.analizando) return;

    _estado = EstadoAnalisis.analizando;
    _etapa = 0;
    notifyListeners();

    await _analisis.analizar();
    if (_analisis.estado != EstadoAnalisis.completado) {
      _estado = EstadoAnalisis.error;
      notifyListeners();
      return;
    }

    _etapa = 1;
    notifyListeners();
    await _stalkerware.revisar();

    _etapa = 2;
    notifyListeners();
    await _dispositivo.revisar();

    _ultimaRevision = DateTime.now();
    _estado = EstadoAnalisis.completado;
    notifyListeners();
  }
}