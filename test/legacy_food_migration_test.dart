import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    'supabase/migrations/zzzzz_migrate_legacy_food_variants.sql',
  );

  test('migration contains only the explicit legacy variant mappings', () {
    expect(migration.existsSync(), isTrue);
    final sql = migration.readAsStringSync();

    const mappings = {
      "('Basmatireis', 'Reis', 'Basmati')",
      "('Jasminreis', 'Reis', 'Jasmin')",
      "('Risottoreis', 'Reis', 'Risotto')",
      "('Cherrytomaten', 'Tomaten', 'Cherry')",
      "('Passierte Tomaten', 'Tomaten', 'passiert')",
      "('Gehackte Tomaten', 'Tomaten', 'gehackt')",
      "('Spaghetti', 'Nudeln', 'Spaghetti')",
      "('Penne', 'Nudeln', 'Penne')",
      "('Fusilli', 'Nudeln', 'Fusilli')",
      "('Makkaroni', 'Nudeln', 'Makkaroni')",
    };

    for (final mapping in mappings) {
      expect(sql, contains(mapping));
    }
    expect(sql, contains("BTRIM(COALESCE(f.note, '')) = ''"));

    final valuesStart = sql.indexOf(
      'INSERT INTO legacy_food_variant_map (legacy_name, target_name, target_note)',
    );
    final runtimeValues = sql.substring(
      valuesStart,
      sql.indexOf(';', valuesStart),
    );
    expect(runtimeValues, isNot(contains('Wildreis')));
    expect(runtimeValues, isNot(contains('Basmati Bio')));
  });

  test(
    'migration merges references before deleting a duplicate legacy food',
    () {
      final sql = migration.readAsStringSync();

      final stockInsert = sql.indexOf('INSERT INTO public.household_stock');
      final shoppingUpdate = sql.indexOf('UPDATE public.shopping_items');
      final dishUpdate = sql.indexOf('UPDATE public.dish_items');
      final genericReferences = sql.indexOf('FROM pg_constraint');
      final legacyDelete = sql.lastIndexOf('DELETE FROM public.foods');

      expect(sql, contains('ON CONFLICT (household_id, food_id) DO NOTHING'));
      expect(sql, contains('DELETE FROM public.dish_items AS legacy_item'));
      expect(sql, contains('pg_advisory_xact_lock'));
      expect(sql, contains('FOR UPDATE OF f'));
      expect(stockInsert, greaterThan(0));
      expect(shoppingUpdate, greaterThan(stockInsert));
      expect(dishUpdate, greaterThan(shoppingUpdate));
      expect(genericReferences, greaterThan(0));
      expect(legacyDelete, greaterThan(dishUpdate));
    },
  );

  test('migration is idempotent and keeps IDs when no target exists', () {
    final sql = migration.readAsStringSync();

    expect(sql, contains('IF target_food_id IS NULL THEN'));
    expect(sql, contains('WHERE id = legacy_food.legacy_id'));
    expect(sql, contains('CONTINUE;'));
    expect(sql, contains('f.household_id IS NOT NULL'));
    expect(
      RegExp(
        r'UPDATE public\.foods\s+SET name =',
        multiLine: true,
      ).allMatches(sql).length,
      1,
    );
  });
}
