-- Follow-up for databases where the earlier food-note migration has already
-- been recorded as applied. Food variants are unique per household by their
-- normalized name and normalized optional note.

ALTER TABLE public.foods DROP CONSTRAINT IF EXISTS foods_name_unique;
ALTER TABLE public.foods DROP CONSTRAINT IF EXISTS foods_name_key;
DROP INDEX IF EXISTS public.foods_name_unique;

-- Recreate the expression index so NULL, empty and whitespace-only notes all
-- represent the same variant. Creating the index intentionally fails if
-- legacy duplicate variants exist; those rows require an explicit data choice.
DROP INDEX IF EXISTS public.foods_household_name_note_unique;
CREATE UNIQUE INDEX foods_household_name_note_unique
  ON public.foods (
    household_id,
    LOWER(REGEXP_REPLACE(BTRIM(name), '\s+', ' ', 'g')),
    LOWER(REGEXP_REPLACE(BTRIM(COALESCE(note, '')), '\s+', ' ', 'g'))
  )
  WHERE household_id IS NOT NULL;
