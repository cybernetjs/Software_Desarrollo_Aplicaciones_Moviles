class ArchivoApk {
  const ArchivoApk({
    required this.ruta,
    required this.nombre,
    required this.tamano,
  });

  final String ruta;
  final String nombre;
  final int tamano;

  factory ArchivoApk.desdeMapa(Map<dynamic, dynamic> mapa) {
    return ArchivoApk(
      ruta: mapa['ruta'] as String,
      nombre: mapa['nombre'] as String,
      tamano: mapa['tamano'] as int,
    );
  }
}