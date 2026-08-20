-- ==============================================================================
-- Dino_food: Reparatur- & Synchronisations-Migration für bestehende Datenbanken
-- Dateiname: supabase_repair_household_food_links.sql
--
-- ZWECK DIESER MIGRATION:
-- 1. Bestehende globale/legacy Lebensmittel (household_id IS NULL) für jeden
--    existierenden Haushalt sicher als haushaltseigene Lebensmittel duplizieren.
-- 2. Alle bestehenden Referenzen (household_stock, shopping_items, dish_items)
--    auf die korrekten haushaltsspezifischen food_id-Werte umstellen.
-- 3. Keine Daten löschen! Vorrat, Einkaufsliste und Gerichte bleiben vollständig erhalten.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. HILFSFUNKTION FÜR HAUSHALTSMITGLIEDSCHAFT
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
-- 2. TABELLENSPALTEN SICHERSTELLEN
-- ------------------------------------------------------------------------------
ALTER TABLE public.foods 
ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES public.households(id) ON DELETE CASCADE;

ALTER TABLE public.dishes 
ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES public.households(id) ON DELETE CASCADE;

ALTER TABLE public.dishes 
ADD COLUMN IF NOT EXISTS is_locked BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.dishes 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;


-- ------------------------------------------------------------------------------
-- 3. DISHES OHNE HOUSEHOLD_ID DEM ERSTELLER-HAUSHALT ZUORDNEN
-- ------------------------------------------------------------------------------
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
-- 4. GLOBALE / ALTE LEBENSMITTEL (household_id IS NULL) FÜR JEDEN HAUSHALT KOPIEREN
-- ------------------------------------------------------------------------------
-- Erstellt für jeden bestehenden Haushalt eine eigene Kopie aller globalen Lebensmittel,
-- falls der Haushalt nicht bereits ein Lebensmittel mit demselben Namen besitzt.
INSERT INTO public.foods (id, household_id, name, category, default_unit, created_at)
SELECT 
    gen_random_uuid(),
    h.id,
    g.name,
    g.category,
    g.default_unit,
    COALESCE(g.created_at, timezone('utc'::text, now()))
FROM public.households h
CROSS JOIN public.foods g
WHERE g.household_id IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM public.foods f2 
      WHERE f2.household_id = h.id 
        AND lower(trim(f2.name)) = lower(trim(g.name))
  );


-- ------------------------------------------------------------------------------
-- 5. VORRAT (household_stock) AUF HAUSHALTSSPEZIFISCHE FOOD-IDS REMAPPEN
-- ------------------------------------------------------------------------------
-- Falls Einträge im Vorrat noch auf alte/globale food_ids zeigen:
-- Aktualisiere sie auf die neue food_id desselben Haushalts mit demselben Namen.
UPDATE public.household_stock hs
SET food_id = f_new.id
FROM public.foods f_old
JOIN public.foods f_new 
  ON lower(trim(f_new.name)) = lower(trim(f_old.name))
WHERE f_old.id = hs.food_id
  AND f_new.household_id = hs.household_id
  AND (f_old.household_id IS NULL OR f_old.household_id != hs.household_id);


-- ------------------------------------------------------------------------------
-- 6. EINKAUFSLISTE (shopping_items) AUF HAUSHALTSSPEZIFISCHE FOOD-IDS REMAPPEN
-- ------------------------------------------------------------------------------
UPDATE public.shopping_items si
SET food_id = f_new.id
FROM public.foods f_old
JOIN public.foods f_new 
  ON lower(trim(f_new.name)) = lower(trim(f_old.name))
WHERE f_old.id = si.food_id
  AND f_new.household_id = si.household_id
  AND (f_old.household_id IS NULL OR f_old.household_id != si.household_id);


-- ------------------------------------------------------------------------------
-- 7. GERICHTE-ZUTATEN (dish_items) AUF HAUSHALTSSPEZIFISCHE FOOD-IDS REMAPPEN
-- ------------------------------------------------------------------------------
UPDATE public.dish_items di
SET food_id = f_new.id
FROM public.dishes d
JOIN public.foods f_old ON f_old.id = di.food_id
JOIN public.foods f_new 
  ON lower(trim(f_new.name)) = lower(trim(f_old.name))
 AND f_new.household_id = d.household_id
WHERE d.id = di.dish_id
  AND d.household_id IS NOT NULL
  AND (f_old.household_id IS NULL OR f_old.household_id != d.household_id);


-- ------------------------------------------------------------------------------
-- 8. PERFORMANCE-INDIZES
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_foods_household_id ON public.foods(household_id);
CREATE INDEX IF NOT EXISTS idx_dishes_household_id ON public.dishes(household_id);
CREATE INDEX IF NOT EXISTS idx_dish_items_dish_id ON public.dish_items(dish_id);
CREATE INDEX IF NOT EXISTS idx_dish_items_food_id ON public.dish_items(food_id);
CREATE INDEX IF NOT EXISTS idx_household_stock_hh_food ON public.household_stock(household_id, food_id);
CREATE INDEX IF NOT EXISTS idx_shopping_items_household_id ON public.shopping_items(household_id);
CREATE INDEX IF NOT EXISTS idx_household_members_user_id ON public.household_members(user_id);


-- ------------------------------------------------------------------------------
-- 9. ROW LEVEL SECURITY (RLS) POLICIES AKTUALISIEREN
-- ------------------------------------------------------------------------------
ALTER TABLE public.foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dish_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.household_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;

-- 9a. FOODS POLICIES
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


-- 9b. DISHES POLICIES
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


-- 9c. DISH ITEMS POLICIES
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


-- 9d. HOUSEHOLD STOCK POLICIES
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


-- 9e. SHOPPING ITEMS POLICIES
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
-- 10. REALTIME AKTIVIERUNG
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
-- 11. ALTE / UNVOLLSTÄNDIGE SEED-FUNKTION ENTFERNEN
-- ------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.seed_household_defaults(UUID, UUID);
DROP FUNCTION IF EXISTS public.seed_household_defaults(UUID);
