-- ==============================================================================
-- Dino_food: Vollständige konsolidierte Migration für bestehende Datenbanken
-- Dateiname: supabase_migration_consolidated_household_schema.sql
-- 
-- SICHERHEITSHINWEIS:
-- - Keine Tabellen werden gelöscht (kein DROP TABLE).
-- - Keine bestehenden Daten werden gelöscht.
-- - Fehlende Spalten werden mit ADD COLUMN IF NOT EXISTS hinzugefügt.
-- - Idempotent und mehrfach ausführbar.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. HILFSFUNKTION FÜR HAUSHALTSMITGLIEDSCHAFT (STABLE & SECURITY DEFINER)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_household_member(h_id UUID)
RETURNS boolean AS $$
BEGIN
    IF h_id IS NULL THEN
        RETURN false;
    END IF;
    RETURN EXISTS (
        SELECT 1 FROM public.household_members
        WHERE household_id = h_id AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;


-- ------------------------------------------------------------------------------
-- 2. FEHLENDE SPALTEN & FOREIGN KEYS SICHER ERGÄNZEN
-- ------------------------------------------------------------------------------

-- foods: household_id ergänzen
ALTER TABLE public.foods 
ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES public.households(id) ON DELETE CASCADE;

-- dishes: household_id ergänzen
ALTER TABLE public.dishes 
ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES public.households(id) ON DELETE CASCADE;

-- dishes: is_locked ergänzen (Standard: false)
ALTER TABLE public.dishes 
ADD COLUMN IF NOT EXISTS is_locked BOOLEAN NOT NULL DEFAULT false;

-- dishes: created_by ergänzen (falls noch nicht vorhanden)
ALTER TABLE public.dishes 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;


-- ------------------------------------------------------------------------------
-- 3. BESTEHENDE DATEN SICHER ZUORDNEN (FALLS household_id BEI DISHES NOCH NULL WAR)
-- ------------------------------------------------------------------------------
-- Falls bereits Gerichte existieren, deren household_id NULL ist, werden diese
-- dem ersten Haushalt ihres Erstellers zugeordnet, damit sie nicht unsichtbar werden:
UPDATE public.dishes d
SET household_id = (
    SELECT hm.household_id 
    FROM public.household_members hm 
    WHERE hm.user_id = d.created_by 
    ORDER BY hm.joined_at ASC 
    LIMIT 1
)
WHERE d.household_id IS NULL AND d.created_by IS NOT NULL;


-- ------------------------------------------------------------------------------
-- 4. PERFORMANCE-INDIZES
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_foods_household_id ON public.foods(household_id);
CREATE INDEX IF NOT EXISTS idx_dishes_household_id ON public.dishes(household_id);
CREATE INDEX IF NOT EXISTS idx_dish_items_dish_id ON public.dish_items(dish_id);
CREATE INDEX IF NOT EXISTS idx_dish_items_food_id ON public.dish_items(food_id);
CREATE INDEX IF NOT EXISTS idx_household_stock_hh_food ON public.household_stock(household_id, food_id);
CREATE INDEX IF NOT EXISTS idx_shopping_items_household_id ON public.shopping_items(household_id);
CREATE INDEX IF NOT EXISTS idx_household_members_user_id ON public.household_members(user_id);


-- ------------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) POLICIES AKTUALISIEREN
-- ------------------------------------------------------------------------------

-- RLS aktivieren (falls noch nicht aktiv)
ALTER TABLE public.foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dish_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.household_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;

-- 5a. FOODS POLICIES
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


-- 5b. DISHES POLICIES
DROP POLICY IF EXISTS "Dishes are viewable by authenticated users" ON public.dishes;
DROP POLICY IF EXISTS "Authenticated users can create dishes" ON public.dishes;
DROP POLICY IF EXISTS "Authenticated users can update dishes" ON public.dishes;
DROP POLICY IF EXISTS "Authenticated users can delete dishes" ON public.dishes;
DROP POLICY IF EXISTS "Household members can view dishes" ON public.dishes;
DROP POLICY IF EXISTS "Household members can create dishes" ON public.dishes;
DROP POLICY IF EXISTS "Household members can update dishes" ON public.dishes;
DROP POLICY IF EXISTS "Household members can delete dishes" ON public.dishes;

CREATE POLICY "Household members can view dishes"
    ON public.dishes FOR SELECT
    TO authenticated
    USING (household_id IS NOT NULL AND public.is_household_member(household_id));

CREATE POLICY "Household members can create dishes"
    ON public.dishes FOR INSERT
    TO authenticated
    WITH CHECK (household_id IS NOT NULL AND public.is_household_member(household_id));

CREATE POLICY "Household members can update dishes"
    ON public.dishes FOR UPDATE
    TO authenticated
    USING (household_id IS NOT NULL AND public.is_household_member(household_id));

CREATE POLICY "Household members can delete dishes"
    ON public.dishes FOR DELETE
    TO authenticated
    USING (household_id IS NOT NULL AND public.is_household_member(household_id));


-- 5c. DISH ITEMS POLICIES
DROP POLICY IF EXISTS "Dish items are viewable by authenticated users" ON public.dish_items;
DROP POLICY IF EXISTS "Authenticated users can insert dish items" ON public.dish_items;
DROP POLICY IF EXISTS "Authenticated users can update dish items" ON public.dish_items;
DROP POLICY IF EXISTS "Authenticated users can delete dish items" ON public.dish_items;
DROP POLICY IF EXISTS "Household members can view dish items" ON public.dish_items;
DROP POLICY IF EXISTS "Household members can insert dish items" ON public.dish_items;
DROP POLICY IF EXISTS "Household members can update dish items" ON public.dish_items;
DROP POLICY IF EXISTS "Household members can delete dish items" ON public.dish_items;

CREATE POLICY "Household members can view dish items"
    ON public.dish_items FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.dishes d
            WHERE d.id = dish_id AND public.is_household_member(d.household_id)
        )
    );

CREATE POLICY "Household members can insert dish items"
    ON public.dish_items FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.dishes d
            WHERE d.id = dish_id AND public.is_household_member(d.household_id)
        )
    );

CREATE POLICY "Household members can update dish items"
    ON public.dish_items FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.dishes d
            WHERE d.id = dish_id AND public.is_household_member(d.household_id)
        )
    );

CREATE POLICY "Household members can delete dish items"
    ON public.dish_items FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.dishes d
            WHERE d.id = dish_id AND public.is_household_member(d.household_id)
        )
    );


-- 5d. HOUSEHOLD STOCK POLICIES
DROP POLICY IF EXISTS "Members can view household stock" ON public.household_stock;
DROP POLICY IF EXISTS "Members can insert household stock" ON public.household_stock;
DROP POLICY IF EXISTS "Members can delete household stock" ON public.household_stock;

CREATE POLICY "Members can view household stock"
    ON public.household_stock FOR SELECT
    TO authenticated
    USING (public.is_household_member(household_id));

CREATE POLICY "Members can insert household stock"
    ON public.household_stock FOR INSERT
    TO authenticated
    WITH CHECK (public.is_household_member(household_id));

CREATE POLICY "Members can delete household stock"
    ON public.household_stock FOR DELETE
    TO authenticated
    USING (public.is_household_member(household_id));


-- 5e. SHOPPING ITEMS POLICIES
DROP POLICY IF EXISTS "Members can view shopping items" ON public.shopping_items;
DROP POLICY IF EXISTS "Members can add shopping items" ON public.shopping_items;
DROP POLICY IF EXISTS "Members can update shopping items" ON public.shopping_items;
DROP POLICY IF EXISTS "Members can delete shopping items" ON public.shopping_items;

CREATE POLICY "Members can view shopping items"
    ON public.shopping_items FOR SELECT
    TO authenticated
    USING (public.is_household_member(household_id));

CREATE POLICY "Members can add shopping items"
    ON public.shopping_items FOR INSERT
    TO authenticated
    WITH CHECK (public.is_household_member(household_id));

CREATE POLICY "Members can update shopping items"
    ON public.shopping_items FOR UPDATE
    TO authenticated
    USING (public.is_household_member(household_id));

CREATE POLICY "Members can delete shopping items"
    ON public.shopping_items FOR DELETE
    TO authenticated
    USING (public.is_household_member(household_id));


-- ------------------------------------------------------------------------------
-- 6. REALTIME REGISTRIERUNG SICHERSTELLEN
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.shopping_items;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.household_members;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.household_stock;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- ------------------------------------------------------------------------------
-- 7. ALTE / UNVOLLSTÄNDIGE SEED-FUNKTION ENTFERNEN (VERMEIDET INKONSISTENZEN)
-- ------------------------------------------------------------------------------
-- Die Initialisierung der ~245 Standard-Lebensmittel und 10 Standardgerichte
-- wird vollständig und konsistent durch die Flutter-Applikation übernommen.
DROP FUNCTION IF EXISTS public.seed_household_defaults(UUID, UUID);
DROP FUNCTION IF EXISTS public.seed_household_defaults(UUID);
