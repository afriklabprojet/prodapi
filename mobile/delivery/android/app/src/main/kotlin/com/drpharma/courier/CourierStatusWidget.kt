package com.drpharma.courier

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.view.View
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.NumberFormat
import java.util.Locale
import com.drpharma.courier.R

/**
 * Widget Android pour afficher le statut du coursier sur l'écran d'accueil
 */
class CourierStatusWidget : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Widget ajouté pour la première fois
    }

    override fun onDisabled(context: Context) {
        // Dernier widget supprimé
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.courier_status_widget)
            
            // Récupérer les données depuis HomeWidget
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            val isOnline = prefs.getBoolean("is_online", false)
            val hasActiveDelivery = prefs.getBoolean("has_active_delivery", false)
            val pharmacyName = prefs.getString("pharmacy_name", "") ?: ""
            val customerAddress = prefs.getString("customer_address", "") ?: ""
            val deliveryStatus = prefs.getString("delivery_status", "") ?: ""
            val estimatedTime = prefs.getString("estimated_time", "") ?: ""
            val todayEarnings = prefs.getInt("today_earnings", 0)
            val todayDeliveries = prefs.getInt("today_deliveries", 0)
            
            // Mettre à jour l'indicateur de statut
            if (isOnline) {
                views.setTextViewText(R.id.status_indicator, "En ligne")
                views.setInt(R.id.status_indicator, "setBackgroundResource", R.drawable.status_badge_online)
            } else {
                views.setTextViewText(R.id.status_indicator, "Hors ligne")
                views.setInt(R.id.status_indicator, "setBackgroundResource", R.drawable.status_badge_offline)
            }
            
            // Afficher section stats ou livraison active
            if (hasActiveDelivery) {
                views.setViewVisibility(R.id.stats_section, View.GONE)
                views.setViewVisibility(R.id.delivery_section, View.VISIBLE)
                
                // Déterminer la destination selon le statut
                val (statusLabel, destinationName) = when (deliveryStatus) {
                    "toPickup" -> Pair("En route vers", pharmacyName)
                    "atPharmacy" -> Pair("À la pharmacie", pharmacyName)
                    "enRoute" -> Pair("En route vers", customerAddress)
                    "atCustomer" -> Pair("Chez le client", customerAddress)
                    else -> Pair("Livraison en cours", pharmacyName)
                }
                
                views.setTextViewText(R.id.delivery_status_label, statusLabel)
                views.setTextViewText(R.id.destination_name, destinationName)
                views.setTextViewText(R.id.estimated_time, if (estimatedTime.isNotEmpty()) "ETA: $estimatedTime" else "")
                
                // Bouton: Ouvrir les détails
                views.setTextViewText(R.id.action_button, "Voir la livraison")
            } else {
                views.setViewVisibility(R.id.stats_section, View.VISIBLE)
                views.setViewVisibility(R.id.delivery_section, View.GONE)
                
                // Statistiques du jour
                views.setTextViewText(R.id.today_deliveries, todayDeliveries.toString())
                
                val formatter = NumberFormat.getInstance(Locale.FRANCE)
                views.setTextViewText(R.id.today_earnings, "${formatter.format(todayEarnings)} FCFA")
                
                // Bouton: Toggle online
                views.setTextViewText(R.id.action_button, if (isOnline) "Passer hors ligne" else "Passer en ligne")
            }
            
            // Intent pour ouvrir l'app
            val openAppIntent = Intent(context, MainActivity::class.java)
            openAppIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val openAppPendingIntent = PendingIntent.getActivity(
                context, 0, openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // Widget cliquable
            views.setOnClickPendingIntent(R.id.action_button, openAppPendingIntent)
            
            // Mettre à jour le widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
