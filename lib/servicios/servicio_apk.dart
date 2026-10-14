import 'package:flutter/services.dart';

import '../modelos/informacion_apk.dart';

class ServicioApk {
  static const MethodChannel _canal = MethodChannel('antivirus/apk');

  Future<InformacionApk?> elegirApk() async {
    final respuesta = await _canal.invokeMapMethod<String, dynamic>('elegirApk');
    return respuesta == null ? null : InformacionApk.desdeMapa(respuesta);
  }
}