class AplicacionNueva {
  const AplicacionNueva({required this.nombre, required this.paquete});

  final String nombre;
  final String paquete;
}

class EstadoVigilancia {
  const EstadoVigilancia({
    required this.activa,
    required this.notificaciones,
    required this.pendientes,
  });

  final bool activa;
  final bool notificaciones;
  final List<AplicacionNueva> pendientes;

  factory EstadoVigilancia.desdeMapa(Map<dynamic, dynamic> mapa) {
    final pendientes = (mapa['pendientes'] as List).map((elemento) {
      final dato = elemento as Map<dynamic, dynamic>;
      return AplicacionNueva(
        nombre: dato['nombre'] as String,
        paquete: dato['paquete'] as String,
      );
    }).toList();

    return EstadoVigilancia(
      activa: mapa['activa'] as bool,
      notificaciones: mapa['notificaciones'] as bool,
      pendientes: pendientes,
    );
  }
}