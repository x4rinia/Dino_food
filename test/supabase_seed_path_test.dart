import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forward migration disables both legacy server seed functions', () {
    final migration = File(
      'supabase/migrations/zzzz_disable_legacy_server_defaults.sql',
    );
    expect(migration.existsSync(), isTrue);

    final sql = migration.readAsStringSync();
    expect(sql, contains('public.seed_household_defaults'));
    expect(sql, contains('public.seed_default_dishes_for_household'));
    expect(
      RegExp(
        r'^\s*(INSERT|UPDATE|DELETE)\s',
        caseSensitive: false,
        multiLine: true,
      ).hasMatch(sql),
      isFalse,
      reason: 'The compatibility migration must not modify existing rows.',
    );
    expect(File('supabase_migration_task2_defaults.sql').existsSync(), isFalse);
  });
}
