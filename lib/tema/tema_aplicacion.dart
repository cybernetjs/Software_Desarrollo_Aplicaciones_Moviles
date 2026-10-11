import 'package:flutter/material.dart';

import 'colores.dart';

class TemaAplicacion {
  TemaAplicacion._();

  static ThemeData get oscuro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colores.fondo,
      colorScheme: const ColorScheme.dark(
        primary: Colores.primario,
        surface: Colores.superficie,
        error: Colores.peligro,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colores.fondo,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colores.textoPrincipal,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colores.primario,
          foregroundColor: Colores.fondo,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}