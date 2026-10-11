import 'package:flutter/material.dart';

import '../widgets/encabezado_pantalla.dart';
import '../widgets/tarjeta_informacion.dart';

class PantallaDispositivo extends StatelessWidget {
  const PantallaDispositivo({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: const [
        EncabezadoPantalla(
          titulo: 'Dispositivo',
          subtitulo: 'Estado de seguridad del equipo',
        ),
        SizedBox(height: 20),
        TarjetaInformacion(
          titulo: 'Sistema',
          filas: [FilaInformacion('Revisión', 'Sin realizar')],
        ),
      ],
    );
  }
}