import 'package:flutter/material.dart';

class RadioWifi {
  RadioWifi._();

  static int canalDesdeFrecuencia(int frecuencia) {
    if (frecuencia == 2484) return 14;
    if (frecuencia < 3000) return (frecuencia - 2407) ~/ 5;
    if (frecuencia < 5925) return (frecuencia - 5000) ~/ 5;
    return (frecuencia - 5950) ~/ 5;
  }

  static String banda(int frecuencia) {
    if (frecuencia < 3000) return '2.4 GHz';
    if (frecuencia < 5925) return '5 GHz';
    return '6 GHz';
  }

  static String calidadSenal(int senal) {
    if (senal >= -50) return 'Excelente';
    if (senal >= -60) return 'Buena';
    if (senal >= -70) return 'Regular';
    return 'Débil';
  }

  static IconData iconoSenal(int senal) {
    if (senal >= -60) return Icons.wifi;
    if (senal >= -70) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }
}