package com.example.sistema_tarea

import android.Manifest
import android.app.KeyguardManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val canalAplicaciones = "antivirus/aplicaciones"
    private val canalDispositivo = "antivirus/dispositivo"
    private val canalWifi = "antivirus/wifi"
    private val codigoPermisoUbicacion = 4101
    private val permisoAccesibilidad = "android.permission.BIND_ACCESSIBILITY_SERVICE"
    private val permisoAdministrador = "android.permission.BIND_DEVICE_ADMIN"
    private val rutasSu = listOf(
        "/system/bin/su",
        "/system/xbin/su",
        "/sbin/su",
        "/system/app/Superuser.apk",
        "/data/local/bin/su",
        "/data/local/xbin/su"
    )
    private val hiloSecundario = Executors.newSingleThreadExecutor()
    private val hiloPrincipal = Handler(Looper.getMainLooper())
    private val escanerWifi by lazy { EscanerWifi(this) }
    private var resultadoPermiso: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registrarCanalAplicaciones(flutterEngine)
        registrarCanalDispositivo(flutterEngine)
        registrarCanalWifi(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != codigoPermisoUbicacion) return

        val concedido = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        resultadoPermiso?.success(concedido)
        resultadoPermiso = null
    }

    private fun registrarCanalAplicaciones(motor: FlutterEngine) {
        MethodChannel(motor.dartExecutor.binaryMessenger, canalAplicaciones)
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

    private fun registrarCanalDispositivo(motor: FlutterEngine) {
        MethodChannel(motor.dartExecutor.binaryMessenger, canalDispositivo)
            .setMethodCallHandler { llamada, resultado ->
                when (llamada.method) {
                    "obtenerEstadoDispositivo" -> try {
                        resultado.success(obtenerEstadoDispositivo())
                    } catch (error: Exception) {
                        resultado.error("ERROR_DISPOSITIVO", error.message, null)
                    }
                    else -> resultado.notImplemented()
                }
            }
    }

    private fun registrarCanalWifi(motor: FlutterEngine) {
        MethodChannel(motor.dartExecutor.binaryMessenger, canalWifi)
            .setMethodCallHandler { llamada, resultado ->
                when (llamada.method) {
                    "solicitarPermisoUbicacion" -> solicitarPermisoUbicacion(resultado)
                    "escanearRedes" -> escanearRedes(resultado)
                    else -> resultado.notImplemented()
                }
            }
    }

    private fun tienePermisoUbicacion(): Boolean =
        ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

    private fun solicitarPermisoUbicacion(resultado: MethodChannel.Result) {
        if (tienePermisoUbicacion()) {
            resultado.success(true)
            return
        }
        if (resultadoPermiso != null) {
            resultado.success(false)
            return
        }
        resultadoPermiso = resultado
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
            codigoPermisoUbicacion
        )
    }

    private fun escanearRedes(resultado: MethodChannel.Result) {
        if (!tienePermisoUbicacion()) {
            resultado.error("SIN_PERMISO", "Falta el permiso de ubicación.", null)
            return
        }
        escanerWifi.escanear { respuesta -> resultado.success(respuesta) }
    }

    private fun obtenerEstadoDispositivo(): Map<String, Any?> {
        return mapOf(
            "versionAndroid" to Build.VERSION.RELEASE,
            "parcheSeguridad" to obtenerParcheSeguridad(),
            "bloqueoPantalla" to tieneBloqueoPantalla(),
            "depuracionUsb" to ajusteGlobalActivo(Settings.Global.ADB_ENABLED),
            "opcionesDesarrollador" to
                ajusteGlobalActivo(Settings.Global.DEVELOPMENT_SETTINGS_ENABLED),
            "dispositivoRoot" to detectarRoot()
        )
    }

    private fun obtenerParcheSeguridad(): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Build.VERSION.SECURITY_PATCH
        } else {
            null
        }

    private fun tieneBloqueoPantalla(): Boolean {
        val gestor = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            gestor.isDeviceSecure
        } else {
            gestor.isKeyguardSecure
        }
    }

    private fun ajusteGlobalActivo(nombre: String): Boolean =
        Settings.Global.getInt(contentResolver, nombre, 0) == 1

    private fun detectarRoot(): Boolean = rutasSu.any { File(it).exists() }

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