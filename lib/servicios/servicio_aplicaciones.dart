import 'package:flutter/services.dart';

import '../modelos/aplicacion_instalada.dart';

class ServicioAplicaciones {
  static const MethodChannel _canal = MethodChannel('antivirus/aplicaciones');

  Future<List<AplicacionInstalada>> obtenerInstaladas() async {
    final respuesta = await _canal.invokeListMethod<Map<dynamic, dynamic>>(
      'obtenerAplicaciones',
    );
    return (respuesta ?? const <Map<dynamic, dynamic>>[])
        .map(AplicacionInstalada.desdeMapa)
        .toList();
  }
}