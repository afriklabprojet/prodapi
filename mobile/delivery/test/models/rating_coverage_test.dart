import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/rating.dart';

void main() {
  group('Rating computed properties', () {
    test('isValid for ratings 1-5', () {
      for (int i = 1; i <= 5; i++) {
        final rating = Rating(deliveryId: 1, rating: i);
        expect(rating.isValid, true, reason: 'rating $i should be valid');
      }
    });

    test('isValid false for 0 and 6', () {
      expect(Rating(deliveryId: 1, rating: 0).isValid, false);
      expect(Rating(deliveryId: 1, rating: 6).isValid, false);
    });

    test('isPositive for >= 4', () {
      expect(Rating(deliveryId: 1, rating: 4).isPositive, true);
      expect(Rating(deliveryId: 1, rating: 5).isPositive, true);
      expect(Rating(deliveryId: 1, rating: 3).isPositive, false);
    });

    test('isNegative for <= 2', () {
      expect(Rating(deliveryId: 1, rating: 1).isNegative, true);
      expect(Rating(deliveryId: 1, rating: 2).isNegative, true);
      expect(Rating(deliveryId: 1, rating: 3).isNegative, false);
    });

    test('isNeutral for exactly 3', () {
      expect(Rating(deliveryId: 1, rating: 3).isNeutral, true);
      expect(Rating(deliveryId: 1, rating: 4).isNeutral, false);
    });

    test('ratingEmoji for all values', () {
      expect(Rating(deliveryId: 1, rating: 1).ratingEmoji, '😞');
      expect(Rating(deliveryId: 1, rating: 2).ratingEmoji, '😕');
      expect(Rating(deliveryId: 1, rating: 3).ratingEmoji, '😐');
      expect(Rating(deliveryId: 1, rating: 4).ratingEmoji, '🙂');
      expect(Rating(deliveryId: 1, rating: 5).ratingEmoji, '😄');
      expect(Rating(deliveryId: 1, rating: 0).ratingEmoji, '❓');
    });

    test('ratingLabel for all values', () {
      expect(Rating(deliveryId: 1, rating: 1).ratingLabel, 'Très mauvais');
      expect(Rating(deliveryId: 1, rating: 2).ratingLabel, 'Mauvais');
      expect(Rating(deliveryId: 1, rating: 3).ratingLabel, 'Correct');
      expect(Rating(deliveryId: 1, rating: 4).ratingLabel, 'Bien');
      expect(Rating(deliveryId: 1, rating: 5).ratingLabel, 'Excellent');
      expect(Rating(deliveryId: 1, rating: 0).ratingLabel, 'Non noté');
    });

    test('toApiPayload minimal', () {
      final rating = Rating(deliveryId: 42, rating: 5);
      final payload = rating.toApiPayload();
      expect(payload['delivery_id'], 42);
      expect(payload['rating'], 5);
      expect(payload.containsKey('comment'), false);
      expect(payload.containsKey('tags'), false);
    });

    test('toApiPayload with comment and tags', () {
      final rating = Rating(
        deliveryId: 42,
        rating: 4,
        comment: 'Très bien',
        tags: ['client_aimable', 'reponse_rapide'],
      );
      final payload = rating.toApiPayload();
      expect(payload['delivery_id'], 42);
      expect(payload['rating'], 4);
      expect(payload['comment'], 'Très bien');
      expect(payload['tags'], ['client_aimable', 'reponse_rapide']);
    });

    test('toApiPayload excludes empty comment', () {
      final rating = Rating(deliveryId: 42, rating: 3, comment: '');
      final payload = rating.toApiPayload();
      expect(payload.containsKey('comment'), false);
    });

    test('toApiPayload excludes empty tags list', () {
      final rating = Rating(deliveryId: 42, rating: 3, tags: []);
      final payload = rating.toApiPayload();
      expect(payload.containsKey('tags'), false);
    });
  });

  group('PositiveRatingTag', () {
    test('displayLabel for all values', () {
      expect(PositiveRatingTag.clientAimable.displayLabel, 'Client aimable');
      expect(PositiveRatingTag.facileTrouver.displayLabel, 'Facile à trouver');
      expect(PositiveRatingTag.bonPourboire.displayLabel, 'Bon pourboire');
      expect(PositiveRatingTag.reponseRapide.displayLabel, 'Réponse rapide');
    });

    test('values count', () {
      expect(PositiveRatingTag.values.length, 4);
    });
  });

  group('NegativeRatingTag', () {
    test('displayLabel for all values', () {
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

    test('values count', () {
      expect(NegativeRatingTag.values.length, 4);
    });
  });

  group('RatingStats', () {
    test('fromJson constructs correctly', () {
      final json = {
        'average_rating': 4.5,
        'total_ratings': 100,
        'rating_distribution': [5, 10, 15, 30, 40],
        'positive_percentage': 70.0,
        'top_tags': ['client_aimable', 'reponse_rapide'],
      };
      final stats = RatingStats.fromJson(json);
      expect(stats.averageRating, 4.5);
      expect(stats.totalRatings, 100);
      expect(stats.distribution, [5, 10, 15, 30, 40]);
      expect(stats.positivePercentage, 70.0);
      expect(stats.topTags, ['client_aimable', 'reponse_rapide']);
    });

    test('default values', () {
      const stats = RatingStats();
      expect(stats.averageRating, 0.0);
      expect(stats.totalRatings, 0);
      expect(stats.distribution, [0, 0, 0, 0, 0]);
      expect(stats.positivePercentage, 0.0);
      expect(stats.topTags, isEmpty);
    });
  });
}
