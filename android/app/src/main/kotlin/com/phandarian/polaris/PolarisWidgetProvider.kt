package com.phandarian.polaris

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Renders the pinned-subjects scrollable list on the user's home
 * screen. The actual row data lives in
 * [PolarisWidgetItemsFactory] — this provider only paints the
 * header chrome and binds the ListView adapter.
 *
 * Wire contract with `PolarisHomeWidgetUpdater` (Dart):
 *   * polaris_widget_header_title    String? — app title chip in the header
 *   * polaris_widget_empty_title     String? — empty-state heading
 *   * polaris_widget_empty_subtitle  String? — empty-state body
 *   * polaris_widget_items_json      String? — JSON array (see factory)
 *
 * Click behaviour:
 *   * Header tap → launches Polaris on its current route.
 *   * Row tap   → same launch intent, fired via a PendingIntent
 *                 template + per-row fill-in intent so each row is
 *                 individually clickable inside the ListView.
 *
 * Caveat: `notifyAppWidgetViewDataChanged` MUST be called every
 * refresh so the adapter re-reads the JSON; without it the list
 * caches the first snapshot forever.
 */
class PolarisWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.polaris_widget_layout)

            views.setTextViewText(
                R.id.polaris_widget_title,
                widgetData.getString(KEY_HEADER_TITLE, "Polaris") ?: "Polaris",
            )
            views.setTextViewText(
                R.id.polaris_widget_empty_title,
                widgetData.getString(KEY_EMPTY_TITLE, "Nothing pinned yet")
                    ?: "Nothing pinned yet",
            )
            views.setTextViewText(
                R.id.polaris_widget_empty_subtitle,
                widgetData.getString(
                    KEY_EMPTY_SUBTITLE,
                    "Pin from inside Polaris",
                ) ?: "Pin from inside Polaris",
            )

            // Bind the ListView to the RemoteViewsService. The
            // appWidgetId is encoded into the intent's data URI so
            // each widget instance gets a distinct adapter — without
            // this the framework caches a single factory across all
            // instances and updates would only land on one of them.
            val adapterIntent = Intent(
                context,
                PolarisWidgetRemoteViewsService::class.java,
            ).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.polaris_widget_list, adapterIntent)
            views.setEmptyView(R.id.polaris_widget_list, R.id.polaris_widget_empty)

            // Header tap launches the app.
            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
            )
            views.setOnClickPendingIntent(R.id.polaris_widget_header, launchIntent)

            // Row taps reuse the same destination via a template +
            // fill-in intent (see PolarisWidgetItemsFactory#getViewAt).
            val templateIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            val templatePending = PendingIntent.getActivity(
                context,
                widgetId,
                templateIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
            views.setPendingIntentTemplate(R.id.polaris_widget_list, templatePending)

            appWidgetManager.updateAppWidget(widgetId, views)
            // Critical: tells the adapter to re-read the JSON. Without
            // this the list caches the first payload across refreshes.
            appWidgetManager.notifyAppWidgetViewDataChanged(
                widgetId,
                R.id.polaris_widget_list,
            )
        }
    }

    companion object {
        const val KEY_HEADER_TITLE = "polaris_widget_header_title"
        const val KEY_EMPTY_TITLE = "polaris_widget_empty_title"
        const val KEY_EMPTY_SUBTITLE = "polaris_widget_empty_subtitle"
    }
}
