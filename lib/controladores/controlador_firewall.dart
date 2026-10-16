import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../modelos/aplicacion_instalada.dart';
import '../servicios/servicio_aplicaciones.dart';
import '../servicios/servicio_firewall.dart';
import 'controlador_analisis.dart';

class ControladorFirewall extends ChangeNotifier {
  ControladorFirewall({
    ServicioFirewall? servicioFirewall,
    ServicioAplicaciones? servicioAplicaciones,
  })  : _servicioFirewall = servicioFirewall ?? ServicioFirewall(),
        _servicioAplicaciones = servicioAplicaciones ?? ServicioAplicaciones();

  static const String _permisoInternet = 'android.permission.INTERNET';

  final ServicioFirewall _servicioFirewall;
  final ServicioAplicaciones _servicioAplicaciones;

  EstadoAnalisis _estado = EstadoAnalisis.inactivo;
  List<AplicacionInstalada> _aplicaciones = const [];
  Set<String> _bloqueadas = <String>{};
  String _paquetePropio = '';
  bool _activo = false;
  bool _mostrarSistema = false;
  bool _ocupado = false;
  String? _mensaje;

  EstadoAnalisis get estado => _estado;
  bool get activo => _activo;
  bool get mostrarSistema => _mostrarSistema;
  bool get ocupado => _ocupado;
  String? get mensaje => _mensaje;
  int get totalBloqueadas => _bloqueadas.length;

  bool estaBloqueada(String paquete) => _bloqueadas.contains(paquete);

  List<AplicacionInstalada> get aplicacionesVisibles {
    final visibles = _aplicaciones
        .where(
          (aplicacion) =>
              aplicacion.paquete != _paquetePropio &&
              aplicacion.permisos.contains(_permisoInternet) &&
              (_mostrarSistema || !aplicacion.esSistema),
        )
        .toList();
    visibles.sort(
      (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
    );
    return visibles;
  }

  Future<void> cargar() async {
    if (_estado == EstadoAnalisis.analizando) return;

    _estado = EstadoAnalisis.analizando;
    _mensaje = null;
    notifyListeners();

    try {
      final estadoNativo = await _servicioFirewall.obtenerEstado();
      final instaladas = await _servicioAplicaciones.obtenerInstaladas();
      _activo = estadoNativo.activo;
      _bloqueadas = {...estadoNativo.bloqueadas};
      _paquetePropio = estadoNativo.paquetePropio;
      _aplicaciones = instaladas;
      _estado = EstadoAnalisis.completado;
    } on MissingPluginException {
      _fallar('El firewall solo está disponible en Android.');
    } on PlatformException catch (error) {
      _fallar(error.message ?? 'No se pudo cargar el firewall.');
    }

    notifyListeners();
  }

    Future<void> sincronizarEstado() async {
    try {
      final estadoNativo = await _servicioFirewall.obtenerEstado();
      _activo = estadoNativo.activo;
      _bloqueadas = {...estadoNativo.bloqueadas};
      notifyListeners();
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> alternarFirewall(bool encender) async {
    if (_ocupado) return;

    _ocupado = true;
    _mensaje = null;
    notifyListeners();

    await _ejecutar(() => encender ? _activar() : _desactivar());

    _ocupado = false;
    notifyListeners();
  }

  Future<void> alternarBloqueo(AplicacionInstalada aplicacion) async {
    if (_ocupado) return;

    _ocupado = true;
    _mensaje = null;
    final anterior = {..._bloqueadas};
    if (!_bloqueadas.add(aplicacion.paquete)) {
      _bloqueadas.remove(aplicacion.paquete);
    }
    notifyListeners();

    await _ejecutar(() => _servicioFirewall.guardarBloqueadas(_bloqueadas));
    if (_mensaje != null) _bloqueadas = anterior;

    _ocupado = false;
    notifyListeners();
  }

  void alternarMostrarSistema() {
    _mostrarSistema = !_mostrarSistema;
    notifyListeners();
  }

  Future<void> _activar() async {
    final permitido = await _servicioFirewall.solicitarPermiso();
    if (!permitido) {
      _mensaje = 'Android necesita tu permiso para crear la VPN local del firewall.';
      return;
    }
    await _servicioFirewall.activar(_bloqueadas);
    _activo = true;
  }

  Future<void> _desactivar() async {
    await _servicioFirewall.desactivar();
    _activo = false;
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    try {
      await accion();
    } on MissingPluginException {
      _mensaje = 'El firewall solo está disponible en Android.';
    } on PlatformException catch (error) {
      _mensaje = error.message ?? 'No se pudo aplicar el cambio.';
    }
  }

  void _fallar(String mensaje) {
    _mensaje = mensaje;
    _estado = EstadoAnalisis.error;
  }
}