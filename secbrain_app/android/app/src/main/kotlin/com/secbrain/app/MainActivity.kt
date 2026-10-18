package com.secbrain.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.secbrain.app/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    val todoTitle = call.argument<String>("todoTitle") ?: ""
                    val todoCount = call.argument<String>("todoCount") ?: ""
                    val todoSubtitle = call.argument<String>("todoSubtitle") ?: ""

                    val prefs = getSharedPreferences(SecBrainWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("flutter.widget_todo_title", todoTitle)
                        .putString("flutter.widget_todo_count", todoCount)
                        .putString("flutter.widget_todo_subtitle", todoSubtitle)
                        .apply()

                    // Broadcast to Widget Provider
                    val appWidgetManager = AppWidgetManager.getInstance(this)
                    val thisWidget = ComponentName(this, SecBrainWidgetProvider::class.java)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
                    for (appWidgetId in appWidgetIds) {
                        SecBrainWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
                    }

                    result.success(true)
                }
                "getLaunchIntentAction" -> {
                    val action = intent?.action ?: ""
                    result.success(action)
                }
                else -> result.notImplemented()
            }
        }
    }
}
