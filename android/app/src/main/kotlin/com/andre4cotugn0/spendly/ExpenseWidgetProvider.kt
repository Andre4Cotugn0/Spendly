package com.andre4cotugn0.spendly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ExpenseWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.expense_widget).apply {
                // Leggi i dati salvati da Flutter
                val total = widgetData.getString("total", "€ 0,00")
                val month = widgetData.getString("month", "")
                
                setTextViewText(R.id.widget_total, total)
                setTextViewText(R.id.widget_month, month)
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
