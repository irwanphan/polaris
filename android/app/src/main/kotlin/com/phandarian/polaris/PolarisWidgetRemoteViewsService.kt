package com.phandarian.polaris

import android.content.Intent
import android.widget.RemoteViewsService

/**
 * Bridges [PolarisWidgetProvider]'s ListView to its
 * [PolarisWidgetItemsFactory] data source.
 *
 * The framework binds this service via `setRemoteAdapter` and calls
 * [onGetViewFactory] once per appWidgetId. The factory is responsible
 * for materializing each `RemoteViews` row from the JSON payload that
 * the Dart side writes through `home_widget`.
 *
 * Registered in `AndroidManifest.xml` with
 * `android:permission="android.permission.BIND_REMOTEVIEWS"` so only
 * the system process can bind to it (required by the Android API).
 */
class PolarisWidgetRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return PolarisWidgetItemsFactory(applicationContext)
    }
}
