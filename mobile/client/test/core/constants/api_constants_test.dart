import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/constants/api_constants.dart';

void main() {
  group('ApiConstants', () {
    group('Authentication Endpoints', () {
      test('login endpoint should be /auth/login', () {
        expect(ApiConstants.login, '/auth/login');
      });

      test('register endpoint should be /auth/register', () {
        expect(ApiConstants.register, '/auth/register');
      });

      test('logout endpoint should be /auth/logout', () {
        expect(ApiConstants.logout, '/auth/logout');
      });

      test('profile endpoint should be /auth/me', () {
        expect(ApiConstants.profile, '/auth/me');
      });

      test('me endpoint should be /auth/me', () {
        expect(ApiConstants.me, '/auth/me');
      });

      test('profile and me should be the same', () {
        expect(ApiConstants.profile, ApiConstants.me);
      });

      test('updateProfile endpoint should be /auth/me/update', () {
        expect(ApiConstants.updateProfile, '/auth/me/update');
      });

      test('uploadAvatar endpoint should be /auth/avatar', () {
        expect(ApiConstants.uploadAvatar, '/auth/avatar');
      });

      test('deleteAvatar endpoint should be /auth/avatar', () {
        expect(ApiConstants.deleteAvatar, '/auth/avatar');
      });

      test('updatePassword endpoint should be /auth/password', () {
        expect(ApiConstants.updatePassword, '/auth/password');
      });

      test('forgotPassword endpoint should be /auth/forgot-password', () {
        expect(ApiConstants.forgotPassword, '/auth/forgot-password');
      });

      test('verifyOtp endpoint should be /auth/verify', () {
        expect(ApiConstants.verifyOtp, '/auth/verify');
      });

      test('verifyFirebaseOtp endpoint should be /auth/verify-firebase', () {
        expect(ApiConstants.verifyFirebaseOtp, '/auth/verify-firebase');
      });

      test('resendOtp endpoint should be /auth/resend', () {
        expect(ApiConstants.resendOtp, '/auth/resend');
      });
    });

    group('Products Endpoints', () {
      test('products endpoint should be /products', () {
        expect(ApiConstants.products, '/products');
      });

      test('productDetails should return correct endpoint', () {
        expect(ApiConstants.productDetails(1), '/products/1');
        expect(ApiConstants.productDetails(42), '/products/42');
        expect(ApiConstants.productDetails(999), '/products/999');
      });

      test('searchProducts endpoint should be /products', () {
        expect(ApiConstants.searchProducts, '/products');
      });
    });

    group('Orders Endpoints', () {
      test('orders endpoint should be /customer/orders', () {
        expect(ApiConstants.orders, '/customer/orders');
      });

      test('orderDetails should return correct endpoint', () {
        expect(ApiConstants.orderDetails(1), '/customer/orders/1');
        expect(ApiConstants.orderDetails(100), '/customer/orders/100');
      });

      test('cancelOrder should return correct endpoint', () {
        expect(ApiConstants.cancelOrder(1), '/customer/orders/1/cancel');
        expect(ApiConstants.cancelOrder(50), '/customer/orders/50/cancel');
      });
    });

    group('Pharmacies Endpoints', () {
      test('pharmacies endpoint should be /customer/pharmacies', () {
        expect(ApiConstants.pharmacies, '/customer/pharmacies');
      });

      test('featuredPharmacies endpoint should be correct', () {
        expect(ApiConstants.featuredPharmacies, '/customer/pharmacies/featured');
      });

      test('nearbyPharmacies endpoint should be correct', () {
        expect(ApiConstants.nearbyPharmacies, '/customer/pharmacies/nearby');
      });

      test('onDutyPharmacies endpoint should be correct', () {
        expect(ApiConstants.onDutyPharmacies, '/customer/pharmacies/on-duty');
      });

      test('pharmacyDetails should return correct endpoint', () {
        expect(ApiConstants.pharmacyDetails(1), '/customer/pharmacies/1');
        expect(ApiConstants.pharmacyDetails(25), '/customer/pharmacies/25');
      });
    });

    group('Addresses Endpoints', () {
      test('addresses endpoint should be /customer/addresses', () {
        expect(ApiConstants.addresses, '/customer/addresses');
      });

      test('addressDetails should return correct endpoint', () {
        expect(ApiConstants.addressDetails(1), '/customer/addresses/1');
        expect(ApiConstants.addressDetails(10), '/customer/addresses/10');
      });

      test('setDefaultAddress should return correct endpoint', () {
        expect(ApiConstants.setDefaultAddress(1), '/customer/addresses/1/default');
        expect(ApiConstants.setDefaultAddress(5), '/customer/addresses/5/default');
      });
    });

    group('Notifications Endpoints', () {
      test('notifications endpoint should be /notifications', () {
        expect(ApiConstants.notifications, '/notifications');
      });

      test('updateFcmToken endpoint should be correct', () {
        expect(ApiConstants.updateFcmToken, '/notifications/fcm-token');
      });

      test('markNotificationRead should return correct endpoint', () {
        expect(ApiConstants.markNotificationRead(1), '/notifications/1/read');
        expect(ApiConstants.markNotificationRead(99), '/notifications/99/read');
      });

      test('markAllNotificationsRead endpoint should be correct', () {
        expect(ApiConstants.markAllNotificationsRead, '/notifications/read-all');
      });
    });

    group('Endpoint format validation', () {
      test('all endpoints should start with /', () {
        expect(ApiConstants.login, startsWith('/'));
        expect(ApiConstants.register, startsWith('/'));
        expect(ApiConstants.logout, startsWith('/'));
        expect(ApiConstants.profile, startsWith('/'));
        expect(ApiConstants.products, startsWith('/'));
        expect(ApiConstants.orders, startsWith('/'));
        expect(ApiConstants.pharmacies, startsWith('/'));
        expect(ApiConstants.addresses, startsWith('/'));
        expect(ApiConstants.notifications, startsWith('/'));
      });

      test('dynamic endpoints should include the ID', () {
        expect(ApiConstants.productDetails(123), contains('123'));
        expect(ApiConstants.orderDetails(456), contains('456'));
        expect(ApiConstants.pharmacyDetails(789), contains('789'));
        expect(ApiConstants.addressDetails(321), contains('321'));
        expect(ApiConstants.markNotificationRead(654), contains('654'));
      });

      test('endpoints should not have trailing slashes', () {
        expect(ApiConstants.login, isNot(endsWith('/')));
        expect(ApiConstants.products, isNot(endsWith('/')));
        expect(ApiConstants.orders, isNot(endsWith('/')));
        expect(ApiConstants.productDetails(1), isNot(endsWith('/')));
      });
    });
  });
}
