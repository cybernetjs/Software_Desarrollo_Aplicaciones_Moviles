package com.example.sistema_tarea

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.Executors

class PluginFiltroDns : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener {
    private val nombreCanal = "antivirus/filtro_dns"
    private val codigoPermisoVpn = 4106
    private val limiteRegistro = 500
    private val hiloSecundario = Executors.newSingleThreadExecutor()
    private val hiloPrincipal = Handler(Looper.getMainLooper())
    private var canal: MethodChannel? = null
    private var contexto: Context? = null
    private var actividad: Activity? = null
    private var enlace: ActivityPluginBinding? = null
    private var resultadoPermiso: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        contexto = binding.applicationContext
        canal = MethodChannel(binding.binaryMessenger, nombreCanal).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        canal?.setMethodCallHandler(null)
        canal = null
        contexto = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        conectar(binding)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        conectar(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        desconectar()
    }

    override fun onDetachedFromActivity() {
        desconectar()
    }

    private fun conectar(binding: ActivityPluginBinding) {
        actividad = binding.activity
        enlace = binding
        binding.addActivityResultListener(this)
    }

    private fun desconectar() {
        enlace?.removeActivityResultListener(this)
        enlace = null
        actividad = null
    }

    override fun onMethodCall(llamada: MethodCall, resultado: MethodChannel.Result) {
        val contextoActual = contexto
        if (contextoActual == null) {
            resultado.error("SIN_CONTEXTO", "No hay contexto disponible.", null)
            return
        }

        when (llamada.method) {
            "obtenerEstado" -> {
                restaurarSiHaceFalta(contextoActual)
                resultado.success(construirEstado(contextoActual))
            }
            "solicitarPermiso" -> solicitarPermiso(contextoActual, resultado)
            "activar" -> {
                activar(contextoActual, llamada.argument<List<String>>("dominios"))
                resultado.success(construirEstado(contextoActual))
            }
            "desactivar" -> {
                RepositorioFiltroDns(contextoActual).activo = false
                enviarAccion(contextoActual, ServicioFiltroDns.ACCION_DETENER)
                resultado.success(construirEstado(contextoActual))
            }
            "obtenerRegistro" -> obtenerRegistro(contextoActual, resultado)
            "limpiarRegistro" -> {
                RegistroDns.limpiar()
                resultado.success(null)
            }
            else -> resultado.notImplemented()
        }
    }

    private fun construirEstado(contexto: Context): Map<String, Any?> {
        val repositorio = RepositorioFiltroDns(contexto)
        return mapOf(
            "activo" to repositorio.activo,
            "dnsPrivadoEstricto" to dnsPrivadoEstricto(contexto),
            "dominiosBloqueados" to repositorio.dominios.size
        )
    }

    private fun dnsPrivadoEstricto(contexto: Context): Boolean =
        Settings.Global.getString(contexto.contentResolver, "private_dns_mode") == "hostname"

    private fun restaurarSiHaceFalta(contexto: Context) {
        val repositorio = RepositorioFiltroDns(contexto)
        if (!repositorio.activo || ServicioFiltroDns.enEjecucion) return

        if (VpnService.prepare(contexto) != null) {
            repositorio.activo = false
            return
        }
        enviarAccion(contexto, ServicioFiltroDns.ACCION_INICIAR)
    }

    @Suppress("DEPRECATION")
    private fun solicitarPermiso(contexto: Context, resultado: MethodChannel.Result) {
        val pantalla = actividad
        if (pantalla == null) {
            resultado.error("SIN_ACTIVIDAD", "No hay una pantalla activa.", null)
            return
        }

        val intento = VpnService.prepare(contexto)
        if (intento == null) {
            resultado.success(true)
            return
        }
        if (resultadoPermiso != null) {
            resultado.success(false)
            return
        }

        resultadoPermiso = resultado
        pantalla.startActivityForResult(intento, codigoPermisoVpn)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != codigoPermisoVpn) return false

        resultadoPermiso?.success(resultCode == Activity.RESULT_OK)
        resultadoPermiso = null
        return true
    }

    private fun activar(contexto: Context, dominios: List<String>?) {
        val repositorio = RepositorioFiltroDns(contexto)
        repositorio.dominios = dominios?.toSet() ?: emptySet()
        repositorio.activo = true

        RepositorioFirewall(contexto).activo = false
        enviarAccion(contexto, ServicioFirewall.ACCION_DETENER, ServicioFirewall::class.java)
        enviarAccion(contexto, ServicioFiltroDns.ACCION_INICIAR)
    }

    private fun enviarAccion(
        contexto: Context,
        accion: String,
        servicio: Class<*> = ServicioFiltroDns::class.java
    ) {
        contexto.startService(Intent(contexto, servicio).setAction(accion))
    }

    private fun obtenerRegistro(contexto: Context, resultado: MethodChannel.Result) {
        hiloSecundario.execute {
            try {
                val gestor = contexto.packageManager
                val instantanea = RegistroDns.instantanea(limiteRegistro) { paquete ->
                    resolverNombre(gestor, paquete)
                }
                hiloPrincipal.post { resultado.success(instantanea) }
            } catch (error: Exception) {
                hiloPrincipal.post { resultado.error("ERROR_REGISTRO", error.message, null) }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun resolverNombre(gestor: PackageManager, paquete: String): String = try {
        gestor.getApplicationLabel(gestor.getApplicationInfo(paquete, 0)).toString()
    } catch (error: PackageManager.NameNotFoundException) {
        paquete
    }
}