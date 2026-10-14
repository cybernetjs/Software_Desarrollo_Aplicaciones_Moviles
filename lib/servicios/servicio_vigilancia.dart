import 'package:flutter/services.dart';

import '../modelos/estado_vigilancia.dart';

class ServicioVigilancia {
  static const MethodChannel _canal = MethodChannel('antivirus/vigilancia');

  Future<EstadoVigilancia> obtenerEstado() => _invocar('obtenerEstado');

  Future<EstadoVigilancia> activar() => _invocar('activar');

  Future<EstadoVigilancia> desactivar() => _invocar('desactivar');

  Future<EstadoVigilancia> marcarRevisadas() => _invocar('marcarRevisadas');

  Future<EstadoVigilancia> _invocar(String metodo) async {
    final respuesta = await _canal.invokeMapMethod<String, dynamic>(metodo);
    if (respuesta == null) {
      throw PlatformException(
        code: 'SIN_RESPUESTA',
        message: 'No se obtuvo el estado de la vigilancia.',
      );
    }
    return EstadoVigilancia.desdeMapa(respuesta);
  }
}