class IndicadorStalkerware {
  const IndicadorStalkerware({
    required this.nombre,
    required this.tipo,
    required this.paquetes,
    required this.certificados,
  });

  final String nombre;
  final String tipo;
  final Set<String> paquetes;
  final Set<String> certificados;

  bool get esWatchware => tipo == 'watchware';
}