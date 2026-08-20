-- ==============================================================================
-- Dino_food - Migration: Default/Favorit Haushalt & Haushalt löschen
-- Datei: supabase/migrations/add_default_household.sql
-- Ausführbar im Supabase SQL Editor
-- ==============================================================================

-- 1. Spalte default_household_id zu profiles hinzufügen (falls noch nicht vorhanden)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS default_household_id UUID NULL;

-- 2. Foreign Key Constraint zu households(id) mit ON DELETE SET NULL
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'profiles_default_household_id_fkey'
    ) THEN
        ALTER TABLE public.profiles
        ADD CONSTRAINT profiles_default_household_id_fkey
        FOREIGN KEY (default_household_id)
        REFERENCES public.households(id)
        ON DELETE SET NULL;
    END IF;
END $$;

-- 3. RLS-DELETE-Policy auf households für den Inhaber (Owner)
DROP POLICY IF EXISTS "Owners can delete household" ON public.households;
CREATE POLICY "Owners can delete household"
    ON public.households FOR DELETE
    TO authenticated
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.household_members
            WHERE household_id = households.id
              AND user_id = auth.uid()
              AND role = 'owner'
        )
    );

-- 4. Bestehende Benutzer migrieren:
-- Für Benutzer ohne default_household_id einen ihrer existierenden Haushalte als Standard setzen
UPDATE public.profiles p
SET default_household_id = (
    SELECT hm.household_id
    FROM public.household_members hm
    WHERE hm.user_id = p.id
    ORDER BY hm.joined_at ASC
    LIMIT 1
)
WHERE p.default_household_id IS NULL;
