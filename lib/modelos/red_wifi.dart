import 'tipo_seguridad.dart';

class RedWifi {
  const RedWifi({
    required this.nombre,
    required this.bssid,
    required this.senal,
    required this.frecuencia,
    required this.seguridad,
  });

  final String nombre;
  final String bssid;
  final int senal;
  final int frecuencia;
  final TipoSeguridad seguridad;

  bool get esOculta => nombre.isEmpty;

  factory RedWifi.desdeMapa(Map<dynamic, dynamic> mapa) {
    return RedWifi(
      nombre: mapa['nombre'] as String,
      bssid: mapa['bssid'] as String,
      senal: mapa['senal'] as int,
      frecuencia: mapa['frecuencia'] as int,
      seguridad: TipoSeguridad.desdeCapacidades(mapa['capacidades'] as String),
    );
  }
}