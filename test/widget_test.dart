import 'package:flutter_test/flutter_test.dart';
import 'package:geo_connect/core/errors/api_exception.dart';
import 'package:geo_connect/main.dart';
import 'package:geo_connect/models/checkin_model.dart';
import 'package:geo_connect/models/user_model.dart';

void main() {
  group('Unit Tests - Data Models & Business Logic', () {
    test('UserModel JSON parsing', () {
      final json = {
        'id': 10,
        'name': 'Somchai Jaidee',
        'email': 'somchai@university.ac.th',
        'isVerified': true,
        'bio': 'Computer Engineering Student',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 10);
      expect(user.name, 'Somchai Jaidee');
      expect(user.email, 'somchai@university.ac.th');
      expect(user.isVerified, true);
      expect(user.bio, 'Computer Engineering Student');
    });

    test('CheckInModel JSON parsing with nested user', () {
      final json = {
        'id': 101,
        'userId': 10,
        'lat': '13.7563',
        'lng': '100.5018',
        'locationName': 'Central Library',
        'description': 'Studying Flutter',
        'createdAt': '2026-08-26T12:00:00.000Z',
        'user': {
          'id': 10,
          'name': 'Somchai Jaidee',
          'email': 'somchai@university.ac.th',
          'isVerified': true,
        },
      };

      final checkin = CheckInModel.fromJson(json);

      expect(checkin.id, 101);
      expect(checkin.userId, 10);
      expect(checkin.lat, 13.7563);
      expect(checkin.lng, 100.5018);
      expect(checkin.locationName, 'Central Library');
      expect(checkin.user?.name, 'Somchai Jaidee');
    });

    test('User grouping logic selects latest check-in by createdAt timestamp', () {
      final now = DateTime.now();
      final user1CheckIn1 = CheckInModel(
        id: 1,
        userId: 5,
        lat: 13.7,
        lng: 100.5,
        description: 'First Check-in',
        createdAt: now.subtract(const Duration(hours: 2)),
        user: CheckInUser(id: 5, name: 'User Five'),
      );

      final user1CheckIn2 = CheckInModel(
        id: 2,
        userId: 5,
        lat: 13.8,
        lng: 100.6,
        description: 'Second Check-in (Latest)',
        createdAt: now.subtract(const Duration(minutes: 10)),
        user: CheckInUser(id: 5, name: 'User Five'),
      );

      final user2CheckIn = CheckInModel(
        id: 3,
        userId: 8,
        lat: 13.9,
        lng: 100.7,
        description: 'User Eight Check-in',
        createdAt: now.subtract(const Duration(hours: 1)),
        user: CheckInUser(id: 8, name: 'User Eight'),
      );

      final rawList = [user1CheckIn1, user1CheckIn2, user2CheckIn];

      // Grouping logic simulation
      final Map<int, CheckInModel> userLatestMap = {};
      for (final item in rawList) {
        final uid = item.user?.id ?? item.userId;
        if (uid == null) continue;
        if (!userLatestMap.containsKey(uid)) {
          userLatestMap[uid] = item;
        } else {
          final existing = userLatestMap[uid]!;
          if ((item.createdAt ?? DateTime(0)).isAfter(existing.createdAt ?? DateTime(0))) {
            userLatestMap[uid] = item;
          }
        }
      }

      final groupedResult = userLatestMap.values.toList();

      expect(groupedResult.length, 2);
      expect(userLatestMap[5]?.id, 2); // Check-in 2 is latest for user 5
      expect(userLatestMap[5]?.description, 'Second Check-in (Latest)');
      expect(userLatestMap[8]?.id, 3);
    });

    test('ApiException parses network and status errors', () {
      final ex = ApiException('Invalid email or password', statusCode: 401);

      expect(ex.message, 'Invalid email or password');
      expect(ex.statusCode, 401);
    });
  });

  group('Widget Smoke Tests', () {
    testWidgets('GeoConnect app loads initial LoginScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const GeoConnectApp());
      expect(find.text('GeoConnect'), findsOneWidget);
      expect(find.text('Sign in to share & discover location check-ins'), findsOneWidget);
    });
  });
}
