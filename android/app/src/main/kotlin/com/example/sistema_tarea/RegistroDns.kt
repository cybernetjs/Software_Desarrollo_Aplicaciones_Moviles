package com.example.sistema_tarea

object RegistroDns {
    private const val MAXIMO_ENTRADAS = 3000

    private class Entrada(val paquete: String, val dominio: String) {
        var consultas = 0
        var bloqueadas = 0
        var ultimaMs = 0L
    }

    private val entradas = HashMap<String, Entrada>()
    private var totalConsultas = 0L
    private var totalBloqueadas = 0L

    @Synchronized
    fun anotar(paquete: String, dominio: String, bloqueada: Boolean) {
        val clave = "$paquete|$dominio"
        var entrada = entradas[clave]

        if (entrada == null) {
            if (entradas.size >= MAXIMO_ENTRADAS) eliminarMasAntigua()
            entrada = Entrada(paquete, dominio)
            entradas[clave] = entrada
        }

        entrada.consultas += 1
        if (bloqueada) entrada.bloqueadas += 1
        entrada.ultimaMs = System.currentTimeMillis()
        totalConsultas += 1
        if (bloqueada) totalBloqueadas += 1
    }

    @Synchronized
    fun instantanea(limite: Int, nombrePara: (String) -> String): Map<String, Any?> {
        val nombres = HashMap<String, String>()
        val lista = entradas.values
            .sortedByDescending { it.ultimaMs }
            .take(limite)
            .map { entrada ->
                mapOf(
                    "paquete" to entrada.paquete,
                    "nombre" to nombres.getOrPut(entrada.paquete) { nombrePara(entrada.paquete) },
                    "dominio" to entrada.dominio,
                    "consultas" to entrada.consultas,
                    "bloqueadas" to entrada.bloqueadas,
                    "ultimaMs" to entrada.ultimaMs
                )
            }

        return mapOf(
            "totalConsultas" to totalConsultas,
            "totalBloqueadas" to totalBloqueadas,
            "entradas" to lista
        )
    }

    @Synchronized
    fun limpiar() {
        entradas.clear()
        totalConsultas = 0
        totalBloqueadas = 0
    }

    private fun eliminarMasAntigua() {
        val masAntigua = entradas.entries.minByOrNull { it.value.ultimaMs } ?: return
        entradas.remove(masAntigua.key)
    }
}