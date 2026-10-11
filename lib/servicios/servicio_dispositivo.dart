import 'package:flutter/services.dart';

import '../modelos/estado_dispositivo.dart';

class ServicioDispositivo {
  static const MethodChannel _canal = MethodChannel('antivirus/dispositivo');

  Future<EstadoDispositivo> obtenerEstado() async {
    final respuesta = await _canal.invokeMapMethod<String, dynamic>(
      'obtenerEstadoDispositivo',
    );
    if (respuesta == null) {
      throw PlatformException(
        code: 'SIN_RESPUESTA',
        message: 'No se obtuvo información del dispositivo.',
      );
    }
    return EstadoDispositivo.desdeMapa(respuesta);
  }
}