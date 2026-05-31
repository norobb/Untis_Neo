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

                val nextSubject2 = widgetData.getString("widget_next_subject2", "") ?: ""
                val nextTime2 = widgetData.getString("widget_next_time2", "") ?: ""
                val nextRoom2 = widgetData.getString("widget_next_room2", "") ?: ""
                val nextSubject3 = widgetData.getString("widget_next_subject3", "") ?: ""
                val nextTime3 = widgetData.getString("widget_next_time3", "") ?: ""
                val nextRoom3 = widgetData.getString("widget_next_room3", "") ?: ""

                setTextViewText(R.id.widget_subject, nextSubject)
                setTextViewText(R.id.widget_time, nextTime)
                if (nextRoom.isNotEmpty()) setTextViewText(R.id.widget_room, "Raum: $nextRoom") else setTextViewText(R.id.widget_room, "")
                
                setTextViewText(R.id.widget_subject2, nextSubject2)
                setTextViewText(R.id.widget_time2, nextTime2)
                if (nextRoom2.isNotEmpty()) setTextViewText(R.id.widget_room2, "Raum: $nextRoom2") else setTextViewText(R.id.widget_room2, "")
                
                setTextViewText(R.id.widget_subject3, nextSubject3)
                setTextViewText(R.id.widget_time3, nextTime3)
                if (nextRoom3.isNotEmpty()) setTextViewText(R.id.widget_room3, "Raum: $nextRoom3") else setTextViewText(R.id.widget_room3, "")

                val bgColorStr = widgetData.getString("widget_bg_color", "#E5E5E5") ?: "#E5E5E5"
                val textColorStr = widgetData.getString("widget_text_color", "#000000") ?: "#000000"
                val secTextColorStr = widgetData.getString("widget_sec_text_color", "#555555") ?: "#555555"

                try {
                    val bgColor = android.graphics.Color.parseColor(bgColorStr)
                    setInt(R.id.widget_container, "setBackgroundColor", bgColor)
                } catch (e: Exception) {}

                try {
                    val textColor = android.graphics.Color.parseColor(textColorStr)
                    val secTextColor = android.graphics.Color.parseColor(secTextColorStr)
                    
                    setTextColor(R.id.widget_subject, textColor)
                    setTextColor(R.id.widget_title, secTextColor)
                    setTextColor(R.id.widget_time, textColor)
                    setTextColor(R.id.widget_room, secTextColor)

                    setTextColor(R.id.widget_subject2, textColor)
                    setTextColor(R.id.widget_time2, textColor)
                    setTextColor(R.id.widget_room2, secTextColor)

                    setTextColor(R.id.widget_subject3, textColor)
                    setTextColor(R.id.widget_time3, textColor)
                    setTextColor(R.id.widget_room3, secTextColor)
                } catch (e: Exception) {}
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
