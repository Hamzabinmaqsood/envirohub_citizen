import 'package:envirohub_citizen/features/auth/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser', () {
    test('parses a worker and exposes role helpers', () {
      final user = AppUser.fromJson({
        'id': 7,
        'email': 'worker@example.com',
        'name': 'Worker One',
        'phone': '03000000000',
        'role': 'worker',
      });

      expect(user.id, 7);
      expect(user.name, 'Worker One');
      expect(user.role, 'WORKER');
      expect(user.isWorker, isTrue);
      expect(user.isCitizen, isFalse);
      expect(user.isAuthority, isFalse);
    });

    test('falls back to email when name is missing', () {
      final user = AppUser.fromJson({
        'id': 1,
        'email': 'authority@example.com',
        'role': 'AUTHORITY',
      });

      expect(user.name, 'authority@example.com');
      expect(user.isAuthority, isTrue);
    });
  });
}
