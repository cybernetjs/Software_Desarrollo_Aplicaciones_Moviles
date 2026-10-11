import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../modelos/estado_dispositivo.dart';
import '../modelos/verificacion_seguridad.dart';
import '../servicios/auditor_dispositivo.dart';
import '../servicios/servicio_dispositivo.dart';
import 'controlador_analisis.dart';

class ControladorDispositivo extends ChangeNotifier {
  ControladorDispositivo({
    ServicioDispositivo? servicio,
    AuditorDispositivo? auditor,
  })  : _servicio = servicio ?? ServicioDispositivo(),
        _auditor = auditor ?? AuditorDispositivo();

  final ServicioDispositivo _servicio;
  final AuditorDispositivo _auditor;

  EstadoAnalisis _estado = EstadoAnalisis.inactivo;
  EstadoDispositivo? _datos;
  List<VerificacionSeguridad> _verificaciones = const [];
  String? _mensajeError;

  EstadoAnalisis get estado => _estado;
  EstadoDispositivo? get datos => _datos;
  List<VerificacionSeguridad> get verificaciones => _verificaciones;
  String? get mensajeError => _mensajeError;

  Future<void> revisar() async {
    if (_estado == EstadoAnalisis.analizando) return;

    _estado = EstadoAnalisis.analizando;
    _mensajeError = null;
    notifyListeners();

    try {
      final datos = await _servicio.obtenerEstado();
      _datos = datos;
      _verificaciones = _auditor.auditar(datos);
      _estado = EstadoAnalisis.completado;
    } on MissingPluginException {
      _mensajeError = 'La revisión solo está disponible en Android.';
      _estado = EstadoAnalisis.error;
    } on PlatformException catch (error) {
      _mensajeError = error.message ?? 'No se pudo revisar el dispositivo.';
      _estado = EstadoAnalisis.error;
    }

    notifyListeners();
  }
}