-- One-time migration for household-scoped foods created by the legacy seed.
-- Only the explicit names below and only rows with an empty note are touched.
-- User foods such as "Wildreis" or "Reis / Basmati Bio" are not candidates.
--
-- Optional preflight (run before this migration in the SQL editor):
-- WITH legacy_map(legacy_name, target_name, target_note) AS (
--   VALUES
--     ('Basmatireis', 'Reis', 'Basmati'),
--     ('Jasminreis', 'Reis', 'Jasmin'),
--     ('Risottoreis', 'Reis', 'Risotto'),
--     ('Cherrytomaten', 'Tomaten', 'Cherry'),
--     ('Passierte Tomaten', 'Tomaten', 'passiert'),
--     ('Gehackte Tomaten', 'Tomaten', 'gehackt'),
--     ('Spaghetti', 'Nudeln', 'Spaghetti'),
--     ('Penne', 'Nudeln', 'Penne'),
--     ('Fusilli', 'Nudeln', 'Fusilli'),
--     ('Makkaroni', 'Nudeln', 'Makkaroni')
-- )
-- SELECT f.household_id, f.id, f.name AS legacy_name,
--        m.target_name, m.target_note,
--        target.id AS existing_target_id
-- FROM public.foods AS f
-- JOIN legacy_map AS m
--   ON LOWER(REGEXP_REPLACE(BTRIM(f.name), '\s+', ' ', 'g')) =
--      LOWER(m.legacy_name)
-- LEFT JOIN public.foods AS target
--   ON target.household_id = f.household_id
--  AND LOWER(REGEXP_REPLACE(BTRIM(target.name), '\s+', ' ', 'g')) =
--      LOWER(m.target_name)
--  AND LOWER(REGEXP_REPLACE(BTRIM(COALESCE(target.note, '')), '\s+', ' ', 'g')) =
--      LOWER(m.target_note)
-- WHERE f.household_id IS NOT NULL
--   AND BTRIM(COALESCE(f.note, '')) = ''
-- ORDER BY f.household_id, f.name;
--
-- This DO statement is one transaction. Any unknown reference conflict aborts
-- and rolls back the complete migration instead of deleting referenced data.

DO $migration$
DECLARE
  legacy_food RECORD;
  foreign_key RECORD;
  foods_id_attnum SMALLINT;
  target_food_id UUID;
  renamed_count INTEGER := 0;
  merged_count INTEGER := 0;
BEGIN
  -- Prevent two copies of this migration from merging the same rows at once.
  PERFORM pg_advisory_xact_lock(
    hashtextextended('dino_food_migrate_legacy_food_variants_v1', 0)
  );

  SELECT attnum
  INTO foods_id_attnum
  FROM pg_attribute
  WHERE attrelid = 'public.foods'::regclass
    AND attname = 'id'
    AND NOT attisdropped;

  IF foods_id_attnum IS NULL THEN
    RAISE EXCEPTION 'public.foods.id was not found';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_constraint AS constraint_row
    WHERE constraint_row.contype = 'f'
      AND constraint_row.confrelid = 'public.foods'::regclass
      AND (
        array_length(constraint_row.conkey, 1) <> 1
        OR array_length(constraint_row.confkey, 1) <> 1
        OR constraint_row.confkey[1] <> foods_id_attnum
      )
  ) THEN
    RAISE EXCEPTION
      'Unsupported composite foreign key references public.foods; migration rolled back';
  END IF;

  CREATE TEMP TABLE IF NOT EXISTS legacy_food_variant_map (
    legacy_name TEXT PRIMARY KEY,
    target_name TEXT NOT NULL,
    target_note TEXT NOT NULL
  ) ON COMMIT DROP;

  TRUNCATE legacy_food_variant_map;

  INSERT INTO legacy_food_variant_map (legacy_name, target_name, target_note)
  VALUES
    ('Basmatireis', 'Reis', 'Basmati'),
    ('Jasminreis', 'Reis', 'Jasmin'),
    ('Risottoreis', 'Reis', 'Risotto'),
    ('Cherrytomaten', 'Tomaten', 'Cherry'),
    ('Passierte Tomaten', 'Tomaten', 'passiert'),
    ('Gehackte Tomaten', 'Tomaten', 'gehackt'),
    ('Spaghetti', 'Nudeln', 'Spaghetti'),
    ('Penne', 'Nudeln', 'Penne'),
    ('Fusilli', 'Nudeln', 'Fusilli'),
    ('Makkaroni', 'Nudeln', 'Makkaroni');

  -- Lock candidate rows in a stable order to minimize deadlock risk.
  PERFORM 1
  FROM public.foods AS f
  JOIN legacy_food_variant_map AS m
    ON LOWER(REGEXP_REPLACE(BTRIM(f.name), '\s+', ' ', 'g')) =
       LOWER(m.legacy_name)
  WHERE f.household_id IS NOT NULL
    AND BTRIM(COALESCE(f.note, '')) = ''
  ORDER BY f.household_id, f.id
  FOR UPDATE OF f;

  FOR legacy_food IN
    SELECT
      f.id AS legacy_id,
      f.household_id,
      m.target_name,
      m.target_note
    FROM public.foods AS f
    JOIN legacy_food_variant_map AS m
      ON LOWER(REGEXP_REPLACE(BTRIM(f.name), '\s+', ' ', 'g')) =
         LOWER(m.legacy_name)
    WHERE f.household_id IS NOT NULL
      AND BTRIM(COALESCE(f.note, '')) = ''
    ORDER BY f.household_id, f.id
  LOOP
    target_food_id := NULL;

    SELECT target.id
    INTO target_food_id
    FROM public.foods AS target
    WHERE target.household_id = legacy_food.household_id
      AND target.id <> legacy_food.legacy_id
      AND LOWER(REGEXP_REPLACE(BTRIM(target.name), '\s+', ' ', 'g')) =
          LOWER(legacy_food.target_name)
      AND LOWER(REGEXP_REPLACE(BTRIM(COALESCE(target.note, '')), '\s+', ' ', 'g')) =
          LOWER(legacy_food.target_note)
    ORDER BY target.id
    LIMIT 1
    FOR UPDATE;

    IF target_food_id IS NULL THEN
      -- Keeping the UUID preserves every reference without further writes.
      UPDATE public.foods
      SET name = legacy_food.target_name,
          note = legacy_food.target_note
      WHERE id = legacy_food.legacy_id;

      renamed_count := renamed_count + 1;
      CONTINUE;
    END IF;

    -- A target variant already exists. Merge stock without violating its
    -- (household_id, food_id) primary key, then remove the legacy stock row.
    IF to_regclass('public.household_stock') IS NOT NULL THEN
      INSERT INTO public.household_stock (household_id, food_id)
      SELECT stock.household_id, target_food_id
      FROM public.household_stock AS stock
      WHERE stock.food_id = legacy_food.legacy_id
      ON CONFLICT (household_id, food_id) DO NOTHING;

      DELETE FROM public.household_stock
      WHERE food_id = legacy_food.legacy_id;
    END IF;

    IF to_regclass('public.shopping_items') IS NOT NULL THEN
      UPDATE public.shopping_items
      SET food_id = target_food_id
      WHERE food_id = legacy_food.legacy_id;
    END IF;

    IF to_regclass('public.dish_items') IS NOT NULL THEN
      -- If a dish already contains both IDs, keep its existing target item and
      -- remove only the redundant legacy ingredient.
      DELETE FROM public.dish_items AS legacy_item
      USING public.dish_items AS target_item
      WHERE legacy_item.food_id = legacy_food.legacy_id
        AND target_item.food_id = target_food_id
        AND target_item.dish_id = legacy_item.dish_id;

      UPDATE public.dish_items
      SET food_id = target_food_id
      WHERE food_id = legacy_food.legacy_id;
    END IF;

    -- Preserve any additional single-column foreign keys to foods that may
    -- exist in production but are not part of the repository schema.
    FOR foreign_key IN
      SELECT
        constraint_row.conrelid AS table_oid,
        referencing_column.attname AS column_name
      FROM pg_constraint AS constraint_row
      JOIN pg_attribute AS referencing_column
        ON referencing_column.attrelid = constraint_row.conrelid
       AND referencing_column.attnum = constraint_row.conkey[1]
      WHERE constraint_row.contype = 'f'
        AND constraint_row.confrelid = 'public.foods'::regclass
        AND array_length(constraint_row.conkey, 1) = 1
        AND array_length(constraint_row.confkey, 1) = 1
        AND constraint_row.confkey[1] = foods_id_attnum
        AND constraint_row.conrelid NOT IN (
          COALESCE(to_regclass('public.household_stock')::OID, 0::OID),
          COALESCE(to_regclass('public.shopping_items')::OID, 0::OID),
          COALESCE(to_regclass('public.dish_items')::OID, 0::OID)
        )
      ORDER BY constraint_row.conrelid, constraint_row.oid
    LOOP
      EXECUTE format(
        'UPDATE %s SET %I = $1 WHERE %I = $2',
        foreign_key.table_oid::regclass,
        foreign_key.column_name,
        foreign_key.column_name
      )
      USING target_food_id, legacy_food.legacy_id;
    END LOOP;

    -- RESTRICT-style unknown references make this DELETE fail and roll back.
    DELETE FROM public.foods WHERE id = legacy_food.legacy_id;
    merged_count := merged_count + 1;
  END LOOP;

  RAISE NOTICE
    'Legacy food migration complete: % rows renamed in place, % rows merged into existing variants',
    renamed_count,
    merged_count;
END;
$migration$;
