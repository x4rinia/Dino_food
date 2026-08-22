-- Downstream repair migration. Diagnose before applying (run separately in
-- the SQL editor if desired):
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'public.foods'::regclass
-- ORDER BY conname;
--
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'public' AND tablename = 'foods'
-- ORDER BY indexname;
--
-- Preflight for legacy duplicate combinations (must return no rows):
-- SELECT household_id,
--        LOWER(REGEXP_REPLACE(BTRIM(name), '\s+', ' ', 'g')) AS normalized_name,
--        LOWER(REGEXP_REPLACE(BTRIM(COALESCE(note, '')), '\s+', ' ', 'g'))
--          AS normalized_note,
--        COUNT(*)
-- FROM public.foods
-- WHERE household_id IS NOT NULL
-- GROUP BY household_id, normalized_name, normalized_note
-- HAVING COUNT(*) > 1;

ALTER TABLE public.foods
ADD COLUMN IF NOT EXISTS icon_key TEXT;

ALTER TABLE public.foods
ALTER COLUMN icon_key SET DEFAULT 'other';

-- Use legacy categories once as migration input. No application code reads or
-- writes category after this migration. Dynamic SQL keeps this migration safe
-- on installations where the legacy column was already removed.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'foods'
      AND column_name = 'category'
  ) THEN
    EXECUTE $migration$
      WITH legacy_icons AS (
        SELECT
          id,
          LOWER(REGEXP_REPLACE(BTRIM(name), '\s+', ' ', 'g')) AS normalized_name,
          CASE LOWER(BTRIM(category))
            WHEN 'gemüse' THEN 'vegetables'
            WHEN 'obst' THEN 'fruit'
            WHEN 'kartoffeln' THEN 'potato'
            WHEN 'fleisch' THEN 'meat'
            WHEN 'wurst' THEN 'sausage'
            WHEN 'fisch' THEN 'fish'
            WHEN 'milchprodukte' THEN 'dairy'
            WHEN 'käse' THEN 'cheese'
            WHEN 'eier' THEN 'eggs'
            WHEN 'brot & backwaren' THEN 'bakery'
            WHEN 'nudeln & reis' THEN 'grains'
            WHEN 'konserven & gläser' THEN 'preserves'
            WHEN 'tiefkühl' THEN 'frozen'
            WHEN 'gewürze' THEN 'spices'
            WHEN 'saucen' THEN 'sauces'
            WHEN 'öle & fette' THEN 'oils'
            WHEN 'frühstück' THEN 'breakfast'
            WHEN 'backen' THEN 'baking'
            WHEN 'getränke' THEN 'drinks'
            WHEN 'snacks' THEN 'sweets'
            WHEN 'süßigkeiten' THEN 'sweets'
            ELSE 'other'
          END AS mapped_icon
        FROM public.foods
      ),
      icons_by_name AS (
        SELECT normalized_name, MIN(mapped_icon) AS mapped_icon
        FROM legacy_icons
        WHERE mapped_icon <> 'other'
        GROUP BY normalized_name
      )
      UPDATE public.foods AS target
      SET icon_key = COALESCE(
        NULLIF(own_icon.mapped_icon, 'other'),
        name_icon.mapped_icon,
        'other'
      )
      FROM legacy_icons AS own_icon
      LEFT JOIN icons_by_name AS name_icon
        ON name_icon.normalized_name = own_icon.normalized_name
      WHERE target.id = own_icon.id
        AND (target.icon_key IS NULL OR target.icon_key = 'other')
    $migration$;
  END IF;
END $$;

UPDATE public.foods SET icon_key = 'other' WHERE icon_key IS NULL;
ALTER TABLE public.foods ALTER COLUMN icon_key SET NOT NULL;

ALTER TABLE public.foods DROP CONSTRAINT IF EXISTS foods_icon_key_valid;
ALTER TABLE public.foods
ADD CONSTRAINT foods_icon_key_valid CHECK (icon_key IN (
  'vegetables', 'fruit', 'potato', 'meat', 'sausage', 'fish', 'dairy',
  'cheese', 'eggs', 'bakery', 'grains', 'preserves', 'frozen', 'spices',
  'sauces', 'oils', 'breakfast', 'baking', 'drinks', 'sweets', 'other'
));

-- Remove every unique constraint that contains name but not note. Such a
-- constraint necessarily blocks legitimate variants, regardless of its name.
DO $$
DECLARE
  name_att SMALLINT;
  note_att SMALLINT;
  old_constraint RECORD;
  old_index RECORD;
BEGIN
  SELECT attnum INTO name_att
  FROM pg_attribute
  WHERE attrelid = 'public.foods'::regclass AND attname = 'name';

  SELECT attnum INTO note_att
  FROM pg_attribute
  WHERE attrelid = 'public.foods'::regclass AND attname = 'note';

  FOR old_constraint IN
    SELECT conname, pg_get_constraintdef(oid) AS definition
    FROM pg_constraint
    WHERE conrelid = 'public.foods'::regclass
      AND contype = 'u'
      AND name_att = ANY(conkey)
      AND NOT (note_att = ANY(conkey))
  LOOP
    RAISE NOTICE 'Dropping incompatible foods constraint %: %',
      old_constraint.conname, old_constraint.definition;
    EXECUTE format(
      'ALTER TABLE public.foods DROP CONSTRAINT %I',
      old_constraint.conname
    );
  END LOOP;

  -- Also remove standalone unique indexes, including expression indexes such
  -- as lower(name), when they do not include note.
  FOR old_index IN
    SELECT indexrelid::regclass AS index_name,
           pg_get_indexdef(indexrelid) AS definition
    FROM pg_index
    WHERE indrelid = 'public.foods'::regclass
      AND indisunique
      AND NOT indisprimary
      AND NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conindid = indexrelid
      )
      AND (
        (indexprs IS NULL AND name_att = ANY(indkey) AND NOT (note_att = ANY(indkey)))
        OR
        (indexprs IS NOT NULL
          AND pg_get_expr(indexprs, indrelid) ILIKE '%name%'
          AND pg_get_expr(indexprs, indrelid) NOT ILIKE '%note%')
      )
  LOOP
    RAISE NOTICE 'Dropping incompatible foods index %: %',
      old_index.index_name, old_index.definition;
    EXECUTE format('DROP INDEX %s', old_index.index_name);
  END LOOP;
END $$;

DROP INDEX IF EXISTS public.foods_household_name_note_unique;
CREATE UNIQUE INDEX foods_household_name_note_unique
  ON public.foods (
    household_id,
    LOWER(REGEXP_REPLACE(BTRIM(name), '\s+', ' ', 'g')),
    LOWER(REGEXP_REPLACE(BTRIM(COALESCE(note, '')), '\s+', ' ', 'g'))
  )
  WHERE household_id IS NOT NULL;

COMMENT ON COLUMN public.foods.icon_key IS
  'User-selected presentation icon; independent of food note and recipes.';
