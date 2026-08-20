-- ==============================================================================
-- Dino_food - Supabase Database Schema & Row Level Security (RLS)
-- Ausführbar im Supabase SQL Editor
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. PROFILES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL DEFAULT 'Dino-Freund',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by authenticated users"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Trigger: Automatische Profilerstellung bei Registrierung
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name)
    VALUES (
        new.id,
        COALESCE(
            NULLIF(trim(new.raw_user_meta_data->>'display_name'), ''),
            split_part(new.email, '@', 1),
            'Dino-Freund'
        )
    )
    ON CONFLICT (id) DO UPDATE
    SET display_name = EXCLUDED.display_name;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- ------------------------------------------------------------------------------
-- 2. HOUSEHOLDS
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_dino_invite_code()
RETURNS text AS $$
DECLARE
    chars text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    result text := 'DINO-';
    i integer;
BEGIN
    FOR i IN 1..4 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE TABLE IF NOT EXISTS public.households (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    color TEXT NOT NULL DEFAULT '#2A9D8F',
    invite_code TEXT UNIQUE NOT NULL DEFAULT public.generate_dino_invite_code(),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.households ENABLE ROW LEVEL SECURITY;


-- ------------------------------------------------------------------------------
-- 3. HOUSEHOLD MEMBERS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.household_members (
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (household_id, user_id)
);

ALTER TABLE public.household_members ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_household_member(h_id UUID)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.household_members
        WHERE household_id = h_id AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE POLICY "Members can view their households"
    ON public.households FOR SELECT
    TO authenticated
    USING (public.is_household_member(id));

CREATE POLICY "Authenticated users can create households"
    ON public.households FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = created_by OR created_by IS NULL);

CREATE POLICY "Members can update their household"
    ON public.households FOR UPDATE
    TO authenticated
    USING (public.is_household_member(id));

CREATE POLICY "Members can view co-members"
    ON public.household_members FOR SELECT
    TO authenticated
    USING (public.is_household_member(household_id));

CREATE POLICY "Authenticated users can join household"
    ON public.household_members FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id OR public.is_household_member(household_id));

CREATE POLICY "Members can leave or owners remove"
    ON public.household_members FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id OR public.is_household_member(household_id));


-- ------------------------------------------------------------------------------
-- 4. FOODS (Lebensmittel-Katalog pro Haushalt)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID REFERENCES public.households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Sonstiges',
    default_unit TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.foods ENABLE ROW LEVEL SECURITY;

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


-- ------------------------------------------------------------------------------
-- 5. SHOPPING ITEMS (Gemeinsame Einkaufsliste mit Notizen)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.shopping_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    food_id UUID REFERENCES public.foods(id) ON DELETE SET NULL,
    custom_name TEXT,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit TEXT NOT NULL DEFAULT '',
    note TEXT,
    checked BOOLEAN NOT NULL DEFAULT false,
    added_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT check_item_name CHECK (food_id IS NOT NULL OR (custom_name IS NOT NULL AND trim(custom_name) <> ''))
);

ALTER TABLE public.shopping_items ENABLE ROW LEVEL SECURITY;

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
-- 6. DISHES & DISH ITEMS (Gerichte, Zutaten & Notizen)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.dishes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    is_locked BOOLEAN NOT NULL DEFAULT false,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.dishes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Household members can view dishes"
    ON public.dishes FOR SELECT
    TO authenticated
    USING (public.is_household_member(household_id));

CREATE POLICY "Household members can create dishes"
    ON public.dishes FOR INSERT
    TO authenticated
    WITH CHECK (public.is_household_member(household_id));

CREATE POLICY "Household members can update dishes"
    ON public.dishes FOR UPDATE
    TO authenticated
    USING (public.is_household_member(household_id));

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


-- ------------------------------------------------------------------------------
-- 7. DISH FAVORITES (Favoriten pro Benutzer)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.dish_favorites (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    dish_id UUID NOT NULL REFERENCES public.dishes(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (user_id, dish_id)
);

ALTER TABLE public.dish_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own favorites"
    ON public.dish_favorites FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites"
    ON public.dish_favorites FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites"
    ON public.dish_favorites FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);


-- ------------------------------------------------------------------------------
-- 8. HOUSEHOLD STOCK (Vorrat pro Haushalt)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.household_stock (
    household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
    food_id UUID NOT NULL REFERENCES public.foods(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (household_id, food_id)
);

ALTER TABLE public.household_stock ENABLE ROW LEVEL SECURITY;

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


-- ------------------------------------------------------------------------------
-- 9. ATOMIC RPC FUNKTIONEN
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_household_and_join(
    name text,
    color text DEFAULT '#2A9D8F'
)
RETURNS public.households
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_household public.households;
    current_uid uuid;
BEGIN
    current_uid := auth.uid();
    IF current_uid IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    INSERT INTO public.households (name, color, created_by, invite_code)
    VALUES (trim(name), color, current_uid, public.generate_dino_invite_code())
    RETURNING * INTO new_household;

    INSERT INTO public.household_members (household_id, user_id, role)
    VALUES (new_household.id, current_uid, 'owner');

    RETURN new_household;
END;
$$;

CREATE OR REPLACE FUNCTION public.join_household_by_code(
    code text
)
RETURNS json AS $$
DECLARE
    target_household public.households;
    current_uid uuid := auth.uid();
BEGIN
    IF current_uid IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT * INTO target_household
    FROM public.households
    WHERE upper(trim(invite_code)) = upper(trim(code))
    LIMIT 1;

    IF target_household.id IS NULL THEN
        RAISE EXCEPTION 'Ungültiger Einladungscode. Bitte prüfe die Eingabe.';
    END IF;

    INSERT INTO public.household_members (household_id, user_id, role)
    VALUES (target_household.id, current_uid, 'member')
    ON CONFLICT (household_id, user_id) DO NOTHING;

    RETURN row_to_json(target_household);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ------------------------------------------------------------------------------
-- 10. REALTIME AKTIVIERUNG
-- ------------------------------------------------------------------------------
ALTER PUBLICATION supabase_realtime ADD TABLE public.shopping_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.household_members;
ALTER PUBLICATION supabase_realtime ADD TABLE public.household_stock;


-- ------------------------------------------------------------------------------
-- 11. SEED DATA (Basislebensmittel)
-- ------------------------------------------------------------------------------
INSERT INTO public.foods (name, category, default_unit) VALUES
('Milch', 'Milchprodukte & Eier', ''),
('Eier', 'Milchprodukte & Eier', ''),
('Brot', 'Brot & Backwaren', ''),
('Butter', 'Milchprodukte & Eier', ''),
('Käse', 'Milchprodukte & Eier', ''),
('Tomaten', 'Obst & Gemüse', ''),
('Kartoffeln', 'Obst & Gemüse', ''),
('Zwiebeln', 'Obst & Gemüse', ''),
('Nudeln', 'Vorrat & Teigwaren', ''),
('Reis', 'Vorrat & Teigwaren', ''),
('Hackfleisch', 'Fleisch & Fisch', ''),
('Paprika', 'Obst & Gemüse', ''),
('Gurke', 'Obst & Gemüse', ''),
('Äpfel', 'Obst & Gemüse', ''),
('Bananen', 'Obst & Gemüse', '')
ON CONFLICT DO NOTHING;
