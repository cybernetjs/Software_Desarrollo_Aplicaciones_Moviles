package com.example.sistema_tarea

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.IOException
import java.security.MessageDigest
import java.util.concurrent.Executors

class PluginApk : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener {
    private val nombreCanal = "antivirus/apk"
    private val codigoSelector = 4103
    private val permisoAccesibilidad = "android.permission.BIND_ACCESSIBILITY_SERVICE"
    private val permisoAdministrador = "android.permission.BIND_DEVICE_ADMIN"
    private val hiloSecundario = Executors.newSingleThreadExecutor()
    private val hiloPrincipal = Handler(Looper.getMainLooper())
    private var canal: MethodChannel? = null
    private var contexto: Context? = null
    private var actividad: Activity? = null
    private var enlace: ActivityPluginBinding? = null
    private var resultadoPendiente: MethodChannel.Result? = null

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
        when (llamada.method) {
            "elegirApk" -> abrirSelector(resultado)
            else -> resultado.notImplemented()
        }
    }

    @Suppress("DEPRECATION")
    private fun abrirSelector(resultado: MethodChannel.Result) {
        val pantalla = actividad
        if (pantalla == null) {
            resultado.error("SIN_ACTIVIDAD", "No hay una pantalla activa.", null)
            return
        }
        if (resultadoPendiente != null) {
            resultado.error("OCUPADO", "Ya hay un archivo en selección.", null)
            return
        }

        resultadoPendiente = resultado
        val intento = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/vnd.android.package-archive", "application/octet-stream")
            )
        }
        pantalla.startActivityForResult(intento, codigoSelector)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != codigoSelector) return false

        val resultado = resultadoPendiente ?: return true
        resultadoPendiente = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            resultado.success(null)
            return true
        }

        hiloSecundario.execute {
            try {
                val informacion = analizarArchivo(uri)
                hiloPrincipal.post { resultado.success(informacion) }
            } catch (error: Exception) {
                hiloPrincipal.post { resultado.error("ERROR_APK", error.message, null) }
            }
        }
        return true
    }

    private fun analizarArchivo(uri: Uri): Map<String, Any?> {
        val contextoActual = contexto ?: throw IOException("No hay contexto disponible.")
        val temporal = File(contextoActual.cacheDir, "apk_analisis.apk")

        try {
            val huella = copiarYCalcularHuella(contextoActual, uri, temporal)
            val informacion = leerPaquete(contextoActual, temporal.absolutePath)
            return construirRespuesta(
                contextoActual,
                uri,
                huella,
                informacion,
                temporal.absolutePath
            )
        } finally {
            temporal.delete()
        }
    }

    private fun copiarYCalcularHuella(
        contexto: Context,
        uri: Uri,
        destino: File
    ): Pair<String, Long> {
        val resumen = MessageDigest.getInstance("SHA-256")
        var total = 0L
        val entrada = contexto.contentResolver.openInputStream(uri)
            ?: throw IOException("No se pudo abrir el archivo.")

        entrada.use { origen ->
            destino.outputStream().use { salida ->
                val almacen = ByteArray(65536)
                while (true) {
                    val leidos = origen.read(almacen)
                    if (leidos < 0) break
                    resumen.update(almacen, 0, leidos)
                    salida.write(almacen, 0, leidos)
                    total += leidos
                }
            }
        }
        return Pair(aHexadecimal(resumen.digest()), total)
    }

    private fun banderaFirmas(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_SIGNATURES
        }

    @Suppress("DEPRECATION")
    private fun leerPaquete(contexto: Context, ruta: String): PackageInfo? {
        val banderas = PackageManager.GET_PERMISSIONS or
            PackageManager.GET_SERVICES or
            PackageManager.GET_RECEIVERS or
            banderaFirmas()
        val gestor = contexto.packageManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            gestor.getPackageArchiveInfo(ruta, PackageManager.PackageInfoFlags.of(banderas.toLong()))
        } else {
            gestor.getPackageArchiveInfo(ruta, banderas)
        }
    }

    @Suppress("DEPRECATION")
    private fun obtenerInstalada(gestor: PackageManager, paquete: String): PackageInfo? = try {
        gestor.getPackageInfo(paquete, banderaFirmas())
    } catch (error: PackageManager.NameNotFoundException) {
        null
    }

    @Suppress("DEPRECATION")
    private fun obtenerFirma(informacion: PackageInfo): String? {
        val firmas = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            informacion.signingInfo?.apkContentsSigners
        } else {
            informacion.signatures
        }
        val primera = firmas?.firstOrNull() ?: return null
        return aHexadecimal(MessageDigest.getInstance("SHA-256").digest(primera.toByteArray()))
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

    private fun obtenerNombreArchivo(contexto: Context, uri: Uri): String {
        val nombre = contexto.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
        return nombre ?: "archivo.apk"
    }

    private fun construirRespuesta(
        contexto: Context,
        uri: Uri,
        huella: Pair<String, Long>,
        informacion: PackageInfo?,
        ruta: String
    ): Map<String, Any?> {
        val gestor = contexto.packageManager
        val instalada = informacion?.let { obtenerInstalada(gestor, it.packageName) }

        return mapOf(
            "nombreArchivo" to obtenerNombreArchivo(contexto, uri),
            "tamano" to huella.second,
            "sha256" to huella.first,
            "esApk" to (informacion != null),
            "paquete" to informacion?.packageName,
            "nombreApp" to informacion?.let { obtenerNombreApp(gestor, it, ruta) },
            "version" to informacion?.versionName,
            "permisos" to (informacion?.requestedPermissions?.toList() ?: emptyList()),
            "usaAccesibilidad" to
                (informacion?.services?.any { it.permission == permisoAccesibilidad } == true),
            "esAdministrador" to
                (informacion?.receivers?.any { it.permission == permisoAdministrador } == true),
            "firma" to informacion?.let { obtenerFirma(it) },
            "instalada" to (instalada != null),
            "firmaInstalada" to instalada?.let { obtenerFirma(it) }
        )
    }

    private fun aHexadecimal(bytes: ByteArray): String =
        bytes.joinToString("") { "%02x".format(it) }
}