package com.andre4cotugn0.moneyra

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
		for (appWidgetId in appWidgetIds) {
			val views = RemoteViews(context.packageName, R.layout.expense_widget)
			val month = widgetData.getString("month", "Moneyra") ?: "Moneyra"
			val total = widgetData.getString("total", "€0,00") ?: "€0,00"

			views.setTextViewText(R.id.expense_widget_title, month)
			views.setTextViewText(R.id.expense_widget_total, total)

			appWidgetManager.updateAppWidget(appWidgetId, views)
		}
	}
}
