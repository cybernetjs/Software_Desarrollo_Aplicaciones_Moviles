import 'package:flutter/services.dart';

import '../modelos/estado_firewall.dart';

class ServicioFirewall {
  static const MethodChannel _canal = MethodChannel('antivirus/firewall');

  Future<EstadoFirewall> obtenerEstado() async {
    final respuesta = await _canal.invokeMapMethod<String, dynamic>(
      'obtenerEstado',
    );
    if (respuesta == null) {
      throw PlatformException(
        code: 'SIN_RESPUESTA',
        message: 'No se obtuvo el estado del firewall.',
      );
    }
    return EstadoFirewall.desdeMapa(respuesta);
  }

  Future<bool> solicitarPermiso() async {
    final concedido = await _canal.invokeMethod<bool>('solicitarPermisoVpn');
    return concedido ?? false;
  }

  Future<void> activar(Set<String> bloqueadas) {
    return _canal.invokeMethod<void>(
      'activar',
      {'paquetes': bloqueadas.toList()},
    );
  }

  Future<void> desactivar() {
    return _canal.invokeMethod<void>('desactivar');
  }

  Future<void> guardarBloqueadas(Set<String> bloqueadas) {
    return _canal.invokeMethod<void>(
      'guardarBloqueadas',
      {'paquetes': bloqueadas.toList()},
    );
  }
}