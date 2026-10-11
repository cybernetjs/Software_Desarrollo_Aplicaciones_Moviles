import 'package:flutter/material.dart';

import '../modelos/aplicacion_instalada.dart';
import '../modelos/motivo_riesgo.dart';
import '../modelos/nivel_riesgo.dart';
import '../modelos/resultado_analisis.dart';

typedef _ReglaPermiso = ({
  Set<String> permisos,
  int puntos,
  IconData icono,
  String motivo,
});

class AnalizadorRiesgo {
  static const int _umbralMedio = 5;
  static const int _umbralAlto = 8;

  static const Set<String> _tiendasConfiables = {
    'com.android.vending',
    'com.sec.android.app.samsungapps',
    'com.huawei.appmarket',
    'com.amazon.venezia',
  };

  static const List<_ReglaPermiso> _reglasPermisos = [
    (
      permisos: {
        'android.permission.READ_SMS',
        'android.permission.RECEIVE_SMS',
        'android.permission.SEND_SMS',
      },
      puntos: 2,
      icono: Icons.sms,
      motivo: 'Puede leer o enviar mensajes SMS',
    ),
    (
      permisos: {'android.permission.RECORD_AUDIO'},
      puntos: 1,
      icono: Icons.mic,
      motivo: 'Puede grabar audio con el micrófono',
    ),
    (
      permisos: {'android.permission.ACCESS_BACKGROUND_LOCATION'},
      puntos: 2,
      icono: Icons.location_on,
      motivo: 'Puede conocer tu ubicación en segundo plano',
    ),
    (
      permisos: {'android.permission.READ_CALL_LOG'},
      puntos: 1,
      icono: Icons.call,
      motivo: 'Puede leer el registro de llamadas',
    ),
    (
      permisos: {'android.permission.SYSTEM_ALERT_WINDOW'},
      puntos: 2,
      icono: Icons.layers,
      motivo: 'Puede dibujar contenido sobre otras aplicaciones',
    ),
    (
      permisos: {'android.permission.REQUEST_INSTALL_PACKAGES'},
      puntos: 1,
      icono: Icons.install_mobile,
      motivo: 'Puede solicitar la instalación de otras aplicaciones',
    ),
  ];

  ResultadoAnalisis analizar(AplicacionInstalada aplicacion) {
    var puntos = 0;
    final motivos = <MotivoRiesgo>[];

    void sumar(int valor, IconData icono, String descripcion) {
      puntos += valor;
      motivos.add(MotivoRiesgo(icono, descripcion));
    }

    if (aplicacion.usaAccesibilidad) {
      sumar(
        3,
        Icons.accessibility_new,
        'Puede leer y controlar la pantalla mediante accesibilidad',
      );
    }
    if (aplicacion.esAdministrador) {
      sumar(
        3,
        Icons.admin_panel_settings,
        'Puede actuar como administrador del dispositivo',
      );
    }
    if (!aplicacion.tieneIcono) {
      sumar(
        3,
        Icons.visibility_off,
        'No muestra un ícono en el menú de aplicaciones',
      );
    }
    for (final regla in _reglasPermisos) {
      if (aplicacion.permisos.any(regla.permisos.contains)) {
        sumar(regla.puntos, regla.icono, regla.motivo);
      }
    }
    if (!_tiendasConfiables.contains(aplicacion.origen)) {
      sumar(
        1,
        Icons.storefront,
        'Fue instalada fuera de una tienda confiable',
      );
    }

    return ResultadoAnalisis(
      aplicacion: aplicacion,
      puntos: puntos,
      nivel: _calcularNivel(puntos),
      motivos: motivos,
    );
  }

  NivelRiesgo _calcularNivel(int puntos) {
    if (puntos >= _umbralAlto) return NivelRiesgo.alto;
    if (puntos >= _umbralMedio) return NivelRiesgo.medio;
    return NivelRiesgo.bajo;
  }
}