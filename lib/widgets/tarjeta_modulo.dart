import 'package:flutter/material.dart';

import '../tema/colores.dart';

class TarjetaModulo extends StatelessWidget {
  const TarjetaModulo({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    this.alPulsar,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback? alPulsar;

  @override
  Widget build(BuildContext context) {
    final habilitada = alPulsar != null;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Colores.borde),
    );

    return Material(
      color: Colores.superficie,
      shape: forma,
      child: InkWell(
        customBorder: forma,
        onTap: alPulsar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: habilitada ? Colores.primario : Colores.superficieElevada,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icono,
                  size: 22,
                  color: habilitada
                      ? Colores.textoPrincipal
                      : Colores.textoSecundario,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colores.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}