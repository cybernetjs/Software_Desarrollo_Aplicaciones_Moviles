package com.example.sistema_tarea

import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import java.security.MessageDigest

object HuellasFirma {
    fun bandera(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_SIGNATURES
        }

    @Suppress("DEPRECATION")
    fun calcular(informacion: PackageInfo): Pair<List<String>, List<String>> {
        val firmas = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val datos = informacion.signingInfo
            when {
                datos == null -> null
                datos.hasMultipleSigners() -> datos.apkContentsSigners
                else -> datos.signingCertificateHistory
            }
        } else {
            informacion.signatures
        }

        val certificados = firmas?.map { it.toByteArray() } ?: emptyList()
        return Pair(
            certificados.map { resumir("SHA-1", it) },
            certificados.map { resumir("SHA-256", it) }
        )
    }

    private fun resumir(algoritmo: String, bytes: ByteArray): String =
        MessageDigest.getInstance(algoritmo)
            .digest(bytes)
            .joinToString("") { "%02x".format(it) }
}