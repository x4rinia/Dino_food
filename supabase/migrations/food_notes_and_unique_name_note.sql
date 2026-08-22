-- Replace the food category with an optional free-text note without dropping
-- legacy columns that older deployed clients may still require.

ALTER TABLE public.foods
ADD COLUMN IF NOT EXISTS note TEXT;

-- Deliberately do not copy category into note. Category values describe the
-- retired classification system and are not user-authored food notes.

-- The old global name constraint prevents two variants such as
-- "Reis / Basmati" and "Reis / Jasmin" in the same household.
ALTER TABLE public.foods DROP CONSTRAINT IF EXISTS foods_name_unique;
ALTER TABLE public.foods DROP CONSTRAINT IF EXISTS foods_name_key;
DROP INDEX IF EXISTS public.foods_name_unique;

-- Enforce the new rule when existing data is already clean. Existing rows are
-- never deleted or rewritten merely to make the index fit.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.foods
    WHERE household_id IS NOT NULL
    GROUP BY
      household_id,
      LOWER(REGEXP_REPLACE(BTRIM(name), '\s+', ' ', 'g')),
      LOWER(REGEXP_REPLACE(BTRIM(COALESCE(note, '')), '\s+', ' ', 'g'))
    HAVING COUNT(*) > 1
  ) THEN
    CREATE UNIQUE INDEX IF NOT EXISTS foods_household_name_note_unique
      ON public.foods (
        household_id,
        LOWER(REGEXP_REPLACE(BTRIM(name), '\s+', ' ', 'g')),
        LOWER(REGEXP_REPLACE(BTRIM(COALESCE(note, '')), '\s+', ' ', 'g'))
      )
      WHERE household_id IS NOT NULL;
  ELSE
    RAISE NOTICE 'foods_household_name_note_unique was not created because duplicate legacy rows exist.';
  END IF;
END $$;

COMMENT ON COLUMN public.foods.note IS
  'Optional free-text food note; replaces the legacy category in the app.';
