/// Événements analytics standardisés
/// Nommage cohérent pour tous les providers (Firebase, Mixpanel, etc.)
abstract class AnalyticsEvents {
  AnalyticsEvents._();

  // ─────────────────────────────────────────────────────────
  // Authentication
  // ─────────────────────────────────────────────────────────

  static const loginStarted = 'login_started';
  static const loginSuccess = 'login_success';
  static const loginFailed = 'login_failed';
  static const logout = 'logout';

  static const registerStarted = 'register_started';
  static const registerSuccess = 'register_success';
  static const registerFailed = 'register_failed';

  static const otpRequested = 'otp_requested';
  static const otpVerified = 'otp_verified';
  static const otpFailed = 'otp_failed';
  static const otpResent = 'otp_resent';

  static const passwordResetRequested = 'password_reset_requested';
  static const passwordResetCompleted = 'password_reset_completed';

  // ─────────────────────────────────────────────────────────
  // Cart / eCommerce
  // ─────────────────────────────────────────────────────────

  static const addToCart = 'add_to_cart';
  static const removeFromCart = 'remove_from_cart';
  static const updateCartQuantity = 'update_cart_quantity';
  static const cartViewed = 'cart_viewed';
  static const cartCleared = 'cart_cleared';

  static const checkoutStarted = 'checkout_started';
  static const checkoutStepCompleted = 'checkout_step_completed';
  static const checkoutCompleted = 'checkout_completed';
  static const checkoutFailed = 'checkout_failed';
  static const checkoutAbandoned = 'checkout_abandoned';

  static const purchase = 'purchase';
  static const refund = 'refund';

  static const promoCodeApplied = 'promo_code_applied';
  static const promoCodeFailed = 'promo_code_failed';

  // ─────────────────────────────────────────────────────────
  // Products / Catalog
  // ─────────────────────────────────────────────────────────

  static const productViewed = 'product_viewed';
  static const productSearched = 'product_searched';
  static const productListViewed = 'product_list_viewed';
  static const productShared = 'product_shared';

  static const categoryViewed = 'category_viewed';

  // ─────────────────────────────────────────────────────────
  // Pharmacies
  // ─────────────────────────────────────────────────────────

  static const pharmacyViewed = 'pharmacy_viewed';
  static const pharmacySearched = 'pharmacy_searched';
  static const pharmacyCalled = 'pharmacy_called';
  static const pharmacyDirections = 'pharmacy_directions';
  static const pharmacyFavorited = 'pharmacy_favorited';

  static const onDutyPharmaciesViewed = 'on_duty_pharmacies_viewed';
  static const nearbyPharmaciesViewed = 'nearby_pharmacies_viewed';

  // ─────────────────────────────────────────────────────────
  // Orders
  // ─────────────────────────────────────────────────────────

  static const orderViewed = 'order_viewed';
  static const orderListViewed = 'order_list_viewed';
  static const orderCancelled = 'order_cancelled';
  static const orderTracked = 'order_tracked';

  static const deliveryTracked = 'delivery_tracked';
  static const courierContacted = 'courier_contacted';

  // ─────────────────────────────────────────────────────────
  // Prescriptions
  // ─────────────────────────────────────────────────────────

  static const prescriptionUploaded = 'prescription_uploaded';
  static const prescriptionViewed = 'prescription_viewed';
  static const prescriptionDeleted = 'prescription_deleted';

  // ─────────────────────────────────────────────────────────
  // Profile / Settings
  // ─────────────────────────────────────────────────────────

  static const profileViewed = 'profile_viewed';
  static const profileUpdated = 'profile_updated';
  static const profilePhotoChanged = 'profile_photo_changed';

  static const addressAdded = 'address_added';
  static const addressUpdated = 'address_updated';
  static const addressDeleted = 'address_deleted';

  static const settingsChanged = 'settings_changed';
  static const notificationToggled = 'notification_toggled';
  static const themeChanged = 'theme_changed';
  static const languageChanged = 'language_changed';

  // ─────────────────────────────────────────────────────────
  // Navigation / Deep Links
  // ─────────────────────────────────────────────────────────

  static const screenView = 'screen_view';
  static const deepLinkReceived = 'deep_link_received';
  static const deepLinkHandled = 'deep_link_handled';
  static const deepLinkFailed = 'deep_link_failed';
  static const deepLinkPending = 'deep_link_pending';

  // ─────────────────────────────────────────────────────────
  // Technical / Errors
  // ─────────────────────────────────────────────────────────

  static const appOpened = 'app_opened';
  static const appBackgrounded = 'app_backgrounded';
  static const appResumed = 'app_resumed';

  static const errorOccurred = 'error_occurred';
  static const networkError = 'network_error';
  static const apiError = 'api_error';

  static const permissionRequested = 'permission_requested';
  static const permissionGranted = 'permission_granted';
  static const permissionDenied = 'permission_denied';

  // ─────────────────────────────────────────────────────────
  // Engagement
  // ─────────────────────────────────────────────────────────

  static const shareClicked = 'share_clicked';
  static const rateAppClicked = 'rate_app_clicked';
  static const supportContacted = 'support_contacted';
  static const feedbackSubmitted = 'feedback_submitted';

  // ─────────────────────────────────────────────────────────
  // Messaging (WhatsApp / SMS)
  // ─────────────────────────────────────────────────────────

  static const messagingSent = 'messaging_sent';
  static const messagingChannelError = 'messaging_channel_error';
  static const messagingAllChannelsFailed = 'messaging_all_channels_failed';
  static const pharmacyContacted = 'pharmacy_contacted';
}

/// Propriétés analytics courantes
abstract class AnalyticsProperties {
  AnalyticsProperties._();

  // User properties
  static const userId = 'user_id';
  static const userEmail = 'user_email';
  static const userPhone = 'user_phone';
  static const userName = 'user_name';

  // Product properties
  static const productId = 'product_id';
  static const productName = 'product_name';
  static const productPrice = 'product_price';
  static const productCategory = 'product_category';
  static const productPharmacy = 'product_pharmacy';

  // Order properties
  static const orderId = 'order_id';
  static const orderTotal = 'order_total';
  static const orderStatus = 'order_status';
  static const paymentMethod = 'payment_method';

  // Cart properties
  static const cartValue = 'cart_value';
  static const cartItemCount = 'cart_item_count';
  static const quantity = 'quantity';

  // Screen properties
  static const screenName = 'screen_name';
  static const screenClass = 'screen_class';
  static const previousScreen = 'previous_screen';

  // Error properties
  static const errorType = 'error_type';
  static const errorMessage = 'error_message';
  static const errorCode = 'error_code';

  // Deep link properties
  static const deepLinkPath = 'deep_link_path';
  static const deepLinkSource = 'deep_link_source';

  // Technical
  static const appVersion = 'app_version';
  static const platform = 'platform';
  static const deviceModel = 'device_model';

  // Messaging properties
  static const channel = 'channel';
  static const orderReference = 'order_reference';
  static const phone = 'phone';
}
