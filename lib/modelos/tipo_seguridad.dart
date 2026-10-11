import 'nivel_riesgo.dart';

enum TipoSeguridad {
  abierta('Abierta', NivelRiesgo.alto),
  wep('WEP', NivelRiesgo.alto),
  wpa('WPA', NivelRiesgo.medio),
  wpa2('WPA2', NivelRiesgo.bajo),
  wpa2Wpa3('WPA2/WPA3', NivelRiesgo.bajo),
  wpa3('WPA3', NivelRiesgo.bajo),
  owe('OWE', NivelRiesgo.bajo);

  const TipoSeguridad(this.etiqueta, this.nivel);

  final String etiqueta;
  final NivelRiesgo nivel;

  bool get tieneCifradoDebil => this == wep || this == wpa;

  static TipoSeguridad desdeCapacidades(String capacidades) {
    final texto = capacidades.toUpperCase();
    final tieneSae = texto.contains('SAE');
    final tienePsk = texto.contains('PSK');

    if (tieneSae && tienePsk) return wpa2Wpa3;
    if (tieneSae) return wpa3;
    if (texto.contains('OWE')) return owe;
    if (texto.contains('RSN') || texto.contains('WPA2')) return wpa2;
    if (texto.contains('WPA')) return wpa;
    if (texto.contains('WEP')) return wep;
    return abierta;
  }
}