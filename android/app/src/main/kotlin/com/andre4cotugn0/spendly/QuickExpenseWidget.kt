package com.andre4cotugn0.spendly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class QuickExpenseWidget : HomeWidgetProvider() {
	override fun onUpdate(
		context: Context,
		appWidgetManager: AppWidgetManager,
		appWidgetIds: IntArray,
		widgetData: SharedPreferences
	) {
		super.onUpdate(context, appWidgetManager, appWidgetIds)
	}
}
