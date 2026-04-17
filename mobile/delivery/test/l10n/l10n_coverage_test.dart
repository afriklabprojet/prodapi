import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/l10n/app_localizations.dart';

void main() {
  group('L10n Key Coverage Tests', () {
    testWidgets('French locale resolves all keys', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      // Core navigation & app
      expect(l10n.appName, isNotEmpty);
      expect(l10n.welcome, isNotEmpty);
      expect(l10n.login, isNotEmpty);
      expect(l10n.logout, isNotEmpty);
      expect(l10n.email, isNotEmpty);
      expect(l10n.password, isNotEmpty);
      expect(l10n.phone, isNotEmpty);
      expect(l10n.forgotPassword, isNotEmpty);
      expect(l10n.signIn, isNotEmpty);
      expect(l10n.signUp, isNotEmpty);
      expect(l10n.createAccount, isNotEmpty);
      expect(l10n.alreadyHaveAccount, isNotEmpty);
      expect(l10n.noAccount, isNotEmpty);
      expect(l10n.home, isNotEmpty);
      expect(l10n.map, isNotEmpty);
      expect(l10n.deliveries, isNotEmpty);
      expect(l10n.wallet, isNotEmpty);
      expect(l10n.profile, isNotEmpty);
      expect(l10n.settings, isNotEmpty);
      expect(l10n.challenges, isNotEmpty);

      // Status
      expect(l10n.online, isNotEmpty);
      expect(l10n.offline, isNotEmpty);
      expect(l10n.goOnline, isNotEmpty);
      expect(l10n.goOffline, isNotEmpty);
      expect(l10n.available, isNotEmpty);
      expect(l10n.busy, isNotEmpty);

      // Delivery
      expect(l10n.delivery, isNotEmpty);
      expect(l10n.activeDelivery, isNotEmpty);
      expect(l10n.noActiveDelivery, isNotEmpty);
      expect(l10n.newDelivery, isNotEmpty);
      expect(l10n.acceptDelivery, isNotEmpty);
      expect(l10n.rejectDelivery, isNotEmpty);
      expect(l10n.startDelivery, isNotEmpty);
      expect(l10n.completeDelivery, isNotEmpty);
      expect(l10n.deliveryCompleted, isNotEmpty);
      expect(l10n.deliveryDetails, isNotEmpty);
      expect(l10n.pickup, isNotEmpty);
      expect(l10n.dropoff, isNotEmpty);
      expect(l10n.pickupAddress, isNotEmpty);
      expect(l10n.deliveryAddress, isNotEmpty);
      expect(l10n.pharmacy, isNotEmpty);
      expect(l10n.customer, isNotEmpty);
      expect(l10n.orderNumber, isNotEmpty);
      expect(l10n.eta, isNotEmpty);
      expect(l10n.etaArrival, isNotEmpty);
      expect(l10n.distance, isNotEmpty);
      expect(l10n.duration, isNotEmpty);
      expect(l10n.minutes, isNotEmpty);
      expect(l10n.km, isNotEmpty);

      // Navigation & communication
      expect(l10n.navigate, isNotEmpty);
      expect(l10n.openInMaps, isNotEmpty);
      expect(l10n.call, isNotEmpty);
      expect(l10n.chat, isNotEmpty);
      expect(l10n.sendMessage, isNotEmpty);
      expect(l10n.typeMessage, isNotEmpty);

      // Proof of delivery
      expect(l10n.proofOfDelivery, isNotEmpty);
      expect(l10n.takePhoto, isNotEmpty);
      expect(l10n.signature, isNotEmpty);
      expect(l10n.getSignature, isNotEmpty);
      expect(l10n.clearSignature, isNotEmpty);
      expect(l10n.confirmSignature, isNotEmpty);
      expect(l10n.scanQRCode, isNotEmpty);
      expect(l10n.enterCodeManually, isNotEmpty);
      expect(l10n.confirmationCode, isNotEmpty);

      // Wallet & earnings
      expect(l10n.walletBalance, isNotEmpty);
      expect(l10n.earnings, isNotEmpty);
      expect(l10n.todayEarnings, isNotEmpty);
      expect(l10n.weekEarnings, isNotEmpty);
      expect(l10n.monthEarnings, isNotEmpty);
      expect(l10n.totalEarnings, isNotEmpty);
      expect(l10n.withdraw, isNotEmpty);
      expect(l10n.withdrawFunds, isNotEmpty);
      expect(l10n.withdrawalRequest, isNotEmpty);
      expect(l10n.withdrawalHistory, isNotEmpty);
      expect(l10n.transactionHistory, isNotEmpty);
      expect(l10n.commission, isNotEmpty);
      expect(l10n.bonus, isNotEmpty);
      expect(l10n.penalty, isNotEmpty);

      // History & filters
      expect(l10n.history, isNotEmpty);
      expect(l10n.filters, isNotEmpty);
      expect(l10n.filter, isNotEmpty);
      expect(l10n.sortBy, isNotEmpty);
      expect(l10n.dateRange, isNotEmpty);
      expect(l10n.status, isNotEmpty);
      expect(l10n.all, isNotEmpty);
      expect(l10n.today, isNotEmpty);
      expect(l10n.yesterday, isNotEmpty);
      expect(l10n.thisWeek, isNotEmpty);
      expect(l10n.thisMonth, isNotEmpty);
      expect(l10n.lastMonth, isNotEmpty);
      expect(l10n.custom, isNotEmpty);

      // Delivery statuses
      expect(l10n.pending, isNotEmpty);
      expect(l10n.accepted, isNotEmpty);
      expect(l10n.pickedUp, isNotEmpty);
      expect(l10n.inTransit, isNotEmpty);
      expect(l10n.delivered, isNotEmpty);
      expect(l10n.cancelled, isNotEmpty);
      expect(l10n.failed, isNotEmpty);

      // Export
      expect(l10n.exportReport, isNotEmpty);
      expect(l10n.exportCSV, isNotEmpty);
      expect(l10n.exportPDF, isNotEmpty);
      expect(l10n.shareReport, isNotEmpty);

      // Notifications
      expect(l10n.notifications, isNotEmpty);
      expect(l10n.enableNotifications, isNotEmpty);
      expect(l10n.disableNotifications, isNotEmpty);
      expect(l10n.pushNotifications, isNotEmpty);
      expect(l10n.soundEnabled, isNotEmpty);
      expect(l10n.vibrationEnabled, isNotEmpty);

      // Language & theme
      expect(l10n.language, isNotEmpty);
      expect(l10n.french, isNotEmpty);
      expect(l10n.english, isNotEmpty);
      expect(l10n.theme, isNotEmpty);
      expect(l10n.lightTheme, isNotEmpty);
      expect(l10n.darkTheme, isNotEmpty);
      expect(l10n.systemTheme, isNotEmpty);

      // Account & profile
      expect(l10n.account, isNotEmpty);
      expect(l10n.personalInfo, isNotEmpty);
      expect(l10n.editProfile, isNotEmpty);
      expect(l10n.changePassword, isNotEmpty);
      expect(l10n.currentPassword, isNotEmpty);
      expect(l10n.newPassword, isNotEmpty);
      expect(l10n.confirmPassword, isNotEmpty);

      // Vehicle
      expect(l10n.vehicleInfo, isNotEmpty);
      expect(l10n.vehicleType, isNotEmpty);
      expect(l10n.motorcycle, isNotEmpty);
      expect(l10n.car, isNotEmpty);
      expect(l10n.bicycle, isNotEmpty);
      expect(l10n.licensePlate, isNotEmpty);

      // Documents
      expect(l10n.documents, isNotEmpty);
      expect(l10n.idCard, isNotEmpty);
      expect(l10n.drivingLicense, isNotEmpty);
      expect(l10n.vehicleRegistration, isNotEmpty);
      expect(l10n.insurance, isNotEmpty);
      expect(l10n.uploadDocument, isNotEmpty);

      // Support
      expect(l10n.support, isNotEmpty);
      expect(l10n.helpCenter, isNotEmpty);
      expect(l10n.faq, isNotEmpty);
      expect(l10n.contactSupport, isNotEmpty);
      expect(l10n.reportProblem, isNotEmpty);
      expect(l10n.myTickets, isNotEmpty);

      // About
      expect(l10n.about, isNotEmpty);
      expect(l10n.version, isNotEmpty);
      expect(l10n.termsOfService, isNotEmpty);
      expect(l10n.privacyPolicy, isNotEmpty);
      expect(l10n.appVersion, isNotEmpty);

      // Gamification
      expect(l10n.gamification, isNotEmpty);
      expect(l10n.level, isNotEmpty);
      expect(l10n.xp, isNotEmpty);
      expect(l10n.xpPoints, isNotEmpty);
      expect(l10n.badges, isNotEmpty);
      expect(l10n.leaderboard, isNotEmpty);
      expect(l10n.rank, isNotEmpty);
      expect(l10n.weeklyRank, isNotEmpty);
      expect(l10n.monthlyRank, isNotEmpty);
      expect(l10n.allTimeRank, isNotEmpty);
      expect(l10n.unlocked, isNotEmpty);
      expect(l10n.locked, isNotEmpty);
      expect(l10n.progress, isNotEmpty);
      expect(l10n.rewards, isNotEmpty);

      // Battery
      expect(l10n.battery, isNotEmpty);
      expect(l10n.batterySaver, isNotEmpty);
      expect(l10n.batterySaverMode, isNotEmpty);
      expect(l10n.batteryCritical, isNotEmpty);
      expect(l10n.batteryLow, isNotEmpty);
      expect(l10n.batteryNormal, isNotEmpty);
      expect(l10n.charging, isNotEmpty);

      // Tutorial
      expect(l10n.tutorial, isNotEmpty);
      expect(l10n.tutorials, isNotEmpty);
      expect(l10n.skipTutorial, isNotEmpty);
      expect(l10n.nextStep, isNotEmpty);
      expect(l10n.previousStep, isNotEmpty);
      expect(l10n.finish, isNotEmpty);
      expect(l10n.resetTutorials, isNotEmpty);

      // Live tracking
      expect(l10n.liveTracking, isNotEmpty);
      expect(l10n.shareLocation, isNotEmpty);
      expect(l10n.stopSharing, isNotEmpty);
      expect(l10n.trackingActive, isNotEmpty);
      expect(l10n.trackingInactive, isNotEmpty);
      expect(l10n.copyLink, isNotEmpty);
      expect(l10n.linkCopied, isNotEmpty);
      expect(l10n.shareWith, isNotEmpty);

      // Common actions & states
      expect(l10n.error, isNotEmpty);
      expect(l10n.success, isNotEmpty);
      expect(l10n.warning, isNotEmpty);
      expect(l10n.info, isNotEmpty);
      expect(l10n.loading, isNotEmpty);
      expect(l10n.retry, isNotEmpty);
      expect(l10n.cancel, isNotEmpty);
      expect(l10n.confirm, isNotEmpty);
      expect(l10n.save, isNotEmpty);
      expect(l10n.delete, isNotEmpty);
      expect(l10n.edit, isNotEmpty);
      expect(l10n.close, isNotEmpty);
      expect(l10n.done, isNotEmpty);
      expect(l10n.ok, isNotEmpty);
      expect(l10n.yes, isNotEmpty);
      expect(l10n.no, isNotEmpty);
      expect(l10n.back, isNotEmpty);
      expect(l10n.next, isNotEmpty);
      expect(l10n.submit, isNotEmpty);
      expect(l10n.search, isNotEmpty);
      expect(l10n.noResults, isNotEmpty);
      expect(l10n.tryAgain, isNotEmpty);

      // Errors & network
      expect(l10n.networkError, isNotEmpty);
      expect(l10n.noInternet, isNotEmpty);
      expect(l10n.serverError, isNotEmpty);
      expect(l10n.sessionExpired, isNotEmpty);
      expect(l10n.pleaseLogin, isNotEmpty);
      expect(l10n.somethingWentWrong, isNotEmpty);
      expect(l10n.offlineMode, isNotEmpty);
      expect(l10n.offlineModeEnabled, isNotEmpty);
      expect(l10n.backOnline, isNotEmpty);
      expect(l10n.errorOccurredRetry, isNotEmpty);
      expect(l10n.connectionTimeout, isNotEmpty);
      expect(l10n.connectionTimeoutCheck, isNotEmpty);
      expect(l10n.requestCancelled, isNotEmpty);
      expect(l10n.securityError, isNotEmpty);
      expect(l10n.unexpectedError, isNotEmpty);
      expect(l10n.slowConnection, isNotEmpty);
      expect(l10n.slowUpload, isNotEmpty);
      expect(l10n.serverTimeout, isNotEmpty);
      expect(l10n.cannotConnectServer, isNotEmpty);
      expect(l10n.noInternetConnection, isNotEmpty);
      expect(l10n.unknownConnectionError, isNotEmpty);
      expect(l10n.serverCommunicationError, isNotEmpty);
      expect(l10n.invalidRequest, isNotEmpty);
      expect(l10n.accessDenied, isNotEmpty);
      expect(l10n.resourceNotFound, isNotEmpty);
      expect(l10n.timeoutRetry, isNotEmpty);
      expect(l10n.dataConflict, isNotEmpty);
      expect(l10n.invalidData, isNotEmpty);
      expect(l10n.tooManyRequests, isNotEmpty);
      expect(l10n.internalServerError, isNotEmpty);
      expect(l10n.serviceUnavailable, isNotEmpty);

      // Misc
      expect(l10n.fcfa, isNotEmpty);
      expect(l10n.currency, isNotEmpty);
      expect(l10n.locationPermission, isNotEmpty);
      expect(l10n.locationPermissionRequired, isNotEmpty);
      expect(l10n.enableLocation, isNotEmpty);
      expect(l10n.backgroundLocation, isNotEmpty);
      expect(l10n.camera, isNotEmpty);
      expect(l10n.gallery, isNotEmpty);
      expect(l10n.chooseSource, isNotEmpty);
      expect(l10n.estimatedDuration, isNotEmpty);

      // Geofence & arrival
      expect(l10n.arrivedAtPharmacy, isNotEmpty);
      expect(l10n.arrivedAtClient, isNotEmpty);
      expect(l10n.arrivedAtDestination, isNotEmpty);
      expect(l10n.pickupPoint, isNotEmpty);
      expect(l10n.deliveryPoint, isNotEmpty);
      expect(l10n.pullToRefresh, isNotEmpty);
      expect(l10n.noDeliveriesFound, isNotEmpty);
      expect(l10n.geofenceNotificationHint, isNotEmpty);

      // Verification
      expect(l10n.verificationSuccess, isNotEmpty);
      expect(l10n.selfieCaptured, isNotEmpty);
      expect(l10n.imageTooSmall, isNotEmpty);
      expect(l10n.registrationSuccess, isNotEmpty);
      expect(l10n.registrationPending, isNotEmpty);

      // Quick messages
      expect(l10n.quickMessage, isNotEmpty);
      expect(l10n.enRouteToPharmacy, isNotEmpty);
      expect(l10n.arrivedAtPharmacyMsg, isNotEmpty);
      expect(l10n.isOrderReady, isNotEmpty);
      expect(l10n.cannotFindAddress, isNotEmpty);
      expect(l10n.arrivingInFiveMin, isNotEmpty);
      expect(l10n.atYourBuilding, isNotEmpty);
      expect(l10n.pleaseComeDown, isNotEmpty);
      expect(l10n.cannotFindYourAddress, isNotEmpty);
      expect(l10n.customerNotResponding, isNotEmpty);
      expect(l10n.phoneNumberUnavailable, isNotEmpty);

      // Onboarding
      expect(l10n.onboardingTitle1, isNotEmpty);
      expect(l10n.onboardingDesc1, isNotEmpty);
      expect(l10n.onboardingTitle2, isNotEmpty);
      expect(l10n.onboardingDesc2, isNotEmpty);
      expect(l10n.onboardingTitle3, isNotEmpty);
      expect(l10n.onboardingDesc3, isNotEmpty);
      expect(l10n.getStarted, isNotEmpty);
      expect(l10n.skip, isNotEmpty);

      // Login screen
      expect(l10n.biometricAuthReason, isNotEmpty);
      expect(l10n.loginWithCredentialsFirst, isNotEmpty);
      expect(l10n.pleaseEnterPhoneNumber, isNotEmpty);
      expect(l10n.connectionFailed, isNotEmpty);
      expect(l10n.incorrectCredentials, isNotEmpty);
      expect(l10n.checkEmailAndPassword, isNotEmpty);
      expect(l10n.resetPassword, isNotEmpty);
      expect(l10n.resetPasswordPhoneDesc, isNotEmpty);
      expect(l10n.resetPasswordEmailDesc, isNotEmpty);
      expect(l10n.phoneNumber, isNotEmpty);
      expect(l10n.phoneHint, isNotEmpty);
      expect(l10n.emailAddress, isNotEmpty);
      expect(l10n.emailHint, isNotEmpty);
      expect(l10n.pleaseEnterEmail, isNotEmpty);
      expect(l10n.invalidEmail, isNotEmpty);
      expect(l10n.resetLinkSent, isNotEmpty);
      expect(l10n.sendOtpCode, isNotEmpty);
      expect(l10n.sendLink, isNotEmpty);
      expect(l10n.courierSpace, isNotEmpty);
      expect(l10n.loginSubtitle, isNotEmpty);
      expect(l10n.emailOrPhone, isNotEmpty);
      expect(l10n.fieldRequired, isNotEmpty);
      expect(l10n.sendCode, isNotEmpty);
      expect(l10n.signInButton, isNotEmpty);
      expect(l10n.or, isNotEmpty);
      expect(l10n.biometricLogin, isNotEmpty);
      expect(l10n.noAccountYet, isNotEmpty);
      expect(l10n.becomeCourier, isNotEmpty);
      expect(l10n.secure, isNotEmpty);
      expect(l10n.certified, isNotEmpty);
      expect(l10n.support247, isNotEmpty);

      // Parameterized keys
      expect(l10n.biometricError('test'), contains('test'));
      expect(l10n.versionLabel('1.0.0'), contains('1.0.0'));
      expect(l10n.cannotLaunchNavigation('Waze'), contains('Waze'));
      expect(l10n.cannotCall('+225070707'), contains('+225070707'));
      expect(l10n.estimatedDurationMinutes(15), contains('15'));
      expect(l10n.deliveriesCount(0), isNotEmpty);
      expect(l10n.deliveriesCount(1), isNotEmpty);
      expect(l10n.deliveriesCount(5), contains('5'));
      expect(l10n.earningsAmount('5000'), contains('5000'));
      expect(l10n.greeting('Jean'), contains('Jean'));
      expect(l10n.levelUp(3), contains('3'));
      expect(
        l10n.approachingPharmacy('PharmaCentre'),
        contains('PharmaCentre'),
      );
      expect(l10n.approachingClient('Konan'), contains('Konan'));
      expect(l10n.verificationFailed('timeout'), contains('timeout'));
    });

    testWidgets('English locale resolves all keys', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      // Core navigation & app
      expect(l10n.appName, isNotEmpty);
      expect(l10n.welcome, isNotEmpty);
      expect(l10n.login, 'Login');
      expect(l10n.logout, isNotEmpty);
      expect(l10n.email, isNotEmpty);
      expect(l10n.password, isNotEmpty);
      expect(l10n.phone, isNotEmpty);
      expect(l10n.forgotPassword, isNotEmpty);
      expect(l10n.signIn, isNotEmpty);
      expect(l10n.signUp, isNotEmpty);
      expect(l10n.createAccount, isNotEmpty);
      expect(l10n.alreadyHaveAccount, isNotEmpty);
      expect(l10n.noAccount, isNotEmpty);
      expect(l10n.home, isNotEmpty);
      expect(l10n.map, isNotEmpty);
      expect(l10n.deliveries, isNotEmpty);
      expect(l10n.wallet, isNotEmpty);
      expect(l10n.profile, isNotEmpty);
      expect(l10n.settings, isNotEmpty);
      expect(l10n.challenges, isNotEmpty);

      // Status
      expect(l10n.online, isNotEmpty);
      expect(l10n.offline, isNotEmpty);
      expect(l10n.goOnline, isNotEmpty);
      expect(l10n.goOffline, isNotEmpty);
      expect(l10n.available, isNotEmpty);
      expect(l10n.busy, isNotEmpty);

      // Delivery
      expect(l10n.delivery, isNotEmpty);
      expect(l10n.activeDelivery, isNotEmpty);
      expect(l10n.noActiveDelivery, isNotEmpty);
      expect(l10n.newDelivery, isNotEmpty);
      expect(l10n.acceptDelivery, isNotEmpty);
      expect(l10n.rejectDelivery, isNotEmpty);
      expect(l10n.startDelivery, isNotEmpty);
      expect(l10n.completeDelivery, isNotEmpty);
      expect(l10n.deliveryCompleted, isNotEmpty);
      expect(l10n.deliveryDetails, isNotEmpty);
      expect(l10n.pickup, isNotEmpty);
      expect(l10n.dropoff, isNotEmpty);
      expect(l10n.pickupAddress, isNotEmpty);
      expect(l10n.deliveryAddress, isNotEmpty);
      expect(l10n.pharmacy, isNotEmpty);
      expect(l10n.customer, isNotEmpty);
      expect(l10n.orderNumber, isNotEmpty);
      expect(l10n.eta, isNotEmpty);
      expect(l10n.etaArrival, isNotEmpty);
      expect(l10n.distance, isNotEmpty);
      expect(l10n.duration, isNotEmpty);
      expect(l10n.minutes, isNotEmpty);
      expect(l10n.km, isNotEmpty);

      // Navigation & communication
      expect(l10n.navigate, isNotEmpty);
      expect(l10n.openInMaps, isNotEmpty);
      expect(l10n.call, isNotEmpty);
      expect(l10n.chat, isNotEmpty);
      expect(l10n.sendMessage, isNotEmpty);
      expect(l10n.typeMessage, isNotEmpty);

      // Proof of delivery
      expect(l10n.proofOfDelivery, isNotEmpty);
      expect(l10n.takePhoto, isNotEmpty);
      expect(l10n.signature, isNotEmpty);
      expect(l10n.getSignature, isNotEmpty);
      expect(l10n.clearSignature, isNotEmpty);
      expect(l10n.confirmSignature, isNotEmpty);
      expect(l10n.scanQRCode, isNotEmpty);
      expect(l10n.enterCodeManually, isNotEmpty);
      expect(l10n.confirmationCode, isNotEmpty);

      // Wallet & earnings
      expect(l10n.walletBalance, isNotEmpty);
      expect(l10n.earnings, isNotEmpty);
      expect(l10n.todayEarnings, isNotEmpty);
      expect(l10n.weekEarnings, isNotEmpty);
      expect(l10n.monthEarnings, isNotEmpty);
      expect(l10n.totalEarnings, isNotEmpty);
      expect(l10n.withdraw, isNotEmpty);
      expect(l10n.withdrawFunds, isNotEmpty);
      expect(l10n.withdrawalRequest, isNotEmpty);
      expect(l10n.withdrawalHistory, isNotEmpty);
      expect(l10n.transactionHistory, isNotEmpty);
      expect(l10n.commission, isNotEmpty);
      expect(l10n.bonus, isNotEmpty);
      expect(l10n.penalty, isNotEmpty);

      // History & filters
      expect(l10n.history, isNotEmpty);
      expect(l10n.filters, isNotEmpty);
      expect(l10n.filter, isNotEmpty);
      expect(l10n.sortBy, isNotEmpty);
      expect(l10n.dateRange, isNotEmpty);
      expect(l10n.status, isNotEmpty);
      expect(l10n.all, isNotEmpty);
      expect(l10n.today, isNotEmpty);
      expect(l10n.yesterday, isNotEmpty);
      expect(l10n.thisWeek, isNotEmpty);
      expect(l10n.thisMonth, isNotEmpty);
      expect(l10n.lastMonth, isNotEmpty);
      expect(l10n.custom, isNotEmpty);

      // Delivery statuses
      expect(l10n.pending, isNotEmpty);
      expect(l10n.accepted, isNotEmpty);
      expect(l10n.pickedUp, isNotEmpty);
      expect(l10n.inTransit, isNotEmpty);
      expect(l10n.delivered, isNotEmpty);
      expect(l10n.cancelled, isNotEmpty);
      expect(l10n.failed, isNotEmpty);

      // Export
      expect(l10n.exportReport, isNotEmpty);
      expect(l10n.exportCSV, isNotEmpty);
      expect(l10n.exportPDF, isNotEmpty);
      expect(l10n.shareReport, isNotEmpty);

      // Notifications
      expect(l10n.notifications, isNotEmpty);
      expect(l10n.enableNotifications, isNotEmpty);
      expect(l10n.disableNotifications, isNotEmpty);
      expect(l10n.pushNotifications, isNotEmpty);
      expect(l10n.soundEnabled, isNotEmpty);
      expect(l10n.vibrationEnabled, isNotEmpty);

      // Language & theme
      expect(l10n.language, isNotEmpty);
      expect(l10n.french, isNotEmpty);
      expect(l10n.english, isNotEmpty);
      expect(l10n.theme, isNotEmpty);
      expect(l10n.lightTheme, isNotEmpty);
      expect(l10n.darkTheme, isNotEmpty);
      expect(l10n.systemTheme, isNotEmpty);

      // Account & profile
      expect(l10n.account, isNotEmpty);
      expect(l10n.personalInfo, isNotEmpty);
      expect(l10n.editProfile, isNotEmpty);
      expect(l10n.changePassword, isNotEmpty);
      expect(l10n.currentPassword, isNotEmpty);
      expect(l10n.newPassword, isNotEmpty);
      expect(l10n.confirmPassword, isNotEmpty);

      // Vehicle
      expect(l10n.vehicleInfo, isNotEmpty);
      expect(l10n.vehicleType, isNotEmpty);
      expect(l10n.motorcycle, isNotEmpty);
      expect(l10n.car, isNotEmpty);
      expect(l10n.bicycle, isNotEmpty);
      expect(l10n.licensePlate, isNotEmpty);

      // Documents
      expect(l10n.documents, isNotEmpty);
      expect(l10n.idCard, isNotEmpty);
      expect(l10n.drivingLicense, isNotEmpty);
      expect(l10n.vehicleRegistration, isNotEmpty);
      expect(l10n.insurance, isNotEmpty);
      expect(l10n.uploadDocument, isNotEmpty);

      // Support
      expect(l10n.support, isNotEmpty);
      expect(l10n.helpCenter, isNotEmpty);
      expect(l10n.faq, isNotEmpty);
      expect(l10n.contactSupport, isNotEmpty);
      expect(l10n.reportProblem, isNotEmpty);
      expect(l10n.myTickets, isNotEmpty);

      // About
      expect(l10n.about, isNotEmpty);
      expect(l10n.version, isNotEmpty);
      expect(l10n.termsOfService, isNotEmpty);
      expect(l10n.privacyPolicy, isNotEmpty);
      expect(l10n.appVersion, isNotEmpty);

      // Gamification
      expect(l10n.gamification, isNotEmpty);
      expect(l10n.level, isNotEmpty);
      expect(l10n.xp, isNotEmpty);
      expect(l10n.xpPoints, isNotEmpty);
      expect(l10n.badges, isNotEmpty);
      expect(l10n.leaderboard, isNotEmpty);
      expect(l10n.rank, isNotEmpty);
      expect(l10n.weeklyRank, isNotEmpty);
      expect(l10n.monthlyRank, isNotEmpty);
      expect(l10n.allTimeRank, isNotEmpty);
      expect(l10n.unlocked, isNotEmpty);
      expect(l10n.locked, isNotEmpty);
      expect(l10n.progress, isNotEmpty);
      expect(l10n.rewards, isNotEmpty);

      // Battery
      expect(l10n.battery, isNotEmpty);
      expect(l10n.batterySaver, isNotEmpty);
      expect(l10n.batterySaverMode, isNotEmpty);
      expect(l10n.batteryCritical, isNotEmpty);
      expect(l10n.batteryLow, isNotEmpty);
      expect(l10n.batteryNormal, isNotEmpty);
      expect(l10n.charging, isNotEmpty);

      // Tutorial
      expect(l10n.tutorial, isNotEmpty);
      expect(l10n.tutorials, isNotEmpty);
      expect(l10n.skipTutorial, isNotEmpty);
      expect(l10n.nextStep, isNotEmpty);
      expect(l10n.previousStep, isNotEmpty);
      expect(l10n.finish, isNotEmpty);
      expect(l10n.resetTutorials, isNotEmpty);

      // Live tracking
      expect(l10n.liveTracking, isNotEmpty);
      expect(l10n.shareLocation, isNotEmpty);
      expect(l10n.stopSharing, isNotEmpty);
      expect(l10n.trackingActive, isNotEmpty);
      expect(l10n.trackingInactive, isNotEmpty);
      expect(l10n.copyLink, isNotEmpty);
      expect(l10n.linkCopied, isNotEmpty);
      expect(l10n.shareWith, isNotEmpty);

      // Common actions & states
      expect(l10n.error, isNotEmpty);
      expect(l10n.success, isNotEmpty);
      expect(l10n.warning, isNotEmpty);
      expect(l10n.info, isNotEmpty);
      expect(l10n.loading, isNotEmpty);
      expect(l10n.retry, isNotEmpty);
      expect(l10n.cancel, isNotEmpty);
      expect(l10n.confirm, isNotEmpty);
      expect(l10n.save, isNotEmpty);
      expect(l10n.delete, isNotEmpty);
      expect(l10n.edit, isNotEmpty);
      expect(l10n.close, isNotEmpty);
      expect(l10n.done, isNotEmpty);
      expect(l10n.ok, isNotEmpty);
      expect(l10n.yes, isNotEmpty);
      expect(l10n.no, isNotEmpty);
      expect(l10n.back, isNotEmpty);
      expect(l10n.next, isNotEmpty);
      expect(l10n.submit, isNotEmpty);
      expect(l10n.search, isNotEmpty);
      expect(l10n.noResults, isNotEmpty);
      expect(l10n.tryAgain, isNotEmpty);

      // Errors & network
      expect(l10n.networkError, isNotEmpty);
      expect(l10n.noInternet, isNotEmpty);
      expect(l10n.serverError, isNotEmpty);
      expect(l10n.sessionExpired, isNotEmpty);
      expect(l10n.pleaseLogin, isNotEmpty);
      expect(l10n.somethingWentWrong, isNotEmpty);
      expect(l10n.offlineMode, isNotEmpty);
      expect(l10n.offlineModeEnabled, isNotEmpty);
      expect(l10n.backOnline, isNotEmpty);
      expect(l10n.errorOccurredRetry, isNotEmpty);
      expect(l10n.connectionTimeout, isNotEmpty);
      expect(l10n.connectionTimeoutCheck, isNotEmpty);
      expect(l10n.requestCancelled, isNotEmpty);
      expect(l10n.securityError, isNotEmpty);
      expect(l10n.unexpectedError, isNotEmpty);
      expect(l10n.slowConnection, isNotEmpty);
      expect(l10n.slowUpload, isNotEmpty);
      expect(l10n.serverTimeout, isNotEmpty);
      expect(l10n.cannotConnectServer, isNotEmpty);
      expect(l10n.noInternetConnection, isNotEmpty);
      expect(l10n.unknownConnectionError, isNotEmpty);
      expect(l10n.serverCommunicationError, isNotEmpty);
      expect(l10n.invalidRequest, isNotEmpty);
      expect(l10n.accessDenied, isNotEmpty);
      expect(l10n.resourceNotFound, isNotEmpty);
      expect(l10n.timeoutRetry, isNotEmpty);
      expect(l10n.dataConflict, isNotEmpty);
      expect(l10n.invalidData, isNotEmpty);
      expect(l10n.tooManyRequests, isNotEmpty);
      expect(l10n.internalServerError, isNotEmpty);
      expect(l10n.serviceUnavailable, isNotEmpty);

      // Misc
      expect(l10n.fcfa, isNotEmpty);
      expect(l10n.currency, isNotEmpty);
      expect(l10n.locationPermission, isNotEmpty);
      expect(l10n.locationPermissionRequired, isNotEmpty);
      expect(l10n.enableLocation, isNotEmpty);
      expect(l10n.backgroundLocation, isNotEmpty);
      expect(l10n.camera, isNotEmpty);
      expect(l10n.gallery, isNotEmpty);
      expect(l10n.chooseSource, isNotEmpty);
      expect(l10n.estimatedDuration, isNotEmpty);

      // Geofence & arrival
      expect(l10n.arrivedAtPharmacy, isNotEmpty);
      expect(l10n.arrivedAtClient, isNotEmpty);
      expect(l10n.arrivedAtDestination, isNotEmpty);
      expect(l10n.pickupPoint, isNotEmpty);
      expect(l10n.deliveryPoint, isNotEmpty);
      expect(l10n.pullToRefresh, isNotEmpty);
      expect(l10n.noDeliveriesFound, isNotEmpty);
      expect(l10n.geofenceNotificationHint, isNotEmpty);

      // Verification
      expect(l10n.verificationSuccess, isNotEmpty);
      expect(l10n.selfieCaptured, isNotEmpty);
      expect(l10n.imageTooSmall, isNotEmpty);
      expect(l10n.registrationSuccess, isNotEmpty);
      expect(l10n.registrationPending, isNotEmpty);

      // Quick messages
      expect(l10n.quickMessage, isNotEmpty);
      expect(l10n.enRouteToPharmacy, isNotEmpty);
      expect(l10n.arrivedAtPharmacyMsg, isNotEmpty);
      expect(l10n.isOrderReady, isNotEmpty);
      expect(l10n.cannotFindAddress, isNotEmpty);
      expect(l10n.arrivingInFiveMin, isNotEmpty);
      expect(l10n.atYourBuilding, isNotEmpty);
      expect(l10n.pleaseComeDown, isNotEmpty);
      expect(l10n.cannotFindYourAddress, isNotEmpty);
      expect(l10n.customerNotResponding, isNotEmpty);
      expect(l10n.phoneNumberUnavailable, isNotEmpty);

      // Onboarding
      expect(l10n.onboardingTitle1, isNotEmpty);
      expect(l10n.onboardingDesc1, isNotEmpty);
      expect(l10n.onboardingTitle2, isNotEmpty);
      expect(l10n.onboardingDesc2, isNotEmpty);
      expect(l10n.onboardingTitle3, isNotEmpty);
      expect(l10n.onboardingDesc3, isNotEmpty);
      expect(l10n.getStarted, isNotEmpty);
      expect(l10n.skip, isNotEmpty);

      // Login screen
      expect(l10n.biometricAuthReason, isNotEmpty);
      expect(l10n.loginWithCredentialsFirst, isNotEmpty);
      expect(l10n.pleaseEnterPhoneNumber, isNotEmpty);
      expect(l10n.connectionFailed, isNotEmpty);
      expect(l10n.incorrectCredentials, isNotEmpty);
      expect(l10n.checkEmailAndPassword, isNotEmpty);
      expect(l10n.resetPassword, isNotEmpty);
      expect(l10n.resetPasswordPhoneDesc, isNotEmpty);
      expect(l10n.resetPasswordEmailDesc, isNotEmpty);
      expect(l10n.phoneNumber, isNotEmpty);
      expect(l10n.phoneHint, isNotEmpty);
      expect(l10n.emailAddress, isNotEmpty);
      expect(l10n.emailHint, isNotEmpty);
      expect(l10n.pleaseEnterEmail, isNotEmpty);
      expect(l10n.invalidEmail, isNotEmpty);
      expect(l10n.resetLinkSent, isNotEmpty);
      expect(l10n.sendOtpCode, isNotEmpty);
      expect(l10n.sendLink, isNotEmpty);
      expect(l10n.courierSpace, isNotEmpty);
      expect(l10n.loginSubtitle, isNotEmpty);
      expect(l10n.emailOrPhone, isNotEmpty);
      expect(l10n.fieldRequired, isNotEmpty);
      expect(l10n.sendCode, isNotEmpty);
      expect(l10n.signInButton, isNotEmpty);
      expect(l10n.or, isNotEmpty);
      expect(l10n.biometricLogin, isNotEmpty);
      expect(l10n.noAccountYet, isNotEmpty);
      expect(l10n.becomeCourier, isNotEmpty);
      expect(l10n.secure, isNotEmpty);
      expect(l10n.certified, isNotEmpty);
      expect(l10n.support247, isNotEmpty);

      // Parameterized keys
      expect(l10n.biometricError('test'), contains('test'));
      expect(l10n.versionLabel('2.0.0'), contains('2.0.0'));
      expect(
        l10n.cannotLaunchNavigation('Google Maps'),
        contains('Google Maps'),
      );
      expect(l10n.cannotCall('+2250101'), contains('+2250101'));
      expect(l10n.estimatedDurationMinutes(30), contains('30'));
      expect(l10n.deliveriesCount(0), isNotEmpty);
      expect(l10n.deliveriesCount(1), isNotEmpty);
      expect(l10n.deliveriesCount(10), contains('10'));
      expect(l10n.earningsAmount('10000'), contains('10000'));
      expect(l10n.greeting('Alice'), contains('Alice'));
      expect(l10n.levelUp(5), contains('5'));
      expect(l10n.approachingPharmacy('TestPharm'), contains('TestPharm'));
      expect(l10n.approachingClient('Bob'), contains('Bob'));
      expect(l10n.verificationFailed('error'), contains('error'));
    });

    testWidgets('supportedLocales includes fr and en', (tester) async {
      expect(
        AppLocalizations.supportedLocales,
        containsAll([const Locale('fr'), const Locale('en')]),
      );
    });

    testWidgets('localizationsDelegates provides all required delegates', (
      tester,
    ) async {
      expect(AppLocalizations.localizationsDelegates, isNotEmpty);
      expect(
        AppLocalizations.localizationsDelegates.length,
        greaterThanOrEqualTo(
          3,
        ), // AppLocalizations + Material + Cupertino at minimum
      );
    });
  });
}
