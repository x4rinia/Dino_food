-- ==============================================================================
-- Migration: TASK 2 – Dino_food: Standard-Lebensmittel & Gerichte für neue Haushalte
-- Dateiname: supabase_migration_task2_defaults.sql
-- ==============================================================================

-- 1. Index-Optimierungen für performante Haushalts-Queries
CREATE INDEX IF NOT EXISTS idx_foods_household_id ON public.foods(household_id);
CREATE INDEX IF NOT EXISTS idx_dishes_household_id ON public.dishes(household_id);
CREATE INDEX IF NOT EXISTS idx_dish_items_dish_id ON public.dish_items(dish_id);
CREATE INDEX IF NOT EXISTS idx_dish_items_food_id ON public.dish_items(food_id);
CREATE INDEX IF NOT EXISTS idx_household_stock_hh_food ON public.household_stock(household_id, food_id);

-- 2. Optional: Server-seitige Hilfsfunktion zum Initialisieren der Standarddaten
-- Hinweis: Die App initialisiert neue Haushalte auch automatisch und idempotent im Client-Service.
CREATE OR REPLACE FUNCTION public.seed_household_defaults(target_household_id UUID, target_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    f_tomaten UUID; f_cherrytomaten UUID; f_gurke UUID; f_paprika UUID; f_zwiebeln UUID;
    f_knoblauch UUID; f_karotten UUID; f_zucchini UUID; f_lauch UUID; f_spinat UUID;
    f_eisbergsalat UUID; f_mais UUID; f_erbsen UUID; f_kidneybohnen UUID;
    f_kartoffeln UUID; f_hackfleisch UUID; f_haehnchenbrust UUID; f_eier UUID;
    f_kochschinken UUID; f_bacon UUID; f_sahne UUID; f_kochsahne UUID;
    f_mozzarella UUID; f_reibekaese UUID; f_wraps UUID; f_nudeln UUID;
    f_spaghetti UUID; f_penne UUID; f_reis UUID; f_passierte_tomaten UUID;
    f_gehackte_tomaten UUID; f_tomatenmark UUID; f_gemuesebruehe UUID; f_basilikum UUID;
    
    d_spaghetti UUID; d_chili UUID; d_kartoffelauflauf UUID; d_nudelauflauf UUID;
    d_gemuese_reis UUID; d_bratkartoffeln UUID; d_wraps UUID; d_pasta UUID;
    d_kartoffelsuppe UUID; d_haehnchen_reis UUID;
BEGIN
    -- Prüfen, ob bereits Lebensmittel für diesen Haushalt existieren
    IF EXISTS (SELECT 1 FROM public.foods WHERE household_id = target_household_id LIMIT 1) THEN
        RETURN;
    END IF;

    -- Standard-Lebensmittel für diesen Haushalt anlegen
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Tomaten', 'Gemüse', '') RETURNING id INTO f_tomaten;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Cherrytomaten', 'Gemüse', '') RETURNING id INTO f_cherrytomaten;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Gurke', 'Gemüse', '') RETURNING id INTO f_gurke;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Paprika', 'Gemüse', '') RETURNING id INTO f_paprika;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Zwiebeln', 'Gemüse', '') RETURNING id INTO f_zwiebeln;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Knoblauch', 'Gemüse', '') RETURNING id INTO f_knoblauch;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Karotten', 'Gemüse', '') RETURNING id INTO f_karotten;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Zucchini', 'Gemüse', '') RETURNING id INTO f_zucchini;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Lauch', 'Gemüse', '') RETURNING id INTO f_lauch;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Eisbergsalat', 'Gemüse', '') RETURNING id INTO f_eisbergsalat;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Mais', 'Gemüse', '') RETURNING id INTO f_mais;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Erbsen', 'Gemüse', '') RETURNING id INTO f_erbsen;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Kidneybohnen', 'Gemüse', '') RETURNING id INTO f_kidneybohnen;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Kartoffeln', 'Kartoffeln', '') RETURNING id INTO f_kartoffeln;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Hackfleisch', 'Fleisch', '') RETURNING id INTO f_hackfleisch;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Hähnchenbrust', 'Fleisch', '') RETURNING id INTO f_haehnchenbrust;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Kochschinken', 'Wurst', '') RETURNING id INTO f_kochschinken;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Bacon', 'Wurst', '') RETURNING id INTO f_bacon;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Sahne', 'Milchprodukte', '') RETURNING id INTO f_sahne;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Kochsahne', 'Milchprodukte', '') RETURNING id INTO f_kochsahne;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Mozzarella', 'Käse', '') RETURNING id INTO f_mozzarella;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Reibekäse', 'Käse', '') RETURNING id INTO f_reibekaese;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Eier', 'Eier', '') RETURNING id INTO f_eier;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Wraps', 'Brot & Backwaren', '') RETURNING id INTO f_wraps;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Nudeln', 'Nudeln & Reis', '') RETURNING id INTO f_nudeln;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Spaghetti', 'Nudeln & Reis', '') RETURNING id INTO f_spaghetti;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Penne', 'Nudeln & Reis', '') RETURNING id INTO f_penne;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Reis', 'Nudeln & Reis', '') RETURNING id INTO f_reis;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Passierte Tomaten', 'Konserven & Gläser', '') RETURNING id INTO f_passierte_tomaten;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Gehackte Tomaten', 'Konserven & Gläser', '') RETURNING id INTO f_gehackte_tomaten;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Tomatenmark', 'Konserven & Gläser', '') RETURNING id INTO f_tomatenmark;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Basilikum', 'Gewürze', '') RETURNING id INTO f_basilikum;
    INSERT INTO public.foods (household_id, name, category, default_unit) VALUES
    (target_household_id, 'Gemüsebrühe', 'Gewürze', '') RETURNING id INTO f_gemuesebruehe;

    -- Standard-Gerichte anlegen und dish_items verknüpfen
    -- 1. Spaghetti Bolognese
    INSERT INTO public.dishes (household_id, name, created_by) VALUES (target_household_id, 'Spaghetti Bolognese', target_user_id) RETURNING id INTO d_spaghetti;
    INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES
    (d_spaghetti, f_spaghetti, 1.0), (d_spaghetti, f_hackfleisch, 1.0), (d_spaghetti, f_passierte_tomaten, 1.0),
    (d_spaghetti, f_tomatenmark, 1.0), (d_spaghetti, f_zwiebeln, 1.0), (d_spaghetti, f_knoblauch, 1.0);

    -- 2. Chili con Carne
    INSERT INTO public.dishes (household_id, name, created_by) VALUES (target_household_id, 'Chili con Carne', target_user_id) RETURNING id INTO d_chili;
    INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES
    (d_chili, f_hackfleisch, 1.0), (d_chili, f_kidneybohnen, 1.0), (d_chili, f_mais, 1.0),
    (d_chili, f_gehackte_tomaten, 1.0), (d_chili, f_zwiebeln, 1.0), (d_chili, f_paprika, 1.0);

    -- 3. Kartoffelauflauf
    INSERT INTO public.dishes (household_id, name, created_by) VALUES (target_household_id, 'Kartoffelauflauf', target_user_id) RETURNING id INTO d_kartoffelauflauf;
    INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES
    (d_kartoffelauflauf, f_kartoffeln, 6.0), (d_kartoffelauflauf, f_sahne, 1.0), (d_kartoffelauflauf, f_reibekaese, 1.0),
    (d_kartoffelauflauf, f_zwiebeln, 1.0), (d_kartoffelauflauf, f_kochschinken, 1.0);

    -- 4. Nudelauflauf
    INSERT INTO public.dishes (household_id, name, created_by) VALUES (target_household_id, 'Nudelauflauf', target_user_id) RETURNING id INTO d_nudelauflauf;
    INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES
    (d_nudelauflauf, f_penne, 1.0), (d_nudelauflauf, f_kochschinken, 1.0), (d_nudelauflauf, f_sahne, 1.0),
    (d_nudelauflauf, f_reibekaese, 1.0), (d_nudelauflauf, f_tomaten, 2.0);

    -- 5. Gemüse-Reis-Pfanne
    INSERT INTO public.dishes (household_id, name, created_by) VALUES (target_household_id, 'Gemüse-Reis-Pfanne', target_user_id) RETURNING id INTO d_gemuese_reis;
    INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES
    (d_gemuese_reis, f_reis, 1.0), (d_gemuese_reis, f_paprika, 2.0), (d_gemuese_reis, f_zucchini, 1.0),
    (d_gemuese_reis, f_karotten, 2.0), (d_gemuese_reis, f_zwiebeln, 1.0), (d_gemuese_reis, f_erbsen, 1.0);

    -- 6. Bratkartoffeln mit Spiegelei
    INSERT INTO public.dishes (household_id, name, created_by) VALUES (target_household_id, 'Bratkartoffeln mit Spiegelei', target_user_id) RETURNING id INTO d_bratkartoffeln;
    INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES
    (d_bratkartoffeln, f_kartoffeln, 6.0), (d_bratkartoffeln, f_eier, 4.0), (d_bratkartoffeln, f_zwiebeln, 1.0), (d_bratkartoffeln, f_bacon, 1.0);

    -- 7. Wraps
    INSERT INTO public.dishes (household_id, name, created_by) VALUES (target_household_id, 'Wraps', target_user_id) RETURNING id INTO d_wraps;
    INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES
    (d_wraps, f_wraps, 1.0), (d_wraps, f_hackfleisch, 1.0), (d_wraps, f_tomaten, 2.0),
    (d_wraps, f_gurke, 1.0), (d_wraps, f_eisbergsalat, 1.0), (d_wraps, f_reibekaese, 1.0);

    -- 8. Tomaten-Mozzarella-Pasta
    INSERT INTO public.dishes (household_id, name, created_by) VALUES (target_household_id, 'Tomaten-Mozzarella-Pasta', target_user_id) RETURNING id INTO d_pasta;
    INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES
    (d_pasta, f_nudeln, 1.0), (d_pasta, f_tomaten, 4.0), (d_pasta, f_mozzarella, 2.0),
    (d_pasta, f_basilikum, 1.0), (d_pasta, f_knoblauch, 1.0);

    -- 9. Kartoffelsuppe
    INSERT INTO public.dishes (household_id, name, created_by) VALUES (target_household_id, 'Kartoffelsuppe', target_user_id) RETURNING id INTO d_kartoffelsuppe;
    INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES
    (d_kartoffelsuppe, f_kartoffeln, 6.0), (d_kartoffelsuppe, f_karotten, 3.0), (d_kartoffelsuppe, f_lauch, 1.0),
    (d_kartoffelsuppe, f_zwiebeln, 1.0), (d_kartoffelsuppe, f_gemuesebruehe, 1.0), (d_kartoffelsuppe, f_sahne, 1.0);

    -- 10. Hähnchen-Reis-Pfanne
    INSERT INTO public.dishes (household_id, name, created_by) VALUES (target_household_id, 'Hähnchen-Reis-Pfanne', target_user_id) RETURNING id INTO d_haehnchen_reis;
    INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES
    (d_haehnchen_reis, f_haehnchenbrust, 1.0), (d_haehnchen_reis, f_reis, 1.0), (d_haehnchen_reis, f_paprika, 2.0),
    (d_haehnchen_reis, f_zucchini, 1.0), (d_haehnchen_reis, f_zwiebeln, 1.0), (d_haehnchen_reis, f_kochsahne, 1.0);
END;
$$;
