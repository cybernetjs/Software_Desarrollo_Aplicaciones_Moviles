import 'package:flutter/material.dart';

import '../tema/colores.dart';

enum NivelRiesgo {
  bajo('Bajo', Colores.seguro),
  medio('Medio', Colores.advertencia),
  alto('Alto', Colores.peligro);

  const NivelRiesgo(this.etiqueta, this.color);

  final String etiqueta;
  final Color color;
}