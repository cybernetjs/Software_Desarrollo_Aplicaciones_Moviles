class EntradaDns {
  const EntradaDns({
    required this.paquete,
    required this.nombreApp,
    required this.dominio,
    required this.consultas,
    required this.bloqueadas,
    required this.ultima,
  });

  final String paquete;
  final String nombreApp;
  final String dominio;
  final int consultas;
  final int bloqueadas;
  final DateTime ultima;

  bool get fueBloqueada => bloqueadas > 0;

  String get nombreMostrado =>
      paquete == 'desconocida' ? 'App desconocida' : nombreApp;

  factory EntradaDns.desdeMapa(Map<dynamic, dynamic> mapa) {
    return EntradaDns(
      paquete: mapa['paquete'] as String,
      nombreApp: mapa['nombre'] as String,
      dominio: mapa['dominio'] as String,
      consultas: mapa['consultas'] as int,
      bloqueadas: mapa['bloqueadas'] as int,
      ultima: DateTime.fromMillisecondsSinceEpoch(mapa['ultimaMs'] as int),
    );
  }
}

class RegistroDns {
  const RegistroDns({
    required this.totalConsultas,
    required this.totalBloqueadas,
    required this.entradas,
  });

  final int totalConsultas;
  final int totalBloqueadas;
  final List<EntradaDns> entradas;

  factory RegistroDns.desdeMapa(Map<dynamic, dynamic> mapa) {
    return RegistroDns(
      totalConsultas: mapa['totalConsultas'] as int,
      totalBloqueadas: mapa['totalBloqueadas'] as int,
      entradas: (mapa['entradas'] as List)
          .map((elemento) => EntradaDns.desdeMapa(elemento as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}