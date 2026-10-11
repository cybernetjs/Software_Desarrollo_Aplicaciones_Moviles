import 'package:flutter/material.dart';

import 'colores.dart';

class TemaAplicacion {
  TemaAplicacion._();

  static BoxDecoration get decoracionTarjeta {
    return BoxDecoration(
      color: Colores.superficie,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colores.borde),
    );
  }

  static ThemeData get oscuro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colores.fondo,
      colorScheme: const ColorScheme.dark(
        primary: Colores.primarioClaro,
        surface: Colores.superficie,
        error: Colores.peligro,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colores.fondo,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colores.textoPrincipal,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colores.superficie,
        selectedItemColor: Colores.primarioClaro,
        unselectedItemColor: Colores.textoSecundario,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        showUnselectedLabels: true,
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colores.superficieElevada,
        contentTextStyle: TextStyle(color: Colores.textoPrincipal),
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colores.primario,
          foregroundColor: Colores.textoPrincipal,
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