import 'package:flutter/material.dart';

import '../modelos/aplicacion_instalada.dart';
import '../modelos/indicador_stalkerware.dart';
import '../modelos/motivo_riesgo.dart';
import '../modelos/resultado_analisis.dart';
import 'analizador_riesgo.dart';
import 'base_stalkerware.dart';

class DetectorStalkerware {
  DetectorStalkerware(this._base, {AnalizadorRiesgo? analizador})
      : _analizador = analizador ?? AnalizadorRiesgo();

  static const int _umbralSospecha = 5;
  static const int _puntosStalkerware = 10;
  static const int _puntosMonitoreo = 6;

  final BaseStalkerware _base;
  final AnalizadorRiesgo _analizador;

  List<ResultadoAnalisis> detectar(List<AplicacionInstalada> aplicaciones) {
    return aplicaciones
        .map(_evaluar)
        .whereType<ResultadoAnalisis>()
        .toList()
      ..sort((a, b) => b.puntos.compareTo(a.puntos));
  }

  ResultadoAnalisis? _evaluar(AplicacionInstalada aplicacion) {
    final coincidencia = _buscarCoincidencia(aplicacion);
    final evaluacion = _analizador.evaluarCaracteristicas(
      permisos: aplicacion.permisos,
      usaAccesibilidad: aplicacion.usaAccesibilidad,
      esAdministrador: aplicacion.esAdministrador,
      tieneIcono: aplicacion.tieneIcono,
    );
    final esSospechosa =
        !aplicacion.tieneIcono && evaluacion.puntos >= _umbralSospecha;

    if (coincidencia == null && !esSospechosa) return null;

    var puntos = evaluacion.puntos;
    final motivos = <MotivoRiesgo>[];

    if (coincidencia != null) {
      puntos += coincidencia.esWatchware ? _puntosMonitoreo : _puntosStalkerware;
      motivos.add(
        MotivoRiesgo(
          Icons.policy,
          coincidencia.esWatchware
              ? 'Coincide con ${coincidencia.nombre}, una app de monitoreo conocida'
              : 'Coincide con ${coincidencia.nombre}, una app de stalkerware conocida',
        ),
      );
    }
    motivos.addAll(evaluacion.motivos);

    return ResultadoAnalisis(
      aplicacion: aplicacion,
      puntos: puntos,
      nivel: _analizador.calcularNivel(puntos),
      motivos: motivos,
    );
  }

  IndicadorStalkerware? _buscarCoincidencia(AplicacionInstalada aplicacion) {
    return _base.buscarPorPaquete(aplicacion.paquete) ??
        _base.buscarPorCertificado([
          ...aplicacion.firmasSha1,
          ...aplicacion.firmasSha256,
        ]);
  }
}