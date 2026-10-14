class InformacionApk {
  const InformacionApk({
    required this.nombreArchivo,
    required this.tamano,
    required this.sha256,
    required this.esApk,
    required this.paquete,
    required this.nombreApp,
    required this.version,
    required this.permisos,
    required this.usaAccesibilidad,
    required this.esAdministrador,
    required this.firma,
    required this.instalada,
    required this.firmaInstalada,
  });

  final String nombreArchivo;
  final int tamano;
  final String sha256;
  final bool esApk;
  final String? paquete;
  final String? nombreApp;
  final String? version;
  final List<String> permisos;
  final bool usaAccesibilidad;
  final bool esAdministrador;
  final String? firma;
  final bool instalada;
  final String? firmaInstalada;

  String get nombreMostrado => nombreApp ?? nombreArchivo;

  String get tamanoLegible {
    const unidades = ['B', 'KB', 'MB', 'GB'];
    var valor = tamano.toDouble();
    var indice = 0;
    while (valor >= 1024 && indice < unidades.length - 1) {
      valor /= 1024;
      indice++;
    }
    return '${valor.toStringAsFixed(indice == 0 ? 0 : 1)} ${unidades[indice]}';
  }

  factory InformacionApk.desdeMapa(Map<dynamic, dynamic> mapa) {
    return InformacionApk(
      nombreArchivo: mapa['nombreArchivo'] as String,
      tamano: mapa['tamano'] as int,
      sha256: mapa['sha256'] as String,
      esApk: mapa['esApk'] as bool,
      paquete: mapa['paquete'] as String?,
      nombreApp: mapa['nombreApp'] as String?,
      version: mapa['version'] as String?,
      permisos: List<String>.from(mapa['permisos'] as List),
      usaAccesibilidad: mapa['usaAccesibilidad'] as bool,
      esAdministrador: mapa['esAdministrador'] as bool,
      firma: mapa['firma'] as String?,
      instalada: mapa['instalada'] as bool,
      firmaInstalada: mapa['firmaInstalada'] as String?,
    );
  }
}