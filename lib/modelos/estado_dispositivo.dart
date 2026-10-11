class EstadoDispositivo {
  const EstadoDispositivo({
    required this.versionAndroid,
    required this.parcheSeguridad,
    required this.bloqueoPantalla,
    required this.depuracionUsb,
    required this.opcionesDesarrollador,
    required this.dispositivoRoot,
  });

  final String versionAndroid;
  final String? parcheSeguridad;
  final bool bloqueoPantalla;
  final bool depuracionUsb;
  final bool opcionesDesarrollador;
  final bool dispositivoRoot;

  factory EstadoDispositivo.desdeMapa(Map<dynamic, dynamic> mapa) {
    return EstadoDispositivo(
      versionAndroid: mapa['versionAndroid'] as String,
      parcheSeguridad: mapa['parcheSeguridad'] as String?,
      bloqueoPantalla: mapa['bloqueoPantalla'] as bool,
      depuracionUsb: mapa['depuracionUsb'] as bool,
      opcionesDesarrollador: mapa['opcionesDesarrollador'] as bool,
      dispositivoRoot: mapa['dispositivoRoot'] as bool,
    );
  }
}