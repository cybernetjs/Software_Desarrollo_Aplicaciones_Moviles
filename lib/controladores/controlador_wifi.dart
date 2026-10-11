import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../modelos/estado_wifi.dart';
import '../modelos/verificacion_seguridad.dart';
import '../servicios/auditor_wifi.dart';
import '../servicios/servicio_wifi.dart';
import 'controlador_analisis.dart';

class ControladorWifi extends ChangeNotifier {
  ControladorWifi({ServicioWifi? servicio, AuditorWifi? auditor})
      : _servicio = servicio ?? ServicioWifi(),
        _auditor = auditor ?? AuditorWifi();

  final ServicioWifi _servicio;
  final AuditorWifi _auditor;

  EstadoAnalisis _estado = EstadoAnalisis.inactivo;
  EstadoWifi? _datos;
  List<VerificacionSeguridad> _verificaciones = const [];
  String? _mensajeError;

  EstadoAnalisis get estado => _estado;
  EstadoWifi? get datos => _datos;
  List<VerificacionSeguridad> get verificaciones => _verificaciones;
  String? get mensajeError => _mensajeError;

  Future<void> escanear() async {
    if (_estado == EstadoAnalisis.analizando) return;

    _estado = EstadoAnalisis.analizando;
    _mensajeError = null;
    notifyListeners();

    try {
      final permitido = await _servicio.solicitarPermiso();
      if (permitido) {
        await _procesarEscaneo();
      } else {
        _fallar('Se necesita el permiso de ubicación para ver las redes WiFi.');
      }
    } on MissingPluginException {
      _fallar('El escaneo solo está disponible en Android.');
    } on PlatformException catch (error) {
      _fallar(error.message ?? 'No se pudo escanear las redes.');
    }

    notifyListeners();
  }

  Future<void> _procesarEscaneo() async {
    final datos = await _servicio.escanear();

    if (!datos.wifiActivo) {
      _fallar('El WiFi está apagado. Actívalo para escanear.');
      return;
    }
    if (!datos.ubicacionActiva) {
      _fallar(
        'Activa la ubicación del dispositivo: Android la exige para ver las redes.',
      );
      return;
    }

    _datos = datos;
    _verificaciones = _auditor.auditar(datos);
    _estado = EstadoAnalisis.completado;
  }

  void _fallar(String mensaje) {
    _mensajeError = mensaje;
    _estado = EstadoAnalisis.error;
  }
}