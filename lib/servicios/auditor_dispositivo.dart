import 'package:flutter/material.dart';

import '../modelos/estado_dispositivo.dart';
import '../modelos/nivel_riesgo.dart';
import '../modelos/verificacion_seguridad.dart';

class AuditorDispositivo {
  static const int _diasParcheAceptable = 90;
  static const int _diasParcheCritico = 180;

  List<VerificacionSeguridad> auditar(
    EstadoDispositivo estado, {
    DateTime? ahora,
  }) {
    return [
      _verificarBloqueo(estado),
      _verificarParche(estado, ahora ?? DateTime.now()),
      _verificarDepuracion(estado),
      _verificarOpcionesDesarrollador(estado),
      _verificarRoot(estado),
    ];
  }

  VerificacionSeguridad _verificarBloqueo(EstadoDispositivo estado) {
    return VerificacionSeguridad(
      titulo: 'Bloqueo de pantalla',
      detalle: estado.bloqueoPantalla
          ? 'Protegido con PIN, patrón o huella'
          : 'Sin protección: cualquiera puede abrir el equipo',
      nivel: estado.bloqueoPantalla ? NivelRiesgo.bajo : NivelRiesgo.alto,
      icono: Icons.lock,
    );
  }

  VerificacionSeguridad _verificarParche(
    EstadoDispositivo estado,
    DateTime ahora,
  ) {
    final parche = estado.parcheSeguridad;
    final fecha = parche == null ? null : DateTime.tryParse(parche);

    if (fecha == null) {
      return const VerificacionSeguridad(
        titulo: 'Actualizaciones de seguridad',
        detalle: 'No se pudo conocer la fecha del último parche',
        nivel: NivelRiesgo.medio,
        icono: Icons.system_update,
      );
    }

    final diferencia = ahora.difference(fecha).inDays;
    final dias = diferencia < 0 ? 0 : diferencia;

    return VerificacionSeguridad(
      titulo: 'Actualizaciones de seguridad',
      detalle: 'Último parche hace $dias días',
      nivel: _calcularNivelParche(dias),
      icono: Icons.system_update,
    );
  }

  NivelRiesgo _calcularNivelParche(int dias) {
    if (dias > _diasParcheCritico) return NivelRiesgo.alto;
    if (dias > _diasParcheAceptable) return NivelRiesgo.medio;
    return NivelRiesgo.bajo;
  }

  VerificacionSeguridad _verificarDepuracion(EstadoDispositivo estado) {
    return VerificacionSeguridad(
      titulo: 'Depuración USB',
      detalle: estado.depuracionUsb
          ? 'Activada: permite controlar el equipo por cable'
          : 'Desactivada',
      nivel: estado.depuracionUsb ? NivelRiesgo.medio : NivelRiesgo.bajo,
      icono: Icons.usb,
    );
  }

  VerificacionSeguridad _verificarOpcionesDesarrollador(
    EstadoDispositivo estado,
  ) {
    return VerificacionSeguridad(
      titulo: 'Opciones de desarrollador',
      detalle: estado.opcionesDesarrollador
          ? 'Activadas: desactívalas si no las usas'
          : 'Desactivadas',
      nivel: estado.opcionesDesarrollador
          ? NivelRiesgo.medio
          : NivelRiesgo.bajo,
      icono: Icons.developer_mode,
    );
  }

  VerificacionSeguridad _verificarRoot(EstadoDispositivo estado) {
    return VerificacionSeguridad(
      titulo: 'Acceso root',
      detalle: estado.dispositivoRoot
          ? 'Se encontraron señales de acceso root'
          : 'No se encontraron señales de acceso root',
      nivel: estado.dispositivoRoot ? NivelRiesgo.alto : NivelRiesgo.bajo,
      icono: Icons.security,
    );
  }
}