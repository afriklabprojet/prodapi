import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/constants/api_constants.dart';

void main() {
  group('ApiConstants - Auth Endpoints', () {
    test('login endpoint', () {
      expect(ApiConstants.login, '/auth/login');
    });

    test('logout endpoint', () {
      expect(ApiConstants.logout, '/auth/logout');
    });

    test('me endpoint', () {
      expect(ApiConstants.me, '/auth/me');
    });

    test('registerCourier endpoint', () {
      expect(ApiConstants.registerCourier, '/auth/register/courier');
    });

    test('refreshToken endpoint', () {
      expect(ApiConstants.refreshToken, '/auth/refresh');
    });

    test('forgotPassword endpoint', () {
      expect(ApiConstants.forgotPassword, '/auth/forgot-password');
    });

    test('verifyOtp endpoint', () {
      expect(ApiConstants.verifyOtp, '/auth/verify');
    });

    test('resendOtp endpoint', () {
      expect(ApiConstants.resendOtp, '/auth/resend');
    });

    test('resetPassword endpoint', () {
      expect(ApiConstants.resetPassword, '/auth/reset-password');
    });

    test('updateMe endpoint', () {
      expect(ApiConstants.updateMe, '/auth/me/update');
    });

    test('uploadAvatar endpoint', () {
      expect(ApiConstants.uploadAvatar, '/auth/avatar');
    });
  });

  group('ApiConstants - Courier Endpoints', () {
    test('profile endpoint', () {
      expect(ApiConstants.profile, '/courier/profile');
    });

    test('availability endpoint', () {
      expect(ApiConstants.availability, '/courier/availability/toggle');
    });

    test('location endpoint', () {
      expect(ApiConstants.location, '/courier/location/update');
    });

    test('deliveries endpoint', () {
      expect(ApiConstants.deliveries, '/courier/deliveries');
    });

    test('wallet endpoint', () {
      expect(ApiConstants.wallet, '/courier/wallet');
    });

    test('statistics endpoint', () {
      expect(ApiConstants.statistics, '/courier/statistics');
    });

    test('leaderboard endpoint', () {
      expect(ApiConstants.leaderboard, '/courier/statistics/leaderboard');
    });
  });

  group('ApiConstants - Dynamic Endpoints', () {
    test('acceptDelivery with id', () {
      expect(ApiConstants.acceptDelivery(42), '/courier/deliveries/42/accept');
    });

    test('deliveryShow with id', () {
      expect(ApiConstants.deliveryShow(99), '/courier/deliveries/99');
    });

    test('pickupDelivery with id', () {
      expect(ApiConstants.pickupDelivery(10), '/courier/deliveries/10/pickup');
    });

    test('completeDelivery with id', () {
      expect(ApiConstants.completeDelivery(5), '/courier/deliveries/5/deliver');
    });

    test('rejectDelivery with id', () {
      expect(ApiConstants.rejectDelivery(7), '/courier/deliveries/7/reject');
    });

    test('rateCustomer with id', () {
      expect(
        ApiConstants.rateCustomer(3),
        '/courier/deliveries/3/rate-customer',
      );
    });

    test('claimChallenge with id', () {
      expect(ApiConstants.claimChallenge(15), '/courier/challenges/15/claim');
    });

    test('messages with orderId', () {
      expect(ApiConstants.messages(22), '/courier/orders/22/messages');
    });

    test('paymentStatus with ref', () {
      expect(
        ApiConstants.paymentStatus('REF-001'),
        '/courier/payments/REF-001/status',
      );
    });

    test('cancelPayment with ref', () {
      expect(
        ApiConstants.cancelPayment('REF-002'),
        '/courier/payments/REF-002/cancel',
      );
    });

    test('supportTicketDetail with id', () {
      expect(ApiConstants.supportTicketDetail(8), '/support/tickets/8');
    });

    test('supportTicketMessages with id', () {
      expect(
        ApiConstants.supportTicketMessages(8),
        '/support/tickets/8/messages',
      );
    });

    test('supportTicketResolve with id', () {
      expect(
        ApiConstants.supportTicketResolve(8),
        '/support/tickets/8/resolve',
      );
    });
  });

  group('ApiConstants - Payment Endpoints', () {
    test('paymentsInitiate endpoint', () {
      expect(ApiConstants.paymentsInitiate, '/courier/payments/initiate');
    });

    test('paymentsMethods endpoint', () {
      expect(ApiConstants.paymentsMethods, '/courier/payments/methods');
    });

    test('paymentsHistory endpoint', () {
      expect(ApiConstants.paymentsHistory, '/courier/payments');
    });
  });

  group('ApiConstants - Support Endpoints', () {
    test('supportTickets endpoint', () {
      expect(ApiConstants.supportTickets, '/support/tickets');
    });

    test('supportTicketsStats endpoint', () {
      expect(ApiConstants.supportTicketsStats, '/support/tickets/stats');
    });

    test('supportFaqCourier endpoint', () {
      expect(ApiConstants.supportFaqCourier, '/support/faq/courier');
    });
  });

  group('ApiConstants - KYC/Liveness Endpoints', () {
    test('livenessStart endpoint', () {
      expect(ApiConstants.livenessStart, '/liveness/start');
    });

    test('livenessValidate endpoint', () {
      expect(ApiConstants.livenessValidate, '/liveness/validate');
    });

    test('livenessStatus with id', () {
      expect(ApiConstants.livenessStatus('44'), '/liveness/status/44');
    });

    test('livenessCancel with id', () {
      expect(ApiConstants.livenessCancel('44'), '/liveness/cancel/44');
    });
  });
}
