package com.secbrain.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class SecBrainWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            intent.action == ACTION_UPDATE_WIDGET
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, SecBrainWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    companion object {
        const val ACTION_UPDATE_WIDGET = "com.secbrain.app.UPDATE_WIDGET"
        const val PREFS_NAME = "FlutterSharedPreferences"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // Read dynamic widget data synced from Flutter
            val todoTitle = prefs.getString("flutter.widget_todo_title", null)
                ?: "Review materi & target hari ini"
            val todoCount = prefs.getString("flutter.widget_todo_count", null)
                ?: "Target Hari Ini Aktif"
            val todoSubtitle = prefs.getString("flutter.widget_todo_subtitle", null)
                ?: "Fokus target aktif • Tap untuk buka"

            val dateFormat = SimpleDateFormat("EEE, d MMM", Locale("id", "ID"))
            val currentDate = dateFormat.format(Date())

            val views = RemoteViews(context.packageName, R.layout.secbrain_widget_layout)

            views.setTextViewText(R.id.widget_date, currentDate)
            views.setTextViewText(R.id.widget_todo_count, todoCount)
            views.setTextViewText(R.id.widget_todo_title, todoTitle)
            views.setTextViewText(R.id.widget_todo_subtitle, todoSubtitle)

            // Intent to open Main App
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_item_container, openAppPendingIntent)

            // Intent to open Quick Add in App
            val quickAddIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                action = "com.secbrain.app.ACTION_QUICK_ADD"
            }
            val quickAddPendingIntent = PendingIntent.getActivity(
                context,
                1,
                quickAddIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_add, quickAddPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
