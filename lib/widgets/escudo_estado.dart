import 'package:flutter/material.dart';

class EscudoEstado extends StatelessWidget {
  const EscudoEstado({
    super.key,
    required this.color,
    required this.icono,
    this.analizando = false,
    this.tamano = 150,
  });

  final Color color;
  final IconData icono;
  final bool analizando;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: analizando ? null : 1,
              strokeWidth: 5,
              color: color,
              backgroundColor: color.withAlpha(40),
            ),
          ),
          Container(
            width: tamano * 0.78,
            height: tamano * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(28),
            ),
            child: Icon(icono, size: tamano * 0.4, color: color),
          ),
        ],
      ),
    );
  }
}