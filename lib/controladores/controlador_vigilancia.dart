import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../modelos/estado_vigilancia.dart';
import '../servicios/servicio_vigilancia.dart';

class ControladorVigilancia extends ChangeNotifier {
  ControladorVigilancia({ServicioVigilancia? servicio})
      : _servicio = servicio ?? ServicioVigilancia();

  final ServicioVigilancia _servicio;

  EstadoVigilancia? _estado;
  bool _ocupado = false;
  String? _mensaje;

  bool get activa => _estado?.activa ?? false;
  bool get notificacionesActivas => _estado?.notificaciones ?? true;
  List<AplicacionNueva> get pendientes => _estado?.pendientes ?? const [];
  bool get ocupado => _ocupado;
  String? get mensaje => _mensaje;

  Future<void> cargar() => _ejecutar(_servicio.obtenerEstado);

  Future<void> alternar(bool encender) {
    return _ejecutar(encender ? _servicio.activar : _servicio.desactivar);
  }

  Future<void> marcarRevisadas() => _ejecutar(_servicio.marcarRevisadas);

  Future<void> _ejecutar(Future<EstadoVigilancia> Function() accion) async {
    if (_ocupado) return;

    _ocupado = true;
    _mensaje = null;
    notifyListeners();

    try {
      _estado = await accion();
    } on MissingPluginException {
      _mensaje = 'La vigilancia solo está disponible en Android.';
    } on PlatformException catch (error) {
      _mensaje = error.message ?? 'No se pudo actualizar la vigilancia.';
    }

    _ocupado = false;
    notifyListeners();
  }
}