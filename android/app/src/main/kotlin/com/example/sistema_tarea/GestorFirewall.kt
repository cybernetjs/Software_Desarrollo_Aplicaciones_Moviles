package com.example.sistema_tarea

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class GestorFirewall(private val actividad: Activity) {
    private val nombreCanal = "antivirus/firewall"
    private val codigoPermisoVpn = 4102
    private val repositorio = RepositorioFirewall(actividad)
    private var resultadoPermiso: MethodChannel.Result? = null

    fun registrar(motor: FlutterEngine) {
        MethodChannel(motor.dartExecutor.binaryMessenger, nombreCanal)
            .setMethodCallHandler { llamada, resultado ->
                when (llamada.method) {
                    "obtenerEstado" -> resultado.success(obtenerEstado())
                    "solicitarPermisoVpn" -> solicitarPermiso(resultado)
                    "activar" -> {
                        activar(extraerPaquetes(llamada))
                        resultado.success(null)
                    }
                    "desactivar" -> {
                        desactivar()
                        resultado.success(null)
                    }
                    "guardarBloqueadas" -> {
                        guardarBloqueadas(extraerPaquetes(llamada))
                        resultado.success(null)
                    }
                    else -> resultado.notImplemented()
                }
            }
    }

    fun procesarResultadoActividad(codigo: Int, resultadoActividad: Int) {
        if (codigo != codigoPermisoVpn) return
        resultadoPermiso?.success(resultadoActividad == Activity.RESULT_OK)
        resultadoPermiso = null
    }

    private fun extraerPaquetes(llamada: MethodCall): Set<String> =
        llamada.argument<List<String>>("paquetes")?.toSet() ?: emptySet()

    private fun obtenerEstado(): Map<String, Any?> {
        restaurarSiHaceFalta()
        return mapOf(
            "activo" to repositorio.activo,
            "bloqueadas" to repositorio.bloqueadas.toList(),
            "paquetePropio" to actividad.packageName
        )
    }

    private fun restaurarSiHaceFalta() {
        if (!repositorio.activo || ServicioFirewall.enEjecucion) return
        if (VpnService.prepare(actividad) != null) {
            repositorio.activo = false
            return
        }
        enviarAccion(ServicioFirewall.ACCION_INICIAR)
    }

    private fun solicitarPermiso(resultado: MethodChannel.Result) {
        val intento = VpnService.prepare(actividad)
        if (intento == null) {
            resultado.success(true)
            return
        }
        if (resultadoPermiso != null) {
            resultado.success(false)
            return
        }
        resultadoPermiso = resultado
        actividad.startActivityForResult(intento, codigoPermisoVpn)
    }

    private fun activar(paquetes: Set<String>) {
        repositorio.bloqueadas = paquetes
        repositorio.activo = true
        enviarAccion(ServicioFirewall.ACCION_INICIAR)
    }

    private fun desactivar() {
        repositorio.activo = false
        enviarAccion(ServicioFirewall.ACCION_DETENER)
    }

    private fun guardarBloqueadas(paquetes: Set<String>) {
        repositorio.bloqueadas = paquetes
        if (repositorio.activo) enviarAccion(ServicioFirewall.ACCION_INICIAR)
    }

    private fun enviarAccion(accion: String) {
        actividad.startService(
            Intent(actividad, ServicioFirewall::class.java).setAction(accion)
        )
    }
}