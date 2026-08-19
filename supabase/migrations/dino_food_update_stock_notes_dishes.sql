-- ==============================================================================
-- Dino_food Migration: Notizen für Einkaufsartikel & Gerichte, Vorrat, Favoriten & Sperre
-- Datei: supabase/migrations/dino_food_update_stock_notes_dishes.sql
-- ==============================================================================

-- 1. Helper-Funktion für Haushaltszugehörigkeit sicherstellen
CREATE OR REPLACE FUNCTION public.is_household_member(h_id UUID)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.household_members
        WHERE household_id = h_id AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;


-- 2. Foreign Key auf profiles für shopping_items korrigieren
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'shopping_items_added_by_fkey'
    ) THEN
        ALTER TABLE public.shopping_items DROP CONSTRAINT shopping_items_added_by_fkey;
    END IF;
END $$;

ALTER TABLE public.shopping_items
    ADD CONSTRAINT shopping_items_added_by_fkey
    FOREIGN KEY (added_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


-- 3. Notiz-Spalte für shopping_items hinzufügen
ALTER TABLE public.shopping_items
    ADD COLUMN IF NOT EXISTS note TEXT;


-- 4. Gerichte-Tabelle (dishes) anlegen oder aktualisieren
CREATE TABLE IF NOT EXISTS public.dishes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    is_locked BOOLEAN NOT NULL DEFAULT false,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.dishes ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.dishes 
    ADD COLUMN IF NOT EXISTS is_locked BOOLEAN NOT NULL DEFAULT false;

DROP POLICY IF EXISTS "Household members can view dishes" ON public.dishes;
CREATE POLICY "Household members can view dishes"
    ON public.dishes FOR SELECT
    TO authenticated
    USING (public.is_household_member(household_id));

DROP POLICY IF EXISTS "Household members can create dishes" ON public.dishes;
CREATE POLICY "Household members can create dishes"
    ON public.dishes FOR INSERT
    TO authenticated
    WITH CHECK (public.is_household_member(household_id));

DROP POLICY IF EXISTS "Household members can update dishes" ON public.dishes;
CREATE POLICY "Household members can update dishes"
    ON public.dishes FOR UPDATE
    TO authenticated
    USING (public.is_household_member(household_id));


-- 5. Zutaten für Gerichte (dish_items) anlegen oder aktualisieren
CREATE TABLE IF NOT EXISTS public.dish_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dish_id UUID NOT NULL REFERENCES public.dishes(id) ON DELETE CASCADE,
    food_id UUID REFERENCES public.foods(id) ON DELETE CASCADE,
    custom_name TEXT,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 1,
    unit TEXT NOT NULL DEFAULT '',
    note TEXT
);

ALTER TABLE public.dish_items ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.dish_items
    ADD COLUMN IF NOT EXISTS note TEXT;

DROP POLICY IF EXISTS "Household members can view dish items" ON public.dish_items;
CREATE POLICY "Household members can view dish items"
    ON public.dish_items FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.dishes d
            WHERE d.id = dish_id AND public.is_household_member(d.household_id)
        )
    );

DROP POLICY IF EXISTS "Household members can insert dish items" ON public.dish_items;
CREATE POLICY "Household members can insert dish items"
    ON public.dish_items FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.dishes d
            WHERE d.id = dish_id AND public.is_household_member(d.household_id)
        )
    );

DROP POLICY IF EXISTS "Household members can update dish items" ON public.dish_items;
CREATE POLICY "Household members can update dish items"
    ON public.dish_items FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.dishes d
            WHERE d.id = dish_id AND public.is_household_member(d.household_id)
        )
    );

DROP POLICY IF EXISTS "Household members can delete dish items" ON public.dish_items;
CREATE POLICY "Household members can delete dish items"
    ON public.dish_items FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.dishes d
            WHERE d.id = dish_id AND public.is_household_member(d.household_id)
        )
    );


-- 6. Favoriten für Gerichte pro Benutzer (dish_favorites)
CREATE TABLE IF NOT EXISTS public.dish_favorites (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    dish_id UUID NOT NULL REFERENCES public.dishes(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (user_id, dish_id)
);

ALTER TABLE public.dish_favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own favorites" ON public.dish_favorites;
CREATE POLICY "Users can view own favorites"
    ON public.dish_favorites FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own favorites" ON public.dish_favorites;
CREATE POLICY "Users can insert own favorites"
    ON public.dish_favorites FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own favorites" ON public.dish_favorites;
CREATE POLICY "Users can delete own favorites"
    ON public.dish_favorites FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);


-- 7. Vorrat pro Haushalt (household_stock)
CREATE TABLE IF NOT EXISTS public.household_stock (
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    food_id UUID NOT NULL REFERENCES public.foods(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (household_id, food_id)
);

ALTER TABLE public.household_stock ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view household stock" ON public.household_stock;
CREATE POLICY "Members can view household stock"
    ON public.household_stock FOR SELECT
    TO authenticated
    USING (public.is_household_member(household_id));

DROP POLICY IF EXISTS "Members can insert household stock" ON public.household_stock;
CREATE POLICY "Members can insert household stock"
    ON public.household_stock FOR INSERT
    TO authenticated
    WITH CHECK (public.is_household_member(household_id));

DROP POLICY IF EXISTS "Members can delete household stock" ON public.household_stock;
CREATE POLICY "Members can delete household stock"
    ON public.household_stock FOR DELETE
    TO authenticated
    USING (public.is_household_member(household_id));


-- 8. Realtime Publikationen
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.shopping_items;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN others THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.household_stock;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN others THEN NULL;
END $$;
