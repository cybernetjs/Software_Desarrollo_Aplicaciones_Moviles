package com.example.sistema_tarea

import android.content.Context
import android.content.pm.ApplicationInfo

class DetectorInstalaciones(
    private val contexto: Context,
    private val repositorio: RepositorioVigilancia
) {
    companion object {
        private val cerrojo = Any()
    }

    fun detectarNuevas(): Map<String, String> = synchronized(cerrojo) {
        val actuales = obtenerInstaladasPorUsuario()
        val conocidas = repositorio.conocidas
        val nuevas = if (repositorio.inicializada) {
            actuales.filterKeys { it !in conocidas }
        } else {
            emptyMap()
        }

        repositorio.conocidas = actuales.keys
        repositorio.inicializada = true
        repositorio.podarPendientes(actuales.keys)
        if (nuevas.isNotEmpty()) repositorio.agregarPendientes(nuevas)
        nuevas
    }

    @Suppress("DEPRECATION")
    private fun obtenerInstaladasPorUsuario(): Map<String, String> {
        val gestor = contexto.packageManager
        val banderasSistema = ApplicationInfo.FLAG_SYSTEM or ApplicationInfo.FLAG_UPDATED_SYSTEM_APP

        return gestor.getInstalledApplications(0)
            .filter { (it.flags and banderasSistema) == 0 && it.packageName != contexto.packageName }
            .associate { it.packageName to gestor.getApplicationLabel(it).toString() }
    }
}