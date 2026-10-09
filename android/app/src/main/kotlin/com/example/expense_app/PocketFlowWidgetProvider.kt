package com.example.expense_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Size-adaptive Money Glance widget.
 * Small: balance + today + add
 * Medium: balance + today/month + budget bar + add
 */
class PocketFlowWidgetProvider : HomeWidgetProvider() {

  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    updateOne(
        context,
        appWidgetManager,
        appWidgetId,
        HomeWidgetPlugin.getData(context),
        newOptions,
    )
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val options = appWidgetManager.getAppWidgetOptions(widgetId)
      updateOne(context, appWidgetManager, widgetId, widgetData, options)
    }
  }

  private fun updateOne(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      widgetData: SharedPreferences,
      options: Bundle?,
  ) {
    val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180) ?: 180
    val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110) ?: 110
    // Need enough width AND height for the richer layout.
    val useMedium = minWidth >= 220 && minHeight >= 100
    val layoutId =
        if (useMedium) R.layout.pocketflow_widget_medium else R.layout.pocketflow_widget_small

    val homeIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("pocketflow://home"),
        )
    val addIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("pocketflow://add?type=expense"),
        )

    val balance = widgetData.getString("balance", null) ?: "—"
    val today = widgetData.getString("today_expense", null) ?: "—"
    val month = widgetData.getString("month_expense", null)
        ?: widgetData.getString("expense", null)
        ?: "—"
    val title = widgetData.getString("title", null) ?: "PocketFlow"
    val updated = widgetData.getString("updated_at", null)?.removePrefix("Updated ")?.trim().orEmpty()
    val budgetLabel = widgetData.getString("budget_label", null) ?: "Budget"
    val progress = widgetData.getInt("budget_progress", 0).coerceIn(0, 100)

    val views =
        RemoteViews(context.packageName, layoutId).apply {
          setOnClickPendingIntent(R.id.widget_root, homeIntent)
          setOnClickPendingIntent(R.id.widget_body, homeIntent)
          setOnClickPendingIntent(R.id.widget_add, addIntent)

          setTextViewText(R.id.widget_title, title)
          setTextViewText(R.id.widget_balance, balance)

          if (useMedium) {
            setTextViewText(R.id.widget_today_expense, "Today $today")
            setTextViewText(R.id.widget_month_expense, "Month $month")
            setTextViewText(R.id.widget_updated_at, updated)
            setTextViewText(R.id.widget_budget_label, budgetLabel)
            setTextViewText(R.id.widget_budget_pct, "$progress%")
            setProgressBar(R.id.widget_budget_bar, 100, progress, false)
            // Hint removed from visible layout to prevent clipping.
            setViewVisibility(R.id.widget_hint, View.GONE)
          } else {
            setTextViewText(R.id.widget_today_expense, "Today $today")
          }
        }

    appWidgetManager.updateAppWidget(widgetId, views)
  }
}
