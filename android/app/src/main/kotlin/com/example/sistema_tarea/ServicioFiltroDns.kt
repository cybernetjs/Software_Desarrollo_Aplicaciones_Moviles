package com.example.sistema_tarea

import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.Process
import android.system.OsConstants
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.Inet4Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

class ServicioFiltroDns : VpnService() {
    companion object {
        const val ACCION_INICIAR = "com.example.sistema_tarea.dns.INICIAR"
        const val ACCION_DETENER = "com.example.sistema_tarea.dns.DETENER"
        const val DESCONOCIDA = "desconocida"
        private const val DIRECCION_TUNEL = "10.255.1.1"
        private const val SERVIDOR_FALSO = "10.255.1.2"
        private const val DNS_RESPALDO = "1.1.1.1"
        private const val VIGENCIA_SERVIDOR_MS = 30_000L

        @Volatile
        var enEjecucion = false
    }

    private class PaqueteDns(
        val ipOrigen: ByteArray,
        val ipDestino: ByteArray,
        val puertoOrigen: Int,
        val dns: ByteArray
    )

    private val repositorio by lazy { RepositorioFiltroDns(this) }
    private var tunel: ParcelFileDescriptor? = null
    private var hiloLectura: Thread? = null
    private var grupo: ExecutorService? = null
    private var servidorReal: InetAddress? = null
    private var consultaServidorMs = 0L

    @Volatile
    private var bloqueados: Set<String> = emptySet()

    override fun onCreate() {
        super.onCreate()
        enEjecucion = true
    }

    override fun onStartCommand(intento: Intent?, banderas: Int, idInicio: Int): Int {
        if (intento?.action == ACCION_DETENER || !repositorio.activo) {
            detener()
            return START_NOT_STICKY
        }
        iniciar()
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

    private fun iniciar() {
        cerrarTunel()
        bloqueados = repositorio.dominios.map { it.lowercase() }.toSet()

        val constructor = Builder()
            .setSession("Filtro DNS")
            .setMtu(1500)
            .addAddress(DIRECCION_TUNEL, 32)
            .addDnsServer(SERVIDOR_FALSO)
            .addRoute(SERVIDOR_FALSO, 32)
        runCatching { constructor.addDisallowedApplication(packageName) }

        val descriptor = constructor.establish() ?: return
        tunel = descriptor
        grupo = Executors.newFixedThreadPool(8)
        iniciarLectura(descriptor)
    }

    private fun iniciarLectura(descriptor: ParcelFileDescriptor) {
        val ejecutor = grupo ?: return
        val entrada = FileInputStream(descriptor.fileDescriptor)
        val salida = FileOutputStream(descriptor.fileDescriptor)

        hiloLectura = Thread {
            val almacen = ByteArray(32767)
            try {
                while (true) {
                    val leidos = entrada.read(almacen)
                    if (leidos < 0) break
                    val paquete = interpretar(almacen, leidos) ?: continue
                    ejecutor.execute { procesarConsulta(paquete, salida) }
                }
            } catch (error: IOException) {
            } catch (error: RejectedExecutionException) {
            }
        }.also { it.start() }
    }

    private fun cerrarTunel() {
        runCatching { tunel?.close() }
        tunel = null
        hiloLectura?.interrupt()
        hiloLectura = null
        grupo?.shutdownNow()
        grupo = null
    }

    private fun detener() {
        cerrarTunel()
        stopSelf()
    }

    private fun interpretar(buffer: ByteArray, longitud: Int): PaqueteDns? {
        if (longitud < 28) return null
        if ((buffer[0].toInt() shr 4) != 4) return null

        val longitudCabecera = (buffer[0].toInt() and 0x0F) * 4
        if (buffer[9].toInt() != 17 || longitud < longitudCabecera + 8) return null
        if (leer16(buffer, longitudCabecera + 2) != 53) return null

        val inicioDns = longitudCabecera + 8
        val finDns = minOf(longitud, longitudCabecera + leer16(buffer, longitudCabecera + 4))
        if (finDns - inicioDns < 12) return null

        return PaqueteDns(
            ipOrigen = buffer.copyOfRange(12, 16),
            ipDestino = buffer.copyOfRange(16, 20),
            puertoOrigen = leer16(buffer, longitudCabecera),
            dns = buffer.copyOfRange(inicioDns, finDns)
        )
    }

    private fun procesarConsulta(paquete: PaqueteDns, salida: FileOutputStream) {
        val pregunta = leerPregunta(paquete.dns)
        val dominio = pregunta?.first ?: "(ilegible)"
        val bloqueado = pregunta != null && estaBloqueado(dominio)
        RegistroDns.anotar(identificarAplicacion(paquete), dominio, bloqueado)

        val respuesta = if (bloqueado && pregunta != null) {
            construirBloqueo(paquete.dns, pregunta.second)
        } else {
            reenviar(paquete.dns)
        }
        if (respuesta == null) return

        val bytes = construirPaquete(paquete, respuesta)
        synchronized(salida) {
            try {
                salida.write(bytes)
            } catch (error: IOException) {
            }
        }
    }

    private fun leerPregunta(dns: ByteArray): Pair<String, Int>? {
        val partes = ArrayList<String>()
        var posicion = 12

        while (posicion < dns.size) {
            val longitud = dns[posicion].toInt() and 0xFF
            if (longitud == 0) {
                val fin = posicion + 1 + 4
                if (fin > dns.size) return null
                return Pair(partes.joinToString("."), fin)
            }
            if ((longitud and 0xC0) != 0) return null
            posicion += 1
            if (posicion + longitud > dns.size) return null
            partes.add(String(dns, posicion, longitud, Charsets.US_ASCII))
            posicion += longitud
        }
        return null
    }

    private fun estaBloqueado(nombre: String): Boolean {
        val lista = bloqueados
        if (lista.isEmpty()) return false

        var candidato = nombre.lowercase()
        while (true) {
            if (candidato in lista) return true
            val punto = candidato.indexOf('.')
            if (punto < 0) return false
            candidato = candidato.substring(punto + 1)
        }
    }

    private fun identificarAplicacion(paquete: PaqueteDns): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return DESCONOCIDA

        return try {
            val gestor = getSystemService(ConnectivityManager::class.java)
            val origen = InetSocketAddress(
                InetAddress.getByAddress(paquete.ipOrigen),
                paquete.puertoOrigen
            )
            val destino = InetSocketAddress(InetAddress.getByAddress(paquete.ipDestino), 53)
            val uid = gestor.getConnectionOwnerUid(OsConstants.IPPROTO_UDP, origen, destino)

            if (uid == Process.INVALID_UID) {
                DESCONOCIDA
            } else {
                packageManager.getPackagesForUid(uid)?.firstOrNull() ?: DESCONOCIDA
            }
        } catch (error: Exception) {
            DESCONOCIDA
        }
    }

    private fun reenviar(consulta: ByteArray): ByteArray? {
        var socket: DatagramSocket? = null
        return try {
            socket = DatagramSocket()
            protect(socket)
            socket.soTimeout = 4000
            socket.send(DatagramPacket(consulta, consulta.size, servidorDns(), 53))

            val almacen = ByteArray(4096)
            val respuesta = DatagramPacket(almacen, almacen.size)
            socket.receive(respuesta)
            almacen.copyOf(respuesta.length)
        } catch (error: IOException) {
            null
        } finally {
            socket?.close()
        }
    }

    @Synchronized
    private fun servidorDns(): InetAddress {
        val ahora = System.currentTimeMillis()
        val actual = servidorReal
        if (actual != null && ahora - consultaServidorMs < VIGENCIA_SERVIDOR_MS) return actual

        val nuevo = buscarServidorDelSistema() ?: InetAddress.getByName(DNS_RESPALDO)
        servidorReal = nuevo
        consultaServidorMs = ahora
        return nuevo
    }

    @Suppress("DEPRECATION")
    private fun buscarServidorDelSistema(): InetAddress? {
        val gestor = getSystemService(ConnectivityManager::class.java) ?: return null

        for (red in gestor.allNetworks) {
            val capacidades = gestor.getNetworkCapabilities(red) ?: continue
            if (capacidades.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) continue
            if (!capacidades.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) continue

            val servidor = gestor.getLinkProperties(red)
                ?.dnsServers
                ?.firstOrNull { it is Inet4Address }
            if (servidor != null) return servidor
        }
        return null
    }

    private fun construirBloqueo(consulta: ByteArray, finPregunta: Int): ByteArray {
        val respuesta = consulta.copyOfRange(0, finPregunta)
        val banderasConsulta = leer16(consulta, 2)
        val banderas = 0x8000 or (banderasConsulta and 0x0100) or 0x0080 or 0x0003

        escribir16(respuesta, 2, banderas)
        for (indice in 6..11) respuesta[indice] = 0
        return respuesta
    }

    private fun construirPaquete(original: PaqueteDns, cargaDns: ByteArray): ByteArray {
        val longitudTotal = 20 + 8 + cargaDns.size
        val salida = ByteArray(longitudTotal)

        salida[0] = 0x45
        escribir16(salida, 2, longitudTotal)
        salida[6] = 0x40
        salida[8] = 64
        salida[9] = 17
        original.ipDestino.copyInto(salida, 12)
        original.ipOrigen.copyInto(salida, 16)
        escribir16(salida, 10, sumaVerificacion(salida, 0, 20))

        escribir16(salida, 20, 53)
        escribir16(salida, 22, original.puertoOrigen)
        escribir16(salida, 24, 8 + cargaDns.size)
        cargaDns.copyInto(salida, 28)
        return salida
    }

    private fun sumaVerificacion(datos: ByteArray, desde: Int, longitud: Int): Int {
        var suma = 0
        var indice = desde
        while (indice < desde + longitud) {
            suma += leer16(datos, indice)
            indice += 2
        }
        while ((suma shr 16) != 0) {
            suma = (suma and 0xFFFF) + (suma shr 16)
        }
        return suma.inv() and 0xFFFF
    }

    private fun leer16(datos: ByteArray, posicion: Int): Int =
        ((datos[posicion].toInt() and 0xFF) shl 8) or (datos[posicion + 1].toInt() and 0xFF)

    private fun escribir16(datos: ByteArray, posicion: Int, valor: Int) {
        datos[posicion] = (valor shr 8).toByte()
        datos[posicion + 1] = valor.toByte()
    }
}