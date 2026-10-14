class AplicacionInstalada {
  const AplicacionInstalada({
    required this.nombre,
    required this.paquete,
    required this.esSistema,
    required this.origen,
    required this.permisos,
    required this.tieneIcono,
    required this.usaAccesibilidad,
    required this.esAdministrador,
    required this.firmasSha1,
    required this.firmasSha256,
  });

  final String nombre;
  final String paquete;
  final bool esSistema;
  final String? origen;
  final List<String> permisos;
  final bool tieneIcono;
  final bool usaAccesibilidad;
  final bool esAdministrador;
  final List<String> firmasSha1;
  final List<String> firmasSha256;

  factory AplicacionInstalada.desdeMapa(Map<dynamic, dynamic> mapa) {
    return AplicacionInstalada(
      nombre: mapa['nombre'] as String,
      paquete: mapa['paquete'] as String,
      esSistema: mapa['esSistema'] as bool,
      origen: mapa['origen'] as String?,
      permisos: List<String>.from(mapa['permisos'] as List),
      tieneIcono: mapa['tieneIcono'] as bool,
      usaAccesibilidad: mapa['usaAccesibilidad'] as bool,
      esAdministrador: mapa['esAdministrador'] as bool,
      firmasSha1: List<String>.from(mapa['firmasSha1'] as List),
      firmasSha256: List<String>.from(mapa['firmasSha256'] as List),
    );
  }
}