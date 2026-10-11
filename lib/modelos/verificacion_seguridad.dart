import 'package:flutter/material.dart';

import 'nivel_riesgo.dart';

class VerificacionSeguridad {
  const VerificacionSeguridad({
    required this.titulo,
    required this.detalle,
    required this.nivel,
    required this.icono,
  });

  final String titulo;
  final String detalle;
  final NivelRiesgo nivel;
  final IconData icono;
}