import 'package:flutter/material.dart';

import '../modelos/estado_wifi.dart';
import '../modelos/nivel_riesgo.dart';
import '../modelos/red_wifi.dart';
import '../modelos/tipo_seguridad.dart';
import '../modelos/verificacion_seguridad.dart';

class AuditorWifi {
  List<VerificacionSeguridad> auditar(EstadoWifi estado) {
    final conexion = estado.conexion;

    return [
      if (conexion != null) _verificarConexion(conexion),
      _verificarRedesAbiertas(estado.redes),
      _verificarCifradoDebil(estado.redes),
      _verificarRedesDuplicadas(estado.redes),
    ];
  }

  VerificacionSeguridad _verificarConexion(ConexionWifi conexion) {
    final seguridad = conexion.seguridad;

    if (seguridad == null) {
      return VerificacionSeguridad(
        titulo: 'Red conectada',
        detalle: 'No se pudo conocer el cifrado de ${conexion.nombre}',
        nivel: NivelRiesgo.medio,
        icono: Icons.help_outline,
      );
    }

    return VerificacionSeguridad(
      titulo: 'Red conectada',
      detalle: _describirCifrado(conexion.nombre, seguridad),
      nivel: seguridad.nivel,
      icono: Icons.wifi_lock,
    );
  }

  String _describirCifrado(String nombre, TipoSeguridad seguridad) {
    switch (seguridad) {
      case TipoSeguridad.abierta:
        return '$nombre no tiene contraseña: cualquiera puede ver tu tráfico';
      case TipoSeguridad.wep:
        return '$nombre usa WEP, un cifrado roto que se vulnera en minutos';
      case TipoSeguridad.wpa:
        return '$nombre usa WPA, un cifrado antiguo';
      default:
        return '$nombre usa ${seguridad.etiqueta}';
    }
  }

  VerificacionSeguridad _verificarRedesAbiertas(List<RedWifi> redes) {
    final cantidad =
        redes.where((red) => red.seguridad == TipoSeguridad.abierta).length;

    return VerificacionSeguridad(
      titulo: 'Redes abiertas',
      detalle: cantidad == 0
          ? 'No hay redes sin contraseña cerca'
          : 'Hay $cantidad ${cantidad == 1 ? 'red' : 'redes'} sin contraseña cerca: evita conectarte',
      nivel: cantidad == 0 ? NivelRiesgo.bajo : NivelRiesgo.medio,
      icono: Icons.lock_open,
    );
  }

  VerificacionSeguridad _verificarCifradoDebil(List<RedWifi> redes) {
    final cantidad =
        redes.where((red) => red.seguridad.tieneCifradoDebil).length;

    return VerificacionSeguridad(
      titulo: 'Cifrado obsoleto',
      detalle: cantidad == 0
          ? 'No hay redes con WEP o WPA cerca'
          : 'Hay $cantidad ${cantidad == 1 ? 'red' : 'redes'} con WEP o WPA, fáciles de vulnerar',
      nivel: cantidad == 0 ? NivelRiesgo.bajo : NivelRiesgo.medio,
      icono: Icons.no_encryption,
    );
  }

  VerificacionSeguridad _verificarRedesDuplicadas(List<RedWifi> redes) {
    final estadosPorNombre = <String, Set<bool>>{};
    for (final red in redes) {
      if (red.esOculta) continue;
      estadosPorNombre
          .putIfAbsent(red.nombre, () => <bool>{})
          .add(red.seguridad == TipoSeguridad.abierta);
    }

    final sospechosas = estadosPorNombre.entries
        .where((entrada) => entrada.value.length > 1)
        .map((entrada) => entrada.key)
        .toList();

    return VerificacionSeguridad(
      titulo: 'Posibles redes falsas',
      detalle: sospechosas.isEmpty
          ? 'No se detectaron redes que imiten a otras'
          : 'Mismo nombre con y sin contraseña: ${sospechosas.join(', ')}',
      nivel: sospechosas.isEmpty ? NivelRiesgo.bajo : NivelRiesgo.medio,
      icono: Icons.copy_all,
    );
  }
}