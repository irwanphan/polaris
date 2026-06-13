package com.phandarian.polaris

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Renders the pinned-event countdown on the user's home screen.
 *
 * The provider is intentionally dumb: it reads three string keys
 * written by the Dart side via the `home_widget` plugin and copies
 * them into a `RemoteViews`. All formatting (date, days, recurrence
 * label) happens in Dart so the styling stays consistent with the
 * in-app `EventCard`.
 *
 * Keys (must mirror PolarisHomeWidgetUpdater in lib/core/widgets/):
 *  - polaris_pinned_title    String?  — event title, null = no pin
 *  - polaris_pinned_days     String?  — formatted "12 days" / "Today"
 *  - polaris_pinned_subtitle String?  — date + recurrence, e.g. "Dec 25 · yearly"
 *
 * When `polaris_pinned_title` is null the widget renders an empty
 * state inviting the user to pin an event from inside the app.
 */
class PolarisWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views =
                RemoteViews(context.packageName, R.layout.polaris_widget_layout).apply {
                    val title = widgetData.getString(KEY_TITLE, null)

                    if (title.isNullOrBlank()) {
                        setTextViewText(R.id.polaris_widget_title, "Polaris")
                        setTextViewText(R.id.polaris_widget_days, "—")
                        setTextViewText(
                            R.id.polaris_widget_subtitle,
                            "Pin an event in Polaris",
                        )
                    } else {
                        setTextViewText(R.id.polaris_widget_title, title)
                        setTextViewText(
                            R.id.polaris_widget_days,
                            widgetData.getString(KEY_DAYS, "—") ?: "—",
                        )
                        setTextViewText(
                            R.id.polaris_widget_subtitle,
                            widgetData.getString(KEY_SUBTITLE, "") ?: "",
                        )
                    }

                    // Tapping anywhere on the widget surface launches
                    // Polaris on its current route. We do not deep-link
                    // to the event yet because the router does not
                    // expose an event detail route in M2.
                    val launchIntent =
                        HomeWidgetLaunchIntent.getActivity(
                            context,
                            MainActivity::class.java,
                        )
                    setOnClickPendingIntent(R.id.polaris_widget_root, launchIntent)
                }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    companion object {
        const val KEY_TITLE = "polaris_pinned_title"
        const val KEY_DAYS = "polaris_pinned_days"
        const val KEY_SUBTITLE = "polaris_pinned_subtitle"
    }
}
