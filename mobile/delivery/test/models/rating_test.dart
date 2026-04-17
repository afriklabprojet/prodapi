import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/rating.dart';

void main() {
  group('PositiveRatingTag', () {
    test('displayLabel returns French names', () {
      expect(PositiveRatingTag.clientAimable.displayLabel, 'Client aimable');
      expect(PositiveRatingTag.facileTrouver.displayLabel, 'Facile à trouver');
      expect(PositiveRatingTag.bonPourboire.displayLabel, 'Bon pourboire');
      expect(PositiveRatingTag.reponseRapide.displayLabel, 'Réponse rapide');
    });
  });

  group('NegativeRatingTag', () {
    test('displayLabel returns French names', () {
      expect(
        NegativeRatingTag.difficileTrouver.displayLabel,
        'Difficile à trouver',
      );
      expect(NegativeRatingTag.pasReponse.displayLabel, 'Pas de réponse');
      expect(
        NegativeRatingTag.adresseIncorrecte.displayLabel,
        'Adresse incorrecte',
      );
      expect(NegativeRatingTag.impoli.displayLabel, 'Impoli');
    });
  });

  group('Rating model', () {
    test('fromJson creates valid rating', () {
      final json = {
        'id': 1,
        'delivery_id': 42,
        'courier_id': 5,
        'customer_id': 10,
        'rating': 4,
        'comment': 'Bon service',
        'tags': ['client_aimable'],
        'created_at': '2024-01-15T10:00:00.000Z',
      };
      final rating = Rating.fromJson(json);
      expect(rating.id, 1);
      expect(rating.deliveryId, 42);
      expect(rating.rating, 4);
      expect(rating.comment, 'Bon service');
      expect(rating.tags, ['client_aimable']);
    });

    test('fromJson handles string numbers (PHP API)', () {
      final json = {'id': '1', 'delivery_id': '42', 'rating': '5'};
      final rating = Rating.fromJson(json);
      expect(rating.id, 1);
      expect(rating.deliveryId, 42);
      expect(rating.rating, 5);
    });

    test('isValid checks range 1-5', () {
      expect(Rating(deliveryId: 1, rating: 0).isValid, isFalse);
      expect(Rating(deliveryId: 1, rating: 1).isValid, isTrue);
      expect(Rating(deliveryId: 1, rating: 5).isValid, isTrue);
      expect(Rating(deliveryId: 1, rating: 6).isValid, isFalse);
    });

    test('isPositive for >= 4', () {
      expect(Rating(deliveryId: 1, rating: 3).isPositive, isFalse);
      expect(Rating(deliveryId: 1, rating: 4).isPositive, isTrue);
      expect(Rating(deliveryId: 1, rating: 5).isPositive, isTrue);
    });

    test('isNegative for <= 2', () {
      expect(Rating(deliveryId: 1, rating: 1).isNegative, isTrue);
      expect(Rating(deliveryId: 1, rating: 2).isNegative, isTrue);
      expect(Rating(deliveryId: 1, rating: 3).isNegative, isFalse);
    });

    test('isNeutral for 3', () {
      expect(Rating(deliveryId: 1, rating: 3).isNeutral, isTrue);
      expect(Rating(deliveryId: 1, rating: 4).isNeutral, isFalse);
    });

    test('ratingEmoji returns correct emojis', () {
      expect(Rating(deliveryId: 1, rating: 1).ratingEmoji, '😞');
      expect(Rating(deliveryId: 1, rating: 2).ratingEmoji, '😕');
      expect(Rating(deliveryId: 1, rating: 3).ratingEmoji, '😐');
      expect(Rating(deliveryId: 1, rating: 4).ratingEmoji, '🙂');
      expect(Rating(deliveryId: 1, rating: 5).ratingEmoji, '😄');
      expect(Rating(deliveryId: 1, rating: 0).ratingEmoji, '❓');
    });

    test('ratingLabel returns French labels', () {
      expect(Rating(deliveryId: 1, rating: 1).ratingLabel, 'Très mauvais');
      expect(Rating(deliveryId: 1, rating: 2).ratingLabel, 'Mauvais');
      expect(Rating(deliveryId: 1, rating: 3).ratingLabel, 'Correct');
      expect(Rating(deliveryId: 1, rating: 4).ratingLabel, 'Bien');
      expect(Rating(deliveryId: 1, rating: 5).ratingLabel, 'Excellent');
      expect(Rating(deliveryId: 1, rating: 0).ratingLabel, 'Non noté');
    });

    test('toApiPayload creates correct map', () {
      final rating = Rating(
        deliveryId: 42,
        rating: 4,
        comment: 'Great',
        tags: ['client_aimable'],
      );
      final payload = rating.toApiPayload();
      expect(payload['delivery_id'], 42);
      expect(payload['rating'], 4);
      expect(payload['comment'], 'Great');
      expect(payload['tags'], ['client_aimable']);
    });

    test('toApiPayload excludes empty comment and tags', () {
      final rating = Rating(deliveryId: 42, rating: 3);
      final payload = rating.toApiPayload();
      expect(payload.containsKey('comment'), isFalse);
      expect(payload.containsKey('tags'), isFalse);
    });
  });

  group('RatingStats', () {
    test('fromJson creates valid stats', () {
      final json = {
        'average_rating': 4.2,
        'total_ratings': 50,
        'rating_distribution': [2, 3, 10, 15, 20],
        'positive_percentage': 70.0,
        'top_tags': ['client_aimable', 'reponse_rapide'],
      };
      final stats = RatingStats.fromJson(json);
      expect(stats.averageRating, 4.2);
      expect(stats.totalRatings, 50);
      expect(stats.distribution.length, 5);
      expect(stats.positivePercentage, 70.0);
      expect(stats.topTags.length, 2);
    });

    test('default values', () {
      final stats = RatingStats.fromJson({});
      expect(stats.averageRating, 0.0);
      expect(stats.totalRatings, 0);
      expect(stats.positivePercentage, 0.0);
    });
  });

  group('Rating - additional', () {
    test('fromJson parses createdAt correctly', () {
      final json = {
        'delivery_id': 1,
        'rating': 4,
        'created_at': '2025-03-15T14:30:00.000Z',
      };
      final rating = Rating.fromJson(json);
      expect(rating.createdAt, DateTime.utc(2025, 3, 15, 14, 30));
    });

    test('fromJson handles null optional fields', () {
      final json = {'delivery_id': 1, 'rating': 3};
      final rating = Rating.fromJson(json);
      expect(rating.id, isNull);
      expect(rating.courierId, isNull);
      expect(rating.customerId, isNull);
      expect(rating.comment, isNull);
      expect(rating.createdAt, isNull);
    });

    test('fromJson parses tags list from server', () {
      final json = {
        'delivery_id': 1,
        'rating': 5,
        'tags': ['client_aimable', 'facile_trouver', 'bon_pourboire'],
      };
      final rating = Rating.fromJson(json);
      expect(rating.tags.length, 3);
      expect(rating.tags, contains('facile_trouver'));
    });

    test('copyWith modifies rating while preserving others', () {
      final original = Rating(
        deliveryId: 42,
        rating: 3,
        comment: 'OK',
        tags: ['client_aimable'],
      );
      final updated = original.copyWith(rating: 5);
      expect(updated.rating, 5);
      expect(updated.deliveryId, 42);
      expect(updated.comment, 'OK');
      expect(updated.tags, ['client_aimable']);
    });

    test('equality for identical ratings', () {
      final a = Rating(deliveryId: 1, rating: 4, comment: 'Good');
      final b = Rating(deliveryId: 1, rating: 4, comment: 'Good');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('toApiPayload excludes empty string comment', () {
      final rating = Rating(deliveryId: 1, rating: 3, comment: '');
      final payload = rating.toApiPayload();
      expect(payload.containsKey('comment'), isFalse);
    });

    test('rating=0 is not valid, not positive, not negative, not neutral', () {
      final rating = Rating(deliveryId: 1, rating: 0);
      expect(rating.isValid, isFalse);
      expect(rating.isPositive, isFalse);
      expect(rating.isNegative, isTrue);
      expect(rating.isNeutral, isFalse);
    });

    test('rating=6 is not valid', () {
      final rating = Rating(deliveryId: 1, rating: 6);
      expect(rating.isValid, isFalse);
      expect(rating.ratingEmoji, '❓');
      expect(rating.ratingLabel, 'Non noté');
    });

    test('RatingStats distribution has 5 elements', () {
      final json = {
        'average_rating': 3.5,
        'total_ratings': 10,
        'rating_distribution': [1, 2, 3, 2, 2],
        'positive_percentage': 40.0,
        'top_tags': ['reponse_rapide'],
      };
      final stats = RatingStats.fromJson(json);
      expect(stats.distribution.length, 5);
      expect(stats.distribution[0], 1);
      expect(stats.distribution[4], 2);
    });

    test('RatingStats topTags parsed correctly', () {
      final json = {
        'top_tags': ['client_aimable', 'reponse_rapide', 'facile_trouver'],
      };
      final stats = RatingStats.fromJson(json);
      expect(stats.topTags.length, 3);
      expect(stats.topTags[0], 'client_aimable');
    });

    test('RatingStats copyWith works', () {
      final stats = RatingStats(averageRating: 4.0, totalRatings: 10);
      final updated = stats.copyWith(totalRatings: 20);
      expect(updated.totalRatings, 20);
      expect(updated.averageRating, 4.0);
    });
  });
}
