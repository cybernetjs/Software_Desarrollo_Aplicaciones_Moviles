class IndicadorStalkerware {
  const IndicadorStalkerware({
    required this.nombre,
    required this.tipo,
    required this.paquetes,
    required this.certificados,
    required this.dominios,
  });

  final String nombre;
  final String tipo;
  final Set<String> paquetes;
  final Set<String> certificados;
  final Set<String> dominios;

  bool get esWatchware => tipo == 'watchware';
}