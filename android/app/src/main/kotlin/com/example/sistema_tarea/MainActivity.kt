package com.example.sistema_tarea

import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val nombreCanal = "antivirus/aplicaciones"
    private val permisoAccesibilidad = "android.permission.BIND_ACCESSIBILITY_SERVICE"
    private val permisoAdministrador = "android.permission.BIND_DEVICE_ADMIN"
    private val hiloSecundario = Executors.newSingleThreadExecutor()
    private val hiloPrincipal = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, nombreCanal)
            .setMethodCallHandler { llamada, resultado ->
                when (llamada.method) {
                    "obtenerAplicaciones" -> hiloSecundario.execute {
                        try {
                            val aplicaciones = obtenerAplicaciones()
                            hiloPrincipal.post { resultado.success(aplicaciones) }
                        } catch (error: Exception) {
                            hiloPrincipal.post {
                                resultado.error("ERROR_ANALISIS", error.message, null)
                            }
                        }
                    }
                    else -> resultado.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun obtenerAplicaciones(): List<Map<String, Any?>> {
        val banderas = PackageManager.GET_PERMISSIONS or
            PackageManager.GET_SERVICES or
            PackageManager.GET_RECEIVERS
        val paquetes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getInstalledPackages(
                PackageManager.PackageInfoFlags.of(banderas.toLong())
            )
        } else {
            packageManager.getInstalledPackages(banderas)
        }
        return paquetes.map { convertirPaquete(it) }
    }

    private fun convertirPaquete(informacion: PackageInfo): Map<String, Any?> {
        val aplicacion = informacion.applicationInfo
        val esSistema = aplicacion != null &&
            (aplicacion.flags and
                (ApplicationInfo.FLAG_SYSTEM or ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0
        val nombre = aplicacion?.let { packageManager.getApplicationLabel(it).toString() }
            ?: informacion.packageName

        return mapOf(
            "nombre" to nombre,
            "paquete" to informacion.packageName,
            "esSistema" to esSistema,
            "origen" to obtenerOrigenInstalacion(informacion.packageName),
            "permisos" to (informacion.requestedPermissions?.toList() ?: emptyList()),
            "tieneIcono" to (packageManager.getLaunchIntentForPackage(informacion.packageName) != null),
            "usaAccesibilidad" to
                (informacion.services?.any { it.permission == permisoAccesibilidad } == true),
            "esAdministrador" to
                (informacion.receivers?.any { it.permission == permisoAdministrador } == true)
        )
    }

    @Suppress("DEPRECATION")
    private fun obtenerOrigenInstalacion(paquete: String): String? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            packageManager.getInstallSourceInfo(paquete).installingPackageName
        } else {
            packageManager.getInstallerPackageName(paquete)
        }
    } catch (error: Exception) {
        null
    }
}