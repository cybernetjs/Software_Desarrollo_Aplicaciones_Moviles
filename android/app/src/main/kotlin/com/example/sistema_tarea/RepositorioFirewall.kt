package com.example.sistema_tarea

import android.content.Context

class RepositorioFirewall(contexto: Context) {
    private val claveActivo = "activo"
    private val claveBloqueadas = "bloqueadas"
    private val preferencias =
        contexto.applicationContext.getSharedPreferences("firewall", Context.MODE_PRIVATE)

    var activo: Boolean
        get() = preferencias.getBoolean(claveActivo, false)
        set(valor) = preferencias.edit().putBoolean(claveActivo, valor).apply()

    var bloqueadas: Set<String>
        get() = preferencias.getStringSet(claveBloqueadas, emptySet())?.toSet() ?: emptySet()
        set(valor) = preferencias.edit().putStringSet(claveBloqueadas, valor).apply()
}