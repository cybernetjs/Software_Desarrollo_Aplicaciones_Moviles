import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

import '../modelos/indicador_stalkerware.dart';
import 'base_stalkerware.dart';
import 'descargador_lista.dart';

class CargaIndicadores {
  const CargaIndicadores(this.base, this.actualizadaEl);

  final BaseStalkerware base;
  final DateTime? actualizadaEl;
}

class RepositorioIndicadores {
  RepositorioIndicadores({DescargadorLista? descargador})
      : _descargador = descargador ?? DescargadorLista();

  static const String _rutaAsset = 'assets/ioc.yaml';
  static const String _nombreArchivo = 'lista_stalkerware.yaml';

  final DescargadorLista _descargador;

  Future<CargaIndicadores> cargar() async {
    final archivo = await _obtenerArchivo();

    if (await archivo.exists()) {
      try {
        final base = _convertir(await archivo.readAsString());
        return CargaIndicadores(base, await archivo.lastModified());
      } on FormatException {
        await archivo.delete();
      }
    }

    final texto = await rootBundle.loadString(_rutaAsset);
    return CargaIndicadores(_convertir(texto), null);
  }

  Future<CargaIndicadores> actualizar() async {
    final texto = await _descargador.descargar();
    final base = _convertirDescarga(texto);
    final archivo = await _obtenerArchivo();
    final temporal = File('${archivo.path}.tmp');

    await temporal.writeAsString(texto, flush: true);
    await temporal.rename(archivo.path);
    return CargaIndicadores(base, await archivo.lastModified());
  }

  BaseStalkerware _convertirDescarga(String texto) {
    try {
      return _convertir(texto);
    } on FormatException {
      throw const ErrorActualizacion(
        'La lista descargada no tiene el formato esperado.',
      );
    }
  }

  Future<File> _obtenerArchivo() async {
    final carpeta = await getApplicationSupportDirectory();
    return File('${carpeta.path}/$_nombreArchivo');
  }

  BaseStalkerware _convertir(String texto) {
    final documento = loadYaml(texto);

    if (documento is! YamlList) {
      throw const FormatException(
        'El archivo de indicadores no tiene el formato esperado.',
      );
    }

    final indicadores =
        documento.whereType<YamlMap>().map(_convertirEntrada).toList();
    if (indicadores.isEmpty) {
      throw const FormatException('La lista de indicadores está vacía.');
    }
    return BaseStalkerware(indicadores);
  }

  IndicadorStalkerware _convertirEntrada(YamlMap entrada) {
    return IndicadorStalkerware(
      nombre: '${entrada['name'] ?? 'Desconocida'}',
      tipo: '${entrada['type'] ?? 'stalkerware'}'.toLowerCase(),
      paquetes: _extraerLista(entrada['packages']).toSet(),
      certificados: _extraerLista(entrada['certificates'])
          .map(_normalizarHuella)
          .where((huella) => huella.isNotEmpty)
          .toSet(),
      dominios: _extraerLista(_buscarDominiosC2(entrada))
          .map(_normalizarDominio)
          .where((dominio) => dominio.isNotEmpty)
          .toSet(),
    );
  }

  dynamic _buscarDominiosC2(YamlMap entrada) {
    final c2 = entrada['c2'];
    return c2 is YamlMap ? c2['domains'] : null;
  }

  Iterable<String> _extraerLista(dynamic valor) {
    if (valor is! YamlList) return const <String>[];
    return valor
        .map((elemento) => '$elemento'.trim())
        .where((texto) => texto.isNotEmpty);
  }

  String _normalizarHuella(String huella) {
    return huella.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toLowerCase();
  }

  String _normalizarDominio(String dominio) {
    return dominio.trim().toLowerCase();
  }
}