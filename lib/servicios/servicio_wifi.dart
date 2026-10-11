import 'package:flutter/services.dart';

import '../modelos/estado_wifi.dart';

class ServicioWifi {
  static const MethodChannel _canal = MethodChannel('antivirus/wifi');

  Future<bool> solicitarPermiso() async {
    final concedido = await _canal.invokeMethod<bool>(
      'solicitarPermisoUbicacion',
    );
    return concedido ?? false;
  }

  Future<EstadoWifi> escanear() async {
    final respuesta = await _canal.invokeMapMethod<String, dynamic>(
      'escanearRedes',
    );
    if (respuesta == null) {
      throw PlatformException(
        code: 'SIN_RESPUESTA',
        message: 'No se obtuvo información de las redes WiFi.',
      );
    }
    return EstadoWifi.desdeMapa(respuesta);
  }
}