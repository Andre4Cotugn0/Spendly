package com.andre4cotugn0.moneyra

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class StatisticsWidget : HomeWidgetProvider() {
	override fun onUpdate(
		context: Context,
		appWidgetManager: AppWidgetManager,
		appWidgetIds: IntArray,
		widgetData: SharedPreferences
	) {
		for (appWidgetId in appWidgetIds) {
			val views = RemoteViews(context.packageName, R.layout.statistics_widget)
			val monthLabel = widgetData.getString("monthLabel", "Statistiche") ?: "Statistiche"
			val monthTotal = widgetData.getString("monthTotal", "€0,00") ?: "€0,00"
			val avgDaily = widgetData.getString("avgDaily", null)
			val topCategory = widgetData.getString("topCategory", null)

			val summary = when {
				topCategory != null -> topCategory
				avgDaily != null -> "Totale $monthTotal • Media $avgDaily"
				else -> "Totale $monthTotal"
			}

			views.setTextViewText(R.id.statistics_widget_title, monthLabel)
			views.setTextViewText(R.id.statistics_widget_summary, summary)

			appWidgetManager.updateAppWidget(appWidgetId, views)
		}
	}
}
