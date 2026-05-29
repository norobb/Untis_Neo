package com.ninocss.untisplus

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

class TimetableWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_timetable).apply {
                val nextSubject = widgetData.getString("widget_next_subject", "Frei") ?: "Frei"
                val nextTime = widgetData.getString("widget_next_time", "--:--") ?: "--:--"
                val nextRoom = widgetData.getString("widget_next_room", "") ?: ""

                setTextViewText(R.id.widget_subject, nextSubject)
                setTextViewText(R.id.widget_time, nextTime)
                
                if (nextRoom.isNotEmpty()) {
                    setTextViewText(R.id.widget_room, "Raum: $nextRoom")
                } else {
                    setTextViewText(R.id.widget_room, "")
                }
                val bgColorStr = widgetData.getString("widget_bg_color", "#E5E5E5") ?: "#E5E5E5"
                val textColorStr = widgetData.getString("widget_text_color", "#000000") ?: "#000000"
                val secTextColorStr = widgetData.getString("widget_sec_text_color", "#555555") ?: "#555555"

                try {
                    val bgColor = android.graphics.Color.parseColor(bgColorStr)
                    views.setInt(R.id.widget_container, "setBackgroundColor", bgColor)
                } catch (e: Exception) {}

                try {
                    val textColor = android.graphics.Color.parseColor(textColorStr)
                    val secTextColor = android.graphics.Color.parseColor(secTextColorStr)
                    
                    views.setTextColor(R.id.widget_subject, textColor)
                    views.setTextColor(R.id.widget_title, secTextColor)
                    views.setTextColor(R.id.widget_time, textColor)
                    views.setTextColor(R.id.widget_room, secTextColor)
                } catch (e: Exception) {}
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
