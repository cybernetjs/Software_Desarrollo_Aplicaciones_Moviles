package com.example.sistema_tarea

import android.content.Context

class RepositorioVigilancia(contexto: Context) {
    private val separador = "::"
    private val preferencias =
        contexto.applicationContext.getSharedPreferences("vigilancia", Context.MODE_PRIVATE)

    var activa: Boolean
        get() = preferencias.getBoolean("activa", false)
        set(valor) = preferencias.edit().putBoolean("activa", valor).apply()

    var inicializada: Boolean
        get() = preferencias.getBoolean("inicializada", false)
        set(valor) = preferencias.edit().putBoolean("inicializada", valor).apply()

    var conocidas: Set<String>
        get() = preferencias.getStringSet("conocidas", emptySet())?.toSet() ?: emptySet()
        set(valor) = preferencias.edit().putStringSet("conocidas", valor.toSet()).apply()

    val pendientes: Map<String, String>
        get() = (preferencias.getStringSet("pendientes", emptySet()) ?: emptySet())
            .associate { entrada ->
                entrada.substringBefore(separador) to entrada.substringAfter(separador)
            }

    fun agregarPendientes(nuevas: Map<String, String>) {
        guardarPendientes(pendientes + nuevas)
    }

    fun podarPendientes(instaladas: Set<String>) {
        val vigentes = pendientes.filterKeys { it in instaladas }
        if (vigentes.size != pendientes.size) guardarPendientes(vigentes)
    }

    fun limpiarPendientes() {
        preferencias.edit().remove("pendientes").apply()
    }

    fun reiniciar() {
        preferencias.edit().clear().apply()
    }

    private fun guardarPendientes(valores: Map<String, String>) {
        val entradas = valores.map { "${it.key}$separador${it.value}" }.toSet()
        preferencias.edit().putStringSet("pendientes", entradas).apply()
    }
}