import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';
import '../widgets/encabezado_pantalla.dart';
import '../widgets/escudo_estado.dart';
import '../widgets/tarjeta_informacion.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  void _mostrarAviso(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('El análisis estará disponible muy pronto')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const EncabezadoPantalla(
          titulo: 'Antivirus',
          subtitulo: 'Protección de tu dispositivo',
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: TemaAplicacion.decoracionTarjeta,
          child: const Column(
            children: [
              EscudoEstado(
                color: Colores.primarioClaro,
                icono: Icons.shield_outlined,
              ),
              SizedBox(height: 20),
              Text(
                'Listo para analizar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colores.textoPrincipal,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Revisa las aplicaciones instaladas en tu dispositivo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colores.textoSecundario),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => _mostrarAviso(context),
          child: const Text('Analizar ahora'),
        ),
        const SizedBox(height: 16),
        const TarjetaInformacion(
          titulo: 'Resumen',
          filas: [
            FilaInformacion('Última revisión', 'Nunca'),
            FilaInformacion('Aplicaciones analizadas', '0'),
            FilaInformacion('Riesgos detectados', '0'),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TarjetaInformacion(
                titulo: 'Archivos',
                filas: [FilaInformacion('Estado', 'Pendiente')],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: TarjetaInformacion(
                titulo: 'Navegación',
                filas: [FilaInformacion('Estado', 'Pendiente')],
              ),
            ),
          ],
        ),
      ],
    );
  }
}