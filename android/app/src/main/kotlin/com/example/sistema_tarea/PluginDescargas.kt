package com.example.sistema_tarea

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException
import java.security.MessageDigest
import java.util.concurrent.Executors

class PluginDescargas : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private val nombreCanal = "antivirus/descargas"
    private val profundidadMaxima = 3
    private val maximoArchivos = 100
    private val permisoAccesibilidad = "android.permission.BIND_ACCESSIBILITY_SERVICE"
    private val permisoAdministrador = "android.permission.BIND_DEVICE_ADMIN"
    private val hiloSecundario = Executors.newSingleThreadExecutor()
    private val hiloPrincipal = android.os.Handler(android.os.Looper.getMainLooper())
    private var canal: MethodChannel? = null
    private var contexto: Context? = null
    private var actividad: Activity? = null

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
        actividad = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        actividad = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        actividad = null
    }

    override fun onDetachedFromActivity() {
        actividad = null
    }

    override fun onMethodCall(llamada: MethodCall, resultado: MethodChannel.Result) {
        when (llamada.method) {
            "permisoArchivos" -> resultado.success(consultarPermiso())
            "abrirAjustesArchivos" -> abrirAjustes(resultado)
            "listarDescargas" -> ejecutar(resultado) { listarApk() }
            "analizarRuta" -> {
                val ruta = llamada.argument<String>("ruta")
                if (ruta == null) {
                    resultado.error("SIN_RUTA", "Falta la ruta del archivo.", null)
                } else {
                    ejecutar(resultado) { analizarRuta(ruta) }
                }
            }
            else -> resultado.notImplemented()
        }
    }

    private fun ejecutar(resultado: MethodChannel.Result, trabajo: () -> Any) {
        hiloSecundario.execute {
            try {
                val respuesta = trabajo()
                hiloPrincipal.post { resultado.success(respuesta) }
            } catch (error: Exception) {
                hiloPrincipal.post { resultado.error("ERROR_DESCARGAS", error.message, null) }
            }
        }
    }

    private fun soportado(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R

    private fun consultarPermiso(): Map<String, Any?> = mapOf(
        "soportado" to soportado(),
        "concedido" to (soportado() && Environment.isExternalStorageManager())
    )

    private fun abrirAjustes(resultado: MethodChannel.Result) {
        val pantalla = actividad
        if (pantalla == null) {
            resultado.error("SIN_ACTIVIDAD", "No hay una pantalla activa.", null)
            return
        }
        if (!soportado()) {
            resultado.error("NO_SOPORTADO", "Esta función necesita Android 11 o superior.", null)
            return
        }

        try {
            pantalla.startActivity(
                Intent(
                    Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:${pantalla.packageName}")
                )
            )
        } catch (error: Exception) {
            pantalla.startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
        }
        resultado.success(null)
    }

    @Suppress("DEPRECATION")
    private fun carpetaDescargas(): File =
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)

    private fun verificarAcceso() {
        if (!soportado() || !Environment.isExternalStorageManager()) {
            throw IOException("Falta el permiso de acceso a todos los archivos.")
        }
    }

    private fun listarApk(): List<Map<String, Any?>> {
        verificarAcceso()
        return carpetaDescargas()
            .walkTopDown()
            .maxDepth(profundidadMaxima)
            .filter { it.isFile && it.extension.equals("apk", ignoreCase = true) }
            .sortedByDescending { it.lastModified() }
            .take(maximoArchivos)
            .map { mapOf("ruta" to it.absolutePath, "nombre" to it.name, "tamano" to it.length()) }
            .toList()
    }

    private fun analizarRuta(ruta: String): Map<String, Any?> {
        verificarAcceso()
        val contextoActual = contexto ?: throw IOException("No hay contexto disponible.")
        val archivo = File(ruta)
        val descargas = carpetaDescargas().canonicalPath

        if (!archivo.isFile || !archivo.canonicalPath.startsWith(descargas + File.separator)) {
            throw IOException("El archivo no está en la carpeta Descargas.")
        }

        val informacion = leerPaquete(contextoActual, archivo.absolutePath)
        return construirRespuesta(contextoActual, archivo, calcularHuella(archivo), informacion)
    }

    private fun calcularHuella(archivo: File): String {
        val resumen = MessageDigest.getInstance("SHA-256")
        FileInputStream(archivo).use { entrada ->
            val almacen = ByteArray(65536)
            while (true) {
                val leidos = entrada.read(almacen)
                if (leidos < 0) break
                resumen.update(almacen, 0, leidos)
            }
        }
        return resumen.digest().joinToString("") { "%02x".format(it) }
    }

    @Suppress("DEPRECATION")
    private fun leerPaquete(contexto: Context, ruta: String): PackageInfo? {
        val banderas = PackageManager.GET_PERMISSIONS or
            PackageManager.GET_SERVICES or
            PackageManager.GET_RECEIVERS or
            HuellasFirma.bandera()
        val gestor = contexto.packageManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            gestor.getPackageArchiveInfo(ruta, PackageManager.PackageInfoFlags.of(banderas.toLong()))
        } else {
            gestor.getPackageArchiveInfo(ruta, banderas)
        }
    }

    @Suppress("DEPRECATION")
    private fun obtenerInstalada(gestor: PackageManager, paquete: String): PackageInfo? = try {
        gestor.getPackageInfo(paquete, HuellasFirma.bandera())
    } catch (error: PackageManager.NameNotFoundException) {
        null
    }

    private fun obtenerNombreApp(
        gestor: PackageManager,
        informacion: PackageInfo,
        ruta: String
    ): String? {
        val aplicacion = informacion.applicationInfo ?: return null
        aplicacion.sourceDir = ruta
        aplicacion.publicSourceDir = ruta
        return gestor.getApplicationLabel(aplicacion).toString()
    }

    private fun construirRespuesta(
        contexto: Context,
        archivo: File,
        huella: String,
        informacion: PackageInfo?
    ): Map<String, Any?> {
        val gestor = contexto.packageManager
        val instalada = informacion?.let { obtenerInstalada(gestor, it.packageName) }

        return mapOf(
            "nombreArchivo" to archivo.name,
            "tamano" to archivo.length(),
            "sha256" to huella,
            "esApk" to (informacion != null),
            "paquete" to informacion?.packageName,
            "nombreApp" to informacion?.let { obtenerNombreApp(gestor, it, archivo.absolutePath) },
            "version" to informacion?.versionName,
            "permisos" to (informacion?.requestedPermissions?.toList() ?: emptyList()),
            "usaAccesibilidad" to
                (informacion?.services?.any { it.permission == permisoAccesibilidad } == true),
            "esAdministrador" to
                (informacion?.receivers?.any { it.permission == permisoAdministrador } == true),
            "firma" to informacion?.let { HuellasFirma.calcular(it).second.firstOrNull() },
            "instalada" to (instalada != null),
            "firmaInstalada" to instalada?.let { HuellasFirma.calcular(it).second.firstOrNull() }
        )
    }
}