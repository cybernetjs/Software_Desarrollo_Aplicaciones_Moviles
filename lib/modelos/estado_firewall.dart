class EstadoFirewall {
  const EstadoFirewall({
    required this.activo,
    required this.bloqueadas,
    required this.paquetePropio,
  });

  final bool activo;
  final Set<String> bloqueadas;
  final String paquetePropio;

  factory EstadoFirewall.desdeMapa(Map<dynamic, dynamic> mapa) {
    return EstadoFirewall(
      activo: mapa['activo'] as bool,
      bloqueadas: Set<String>.from(mapa['bloqueadas'] as List),
      paquetePropio: mapa['paquetePropio'] as String,
    );
  }
}