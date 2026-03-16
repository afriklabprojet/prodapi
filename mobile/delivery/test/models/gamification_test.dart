import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/gamification.dart';

void main() {
  group('CourierLevel', () {
    test('fromJson creates level correctly', () {
      final json = {
        'level': 1,
        'title': 'Bronze',
        'current_xp': 250,
        'required_xp': 500,
        'total_xp': 250,
        'color': 'bronze',
        'perks': ['Bonus 5%'],
      };
      
      final level = CourierLevel.fromJson(json);
      
      expect(level.level, 1);
      expect(level.title, 'Bronze');
      expect(level.currentXP, 250);
      expect(level.requiredXP, 500);
      expect(level.totalXP, 250);
      expect(level.perks, ['Bonus 5%']);
    });

    test('progress is calculated correctly', () {
      final level = CourierLevel(
        level: 1,
        title: 'Bronze',
        currentXP: 250,
        requiredXP: 500,
        totalXP: 250,
        color: Colors.grey,
      );
      
      expect(level.progress, 0.5);
    });

    test('xpToNextLevel returns correct value', () {
      final level = CourierLevel(
        level: 1,
        title: 'Bronze',
        currentXP: 250,
        requiredXP: 500,
        totalXP: 250,
        color: Colors.grey,
      );
      
      expect(level.xpToNextLevel, 250);
    });

    test('icon returns correct icon for level', () {
      final level1 = CourierLevel(level: 1, title: 'test', currentXP: 0, requiredXP: 100, totalXP: 0, color: Colors.grey);
      final level10 = CourierLevel(level: 10, title: 'test', currentXP: 0, requiredXP: 100, totalXP: 0, color: Colors.grey);
      final level50 = CourierLevel(level: 50, title: 'test', currentXP: 0, requiredXP: 100, totalXP: 0, color: Colors.grey);
      
      expect(level1.icon, Icons.star_border);
      expect(level10.icon, Icons.star);
      expect(level50.icon, Icons.diamond);
    });
  });

  group('GamificationBadge', () {
    test('fromJson creates badge correctly', () {
      final json = {
        'id': 'badge_1',
        'name': 'Premier pas',
        'description': 'Effectuer votre première livraison',
        'icon': 'star',
        'color': 'gold',
        'is_unlocked': true,
        'required_value': 1,
        'current_value': 1,
        'category': 'delivery',
      };
      
      final badge = GamificationBadge.fromJson(json);
      
      expect(badge.id, 'badge_1');
      expect(badge.name, 'Premier pas');
      expect(badge.isUnlocked, true);
      expect(badge.category, 'delivery');
    });

    test('progress is calculated correctly', () {
      const badge = GamificationBadge(
        id: 'test',
        name: 'Test',
        description: 'Test description',
        iconName: 'star',
        color: Colors.blue,
        requiredValue: 10,
        currentValue: 5,
      );
      
      expect(badge.progress, 0.5);
    });

    test('progress is clamped to 1.0', () {
      const badge = GamificationBadge(
        id: 'test',
        name: 'Test',
        description: 'Test description',
        iconName: 'star',
        color: Colors.blue,
        requiredValue: 10,
        currentValue: 15,
      );
      
      expect(badge.progress, 1.0);
    });

    test('icon returns correct icon for iconName', () {
      const badge = GamificationBadge(
        id: 'test',
        name: 'Test',
        description: 'Test',
        iconName: 'star',
        color: Colors.blue,
      );
      
      expect(badge.icon, Icons.star);
    });
  });
}
