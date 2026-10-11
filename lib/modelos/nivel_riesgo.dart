import 'package:flutter/material.dart';

import '../tema/colores.dart';

enum NivelRiesgo {
  bajo('Bajo', Colores.seguro, Icons.verified_user),
  medio('Medio', Colores.advertencia, Icons.warning_rounded),
  alto('Alto', Colores.peligro, Icons.gpp_bad);

  const NivelRiesgo(this.etiqueta, this.color, this.icono);

  final String etiqueta;
  final Color color;
  final IconData icono;
}