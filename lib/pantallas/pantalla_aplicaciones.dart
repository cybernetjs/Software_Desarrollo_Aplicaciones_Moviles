import 'package:flutter/material.dart';

import '../widgets/encabezado_pantalla.dart';
import '../widgets/tarjeta_informacion.dart';

class PantallaAplicaciones extends StatelessWidget {
  const PantallaAplicaciones({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: const [
        EncabezadoPantalla(
          titulo: 'Aplicaciones',
          subtitulo: 'Permisos y riesgos de lo instalado',
        ),
        SizedBox(height: 20),
        TarjetaInformacion(
          titulo: 'Análisis',
          filas: [FilaInformacion('Estado', 'Sin analizar')],
        ),
      ],
    );
  }
}