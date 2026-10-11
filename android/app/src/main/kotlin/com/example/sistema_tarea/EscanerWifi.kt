package com.example.sistema_tarea

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.LocationManager
import android.net.wifi.ScanResult
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import androidx.core.location.LocationManagerCompat

class EscanerWifi(contexto: Context) {
    private val contextoApp = contexto.applicationContext
    private val gestorWifi = contextoApp.getSystemService(Context.WIFI_SERVICE) as WifiManager
    private val hiloPrincipal = Handler(Looper.getMainLooper())
    private val tiempoEsperaMs = 4000L
    private val nombreDesconocido = "<unknown ssid>"

    @Suppress("DEPRECATION")
    fun escanear(alTerminar: (Map<String, Any?>) -> Unit) {
        if (!gestorWifi.isWifiEnabled) {
            alTerminar(construirRespuesta())
            return
        }

        var terminado = false
        lateinit var receptor: BroadcastReceiver

        fun finalizar() {
            if (terminado) return
            terminado = true
            runCatching { contextoApp.unregisterReceiver(receptor) }
            alTerminar(construirRespuesta())
        }

        receptor = object : BroadcastReceiver() {
            override fun onReceive(contexto: Context?, intento: Intent?) {
                finalizar()
            }
        }

        contextoApp.registerReceiver(
            receptor,
            IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
        )
        gestorWifi.startScan()
        hiloPrincipal.postDelayed({ finalizar() }, tiempoEsperaMs)
    }

    private fun ubicacionActiva(): Boolean {
        val gestor = contextoApp.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return LocationManagerCompat.isLocationEnabled(gestor)
    }

    @Suppress("DEPRECATION")
    private fun construirRespuesta(): Map<String, Any?> {
        val redes: List<ScanResult> = try {
            gestorWifi.scanResults ?: emptyList()
        } catch (error: SecurityException) {
            emptyList()
        }

        return mapOf(
            "wifiActivo" to gestorWifi.isWifiEnabled,
            "ubicacionActiva" to ubicacionActiva(),
            "conectada" to construirConexion(redes),
            "redes" to redes.map { convertirRed(it) }
        )
    }

    @Suppress("DEPRECATION")
    private fun construirConexion(redes: List<ScanResult>): Map<String, Any?>? {
        val informacion = gestorWifi.connectionInfo ?: return null
        if (informacion.networkId == -1) return null

        val coincidencia = redes.firstOrNull { it.BSSID == informacion.bssid }
        return mapOf(
            "nombre" to limpiarNombre(informacion.ssid),
            "senal" to informacion.rssi,
            "velocidadEnlace" to informacion.linkSpeed,
            "frecuencia" to informacion.frequency,
            "capacidades" to coincidencia?.capabilities
        )
    }

    private fun limpiarNombre(ssid: String?): String {
        val limpio = ssid?.removeSurrounding("\"").orEmpty()
        return if (limpio.isEmpty() || limpio == nombreDesconocido) "Red desconocida" else limpio
    }

    @Suppress("DEPRECATION")
    private fun convertirRed(resultado: ScanResult): Map<String, Any?> = mapOf(
        "nombre" to (resultado.SSID ?: ""),
        "bssid" to (resultado.BSSID ?: ""),
        "senal" to resultado.level,
        "frecuencia" to resultado.frequency,
        "capacidades" to (resultado.capabilities ?: "")
    )
}