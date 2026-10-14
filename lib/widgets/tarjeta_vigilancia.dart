import 'package:flutter/material.dart';

import '../controladores/controlador_vigilancia.dart';
import '../tema/colores.dart';
import '../tema/tema_aplicacion.dart';

class TarjetaVigilancia extends StatelessWidget {
  const TarjetaVigilancia({
    super.key,
    required this.controlador,
    required this.alRevisar,
  });

  final ControladorVigilancia controlador;
  final VoidCallback alRevisar;

  String _describirPendientes() {
    final nombres = controlador.pendientes.map((app) => app.nombre).toList();
    final total = nombres.length;
    final visibles = nombres.take(2).join(', ');
    final resto = total > 2 ? ' y ${total - 2} más' : '';
    final titulo = total == 1
        ? 'Se instaló 1 app nueva'
        : 'Se instalaron $total apps nuevas';
    return '$titulo: $visibles$resto';
  }

  @override
  Widget build(BuildContext context) {
    final activa = controlador.activa;
    final pendientes = controlador.pendientes;
    final mensaje = controlador.mensaje;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: TemaAplicacion.decoracionTarjeta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: activa ? Colores.seguro : Colores.superficieElevada,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.visibility,
                  size: 26,
                  color: activa ? Colores.fondo : Colores.textoSecundario,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vigilancia de instalaciones',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activa
                          ? 'Activa · te avisa cuando se instala una app'
                          : 'Desactivada',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: activa,
                onChanged: controlador.ocupado ? null : controlador.alternar,
              ),
            ],
          ),
          if (activa && !controlador.notificacionesActivas) ...[
            const SizedBox(height: 12),
            const Text(
              'Las notificaciones están desactivadas: verás las apps nuevas al abrir esta app.',
              style: TextStyle(fontSize: 12, color: Colores.textoSecundario),
            ),
          ],
          if (mensaje != null) ...[
            const SizedBox(height: 12),
            Text(
              mensaje,
              style: const TextStyle(fontSize: 13, color: Colores.advertencia),
            ),
          ],
          if (pendientes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _describirPendientes(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colores.textoPrincipal,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: alRevisar,
              child: const Text('Revisar ahora'),
            ),
          ],
        ],
      ),
    );
  }
}