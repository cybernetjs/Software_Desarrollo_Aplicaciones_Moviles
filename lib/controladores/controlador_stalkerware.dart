import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../modelos/nivel_riesgo.dart';
import '../modelos/resultado_analisis.dart';
import '../servicios/base_stalkerware.dart';
import '../servicios/descargador_lista.dart';
import '../servicios/detector_stalkerware.dart';
import '../servicios/repositorio_indicadores.dart';
import '../servicios/servicio_aplicaciones.dart';
import 'controlador_analisis.dart';

class ControladorStalkerware extends ChangeNotifier {
  ControladorStalkerware({
    ServicioAplicaciones? servicioAplicaciones,
    RepositorioIndicadores? repositorio,
  })  : _servicioAplicaciones = servicioAplicaciones ?? ServicioAplicaciones(),
        _repositorio = repositorio ?? RepositorioIndicadores();

  static const Duration _vigencia = Duration(days: 7);

  final ServicioAplicaciones _servicioAplicaciones;
  final RepositorioIndicadores _repositorio;

  EstadoAnalisis _estado = EstadoAnalisis.inactivo;
  List<ResultadoAnalisis> _hallazgos = const [];
  int _aplicacionesRevisadas = 0;
  BaseStalkerware? _base;
  DateTime? _fechaLista;
  bool _actualizando = false;
  bool _intentoAutomatico = false;
  String? _avisoLista;
  String? _mensajeError;

  EstadoAnalisis get estado => _estado;
  List<ResultadoAnalisis> get hallazgos => _hallazgos;
  int get aplicacionesRevisadas => _aplicacionesRevisadas;
  int get totalIndicadores => _base?.totalIndicadores ?? 0;
  bool get listaCargada => _base != null;
  DateTime? get fechaLista => _fechaLista;
  bool get actualizando => _actualizando;
  String? get avisoLista => _avisoLista;
  String? get mensajeError => _mensajeError;

  bool get _listaVencida {
    final fecha = _fechaLista;
    return fecha == null || DateTime.now().difference(fecha) > _vigencia;
  }

  NivelRiesgo get nivelGeneral {
    if (_hallazgos.any((hallazgo) => hallazgo.nivel == NivelRiesgo.alto)) {
      return NivelRiesgo.alto;
    }
    if (_hallazgos.isNotEmpty) return NivelRiesgo.medio;
    return NivelRiesgo.bajo;
  }

  Future<void> cargarLista() async {
    if (_base != null) return;

    try {
      final carga = await _repositorio.cargar();
      _base = carga.base;
      _fechaLista = carga.actualizadaEl;
      _avisoLista = null;
    } on FlutterError {
      _avisoLista =
          'No se encontró la lista incluida. Revisa que assets/ioc.yaml exista y esté declarada en pubspec.yaml.';
    } on FormatException {
      _avisoLista = 'La lista incluida no se pudo leer: formato inesperado.';
    }

    notifyListeners();
  }

  Future<void> actualizarLista() async {
    if (_actualizando) return;

    _actualizando = true;
    _avisoLista = null;
    notifyListeners();

    try {
      final carga = await _repositorio.actualizar();
      _base = carga.base;
      _fechaLista = carga.actualizadaEl;
      _avisoLista =
          'Lista actualizada: ${carga.base.totalIndicadores} apps conocidas.';
    } on ErrorActualizacion catch (error) {
      _avisoLista = error.mensaje;
    } on FileSystemException {
      _avisoLista = 'No se pudo guardar la lista descargada.';
    }

    _actualizando = false;
    notifyListeners();
  }

  Future<void> revisar() async {
    if (_estado == EstadoAnalisis.analizando) return;

    _estado = EstadoAnalisis.analizando;
    _mensajeError = null;
    notifyListeners();

    try {
      await _prepararLista();
      final base = _base;
      if (base == null) {
        _fallar(_avisoLista ?? 'No se pudo cargar la lista de stalkerware.');
      } else {
        await _revisarAplicaciones(base);
      }
    } on MissingPluginException {
      _fallar('La revisión solo está disponible en Android.');
    } on PlatformException catch (error) {
      _fallar(error.message ?? 'No se pudo revisar las aplicaciones.');
    }

    notifyListeners();
  }

  Future<void> _prepararLista() async {
    await cargarLista();
    if (_base == null || _intentoAutomatico || !_listaVencida) return;

    _intentoAutomatico = true;
    await actualizarLista();
  }

  Future<void> _revisarAplicaciones(BaseStalkerware base) async {
    final instaladas = await _servicioAplicaciones.obtenerInstaladas();
    final revisables =
        instaladas.where((aplicacion) => !aplicacion.esSistema).toList();

    _hallazgos = DetectorStalkerware(base).detectar(revisables);
    _aplicacionesRevisadas = revisables.length;
    _estado = EstadoAnalisis.completado;
  }

  void _fallar(String mensaje) {
    _mensajeError = mensaje;
    _estado = EstadoAnalisis.error;
  }
}