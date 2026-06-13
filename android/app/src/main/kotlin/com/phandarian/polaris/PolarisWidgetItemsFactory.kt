package com.phandarian.polaris

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONException

/**
 * Backing data source for the Polaris widget's ListView.
 *
 * Data lifecycle:
 *  1. Dart-side [PolarisHomeWidgetUpdater] serializes the list of
 *     pinned subjects as a JSON array and stores it under
 *     [KEY_ITEMS_JSON] in the `home_widget` SharedPreferences file
 *     (`HomeWidgetPreferences`).
 *  2. Dart calls `HomeWidget.updateWidget`, which triggers
 *     `PolarisWidgetProvider#onUpdate` plus
 *     `notifyAppWidgetViewDataChanged` so the list reloads.
 *  3. Android binds this service via `setRemoteAdapter`, the
 *     framework calls [onDataSetChanged] on a worker thread, and we
 *     re-read the JSON and rebuild the row cache.
 *  4. The framework requests one row at a time via [getViewAt],
 *     which inflates `polaris_widget_item.xml` and stamps the
 *     per-row title / hero / subtitle / accent color.
 *
 * Wire contract:
 *  Each JSON object looks like:
 *    { "id": "life", "kind": "life", "title": "Sisa Hariku",
 *      "hero": "10906 hari lagi",
 *      "subtitle": "Satu napas pada satu waktu",
 *      "accent": "#6366F1" }
 *
 * Errors at parse time are logged and result in an empty list — the
 * empty view configured in [PolarisWidgetProvider] then takes over.
 */
class PolarisWidgetItemsFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {

    private val rows: MutableList<WidgetRow> = mutableListOf()

    override fun onCreate() {
        // Nothing to set up — `onDataSetChanged` will be invoked
        // before the first `getViewAt` call.
    }

    override fun onDataSetChanged() {
        rows.clear()
        val prefs = context.getSharedPreferences(
            HOME_WIDGET_PREFS,
            Context.MODE_PRIVATE,
        )
        val json = prefs.getString(KEY_ITEMS_JSON, null)
        if (json.isNullOrBlank()) return

        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                rows.add(
                    WidgetRow(
                        id = obj.optString("id"),
                        kind = obj.optString("kind"),
                        title = obj.optString("title"),
                        hero = obj.optString("hero"),
                        subtitle = obj.optString("subtitle"),
                        accentHex = obj.optString("accent", DEFAULT_ACCENT_HEX),
                    ),
                )
            }
        } catch (e: JSONException) {
            Log.w(TAG, "Failed to parse widget items JSON; rendering empty.", e)
        }
    }

    override fun onDestroy() {
        rows.clear()
    }

    override fun getCount(): Int = rows.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position < 0 || position >= rows.size) {
            // Defensive — the framework occasionally probes past the
            // last row during data set transitions.
            return RemoteViews(context.packageName, R.layout.polaris_widget_item)
        }
        val row = rows[position]
        val views = RemoteViews(context.packageName, R.layout.polaris_widget_item)
        views.setTextViewText(R.id.polaris_widget_item_title, row.title)
        views.setTextViewText(R.id.polaris_widget_item_hero, row.hero)
        views.setTextViewText(R.id.polaris_widget_item_subtitle, row.subtitle)
        views.setInt(
            R.id.polaris_widget_item_accent,
            "setBackgroundColor",
            parseHexColor(row.accentHex),
        )

        // Empty fill-in intent so the ListView's PendingIntent
        // template (set in PolarisWidgetProvider) fires when the
        // row is tapped. The current router has no event detail
        // route, so all rows simply launch the app.
        views.setOnClickFillInIntent(R.id.polaris_widget_item_root, Intent())
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long {
        return if (position in rows.indices) rows[position].id.hashCode().toLong()
        else position.toLong()
    }

    override fun hasStableIds(): Boolean = true

    private fun parseHexColor(hex: String): Int {
        return try {
            Color.parseColor(hex)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "Invalid accent color '$hex' — using default.", e)
            Color.parseColor(DEFAULT_ACCENT_HEX)
        }
    }

    private data class WidgetRow(
        val id: String,
        val kind: String,
        val title: String,
        val hero: String,
        val subtitle: String,
        val accentHex: String,
    )

    companion object {
        private const val TAG = "PolarisWidgetItemsFactory"

        /** Mirrors the `home_widget` plugin's SharedPreferences file. */
        const val HOME_WIDGET_PREFS = "HomeWidgetPreferences"

        /** Mirrors `PolarisHomeWidgetUpdater.kItemsJsonKey` in Dart. */
        const val KEY_ITEMS_JSON = "polaris_widget_items_json"

        /** Indigo 500 — used when a row omits or mis-specifies its accent. */
        private const val DEFAULT_ACCENT_HEX = "#6366F1"
    }
}
