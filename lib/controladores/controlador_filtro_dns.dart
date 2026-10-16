import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../modelos/entrada_dns.dart';
import '../modelos/estado_filtro_dns.dart';
import '../servicios/analizador_dominios.dart';
import '../servicios/repositorio_indicadores.dart';
import '../servicios/servicio_filtro_dns.dart';

class ControladorFiltroDns extends ChangeNotifier {
  ControladorFiltroDns({
    ServicioFiltroDns? servicio,
    RepositorioIndicadores? repositorio,
    AnalizadorDominios? analizador,
    this.alCambiarModo,
  })  : _servicio = servicio ?? ServicioFiltroDns(),
        _repositorio = repositorio ?? RepositorioIndicadores(),
        _analizador = analizador ?? AnalizadorDominios();

  final VoidCallback? alCambiarModo;
  final ServicioFiltroDns _servicio;
  final RepositorioIndicadores _repositorio;
  final AnalizadorDominios _analizador;

  EstadoFiltroDns? _estado;
  RegistroDns? _registro;
  bool _ocupado = false;
  bool _leyendo = false;
  String? _mensaje;

  bool get activo => _estado?.activo ?? false;
  bool get dnsPrivadoEstricto => _estado?.dnsPrivadoEstricto ?? false;
  int get dominiosBloqueados => _estado?.dominiosBloqueados ?? 0;
  bool get ocupado => _ocupado;
  String? get mensaje => _mensaje;
  int get totalConsultas => _registro?.totalConsultas ?? 0;
  int get totalBloqueadas => _registro?.totalBloqueadas ?? 0;
  List<EntradaDns> get entradas => _registro?.entradas ?? const [];

  int get appsActivas =>
      entradas.map((entrada) => entrada.paquete).toSet().length;

  bool esSospechosa(EntradaDns entrada) {
    return !entrada.fueBloqueada && _analizador.parecenAleatorio(entrada.dominio);
  }

  List<EntradaDns> get alertas => entradas
      .where((entrada) => entrada.fueBloqueada || esSospechosa(entrada))
      .toList();

  List<EntradaDns> get actividad => entradas
      .where((entrada) => !entrada.fueBloqueada && !esSospechosa(entrada))
      .toList();

  Future<void> cargar() {
    return _ejecutar(() async {
      _estado = await _servicio.obtenerEstado();
      if (activo) _registro = await _servicio.obtenerRegistro();
    });
  }

  Future<void> alternar(bool encender) {
    return _ejecutar(() async {
      if (!encender) {
        _estado = await _servicio.desactivar();
        return;
      }

      final permitido = await _servicio.solicitarPermiso();
      if (!permitido) {
        _mensaje =
            'Android necesita tu permiso para crear la VPN local del filtro.';
        return;
      }

      final carga = await _repositorio.cargar();
      _estado = await _servicio.activar(carga.base.dominiosC2);
      alCambiarModo?.call();
    });
  }

  Future<void> limpiarRegistro() {
    return _ejecutar(() async {
      await _servicio.limpiarRegistro();
      _registro = await _servicio.obtenerRegistro();
    });
  }

  Future<void> actualizarRegistro() async {
    if (!activo || _leyendo) return;

    _leyendo = true;
    try {
      _registro = await _servicio.obtenerRegistro();
      notifyListeners();
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    } finally {
      _leyendo = false;
    }
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_ocupado) return;

    _ocupado = true;
    _mensaje = null;
    notifyListeners();

    try {
      await accion();
    } on MissingPluginException {
      _mensaje = 'El filtro DNS solo está disponible en Android.';
    } on PlatformException catch (error) {
      _mensaje = error.message ?? 'No se pudo actualizar el filtro DNS.';
    } on FlutterError {
      _mensaje = 'No se encontró la lista de indicadores (assets/ioc.yaml).';
    } on FormatException {
      _mensaje = 'La lista de indicadores no se pudo leer.';
    }

    _ocupado = false;
    notifyListeners();
  }
}