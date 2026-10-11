import 'red_wifi.dart';
import 'tipo_seguridad.dart';

class ConexionWifi {
  const ConexionWifi({
    required this.nombre,
    required this.senal,
    required this.velocidadEnlace,
    required this.frecuencia,
    required this.seguridad,
  });

  final String nombre;
  final int senal;
  final int velocidadEnlace;
  final int frecuencia;
  final TipoSeguridad? seguridad;

  factory ConexionWifi.desdeMapa(Map<dynamic, dynamic> mapa) {
    final capacidades = mapa['capacidades'] as String?;
    return ConexionWifi(
      nombre: mapa['nombre'] as String,
      senal: mapa['senal'] as int,
      velocidadEnlace: mapa['velocidadEnlace'] as int,
      frecuencia: mapa['frecuencia'] as int,
      seguridad: capacidades == null
          ? null
          : TipoSeguridad.desdeCapacidades(capacidades),
    );
  }
}

class EstadoWifi {
  const EstadoWifi({
    required this.wifiActivo,
    required this.ubicacionActiva,
    required this.conexion,
    required this.redes,
  });

  final bool wifiActivo;
  final bool ubicacionActiva;
  final ConexionWifi? conexion;
  final List<RedWifi> redes;

  factory EstadoWifi.desdeMapa(Map<dynamic, dynamic> mapa) {
    final conexion = mapa['conectada'] as Map<dynamic, dynamic>?;
    final redes = (mapa['redes'] as List)
        .map((elemento) => RedWifi.desdeMapa(elemento as Map<dynamic, dynamic>))
        .toList()
      ..sort((a, b) => b.senal.compareTo(a.senal));

    return EstadoWifi(
      wifiActivo: mapa['wifiActivo'] as bool,
      ubicacionActiva: mapa['ubicacionActiva'] as bool,
      conexion: conexion == null ? null : ConexionWifi.desdeMapa(conexion),
      redes: redes,
    );
  }
}