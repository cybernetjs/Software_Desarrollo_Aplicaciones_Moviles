import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../modelos/nivel_riesgo.dart';
import '../modelos/resultado_apk.dart';
import '../servicios/analizador_apk.dart';
import '../servicios/servicio_descargas.dart';
import 'controlador_analisis.dart';

class ControladorDescargas extends ChangeNotifier {
  ControladorDescargas({ServicioDescargas? servicio, AnalizadorApk? analizador})
      : _servicio = servicio ?? ServicioDescargas(),
        _analizador = analizador ?? AnalizadorApk();

  final ServicioDescargas _servicio;
  final AnalizadorApk _analizador;

  EstadoAnalisis _estado = EstadoAnalisis.inactivo;
  bool _soportado = true;
  bool _concedido = false;
  List<ResultadoApk> _resultados = const [];
  int _revisados = 0;
  int _total = 0;
  int _omitidos = 0;
  String? _mensajeError;

  EstadoAnalisis get estado => _estado;
  bool get soportado => _soportado;
  bool get concedido => _concedido;
  List<ResultadoApk> get resultados => _resultados;
  int get revisados => _revisados;
  int get total => _total;
  int get omitidos => _omitidos;
  String? get mensajeError => _mensajeError;

  int contarPorNivel(NivelRiesgo nivel) =>
      _resultados.where((resultado) => resultado.nivel == nivel).length;

  Future<void> consultarPermiso() async {
    try {
      final permiso = await _servicio.consultarPermiso();
      _soportado = permiso.soportado;
      _concedido = permiso.concedido;
    } on MissingPluginException {
      _soportado = false;
    } on PlatformException {
      _concedido = false;
    }
    notifyListeners();
  }

  Future<void> abrirAjustes() async {
    try {
      await _servicio.abrirAjustes();
    } on PlatformException catch (error) {
      _fallar(error.message ?? 'No se pudieron abrir los ajustes.');
      notifyListeners();
    }
  }

  Future<void> revisar() async {
    if (_estado == EstadoAnalisis.analizando) return;

    _estado = EstadoAnalisis.analizando;
    _mensajeError = null;
    _revisados = 0;
    _total = 0;
    _omitidos = 0;
    notifyListeners();

    try {
      final archivos = await _servicio.listar();
      _total = archivos.length;
      notifyListeners();

      final resultados = <ResultadoApk>[];
      for (final archivo in archivos) {
        try {
          final informacion = await _servicio.analizar(archivo.ruta);
          resultados.add(_analizador.analizar(informacion));
        } on PlatformException {
          _omitidos++;
        }
        _revisados++;
        notifyListeners();
      }

      resultados.sort((a, b) => b.puntos.compareTo(a.puntos));
      _resultados = resultados;
      _estado = EstadoAnalisis.completado;
    } on MissingPluginException {
      _fallar('La revisión de descargas solo está disponible en Android.');
    } on PlatformException catch (error) {
      _fallar(error.message ?? 'No se pudo revisar la carpeta Descargas.');
    }

    notifyListeners();
  }

  void _fallar(String mensaje) {
    _mensajeError = mensaje;
    _estado = EstadoAnalisis.error;
  }
}