-- ==============================================================================
-- Dino_food: Migration für haushaltsbezogene Lebensmittel (foods)
-- Ausführbar im Supabase SQL Editor
-- ==============================================================================

-- 1. Fügt die Spalte household_id zur foods Tabelle hinzu (falls noch nicht vorhanden)
ALTER TABLE public.foods 
ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES public.households(id) ON DELETE CASCADE;

-- 2. Aktualisiere die RLS-Policies für foods, damit Haushaltsmitglieder ihre Lebensmittel verwalten können
DROP POLICY IF EXISTS "Foods are viewable by authenticated users" ON public.foods;
DROP POLICY IF EXISTS "Authenticated users can add custom foods" ON public.foods;
DROP POLICY IF EXISTS "Authenticated users can update foods" ON public.foods;
DROP POLICY IF EXISTS "Authenticated users can delete foods" ON public.foods;
DROP POLICY IF EXISTS "Household members can view foods" ON public.foods;
DROP POLICY IF EXISTS "Household members can add foods" ON public.foods;
DROP POLICY IF EXISTS "Household members can update foods" ON public.foods;
DROP POLICY IF EXISTS "Household members can delete foods" ON public.foods;

CREATE POLICY "Household members can view foods"
    ON public.foods FOR SELECT
    TO authenticated
    USING (household_id IS NULL OR public.is_household_member(household_id));

CREATE POLICY "Household members can add foods"
    ON public.foods FOR INSERT
    TO authenticated
    WITH CHECK (household_id IS NULL OR public.is_household_member(household_id));

CREATE POLICY "Household members can update foods"
    ON public.foods FOR UPDATE
    TO authenticated
    USING (household_id IS NULL OR public.is_household_member(household_id));

CREATE POLICY "Household members can delete foods"
    ON public.foods FOR DELETE
    TO authenticated
    USING (household_id IS NULL OR public.is_household_member(household_id));
