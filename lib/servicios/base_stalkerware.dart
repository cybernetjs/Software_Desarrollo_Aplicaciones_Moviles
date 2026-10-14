import '../modelos/indicador_stalkerware.dart';

class BaseStalkerware {
  BaseStalkerware(List<IndicadorStalkerware> indicadores)
      : totalIndicadores = indicadores.length,
        _porPaquete = {
          for (final indicador in indicadores)
            for (final paquete in indicador.paquetes) paquete: indicador,
        },
        _porCertificado = {
          for (final indicador in indicadores)
            for (final certificado in indicador.certificados)
              certificado: indicador,
        };

  final int totalIndicadores;
  final Map<String, IndicadorStalkerware> _porPaquete;
  final Map<String, IndicadorStalkerware> _porCertificado;

  IndicadorStalkerware? buscarPorPaquete(String paquete) {
    return _porPaquete[paquete];
  }

  IndicadorStalkerware? buscarPorCertificado(Iterable<String> huellas) {
    for (final huella in huellas) {
      final indicador = _porCertificado[huella.toLowerCase()];
      if (indicador != null) return indicador;
    }
    return null;
  }
}