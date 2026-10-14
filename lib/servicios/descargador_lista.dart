import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ErrorActualizacion implements Exception {
  const ErrorActualizacion(this.mensaje);

  final String mensaje;
}

class DescargadorLista {
  static const String _direccion =
      'https://raw.githubusercontent.com/AssoEchap/stalkerware-indicators/master/ioc.yaml';
  static const Duration _espera = Duration(seconds: 10);
  static const Duration _esperaLectura = Duration(seconds: 30);
  static const int _tamanoMaximo = 8 * 1024 * 1024;

  Future<String> descargar() async {
    final cliente = HttpClient()..connectionTimeout = _espera;

    try {
      final peticion = await cliente.getUrl(Uri.parse(_direccion)).timeout(_espera);
      final respuesta = await peticion.close().timeout(_espera);

      if (respuesta.statusCode != HttpStatus.ok) {
        throw ErrorActualizacion(
          'El servidor respondió con el código ${respuesta.statusCode}.',
        );
      }
      return await _leer(respuesta).timeout(_esperaLectura);
    } on SocketException {
      throw const ErrorActualizacion('Sin conexión a internet.');
    } on TimeoutException {
      throw const ErrorActualizacion('La descarga tardó demasiado.');
    } on HandshakeException {
      throw const ErrorActualizacion('No se pudo establecer una conexión segura.');
    } on HttpException {
      throw const ErrorActualizacion('Falló la descarga de la lista.');
    } finally {
      cliente.close(force: true);
    }
  }

  Future<String> _leer(HttpClientResponse respuesta) async {
    final bytes = BytesBuilder(copy: false);

    await for (final bloque in respuesta) {
      bytes.add(bloque);
      if (bytes.length > _tamanoMaximo) {
        throw const ErrorActualizacion('La lista descargada es demasiado grande.');
      }
    }

    try {
      return utf8.decode(bytes.takeBytes());
    } on FormatException {
      throw const ErrorActualizacion('La lista descargada no se pudo leer.');
    }
  }
}