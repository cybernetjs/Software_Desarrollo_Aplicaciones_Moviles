import 'package:flutter/material.dart';

import '../modelos/informacion_apk.dart';
import '../modelos/motivo_riesgo.dart';
import '../modelos/nivel_riesgo.dart';
import '../modelos/resultado_apk.dart';
import 'analizador_riesgo.dart';
import 'base_firmas.dart';

class AnalizadorApk {
  AnalizadorApk({AnalizadorRiesgo? analizador, BaseFirmas? baseFirmas})
      : _analizador = analizador ?? AnalizadorRiesgo(),
        _baseFirmas = baseFirmas ?? const BaseFirmas();

  static const List<String> _extensionesEmpaquetadas = [
    '.xapk',
    '.apks',
    '.apkm',
  ];

  final AnalizadorRiesgo _analizador;
  final BaseFirmas _baseFirmas;

  ResultadoApk analizar(InformacionApk informacion) {
    if (!informacion.esApk) {
      return _esPaqueteEmpaquetado(informacion.nombreArchivo)
          ? _resultadoEmpaquetado(informacion)
          : _resultadoInvalido(informacion);
    }

    var puntos = 0;
    final motivos = <MotivoRiesgo>[];

    void sumar(int valor, IconData icono, String descripcion) {
      puntos += valor;
      motivos.add(MotivoRiesgo(icono, descripcion));
    }

    if (_baseFirmas.esMalwareConocido(informacion.sha256)) {
      sumar(10, Icons.bug_report, 'Coincide con una firma de malware conocido');
    }
    if (_firmaDistintaDeLaInstalada(informacion)) {
      sumar(
        8,
        Icons.fingerprint,
        'Su firma no coincide con la de la app ya instalada con el mismo paquete',
      );
    }
    if (informacion.firma == null) {
      sumar(5, Icons.gpp_maybe, 'El archivo no tiene una firma válida');
    }

    final caracteristicas = _analizador.evaluarCaracteristicas(
      permisos: informacion.permisos,
      usaAccesibilidad: informacion.usaAccesibilidad,
      esAdministrador: informacion.esAdministrador,
      tieneIcono: true,
    );
    puntos += caracteristicas.puntos;
    motivos.addAll(caracteristicas.motivos);

    return ResultadoApk(
      informacion: informacion,
      puntos: puntos,
      nivel: _analizador.calcularNivel(puntos),
      motivos: motivos,
    );
  }

  bool _esPaqueteEmpaquetado(String nombreArchivo) {
    final nombre = nombreArchivo.toLowerCase();
    return _extensionesEmpaquetadas.any(nombre.endsWith);
  }

  ResultadoApk _resultadoEmpaquetado(InformacionApk informacion) {
    return ResultadoApk(
      informacion: informacion,
      puntos: 5,
      nivel: NivelRiesgo.medio,
      motivos: const [
        MotivoRiesgo(
          Icons.inventory_2,
          'Es un paquete de varios APK que todavía no se puede analizar a fondo',
        ),
      ],
    );
  }

  ResultadoApk _resultadoInvalido(InformacionApk informacion) {
    return ResultadoApk(
      informacion: informacion,
      puntos: 10,
      nivel: NivelRiesgo.alto,
      motivos: const [
        MotivoRiesgo(
          Icons.report_problem,
          'El archivo no es un APK válido o está dañado',
        ),
      ],
    );
  }

  bool _firmaDistintaDeLaInstalada(InformacionApk informacion) {
    final instalada = informacion.firmaInstalada;
    final actual = informacion.firma;
    return informacion.instalada &&
        instalada != null &&
        actual != null &&
        instalada != actual;
  }
}