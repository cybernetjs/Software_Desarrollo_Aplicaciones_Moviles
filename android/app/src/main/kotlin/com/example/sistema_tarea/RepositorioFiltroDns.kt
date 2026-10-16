package com.example.sistema_tarea

import android.content.Context

class RepositorioFiltroDns(contexto: Context) {
    private val preferencias =
        contexto.applicationContext.getSharedPreferences("filtro_dns", Context.MODE_PRIVATE)

    var activo: Boolean
        get() = preferencias.getBoolean("activo", false)
        set(valor) = preferencias.edit().putBoolean("activo", valor).apply()

    var dominios: Set<String>
        get() = preferencias.getStringSet("dominios", emptySet())?.toSet() ?: emptySet()
        set(valor) = preferencias.edit().putStringSet("dominios", valor.toSet()).apply()
}