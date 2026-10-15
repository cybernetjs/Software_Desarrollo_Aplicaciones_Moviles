import 'package:flutter/services.dart';

import '../modelos/archivo_apk.dart';
import '../modelos/informacion_apk.dart';

typedef PermisoArchivos = ({bool soportado, bool concedido});

class ServicioDescargas {
  static const MethodChannel _canal = MethodChannel('antivirus/descargas');

  Future<PermisoArchivos> consultarPermiso() async {
    final respuesta = await _canal.invokeMapMethod<String, dynamic>(
      'permisoArchivos',
    );
    return (
      soportado: respuesta?['soportado'] as bool? ?? false,
      concedido: respuesta?['concedido'] as bool? ?? false,
    );
  }

  Future<void> abrirAjustes() {
    return _canal.invokeMethod<void>('abrirAjustesArchivos');
  }

  Future<List<ArchivoApk>> listar() async {
    final respuesta = await _canal.invokeListMethod<Map<dynamic, dynamic>>(
      'listarDescargas',
    );
    return (respuesta ?? const <Map<dynamic, dynamic>>[])
        .map(ArchivoApk.desdeMapa)
        .toList();
  }

  Future<InformacionApk> analizar(String ruta) async {
    final respuesta = await _canal.invokeMapMethod<String, dynamic>(
      'analizarRuta',
      {'ruta': ruta},
    );
    if (respuesta == null) {
      throw PlatformException(
        code: 'SIN_RESPUESTA',
        message: 'No se obtuvo información del archivo.',
      );
    }
    return InformacionApk.desdeMapa(respuesta);
  }
}