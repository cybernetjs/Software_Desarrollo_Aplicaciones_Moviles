package com.example.sistema_tarea

import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.ParcelFileDescriptor
import java.io.FileInputStream
import java.io.IOException

class ServicioFirewall : VpnService() {
    companion object {
        const val ACCION_INICIAR = "com.example.sistema_tarea.firewall.INICIAR"
        const val ACCION_DETENER = "com.example.sistema_tarea.firewall.DETENER"

        @Volatile
        var enEjecucion = false
    }

    private val repositorio by lazy { RepositorioFirewall(this) }
    private var tunel: ParcelFileDescriptor? = null
    private var hiloLectura: Thread? = null

    override fun onCreate() {
        super.onCreate()
        enEjecucion = true
    }

    override fun onStartCommand(intento: Intent?, banderas: Int, idInicio: Int): Int {
        if (intento?.action == ACCION_DETENER || !repositorio.activo) {
            detener()
            return START_NOT_STICKY
        }
        aplicarReglas()
        return START_STICKY
    }

    override fun onRevoke() {
        repositorio.activo = false
        cerrarTunel()
        super.onRevoke()
    }

    override fun onDestroy() {
        cerrarTunel()
        enEjecucion = false
        super.onDestroy()
    }

    private fun aplicarReglas() {
        val destinos = repositorio.bloqueadas.filter { it != packageName }
        cerrarTunel()
        if (destinos.isEmpty()) return

        val constructor = Builder()
            .setSession("Firewall")
            .setMtu(1500)
            .addAddress("10.255.0.1", 32)
            .addAddress("fd00:1:fd00:1:fd00:1:fd00:1", 128)
            .addRoute("0.0.0.0", 0)
            .addRoute("::", 0)

        val agregadas = destinos.count { agregarAplicacion(constructor, it) }
        if (agregadas == 0) return

        val descriptor = constructor.establish() ?: return
        tunel = descriptor
        descartarTrafico(descriptor)
    }

    private fun agregarAplicacion(constructor: VpnService.Builder, paquete: String): Boolean =
        try {
            constructor.addAllowedApplication(paquete)
            true
        } catch (error: PackageManager.NameNotFoundException) {
            false
        }

    private fun descartarTrafico(descriptor: ParcelFileDescriptor) {
        hiloLectura = Thread {
            val entrada = FileInputStream(descriptor.fileDescriptor)
            val almacen = ByteArray(32767)
            try {
                while (entrada.read(almacen) >= 0) {
                    Thread.yield()
                }
            } catch (error: IOException) {
                return@Thread
            }
        }.also { it.start() }
    }

    private fun cerrarTunel() {
        hiloLectura?.interrupt()
        hiloLectura = null
        runCatching { tunel?.close() }
        tunel = null
    }

    private fun detener() {
        cerrarTunel()
        stopSelf()
    }
}