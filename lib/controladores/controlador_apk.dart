import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../modelos/resultado_apk.dart';
import '../servicios/analizador_apk.dart';
import '../servicios/servicio_apk.dart';
import 'controlador_analisis.dart';

class ControladorApk extends ChangeNotifier {
  ControladorApk({ServicioApk? servicio, AnalizadorApk? analizador})
      : _servicio = servicio ?? ServicioApk(),
        _analizador = analizador ?? AnalizadorApk();

  final ServicioApk _servicio;
  final AnalizadorApk _analizador;

  EstadoAnalisis _estado = EstadoAnalisis.inactivo;
  ResultadoApk? _resultado;
  String? _mensajeError;

  EstadoAnalisis get estado => _estado;
  ResultadoApk? get resultado => _resultado;
  String? get mensajeError => _mensajeError;

  Future<void> elegirArchivo() async {
    if (_estado == EstadoAnalisis.analizando) return;

    _estado = EstadoAnalisis.analizando;
    _mensajeError = null;
    notifyListeners();

    try {
      final informacion = await _servicio.elegirApk();
      if (informacion == null) {
        _estado = _resultado == null
            ? EstadoAnalisis.inactivo
            : EstadoAnalisis.completado;
      } else {
        _resultado = _analizador.analizar(informacion);
        _estado = EstadoAnalisis.completado;
      }
    } on MissingPluginException {
      _fallar('El escáner de archivos solo está disponible en Android.');
    } on PlatformException catch (error) {
      _fallar(error.message ?? 'No se pudo analizar el archivo.');
    }

    notifyListeners();
  }

  void _fallar(String mensaje) {
    _mensajeError = mensaje;
    _estado = EstadoAnalisis.error;
  }
}