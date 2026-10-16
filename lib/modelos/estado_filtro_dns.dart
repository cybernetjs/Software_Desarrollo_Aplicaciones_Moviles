class EstadoFiltroDns {
  const EstadoFiltroDns({
    required this.activo,
    required this.dnsPrivadoEstricto,
    required this.dominiosBloqueados,
  });

  final bool activo;
  final bool dnsPrivadoEstricto;
  final int dominiosBloqueados;

  factory EstadoFiltroDns.desdeMapa(Map<dynamic, dynamic> mapa) {
    return EstadoFiltroDns(
      activo: mapa['activo'] as bool,
      dnsPrivadoEstricto: mapa['dnsPrivadoEstricto'] as bool,
      dominiosBloqueados: mapa['dominiosBloqueados'] as int,
    );
  }
}