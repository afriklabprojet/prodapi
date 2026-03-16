// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DR-PHARMA';

  @override
  String get navHome => 'Home';

  @override
  String get navMyCart => 'My Cart';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'My Profile';

  @override
  String get navMyOrders => 'My Orders';

  @override
  String get navCheckout => 'Order Checkout';

  @override
  String get navOrderDetails => 'Order Details';

  @override
  String get navOnDutyPharmacies => 'On-Duty Pharmacies';

  @override
  String get navPrescriptionUpload => 'Upload Prescription';

  @override
  String get navEditAddress => 'Edit Address';

  @override
  String get navTerms => 'Terms of Use';

  @override
  String get navPrivacy => 'Privacy Policy';

  @override
  String get navLegal => 'Legal Notices';

  @override
  String get navError => 'Error';

  @override
  String get navTheme => 'Theme';

  @override
  String get homeMedications => 'Medications';

  @override
  String get homeAllProducts => 'All Products';

  @override
  String get homeGuard => 'On Duty';

  @override
  String get homePharmacies => 'Pharmacies';

  @override
  String get homePrescription => 'Prescription';

  @override
  String get homeServices => 'Services';

  @override
  String get homeFeatured => 'Featured';

  @override
  String get homeSeeAll => 'See All';

  @override
  String get homeGreeting => 'Hello,';

  @override
  String get promoFreeDelivery => 'Free Delivery';

  @override
  String get promoFirstOrder => 'On your first order';

  @override
  String get promoVitamins => 'Vitamins & Supplements';

  @override
  String get promoService24 => '24/7 Service';

  @override
  String get promoOnDutyPharmacy => 'On-duty pharmacy';

  @override
  String get onboardingWelcome => 'Welcome to DR-PHARMA';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingPrevious => 'Previous';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get authLogin => 'Log In';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authForgotPassword => 'Forgot Password?';

  @override
  String get authLogout => 'Log Out';

  @override
  String get authRegistrationSuccess => 'Registration Successful!';

  @override
  String get authPhoneNumber => 'Phone Number';

  @override
  String get authPassword => 'Password';

  @override
  String get authConfirmPassword => 'Confirm Password';

  @override
  String get authFirstName => 'First Name';

  @override
  String get authLastName => 'Last Name';

  @override
  String get authEmail => 'Email';

  @override
  String get authRememberMe => 'Remember me';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authOtpSent => 'Code sent';

  @override
  String get authOtpVerify => 'Verify code';

  @override
  String get authAcceptTerms => 'I accept the terms of use';

  @override
  String get btnRetry => 'Retry';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnBackToHome => 'Back to Home';

  @override
  String get btnValidate => 'Confirm';

  @override
  String get btnOk => 'OK';

  @override
  String get btnNo => 'No';

  @override
  String get btnDelete => 'Delete';

  @override
  String get btnEdit => 'Edit';

  @override
  String get btnQuit => 'Quit';

  @override
  String get btnRefresh => 'Refresh';

  @override
  String get btnClearSearch => 'Clear Search';

  @override
  String get btnBrowseProducts => 'Browse Products';

  @override
  String get btnTakePhoto => 'Take a Photo';

  @override
  String get btnChooseGallery => 'Choose from Gallery';

  @override
  String get btnSave => 'Save';

  @override
  String get cartAddToCart => 'Add to Cart';

  @override
  String get cartViewProducts => 'View Products';

  @override
  String get cartPlaceOrder => 'Place Order';

  @override
  String get cartClearCart => 'Clear Cart';

  @override
  String get cartClear => 'Clear';

  @override
  String cartConfirmOrder(String total) {
    return 'Confirm Order - $total';
  }

  @override
  String get cartViewDetails => 'View Details';

  @override
  String get cartMyOrders => 'My Orders';

  @override
  String get cartCheckPayment => 'Check Payment';

  @override
  String get cartSimulatePayment => 'Simulate Payment';

  @override
  String get cartSendReview => 'Send My Review';

  @override
  String get prescriptionSend => 'Send a Prescription';

  @override
  String get prescriptionSendForValidation => 'Send for Validation';

  @override
  String get prescriptionAddPhoto => 'Add a Photo';

  @override
  String get prescriptionAddPrescription => 'Add a Prescription';

  @override
  String get prescriptionConfirmPay => 'Confirm and Pay';

  @override
  String get prescriptionPay => 'Pay';

  @override
  String get prescriptionViewDetails => 'View Details';

  @override
  String get prescriptionNoPhotos => 'No photos added';

  @override
  String get pharmacyCall => 'Call';

  @override
  String get pharmacyRoute => 'Directions';

  @override
  String get pharmacyDetails => 'Details';

  @override
  String get pharmacyEnableLocation => 'Enable Location';

  @override
  String get pharmacyUpdatePosition => 'Update Position';

  @override
  String get addressDeliveryAddress => 'Delivery Address';

  @override
  String get addressSelectDelivery => 'Please select a delivery address';

  @override
  String get addressAddForOrders => 'Add an address to simplify your orders';

  @override
  String get addressDeliveryCode => 'Delivery Code';

  @override
  String get addressDeliveryCodeHint =>
      'Share this code with the courier\nto confirm receipt';

  @override
  String get addressSetDefault => 'Set as default address';

  @override
  String get addressDeliveryInstructions => 'Delivery Instructions';

  @override
  String get addressLocating => 'Locating...';

  @override
  String get addressSaved => 'Address saved';

  @override
  String get addressNew => 'New Address';

  @override
  String get addressForNextOrders => 'For your next orders';

  @override
  String get addressDelete => 'Delete address';

  @override
  String get addressAdd => 'Add an address';

  @override
  String get addressNewTitle => 'New Address';

  @override
  String get addressSetAsDefault => 'Set as default';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusConfirmed => 'Confirmed';

  @override
  String get orderStatusConfirmedPlural => 'Confirmed';

  @override
  String get orderStatusReady => 'Ready';

  @override
  String get orderStatusDelivering => 'In Delivery';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusDeliveredPlural => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusCancelledPlural => 'Cancelled';

  @override
  String get orderStatusFailed => 'Failed';

  @override
  String get orderStatusPickedUp => 'Order picked up';

  @override
  String get orderStatusDeliveredCheck => 'Delivered ✓';

  @override
  String get orderStatusPreparing => 'Preparing';

  @override
  String get orderStatusPreparingEllipsis => 'Preparing...';

  @override
  String get orderStatusProcessing => 'Processing';

  @override
  String get orderStatusValidated => 'Validated';

  @override
  String get orderStatusRejected => 'Rejected';

  @override
  String get orderStatusCancelledOn => 'Cancelled on';

  @override
  String get orderStatusPendingFull => 'Order pending';

  @override
  String get paymentOnline => 'Online Payment';

  @override
  String get paymentOnDelivery => 'Cash on Delivery';

  @override
  String get paymentChooseMethod => 'Choose payment method';

  @override
  String get paymentInitializing => 'Initializing payment...';

  @override
  String get paymentProcessing => 'Payment in progress...';

  @override
  String get paymentSuccess => 'Payment Successful!';

  @override
  String get paymentSuccessMessage => 'Your payment was completed successfully';

  @override
  String get paymentWaitingConfirmation =>
      'Waiting for payment confirmation...';

  @override
  String get paymentConfirm => 'Confirm Payment';

  @override
  String get paymentMode => 'Payment method:';

  @override
  String get paymentDeliveryFees => 'Delivery Fees';

  @override
  String get paymentProcessingFees => 'Payment Fees';

  @override
  String get paymentOnlineFees => 'Online payment processing fees';

  @override
  String get paymentOrderSummary => 'Order Summary';

  @override
  String get paymentSubtotal => 'Subtotal';

  @override
  String get paymentTotal => 'Total';

  @override
  String get paymentAutoConfirm => 'Payment will be automatically confirmed';

  @override
  String get emptyNoProducts => 'No products';

  @override
  String get emptyNoResults => 'No results';

  @override
  String get emptyNoOrders => 'No orders';

  @override
  String get emptyCart => 'Cart is empty';

  @override
  String get emptyNoNotifications => 'No notifications';

  @override
  String get emptyNoProfile => 'No profile available';

  @override
  String get emptyNoData => 'No data available';

  @override
  String get emptyNoDataShort => 'No data';

  @override
  String get emptyNoPharmacies => 'No pharmacies available';

  @override
  String get emptyNoOnDutyPharmacies => 'No on-duty pharmacies';

  @override
  String get emptyImageNotAvailable => 'Image not available';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get errorGenericRetry => 'An error occurred. Please try again.';

  @override
  String get errorUnexpected => 'An unexpected error occurred';

  @override
  String get errorNoInternet => 'No Internet Connection';

  @override
  String get errorNoInternetLower => 'No internet connection';

  @override
  String get errorCheckConnection => 'Check your connection and try again.';

  @override
  String get errorConnection => 'Connection error';

  @override
  String get errorTimeout => 'Connection timed out';

  @override
  String get errorServerUnreachable => 'Unable to connect to the server';

  @override
  String get errorSessionExpired => 'Session expired. Please log in again';

  @override
  String get errorUnauthorized => 'Unauthorized access';

  @override
  String get errorNotFound => 'Resource not found';

  @override
  String get errorInvalidData => 'Invalid data';

  @override
  String get errorTooManyRequests => 'Too many requests. Please wait';

  @override
  String get errorServer => 'Server error. Please try again later';

  @override
  String get errorServiceUnavailable => 'Service temporarily unavailable';

  @override
  String get errorInvalidRequest => 'Invalid request';

  @override
  String get errorRequestCancelled => 'Request cancelled';

  @override
  String get errorInvalidCertificate => 'Invalid security certificate';

  @override
  String get errorDataConflict => 'Data conflict';

  @override
  String get errorRequestTimeout => 'The request took too long';

  @override
  String get errorInvalidServerData => 'Invalid data received from server';

  @override
  String get errorValidation => 'Validation error';

  @override
  String get errorLoadingNotifications => 'Error loading notifications';

  @override
  String get errorUpdating => 'Error updating';

  @override
  String get errorDeleting => 'Error deleting';

  @override
  String get errorLoadingPrescriptions => 'Error loading prescriptions';

  @override
  String get errorLoadingDetails => 'Error loading details';

  @override
  String get errorPayment => 'Payment error';

  @override
  String get errorCalculatingFees => 'Error calculating fees';

  @override
  String get errorConnectionCheck => 'Connection error. Check your internet.';

  @override
  String get errorNetworkCheck => 'Network error. Check your connection.';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String get errorPaymentFailed => 'Payment failed. Please try again.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please try again later.';

  @override
  String get errorSessionExpiredNewCode =>
      'Session expired. Please request a new code.';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationPassword6Chars =>
      'Password must be at least 6 characters';

  @override
  String get validationPassword8Chars =>
      'Password must be at least 8 characters';

  @override
  String get validationPasswordUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get validationPasswordLowercase =>
      'Password must contain at least one lowercase letter';

  @override
  String get validationPasswordDigit =>
      'Password must contain at least one digit';

  @override
  String get validationConfirmPassword => 'Confirm password';

  @override
  String get validationPleaseConfirmPassword => 'Please confirm the password';

  @override
  String get validationEmailInvalid => 'Please enter a valid email';

  @override
  String get validationPhoneInvalid => 'Please enter a valid phone number';

  @override
  String get validationAmountInvalid => 'Please enter a valid amount';

  @override
  String get validationNumberInvalid => 'Please enter a valid number';

  @override
  String get validationNameRequired => 'Name is required';

  @override
  String get validationAddressRequired => 'Please enter your address';

  @override
  String get validationCityRequired => 'Please enter the city';

  @override
  String get validationPhoneRequired => 'Please enter your number';

  @override
  String get validationCurrentPasswordRequired =>
      'Please enter your current password';

  @override
  String get validationNewPasswordRequired => 'Please enter a new password';

  @override
  String get validationConfirmNewPassword => 'Please confirm your password';

  @override
  String get validationSelectionRequired => 'Please make a selection';

  @override
  String get validationAcceptTerms => 'Please accept the terms of use';

  @override
  String get searchPharmacy => 'Search for a pharmacy...';

  @override
  String get searchMedications => 'Search for medications...';

  @override
  String get searchMedication => 'Search for a medication...';

  @override
  String get searchOnDutyPharmacies => 'Searching on-duty pharmacies...';

  @override
  String get searchLoadingPharmacies => 'Loading pharmacies...';

  @override
  String get pharmacyStatusOpen => 'Open';

  @override
  String get pharmacyStatusOpenFeminine => 'Open';

  @override
  String get pharmacyStatusOpenPlural => 'Open';

  @override
  String get pharmacyStatusClosed => 'Closed';

  @override
  String get pharmacyStatusClosedFeminine => 'Closed';

  @override
  String get pharmacyStatusOnDuty => 'On-duty pharmacy';

  @override
  String get pharmacyAddressUnavailable => 'Address not available';

  @override
  String get ratingFast => 'Fast';

  @override
  String get ratingPolite => 'Polite';

  @override
  String get ratingProfessional => 'Professional';

  @override
  String get ratingPunctual => 'Punctual';

  @override
  String get ratingLate => 'Late';

  @override
  String get ratingRude => 'Rude';

  @override
  String get ratingDamaged => 'Package damaged';

  @override
  String get ratingGoodPackaging => 'Good packaging';

  @override
  String get ratingCorrectProducts => 'Correct products';

  @override
  String get ratingFastService => 'Fast service';

  @override
  String get ratingMissingProduct => 'Missing product';

  @override
  String get ratingPoorPackaging => 'Poor packaging';

  @override
  String get ratingLongWait => 'Long wait';

  @override
  String get ratingTitle => 'Rate your order';

  @override
  String get ratingCommentHint => 'Add a comment (optional)...';

  @override
  String get ratingThankYou => 'Thank you for your review!';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get profileEditSubtitle => 'Change your personal information';

  @override
  String get profileMyAddresses => 'My Addresses';

  @override
  String get profileMyAddressesSubtitle => 'Manage your delivery addresses';

  @override
  String get profileNotificationsSubtitle =>
      'Manage your notification preferences';

  @override
  String get profileHelpSupport => 'Help & Support';

  @override
  String get profileLegal => 'Legal notices';

  @override
  String get profileLegalSubtitle => 'Terms of use and privacy';

  @override
  String get profileOrders => 'Orders';

  @override
  String get profileDelivered => 'Delivered';

  @override
  String get profileTotalSpent => 'Total Spent';

  @override
  String get profileMemberSince => 'Member since';

  @override
  String get profileDefaultAddress => 'Default address';

  @override
  String get profileAccountInfo => 'Account Information';

  @override
  String get profilePersonalInfo => 'Personal Information';

  @override
  String get profileOrderUpdates => 'Order Updates';

  @override
  String get profileDeliveryAlerts => 'Delivery Alerts';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemDescription => 'Follows device theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightDescription => 'Always use light theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkDescription => 'Always use dark theme';

  @override
  String get dialogQuitApp => 'Quit Application';

  @override
  String get dialogQuitAppMessage => 'Are you sure you want to quit DR-PHARMA?';

  @override
  String get dialogCancelOrder => 'Cancel Order';

  @override
  String get dialogCancelOrderMessage =>
      'Are you sure you want to cancel this order?';

  @override
  String get dialogClearCartMessage =>
      'Are you sure you want to remove all items from the cart?';

  @override
  String get dialogDeleteAvatarMessage =>
      'Are you sure you want to delete your profile picture?';

  @override
  String get dialogNotificationDeleted => 'Notification deleted';

  @override
  String get loadingGeneric => 'Loading...';

  @override
  String get loadingInProgress => 'Loading';

  @override
  String get loadingSending => 'Sending...';

  @override
  String get loadingProcessing => 'Processing...';

  @override
  String get loadingOrderProcessing => 'Processing order...';

  @override
  String get successPrescriptionSent => 'Prescription sent successfully!';

  @override
  String get successAddressUpdated => 'Address updated successfully';

  @override
  String get successGpsUpdated => 'GPS position updated';

  @override
  String get successPasswordUpdated => 'Your password was updated successfully';

  @override
  String get permissionLocationDenied => 'Location permission denied';

  @override
  String get permissionLocationDisabled =>
      'Location is disabled. Enable it in settings.';

  @override
  String get miscAvatarChangeSoon => 'Avatar change - Coming soon';

  @override
  String get miscCannotOpenEmail => 'Unable to open email app';

  @override
  String get miscSinglePharmacyOrder =>
      'You can only order from one pharmacy at a time';

  @override
  String get miscDeliveryContact =>
      'Hello, I\'m contacting you about my delivery.';

  @override
  String get miscDeleteAvatar => 'Delete avatar';

  @override
  String get miscTrackDelivery => 'Track delivery';
}
