package com.example.sistema_tarea

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.concurrent.Executors

class ServicioVigilancia : JobService() {
    companion object {
        private const val IDENTIFICADOR_TRABAJO = 7301
        private const val IDENTIFICADOR_NOTIFICACION = 7302
        private const val IDENTIFICADOR_CANAL = "instalaciones"
        private const val INTERVALO_MS = 15 * 60 * 1000L

        fun programar(contexto: Context) {
            val planificador =
                contexto.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
            val trabajo = JobInfo.Builder(
                IDENTIFICADOR_TRABAJO,
                ComponentName(contexto, ServicioVigilancia::class.java)
            )
                .setPeriodic(INTERVALO_MS)
                .setPersisted(true)
                .build()
            planificador.schedule(trabajo)
        }

        fun cancelar(contexto: Context) {
            val planificador =
                contexto.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
            planificador.cancel(IDENTIFICADOR_TRABAJO)
        }
    }

    private val hilo = Executors.newSingleThreadExecutor()

    override fun onStartJob(parametros: JobParameters): Boolean {
        hilo.execute {
            try {
                revisar()
            } finally {
                jobFinished(parametros, false)
            }
        }
        return true
    }

    override fun onStopJob(parametros: JobParameters): Boolean = false

    private fun revisar() {
        val repositorio = RepositorioVigilancia(this)
        if (!repositorio.activa) {
            cancelar(this)
            return
        }

        val nuevas = DetectorInstalaciones(this, repositorio).detectarNuevas()
        if (nuevas.isNotEmpty()) notificar(nuevas.values.toList())
    }

    private fun notificar(nombres: List<String>) {
        val gestor = NotificationManagerCompat.from(this)
        if (!gestor.areNotificationsEnabled()) return

        crearCanal()
        val titulo = if (nombres.size == 1) {
            "Nueva app instalada"
        } else {
            "${nombres.size} apps nuevas instaladas"
        }
        val intento = packageManager.getLaunchIntentForPackage(packageName)
        val accion = intento?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        }

        val notificacion = NotificationCompat.Builder(this, IDENTIFICADOR_CANAL)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle(titulo)
            .setContentText("${resumirNombres(nombres)} · Toca para revisar")
            .setContentIntent(accion)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        runCatching { gestor.notify(IDENTIFICADOR_NOTIFICACION, notificacion) }
    }

    private fun resumirNombres(nombres: List<String>): String {
        val visibles = nombres.take(2).joinToString(", ")
        val resto = if (nombres.size > 2) " y ${nombres.size - 2} más" else ""
        return visibles + resto
    }

    private fun crearCanal() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val canal = NotificationChannel(
            IDENTIFICADOR_CANAL,
            "Instalaciones nuevas",
            NotificationManager.IMPORTANCE_DEFAULT
        )
        canal.description = "Avisa cuando se instala una app nueva para que la revises"
        getSystemService(NotificationManager::class.java).createNotificationChannel(canal)
    }
}