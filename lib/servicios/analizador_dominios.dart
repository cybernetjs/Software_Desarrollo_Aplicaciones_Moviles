import 'dart:math' as matematicas;

class AnalizadorDominios {
  static const int _longitudMinima = 12;
  static const double _entropiaMinima = 3.3;
  static const double _proporcionVocalesMaxima = 0.25;
  static const String _vocales = 'aeiou';

  bool parecenAleatorio(String dominio) {
    final etiqueta = _etiquetaPrincipal(dominio);
    if (etiqueta.length < _longitudMinima) return false;

    final vocales = etiqueta.split('').where(_vocales.contains).length;
    final proporcion = vocales / etiqueta.length;
    return _entropia(etiqueta) >= _entropiaMinima &&
        proporcion <= _proporcionVocalesMaxima;
  }

  String _etiquetaPrincipal(String dominio) {
    final partes = dominio
        .toLowerCase()
        .split('.')
        .where((parte) => parte.isNotEmpty)
        .toList();
    if (partes.length < 2) return '';
    return partes[partes.length - 2];
  }

  double _entropia(String texto) {
    final frecuencias = <String, int>{};
    for (final letra in texto.split('')) {
      frecuencias[letra] = (frecuencias[letra] ?? 0) + 1;
    }

    var entropia = 0.0;
    for (final cantidad in frecuencias.values) {
      final probabilidad = cantidad / texto.length;
      entropia -=
          probabilidad * (matematicas.log(probabilidad) / matematicas.ln2);
    }
    return entropia;
  }
}