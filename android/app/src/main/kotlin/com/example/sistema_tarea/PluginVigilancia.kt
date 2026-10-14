package com.example.sistema_tarea

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.concurrent.Executors

class PluginVigilancia : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    PluginRegistry.RequestPermissionsResultListener {
    private val nombreCanal = "antivirus/vigilancia"
    private val codigoPermiso = 4104
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
        binding.addRequestPermissionsResultListener(this)
    }

    private fun desconectar() {
        enlace?.removeRequestPermissionsResultListener(this)
        enlace = null
        actividad = null
    }

    override fun onMethodCall(llamada: MethodCall, resultado: MethodChannel.Result) {
        when (llamada.method) {
            "obtenerEstado" -> responder(resultado) { contexto, repositorio ->
                if (repositorio.activa) DetectorInstalaciones(contexto, repositorio).detectarNuevas()
            }
            "activar" -> activar(resultado)
            "desactivar" -> responder(resultado) { contexto, repositorio ->
                ServicioVigilancia.cancelar(contexto)
                repositorio.reiniciar()
            }
            "marcarRevisadas" -> responder(resultado) { _, repositorio ->
                repositorio.limpiarPendientes()
            }
            else -> resultado.notImplemented()
        }
    }

    private fun responder(
        resultado: MethodChannel.Result,
        trabajo: (Context, RepositorioVigilancia) -> Unit
    ) {
        val contextoActual = contexto
        if (contextoActual == null) {
            resultado.error("SIN_CONTEXTO", "No hay contexto disponible.", null)
            return
        }

        hiloSecundario.execute {
            try {
                val repositorio = RepositorioVigilancia(contextoActual)
                trabajo(contextoActual, repositorio)
                val estado = construirEstado(contextoActual, repositorio)
                hiloPrincipal.post { resultado.success(estado) }
            } catch (error: Exception) {
                hiloPrincipal.post { resultado.error("ERROR_VIGILANCIA", error.message, null) }
            }
        }
    }

    private fun activar(resultado: MethodChannel.Result) {
        val contextoActual = contexto
        if (contextoActual == null) {
            resultado.error("SIN_CONTEXTO", "No hay contexto disponible.", null)
            return
        }

        hiloSecundario.execute {
            try {
                val repositorio = RepositorioVigilancia(contextoActual)
                repositorio.activa = true
                DetectorInstalaciones(contextoActual, repositorio).detectarNuevas()
                ServicioVigilancia.programar(contextoActual)
                hiloPrincipal.post { pedirNotificacionesYResponder(contextoActual, resultado) }
            } catch (error: Exception) {
                hiloPrincipal.post { resultado.error("ERROR_VIGILANCIA", error.message, null) }
            }
        }
    }

    private fun pedirNotificacionesYResponder(
        contexto: Context,
        resultado: MethodChannel.Result
    ) {
        val pantalla = actividad
        val faltaPermiso = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                contexto,
                Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED

        if (faltaPermiso && pantalla != null && resultadoPermiso == null) {
            resultadoPermiso = resultado
            ActivityCompat.requestPermissions(
                pantalla,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                codigoPermiso
            )
            return
        }
        resultado.success(construirEstado(contexto, RepositorioVigilancia(contexto)))
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != codigoPermiso) return false

        val resultado = resultadoPermiso ?: return true
        resultadoPermiso = null

        val contextoActual = contexto
        if (contextoActual == null) {
            resultado.success(null)
        } else {
            resultado.success(construirEstado(contextoActual, RepositorioVigilancia(contextoActual)))
        }
        return true
    }

    private fun construirEstado(
        contexto: Context,
        repositorio: RepositorioVigilancia
    ): Map<String, Any?> = mapOf(
        "activa" to repositorio.activa,
        "notificaciones" to NotificationManagerCompat.from(contexto).areNotificationsEnabled(),
        "pendientes" to repositorio.pendientes.map {
            mapOf("paquete" to it.key, "nombre" to it.value)
        }
    )
}