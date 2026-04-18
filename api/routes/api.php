<?php

use App\Http\Controllers\Admin\CourierAssignmentController;
use App\Http\Controllers\Api\Auth\LoginController;
use App\Http\Controllers\Api\Auth\RegisterController;
use App\Http\Controllers\Api\Auth\SocialAuthController;
use App\Http\Controllers\Api\Customer\OrderController as CustomerOrderController;
use App\Http\Controllers\Api\Customer\PharmacyController;
use App\Http\Controllers\Api\Customer\PrescriptionController;
use App\Http\Controllers\Api\Pharmacy\OrderController as PharmacyOrderController;
use App\Http\Controllers\Api\Pharmacy\InventoryController;
use App\Http\Controllers\Api\Courier\DeliveryController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\SupportController;
use App\Http\Controllers\Api\WebhookController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Webhooks (no auth required, rate limited by IP)
Route::middleware('throttle:webhook')->group(function () {
    Route::post('/webhooks/jeko', [\App\Http\Controllers\Api\JekoWebhookController::class, 'handle'])->name('webhooks.jeko');
    Route::get('/webhooks/jeko/health', [\App\Http\Controllers\Api\JekoWebhookController::class, 'health']);

    // Infobip webhooks (WhatsApp + SMS) - Protected by signature/IP verification
    Route::middleware(\App\Http\Middleware\VerifyInfobipWebhook::class)->group(function () {
        // WhatsApp Infobip webhooks
        Route::post('/webhooks/whatsapp/delivery', [\App\Http\Controllers\Api\WhatsAppWebhookController::class, 'deliveryReport'])->name('webhooks.whatsapp.delivery');
        Route::post('/webhooks/whatsapp/incoming', [\App\Http\Controllers\Api\WhatsAppWebhookController::class, 'incomingMessage'])->name('webhooks.whatsapp.incoming');

        // SMS Infobip webhooks
        Route::post('/webhooks/sms/delivery', [\App\Http\Controllers\Api\SmsWebhookController::class, 'deliveryReport'])->name('webhooks.sms.delivery');
        Route::post('/webhooks/sms/incoming', [\App\Http\Controllers\Api\SmsWebhookController::class, 'incomingMessage'])->name('webhooks.sms.incoming');
    });
});

// JEKO Payment Callbacks (no auth required - redirect from JEKO)
Route::get('/payments/callback/success', [\App\Http\Controllers\Api\JekoPaymentController::class, 'callbackSuccess']);
Route::get('/payments/callback/error', [\App\Http\Controllers\Api\JekoPaymentController::class, 'callbackError']);

// SANDBOX: Route pour confirmer un paiement en mode test (sans vraie passerelle JEKO)
// SECURITY: Cette route n'est disponible qu'en environnement local/testing
if (app()->environment('local', 'testing')) {
    Route::get('/payments/sandbox/confirm', [\App\Http\Controllers\Api\JekoPaymentController::class, 'sandboxConfirm']);
}

// App Version Check & Feature Flags (public - apps need to check on startup)
Route::middleware('throttle:public')->prefix('app')->group(function () {
    Route::get('/version-check', [\App\Http\Controllers\Api\AppVersionController::class, 'check']);
    Route::get('/features', [\App\Http\Controllers\Api\AppVersionController::class, 'features']);
});

// Public Data Routes (rate limited for public access)
Route::middleware('throttle:public')->group(function () {
    Route::get('/duty-zones', [\App\Http\Controllers\Api\Pharmacy\DutyZoneController::class, 'index']);
    Route::get('/duty-zones/{id}', [\App\Http\Controllers\Api\Pharmacy\DutyZoneController::class, 'show']);
    
    // Delivery Fee Estimation (public - customers need to see prices before ordering)
    Route::get('/delivery/pricing', [\App\Http\Controllers\Api\DeliveryPricingController::class, 'getPricing']);
    Route::post('/delivery/estimate', [\App\Http\Controllers\Api\DeliveryPricingController::class, 'estimate']);
    
    // Pricing & Fees (public - customers need to see all fees before ordering)
    Route::get('/pricing', [\App\Http\Controllers\Api\PricingController::class, 'index']);
    Route::post('/pricing/calculate', [\App\Http\Controllers\Api\PricingController::class, 'calculate']);
    Route::post('/pricing/delivery', [\App\Http\Controllers\Api\PricingController::class, 'estimateDelivery']);
    
    // Support Settings (public - apps need contact info)
    Route::get('/support/settings', [\App\Http\Controllers\Api\SupportSettingsController::class, 'index']);
    Route::get('/support/faq/courier', [\App\Http\Controllers\Api\SupportSettingsController::class, 'courierFaq']);
    Route::get('/support/faq/customer', [\App\Http\Controllers\Api\SupportSettingsController::class, 'customerFaq']);
});

// Public Pharmacies routes (no auth required - customers can browse)
Route::prefix('customer/pharmacies')->middleware('throttle:search')->group(function () {
    Route::get('/', [PharmacyController::class, 'index']);
    Route::get('/nearby', [PharmacyController::class, 'nearby']);
    Route::get('/on-duty', [PharmacyController::class, 'onDuty']);
    Route::get('/featured', [PharmacyController::class, 'featured']);
    Route::get('/{id}', [PharmacyController::class, 'show'])->where('id', '[0-9]+');
    Route::get('/{id}/ratings', [\App\Http\Controllers\Api\Customer\RatingController::class, 'pharmacyRatings'])->where('id', '[0-9]+');
});

// Public Product routes (no auth required - customers can browse)
// Rate limited for search operations
Route::prefix('products')->middleware('throttle:search')->group(function () {
    Route::get('/', [ProductController::class, 'index']);
    Route::get('/featured', [ProductController::class, 'featured']);
    Route::get('/categories', [ProductController::class, 'categories']);
    Route::get('/category/{category}', [ProductController::class, 'byCategory']);
    Route::get('/search', [ProductController::class, 'search']);
    Route::get('/{id}', [ProductController::class, 'show'])->where('id', '[0-9]+');
    Route::get('/{id}/compare-prices', [ProductController::class, 'comparePrices'])->where('id', '[0-9]+');
    Route::get('/{id}/reviews', [\App\Http\Controllers\Api\ProductReviewController::class, 'index'])->where('id', '[0-9]+');
    Route::get('/slug/{slug}', [ProductController::class, 'showBySlug']);
});

// Authentication routes with rate limiting for security
Route::prefix('auth')->group(function () {
    // Auth routes - strict rate limiting (5 attempts per minute)
    Route::middleware('throttle:auth')->group(function () {
        Route::post('/register', [RegisterController::class, 'register']);
        Route::post('/register/courier', [RegisterController::class, 'registerCourier']);
        Route::post('/register/pharmacy', [RegisterController::class, 'registerPharmacy']);
        Route::post('/login', [LoginController::class, 'login']);
        Route::post('/social-google', [SocialAuthController::class, 'loginWithGoogle']);
    });
    
    // OTP verification - very strict (3 attempts per minute)
    Route::middleware('throttle:otp')->group(function () {
        Route::post('/verify', [\App\Http\Controllers\Api\Auth\VerificationController::class, 'verify']);
        Route::post('/verify-firebase', [\App\Http\Controllers\Api\Auth\VerificationController::class, 'verifyWithFirebase']);
        Route::post('/verify-reset-otp', [\App\Http\Controllers\Api\Auth\PasswordResetController::class, 'verifyResetOtp']);
    });
    
    // OTP sending - limited to prevent SMS spam
    Route::middleware('throttle:otp-send')->group(function () {
        Route::post('/resend', [\App\Http\Controllers\Api\Auth\VerificationController::class, 'resend']);
        Route::post('/forgot-password', [\App\Http\Controllers\Api\Auth\PasswordResetController::class, 'forgotPassword']);
    });
    
    // Password reset - strict
    Route::middleware('throttle:password-reset')->group(function () {
        Route::post('/reset-password', [\App\Http\Controllers\Api\Auth\PasswordResetController::class, 'resetPassword']);
    });
    
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/logout', [LoginController::class, 'logout']);
        Route::get('/me', [LoginController::class, 'me']);
        Route::post('/me/update', [LoginController::class, 'updateProfile']);
        Route::post('/avatar', [LoginController::class, 'uploadAvatar']);
        Route::delete('/avatar', [LoginController::class, 'deleteAvatar']);
        Route::post('/password', [\App\Http\Controllers\Api\Auth\PasswordResetController::class, 'updatePassword']);
        Route::get('/sessions', [LoginController::class, 'sessions']);
        Route::post('/sessions/revoke-others', [LoginController::class, 'revokeOtherSessions']);
        Route::get('/firebase-token', [LoginController::class, 'refreshFirebaseToken']);
    });
});

// Liveness Detection (Active KYC Verification)
// SECURITY: Requires auth + throttle to prevent abuse
Route::prefix('liveness')->middleware(['auth:sanctum', 'throttle:liveness'])->group(function () {
    Route::post('/start', [\App\Http\Controllers\Api\LivenessController::class, 'start']);
    Route::post('/validate', [\App\Http\Controllers\Api\LivenessController::class, 'validate']);
    Route::post('/validate/file', [\App\Http\Controllers\Api\LivenessController::class, 'validateWithFile']);
    Route::get('/status/{sessionId}', [\App\Http\Controllers\Api\LivenessController::class, 'status']);
    Route::get('/score/{sessionId}', [\App\Http\Controllers\Api\LivenessController::class, 'score']);
    Route::get('/history', [\App\Http\Controllers\Api\LivenessController::class, 'history']);
    Route::delete('/cancel/{sessionId}', [\App\Http\Controllers\Api\LivenessController::class, 'cancel']);
    Route::get('/diagnostics', [\App\Http\Controllers\Api\LivenessController::class, 'diagnostics']);
});

// Protected routes
Route::middleware(['auth:sanctum', 'password.changed'])->group(function () {
    
    // KYC Routes for couriers (doesn't require courier middleware - allows incomplete KYC status)
    Route::prefix('courier/kyc')->group(function () {
        Route::get('/status', [\App\Http\Controllers\Api\Courier\KycController::class, 'status']);
        Route::post('/resubmit', [\App\Http\Controllers\Api\Courier\KycController::class, 'resubmit']);
    });
    
    // Secure Document Access
    Route::prefix('documents')->group(function () {
        Route::get('/{type}/{filename}', [\App\Http\Controllers\Api\SecureDocumentController::class, 'serve'])
            ->name('secure.document')
            ->where('filename', '.*');
        Route::get('/{type}/{filename}/url', [\App\Http\Controllers\Api\SecureDocumentController::class, 'getTemporaryUrl'])
            ->where('filename', '.*');
    });
    
    // Notifications (for all authenticated users)
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::get('/unread', [NotificationController::class, 'unread']);
        Route::get('/sounds', [NotificationController::class, 'getSoundSettings']);
        Route::post('/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::post('/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::post('/fcm-token', [NotificationController::class, 'updateFcmToken']);
        Route::delete('/fcm-token', [NotificationController::class, 'removeFcmToken']);
        Route::get('/preferences', [NotificationController::class, 'getPreferences']);
        Route::put('/preferences', [NotificationController::class, 'updatePreferences']);
        Route::delete('/{id}', [NotificationController::class, 'destroy']);
    });
    
    // Support Tickets (for all authenticated users)
    Route::prefix('support')->group(function () {
        Route::get('/tickets', [SupportController::class, 'index']);
        Route::post('/tickets', [SupportController::class, 'store']);
        Route::get('/tickets/stats', [SupportController::class, 'stats']);
        Route::get('/tickets/{ticket}', [SupportController::class, 'show']);
        Route::post('/tickets/{ticket}/messages', [SupportController::class, 'sendMessage']);
        Route::post('/tickets/{ticket}/resolve', [SupportController::class, 'resolve']);
        Route::post('/tickets/{ticket}/close', [SupportController::class, 'close']);
    });
    
    // Customer routes - Nécessite rôle customer, téléphone vérifié pour les actions sensibles
    Route::prefix('customer')->middleware('role:customer')->group(function () {
        // Addresses - Gestion des adresses de livraison
        Route::prefix('addresses')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\Customer\AddressController::class, 'index']);
            Route::get('/labels', [\App\Http\Controllers\Api\Customer\AddressController::class, 'getLabels']);
            Route::get('/default', [\App\Http\Controllers\Api\Customer\AddressController::class, 'getDefault']);
            Route::get('/{id}', [\App\Http\Controllers\Api\Customer\AddressController::class, 'show']);
            Route::post('/', [\App\Http\Controllers\Api\Customer\AddressController::class, 'store']);
            Route::put('/{id}', [\App\Http\Controllers\Api\Customer\AddressController::class, 'update']);
            Route::delete('/{id}', [\App\Http\Controllers\Api\Customer\AddressController::class, 'destroy']);
            Route::post('/{id}/default', [\App\Http\Controllers\Api\Customer\AddressController::class, 'setDefault']);
        });
        
        // Orders - Lecture seule
        Route::get('/orders', [CustomerOrderController::class, 'index']);
        Route::get('/orders/{id}', [CustomerOrderController::class, 'show']);
        Route::get('/orders/{id}/delivery-waiting-status', [CustomerOrderController::class, 'deliveryWaitingStatus']);
        
        // Ratings
        Route::get('/orders/{id}/rating', [\App\Http\Controllers\Api\Customer\RatingController::class, 'show']);
        Route::post('/orders/{id}/rate', [\App\Http\Controllers\Api\Customer\RatingController::class, 'store']);
        
        // Product Reviews (authenticated - must have purchased)
        Route::post('/products/{id}/reviews', [\App\Http\Controllers\Api\ProductReviewController::class, 'store'])->where('id', '[0-9]+');
        
        // Loyalty Program
        Route::prefix('loyalty')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\Customer\LoyaltyController::class, 'index']);
            Route::post('/redeem', [\App\Http\Controllers\Api\Customer\LoyaltyController::class, 'redeem']);
            Route::get('/history', [\App\Http\Controllers\Api\Customer\LoyaltyController::class, 'history']);
        });
        
        // Chat avec le livreur (via delivery) - SECURITY: Rate limiting anti-spam
        Route::prefix('deliveries/{delivery}/chat')->middleware('throttle:chat')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\ChatController::class, 'getMessages']);
            Route::post('/', [\App\Http\Controllers\Api\ChatController::class, 'sendMessage']);
            Route::get('/unread', [\App\Http\Controllers\Api\ChatController::class, 'getUnreadCount']);
            Route::post('/read', [\App\Http\Controllers\Api\ChatController::class, 'markAllAsRead']);
            Route::get('/participants', [\App\Http\Controllers\Api\ChatController::class, 'getParticipants']);
            Route::delete('/messages/{message}', [\App\Http\Controllers\Api\ChatController::class, 'deleteMessage']);
        });

        // Chat via order ID (résout la delivery automatiquement) - pour les cas où deliveryId n'est pas connu côté client
        Route::prefix('orders/{order}/chat')->middleware('throttle:chat')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\ChatController::class, 'getMessagesByOrder']);
            Route::post('/', [\App\Http\Controllers\Api\ChatController::class, 'sendMessageByOrder']);
        });
        
        // Orders - Actions sensibles nécessitent téléphone vérifié et rate limiting
        Route::middleware(['verified.phone', 'throttle:orders', 'idempotent'])->group(function () {
            Route::post('/orders', [CustomerOrderController::class, 'store']);
            Route::post('/orders/{id}/cancel', [CustomerOrderController::class, 'cancel']);
        });
        
        // Payment - Rate limiting strict + idempotency
        Route::middleware(['verified.phone', 'throttle:payment', 'idempotent'])->group(function () {
            Route::post('/orders/{id}/payment/initiate', [CustomerOrderController::class, 'initiatePayment']);
        });
        
        // Prescriptions - Lecture
        Route::get('/prescriptions', [PrescriptionController::class, 'index']);
        Route::get('/prescriptions/{id}', [PrescriptionController::class, 'show']);
        
        // Prescriptions - Upload nécessite téléphone vérifié et rate limiting
        Route::middleware(['verified.phone', 'throttle:uploads'])->group(function () {
            Route::post('/prescriptions/upload', [PrescriptionController::class, 'upload']);
            Route::post('/prescriptions/ocr', [PrescriptionController::class, 'ocr']);
            Route::post('/prescriptions/check-duplicate', [PrescriptionController::class, 'checkDuplicate']);
        });
        
        // Prescription payment - rate limiting strict
        Route::middleware(['verified.phone', 'throttle:payment'])->group(function () {
            Route::post('/prescriptions/{id}/pay', [PrescriptionController::class, 'pay']);
        });

        // Promo Codes - Validation
        Route::post('/promo-codes/validate', [\App\Http\Controllers\Api\PromoCodeController::class, 'validate']);

        // Refunds - Demandes de remboursement
        Route::prefix('refunds')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\RefundController::class, 'index']);
            Route::get('/{id}', [\App\Http\Controllers\Api\RefundController::class, 'show']);
            Route::post('/', [\App\Http\Controllers\Api\RefundController::class, 'store'])->middleware('throttle:10,1');
        });

        // Wallet
        Route::prefix('wallet')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\Customer\WalletController::class, 'index']);
            Route::get('/transactions', [\App\Http\Controllers\Api\Customer\WalletController::class, 'transactions']);
            Route::middleware(['verified.phone', 'throttle:payment', 'idempotent'])->group(function () {
                Route::post('/topup', [\App\Http\Controllers\Api\Customer\WalletController::class, 'topUp']);
                Route::post('/withdraw', [\App\Http\Controllers\Api\Customer\WalletController::class, 'withdraw']);
                Route::post('/pay-order', [\App\Http\Controllers\Api\Customer\WalletController::class, 'payOrder']);
            });
        });

        // JEKO Payments - Customer
        Route::post('/payments/initiate', [\App\Http\Controllers\Api\JekoPaymentController::class, 'initiate'])
            ->middleware(['verified.phone', 'throttle:10,1', 'idempotent']);
        Route::get('/payments', [\App\Http\Controllers\Api\JekoPaymentController::class, 'index']);
        Route::get('/payments/methods', [\App\Http\Controllers\Api\JekoPaymentController::class, 'methods']);
        Route::get('/payments/{reference}/status', [\App\Http\Controllers\Api\JekoPaymentController::class, 'status']);
    });
    
    // Pharmacy routes - Nécessite rôle pharmacy
    Route::prefix('pharmacy')->middleware('role:pharmacy')->group(function () {
        // Pharmacy Profile
        Route::get('/profile', [\App\Http\Controllers\Api\Pharmacy\PharmacyProfileController::class, 'index']);
        Route::put('/profile/{id}', [\App\Http\Controllers\Api\Pharmacy\PharmacyProfileController::class, 'update']);
        Route::post('/profile/{id}', [\App\Http\Controllers\Api\Pharmacy\PharmacyProfileController::class, 'update']);

        // Delivery Zones
        Route::get('/delivery-zone', [\App\Http\Controllers\Api\Pharmacy\DeliveryZoneController::class, 'show']);
        Route::post('/delivery-zone', [\App\Http\Controllers\Api\Pharmacy\DeliveryZoneController::class, 'store']);
        Route::delete('/delivery-zone', [\App\Http\Controllers\Api\Pharmacy\DeliveryZoneController::class, 'destroy']);

        // Orders
        Route::get('/orders', [PharmacyOrderController::class, 'index']);
        Route::get('/orders/{id}', [PharmacyOrderController::class, 'show']);
        Route::post('/orders/{id}/confirm', [PharmacyOrderController::class, 'confirm']);
        Route::post('/orders/{id}/ready', [PharmacyOrderController::class, 'ready']);
        Route::post('/orders/{id}/delivered', [PharmacyOrderController::class, 'delivered']);
        Route::post('/orders/{id}/reject', [PharmacyOrderController::class, 'reject']);
        Route::post('/orders/{id}/notes', [PharmacyOrderController::class, 'addNotes']);
        Route::get('/orders/{id}/delivery-waiting-status', [PharmacyOrderController::class, 'deliveryWaitingStatus']);
        Route::post('/orders/{id}/rate-courier', [PharmacyOrderController::class, 'rateCourier']);

        // Inventory
        Route::get('/inventory/categories', [InventoryController::class, 'categories']);
        Route::post('/inventory/categories', [InventoryController::class, 'storeCategory']); // Add Category
        Route::put('/inventory/categories/{id}', [InventoryController::class, 'updateCategory']); // Update Category
        Route::delete('/inventory/categories/{id}', [InventoryController::class, 'deleteCategory']); // Delete Category
        Route::get('/inventory', [InventoryController::class, 'index']);
        Route::post('/inventory', [InventoryController::class, 'store']); // Create new product
        Route::post('/inventory/{id}/update', [InventoryController::class, 'update']); // Update product (POST for files)
        Route::delete('/inventory/{id}', [InventoryController::class, 'destroy']); // Delete product
        
        // Inventory Item Actions
        Route::post('/inventory/{id}/stock', [InventoryController::class, 'updateStock']);
        Route::post('/inventory/{id}/price', [InventoryController::class, 'updatePrice']);
        Route::post('/inventory/{id}/toggle-status', [InventoryController::class, 'toggleStatus']);
        Route::post('/inventory/{id}/promotion', [InventoryController::class, 'applyPromotion']);
        Route::delete('/inventory/{id}/promotion', [InventoryController::class, 'removePromotion']);
        Route::post('/inventory/{id}/loss', [InventoryController::class, 'markAsLoss']);

        // Prescriptions
        Route::get('/prescriptions', [\App\Http\Controllers\Api\Pharmacy\PrescriptionController::class, 'index']);
        Route::get('/prescriptions/{id}', [\App\Http\Controllers\Api\Pharmacy\PrescriptionController::class, 'show']);
        Route::post('/prescriptions/{id}/status', [\App\Http\Controllers\Api\Pharmacy\PrescriptionController::class, 'updateStatus']);
        Route::post('/prescriptions/{id}/analyze', [\App\Http\Controllers\Api\Pharmacy\PrescriptionController::class, 'analyze']);
        Route::post('/prescriptions/{id}/dispense', [\App\Http\Controllers\Api\Pharmacy\PrescriptionController::class, 'dispense']);
        Route::get('/prescriptions/{id}/dispensing-history', [\App\Http\Controllers\Api\Pharmacy\PrescriptionController::class, 'dispensingHistory']);
        Route::get('/prescriptions-stats/analysis', [\App\Http\Controllers\Api\Pharmacy\PrescriptionController::class, 'analysisStats']);

        // Wallet
        Route::get('/wallet', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'index']);
        Route::get('/wallet/stats', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'stats']);
        Route::post('/wallet/withdraw', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'withdraw'])->middleware('idempotent');
        Route::post('/wallet/bank-info', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'saveBankInfo']);
        Route::post('/wallet/mobile-money', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'saveMobileMoneyInfo']);
        Route::get('/wallet/threshold', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'getWithdrawalSettings']);
        Route::post('/wallet/threshold', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'setWithdrawalThreshold']);
        Route::get('/wallet/export', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'exportTransactions']);
        
        // PIN Security & Payment Info
        Route::get('/wallet/pin-status', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'getPinStatus']);
        Route::post('/wallet/pin/set', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'setPin']);
        Route::post('/wallet/pin/change', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'changePin']);
        Route::post('/wallet/pin/verify', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'verifyPin']);
        Route::post('/wallet/pin/reset-request', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'requestPinReset']);
        Route::post('/wallet/pin/reset-confirm', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'confirmPinReset']);
        Route::get('/wallet/payment-info', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'getPaymentInfo']);
        Route::put('/wallet/bank-info', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'updateBankInfo']);
        Route::put('/wallet/mobile-money', [\App\Http\Controllers\Api\Pharmacy\WalletController::class, 'updateMobileMoneyInfo']);

        // On-Call Management
        Route::get('/on-calls', [\App\Http\Controllers\Api\Pharmacy\OnCallController::class, 'index']);
        Route::post('/on-calls', [\App\Http\Controllers\Api\Pharmacy\OnCallController::class, 'store']);
        Route::put('/on-calls/{id}', [\App\Http\Controllers\Api\Pharmacy\OnCallController::class, 'update']);
        Route::delete('/on-calls/{id}', [\App\Http\Controllers\Api\Pharmacy\OnCallController::class, 'destroy']);

        // Duty Zone self-service (pharmacie crée sa propre zone)
        Route::post('/duty-zones', [\App\Http\Controllers\Api\Pharmacy\DutyZoneController::class, 'storeForPharmacy']);

        // Dashboard Stats
        Route::get('/stats/week', [\App\Http\Controllers\Api\Pharmacy\PharmacyDashboardController::class, 'weekStats']);
        Route::get('/stats/daily', [\App\Http\Controllers\Api\Pharmacy\PharmacyDashboardController::class, 'dailyStats']);

        // Reports & Analytics
        Route::prefix('reports')->group(function () {
            Route::get('/overview', [\App\Http\Controllers\Api\Pharmacy\ReportsController::class, 'overview']);
            Route::get('/sales', [\App\Http\Controllers\Api\Pharmacy\ReportsController::class, 'sales']);
            Route::get('/orders', [\App\Http\Controllers\Api\Pharmacy\ReportsController::class, 'orders']);
            Route::get('/inventory', [\App\Http\Controllers\Api\Pharmacy\ReportsController::class, 'inventory']);
            Route::get('/stock-alerts', [\App\Http\Controllers\Api\Pharmacy\ReportsController::class, 'stockAlerts']);
            Route::get('/export', [\App\Http\Controllers\Api\Pharmacy\ReportsController::class, 'export']);
        });

        // Team Management (Gestion d'équipe multi-utilisateurs)
        Route::prefix('team')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\Pharmacy\TeamController::class, 'index']);
            Route::get('/roles', [\App\Http\Controllers\Api\Pharmacy\TeamController::class, 'availableRoles']);
            Route::post('/invite', [\App\Http\Controllers\Api\Pharmacy\TeamController::class, 'invite']);
            Route::get('/invitations', [\App\Http\Controllers\Api\Pharmacy\TeamController::class, 'pendingInvitations']);
            Route::delete('/invitations/{id}', [\App\Http\Controllers\Api\Pharmacy\TeamController::class, 'cancelInvitation']);
            Route::post('/invitations/accept', [\App\Http\Controllers\Api\Pharmacy\TeamController::class, 'acceptInvitation']);
            Route::put('/members/{id}/role', [\App\Http\Controllers\Api\Pharmacy\TeamController::class, 'updateRole']);
            Route::delete('/members/{id}', [\App\Http\Controllers\Api\Pharmacy\TeamController::class, 'removeMember']);
        });

        // Statement Preferences (Relevés automatiques)
        Route::get('/statement-preferences', [\App\Http\Controllers\Api\Pharmacy\StatementPreferenceController::class, 'show']);
        Route::post('/statement-preferences', [\App\Http\Controllers\Api\Pharmacy\StatementPreferenceController::class, 'store']);
        Route::delete('/statement-preferences', [\App\Http\Controllers\Api\Pharmacy\StatementPreferenceController::class, 'disable']);
        
        // Chat V2 (via delivery) - SECURITY: Rate limiting anti-spam
        Route::prefix('deliveries/{delivery}/chat')->middleware('throttle:chat')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\ChatController::class, 'getMessages']);
            Route::post('/', [\App\Http\Controllers\Api\ChatController::class, 'sendMessage']);
            Route::get('/unread', [\App\Http\Controllers\Api\ChatController::class, 'getUnreadCount']);
            Route::post('/read', [\App\Http\Controllers\Api\ChatController::class, 'markAllAsRead']);
            Route::get('/participants', [\App\Http\Controllers\Api\ChatController::class, 'getParticipants']);
            Route::delete('/messages/{message}', [\App\Http\Controllers\Api\ChatController::class, 'deleteMessage']);
        });

        // Chat Sessions persistantes pharmacie ↔ client
        Route::prefix('chat-sessions')->middleware('throttle:chat')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\Pharmacy\ChatSessionController::class, 'index']);
            Route::post('/', [\App\Http\Controllers\Api\Pharmacy\ChatSessionController::class, 'getOrCreate']);
            Route::prefix('{chatSession}')->group(function () {
                Route::get('/messages', [\App\Http\Controllers\Api\Pharmacy\ChatSessionController::class, 'getMessages']);
                Route::post('/messages', [\App\Http\Controllers\Api\Pharmacy\ChatSessionController::class, 'sendMessage']);
                Route::post('/read', [\App\Http\Controllers\Api\Pharmacy\ChatSessionController::class, 'markAsRead']);
                Route::get('/unread', [\App\Http\Controllers\Api\Pharmacy\ChatSessionController::class, 'unreadCount']);
                Route::patch('/status', [\App\Http\Controllers\Api\Pharmacy\ChatSessionController::class, 'updateStatus']);
            });
        });
    });
    
    // Courier routes - Middleware 'courier' vérifie le profil coursier
    Route::prefix('courier')->middleware('courier')->group(function () {
        Route::get('/profile', [DeliveryController::class, 'profile']);
        Route::post('/profile/update', [DeliveryController::class, 'updateCourierProfile']);
        
        // Wallet
        Route::get('/wallet', [\App\Http\Controllers\Api\Courier\WalletController::class, 'index']);
        Route::post('/wallet/topup', [\App\Http\Controllers\Api\Courier\WalletController::class, 'topUp'])->middleware('idempotent');
        Route::post('/wallet/withdraw', [\App\Http\Controllers\Api\Courier\WalletController::class, 'withdraw'])->middleware('idempotent');
        Route::get('/wallet/can-deliver', [\App\Http\Controllers\Api\Courier\WalletController::class, 'canDeliver']);
        Route::get('/wallet/earnings-history', [\App\Http\Controllers\Api\Courier\WalletController::class, 'earningsHistory']);

        // Statistics
        Route::get('/statistics', [\App\Http\Controllers\Api\Courier\StatisticsController::class, 'index']);
        Route::get('/statistics/leaderboard', [\App\Http\Controllers\Api\Courier\StatisticsController::class, 'leaderboard']);

        // === BROADCAST DISPATCH (Phase 1) - Offres de livraison ===
        Route::get('/offers', [\App\Http\Controllers\Api\Courier\DeliveryOfferController::class, 'index']);
        Route::get('/offers/{id}', [\App\Http\Controllers\Api\Courier\DeliveryOfferController::class, 'show']);
        Route::post('/offers/{id}/accept', [\App\Http\Controllers\Api\Courier\DeliveryOfferController::class, 'accept']);
        Route::post('/offers/{id}/reject', [\App\Http\Controllers\Api\Courier\DeliveryOfferController::class, 'reject']);

        // === SHIFT MANAGEMENT (Phase 6) - Réservation de créneaux ===
        Route::get('/shifts', [\App\Http\Controllers\Api\Courier\ShiftController::class, 'index']);
        Route::get('/shifts/active', [\App\Http\Controllers\Api\Courier\ShiftController::class, 'active']);
        Route::get('/shifts/slots', [\App\Http\Controllers\Api\Courier\ShiftController::class, 'availableSlots']);
        Route::post('/shifts/book', [\App\Http\Controllers\Api\Courier\ShiftController::class, 'book']);
        Route::post('/shifts/{id}/cancel', [\App\Http\Controllers\Api\Courier\ShiftController::class, 'cancel']);
        Route::post('/shifts/{id}/start', [\App\Http\Controllers\Api\Courier\ShiftController::class, 'start']);
        Route::post('/shifts/{id}/end', [\App\Http\Controllers\Api\Courier\ShiftController::class, 'end']);

        // Challenges & Bonuses
        Route::get('/challenges', [\App\Http\Controllers\Api\Courier\ChallengeController::class, 'index']);
        Route::post('/challenges/{id}/claim', [\App\Http\Controllers\Api\Courier\ChallengeController::class, 'claimReward']);
        Route::get('/bonuses', [\App\Http\Controllers\Api\Courier\ChallengeController::class, 'bonuses']);
        Route::post('/bonuses/calculate', [\App\Http\Controllers\Api\Courier\ChallengeController::class, 'calculateBonus']);

        // Gamification (badges, niveaux, classement)
        Route::get('/gamification', [\App\Http\Controllers\Api\Courier\GamificationController::class, 'index']);

        Route::get('/deliveries', [DeliveryController::class, 'index']);
        
        // Batch deliveries & route (must be before {id} route)
        Route::post('/deliveries/batch-accept', [DeliveryController::class, 'batchAccept']);
        Route::get('/deliveries/route', [DeliveryController::class, 'getOptimizedRoute']);
        
        Route::get('/deliveries/{id}', [DeliveryController::class, 'show']);
        Route::post('/deliveries/{id}/accept', [DeliveryController::class, 'accept']);
        Route::post('/deliveries/{id}/reject', [DeliveryController::class, 'reject']); // Nouvelle route de refus
        Route::post('/deliveries/{id}/pickup', [DeliveryController::class, 'pickup']);
        Route::post('/deliveries/{id}/deliver', [DeliveryController::class, 'deliver']);
        Route::post('/deliveries/{id}/proof', [DeliveryController::class, 'uploadProof']); // Photo + signature
        Route::post('/deliveries/{id}/rate-customer', [DeliveryController::class, 'rateCustomer']);
        
        // Minuterie d'attente livraison
        Route::post('/deliveries/{id}/arrived', [DeliveryController::class, 'arrived']);
        Route::get('/deliveries/{id}/waiting-status', [DeliveryController::class, 'waitingStatus']);
        Route::get('/waiting-settings', [DeliveryController::class, 'getWaitingSettings']);
        
        Route::post('/location/update', [DeliveryController::class, 'updateLocation']);
        Route::post('/availability/toggle', [DeliveryController::class, 'toggleAvailability']);
        
        // Chat (Legacy - à déprécier)
        Route::get('/orders/{id}/messages', [\App\Http\Controllers\Api\Courier\ChatController::class, 'index']);
        Route::post('/orders/{id}/messages', [\App\Http\Controllers\Api\Courier\ChatController::class, 'store']);
        
        // Chat V2 (via delivery) - SECURITY: Rate limiting anti-spam
        Route::prefix('deliveries/{delivery}/chat')->middleware('throttle:chat')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\ChatController::class, 'getMessages']);
            Route::post('/', [\App\Http\Controllers\Api\ChatController::class, 'sendMessage']);
            Route::get('/unread', [\App\Http\Controllers\Api\ChatController::class, 'getUnreadCount']);
            Route::post('/read', [\App\Http\Controllers\Api\ChatController::class, 'markAllAsRead']);
            Route::get('/participants', [\App\Http\Controllers\Api\ChatController::class, 'getParticipants']);
            Route::delete('/messages/{message}', [\App\Http\Controllers\Api\ChatController::class, 'deleteMessage']);
        });
        
        // JEKO Payments
        // SECURITY V-003: Rate limiting - max 10 initiations de paiement par minute par utilisateur
        Route::post('/payments/initiate', [\App\Http\Controllers\Api\JekoPaymentController::class, 'initiate'])
            ->middleware(['throttle:10,1', 'idempotent']);
        Route::get('/payments', [\App\Http\Controllers\Api\JekoPaymentController::class, 'index']);
        Route::get('/payments/methods', [\App\Http\Controllers\Api\JekoPaymentController::class, 'methods']);
        Route::get('/payments/{reference}/status', [\App\Http\Controllers\Api\JekoPaymentController::class, 'status']);
        Route::post('/payments/{reference}/cancel', [\App\Http\Controllers\Api\JekoPaymentController::class, 'cancel']);
        
        // Support
        Route::post('/report-problem', [\App\Http\Controllers\Api\Courier\SupportController::class, 'reportProblem']);
    });
    
    // Admin routes - Courier Assignment
    Route::prefix('admin')->middleware(['role:admin', 'audit'])->group(function () {
        // Refunds - workflow approbation
        Route::prefix('refunds')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\Admin\RefundAdminController::class, 'index']);
            Route::post('/{id}/approve', [\App\Http\Controllers\Api\Admin\RefundAdminController::class, 'approve']);
            Route::post('/{id}/reject', [\App\Http\Controllers\Api\Admin\RefundAdminController::class, 'reject']);
            Route::post('/{id}/process', [\App\Http\Controllers\Api\Admin\RefundAdminController::class, 'process']);
        });

        Route::get('/orders/{order}/couriers/available', [CourierAssignmentController::class, 'getAvailableCouriers']);
        Route::post('/orders/{order}/couriers/auto-assign', [CourierAssignmentController::class, 'autoAssign']);
        Route::post('/orders/{order}/couriers/manual-assign', [CourierAssignmentController::class, 'manualAssign']);
        Route::post('/deliveries/{delivery}/reassign', [CourierAssignmentController::class, 'reassign']);
        Route::post('/orders/{order}/estimate-time', [CourierAssignmentController::class, 'estimateDeliveryTime']);

        // Heatmap / Analytics
        Route::get('/heatmap/orders', [\App\Http\Controllers\Api\Admin\OrderHeatmapController::class, 'index']);
        Route::get('/heatmap/pharmacies', [\App\Http\Controllers\Api\Admin\OrderHeatmapController::class, 'pharmacyHeatmap']);

        // Stats & Revenue tracking
        Route::get('/stats/dashboard', [\App\Http\Controllers\Api\Admin\StatsController::class, 'dashboard']);
        Route::get('/stats/revenue', [\App\Http\Controllers\Api\Admin\StatsController::class, 'revenue']);
        Route::get('/stats/today', [\App\Http\Controllers\Api\Admin\StatsController::class, 'today']);
        Route::get('/stats/funnel', [\App\Http\Controllers\Api\Admin\StatsController::class, 'funnel']);
        Route::get('/stats/events', [\App\Http\Controllers\Api\Admin\StatsController::class, 'events']);
        Route::get('/stats/alerts', [\App\Http\Controllers\Api\Admin\StatsController::class, 'alerts']);

        // CSV Exports
        Route::prefix('export')->group(function () {
            Route::get('/orders', [\App\Http\Controllers\Api\Admin\ExportController::class, 'orders']);
            Route::get('/deliveries', [\App\Http\Controllers\Api\Admin\ExportController::class, 'deliveries']);
            Route::get('/revenue', [\App\Http\Controllers\Api\Admin\ExportController::class, 'revenue']);
            Route::get('/pharmacies', [\App\Http\Controllers\Api\Admin\ExportController::class, 'pharmacies']);
            Route::get('/couriers', [\App\Http\Controllers\Api\Admin\ExportController::class, 'couriers']);
        });

        // Audit Trail
        Route::get('/audit-logs', function (\Illuminate\Http\Request $request) {
            $logs = \Illuminate\Support\Facades\DB::table('admin_audit_logs')
                ->orderByDesc('created_at')
                ->when($request->input('user_id'), fn ($q, $id) => $q->where('user_id', $id))
                ->when($request->input('action'), fn ($q, $a) => $q->where('action', $a))
                ->paginate(min($request->input('per_page', 50), 100));

            return response()->json(['success' => true, 'data' => $logs]);
        });
    });
});

// Public health check (no auth required)
Route::get('/health', \App\Http\Controllers\Api\HealthController::class);

// DEBUG: Diagnostic pharmacies — protégé par auth admin
Route::middleware(['auth:sanctum'])->get('/debug/pharmacies-audit', function () {
    // Restreindre aux admins uniquement
    /** @var \App\Models\User|null $user */
    $user = \Illuminate\Support\Facades\Auth::user();
    if (!$user || $user->role !== 'admin') {
        return response()->json(['success' => false, 'message' => 'Accès refusé'], 403);
    }

    $pharmacies = \App\Models\Pharmacy::withCount('products')
        ->withCount(['products as available_products_count' => function ($q) {
            $q->where('is_available', true);
        }])
        ->get(['id', 'name', 'status', 'is_active', 'is_open', 'created_at']);
    
    return response()->json([
        'success' => true,
        'total_pharmacies' => $pharmacies->count(),
        'approved_count' => $pharmacies->where('status', 'approved')->count(),
        'pending_count' => $pharmacies->where('status', 'pending')->count(),
        'rejected_count' => $pharmacies->where('status', 'rejected')->count(),
        'pharmacies' => $pharmacies->map(fn($p) => [
            'id' => $p->id,
            'name' => $p->name,
            'status' => $p->status,
            'is_active' => $p->is_active,
            'is_open' => $p->is_open,
            'total_products' => $p->products_count,
            'available_products' => $p->available_products_count,
            'created_at' => $p->created_at?->toDateTimeString(),
        ]),
    ]);
});

