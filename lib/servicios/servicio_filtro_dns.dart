import 'package:flutter/services.dart';

import '../modelos/entrada_dns.dart';
import '../modelos/estado_filtro_dns.dart';

class ServicioFiltroDns {
  static const MethodChannel _canal = MethodChannel('antivirus/filtro_dns');

  Future<EstadoFiltroDns> obtenerEstado() => _invocarEstado('obtenerEstado');

  Future<bool> solicitarPermiso() async {
    final concedido = await _canal.invokeMethod<bool>('solicitarPermiso');
    return concedido ?? false;
  }

  Future<EstadoFiltroDns> activar(Set<String> dominios) {
    return _invocarEstado('activar', {'dominios': dominios.toList()});
  }

  Future<EstadoFiltroDns> desactivar() => _invocarEstado('desactivar');

  Future<RegistroDns> obtenerRegistro() async {
    final respuesta = await _canal.invokeMapMethod<String, dynamic>(
      'obtenerRegistro',
    );
    if (respuesta == null) {
      throw PlatformException(
        code: 'SIN_RESPUESTA',
        message: 'No se obtuvo el registro de consultas.',
      );
    }
    return RegistroDns.desdeMapa(respuesta);
  }

  Future<void> limpiarRegistro() {
    return _canal.invokeMethod<void>('limpiarRegistro');
  }

  Future<EstadoFiltroDns> _invocarEstado(
    String metodo, [
    Map<String, dynamic>? argumentos,
  ]) async {
    final respuesta = await _canal.invokeMapMethod<String, dynamic>(
      metodo,
      argumentos,
    );
    if (respuesta == null) {
      throw PlatformException(
        code: 'SIN_RESPUESTA',
        message: 'No se obtuvo el estado del filtro DNS.',
      );
    }
    return EstadoFiltroDns.desdeMapa(respuesta);
  }
}