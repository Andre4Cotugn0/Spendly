package com.andre4cotugn0.moneyra

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class QuickExpenseWidget : HomeWidgetProvider() {
	override fun onUpdate(
		context: Context,
		appWidgetManager: AppWidgetManager,
		appWidgetIds: IntArray,
		widgetData: SharedPreferences
	) {
		for (appWidgetId in appWidgetIds) {
			val views = RemoteViews(context.packageName, R.layout.quick_expense_widget)
			val monthTotal = widgetData.getString("monthTotal", null)
			val lastAmount = widgetData.getString("lastAmount", null)

			val summary = when {
				lastAmount != null -> "Ultima spesa: €$lastAmount"
				monthTotal != null -> "Totale mese: $monthTotal"
				else -> "Apri Moneyra per aggiungere una spesa"
			}

			views.setTextViewText(R.id.quick_expense_widget_title, "Moneyra")
			views.setTextViewText(R.id.quick_expense_widget_hint, summary)

			appWidgetManager.updateAppWidget(appWidgetId, views)
		}
	}
}
