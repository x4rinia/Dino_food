-- ==============================================================================
-- DINO_FOOD: EINMALIGE PRODUKTIV-REPARATUR FÜR FEHLENDE STANDARDGERICHTE
-- ==============================================================================
-- WICHTIG:
-- 1. Diese Reparatur ist 100% sicher für bestehende Daten.
-- 2. Bestehende Gerichte (eigene & Standards) werden NICHT gelöscht oder überschrieben.
-- 3. Fehlende Standardgerichte werden anhand der 10 Vorlagen ermittelt.
-- 4. Jede Zutat wird exakt gegen die 'foods'-Tabelle DESSELBEN Haushalts verlinkt.
-- 5. Es werden KEINE Standard-Lebensmittel ungefragt neu erzeugt.
-- 6. Es wird KEIN Re-Seeding-Trigger oder eine Heuristik hinterlassen.
-- ==============================================================================

DO $$
DECLARE
    hh RECORD;
    v_dish_id UUID;
    v_food_id UUID;
    v_dish_exists BOOLEAN;
    v_missing_food_count INT;
    v_missing_food_names TEXT;
    
    -- Template structure
    TYPE t_ingredient IS RECORD (name TEXT, qty NUMERIC);
BEGIN
    RAISE NOTICE '=== STARTE EINMALIGE PRODUKTIV-REPARATUR DER STANDARDGERICHTE ===';

    FOR hh IN SELECT id, name, created_by FROM public.households LOOP
        RAISE NOTICE '------------------------------------------------------------';
        RAISE NOTICE 'Prüfe Haushalt "%" (ID: %)...', hh.name, hh.id;

        -- 1. Spaghetti Bolognese
        SELECT EXISTS(SELECT 1 FROM public.dishes WHERE household_id = hh.id AND LOWER(TRIM(name)) = 'spaghetti bolognese') INTO v_dish_exists;
        IF NOT v_dish_exists THEN
            -- Check if all 6 foods exist
            IF (SELECT COUNT(DISTINCT LOWER(TRIM(name))) FROM public.foods WHERE household_id = hh.id AND LOWER(TRIM(name)) IN ('spaghetti', 'hackfleisch', 'passierte tomaten', 'tomatenmark', 'zwiebeln', 'knoblauch')) = 6 THEN
                INSERT INTO public.dishes (household_id, name, created_by) VALUES (hh.id, 'Spaghetti Bolognese', hh.created_by) RETURNING id INTO v_dish_id;
                INSERT INTO public.dish_items (dish_id, food_id, quantity)
                SELECT v_dish_id, f.id, 
                    CASE LOWER(TRIM(f.name))
                        WHEN 'spaghetti' THEN 1.0
                        WHEN 'hackfleisch' THEN 1.0
                        WHEN 'passierte tomaten' THEN 1.0
                        WHEN 'tomatenmark' THEN 1.0
                        WHEN 'zwiebeln' THEN 1.0
                        WHEN 'knoblauch' THEN 1.0
                    END
                FROM public.foods f WHERE f.household_id = hh.id AND LOWER(TRIM(f.name)) IN ('spaghetti', 'hackfleisch', 'passierte tomaten', 'tomatenmark', 'zwiebeln', 'knoblauch');
                RAISE NOTICE '  [+] "Spaghetti Bolognese" erfolgreich wiederhergestellt.';
            ELSE
                RAISE NOTICE '  [!] "Spaghetti Bolognese" übersprungen (nicht alle 6 Zutaten im Haushalt vorhanden).';
            END IF;
        ELSE
            RAISE NOTICE '  [=] "Spaghetti Bolognese" existiert bereits (unverändert).';
        END IF;

        -- 2. Chili con Carne
        SELECT EXISTS(SELECT 1 FROM public.dishes WHERE household_id = hh.id AND LOWER(TRIM(name)) = 'chili con carne') INTO v_dish_exists;
        IF NOT v_dish_exists THEN
            IF (SELECT COUNT(DISTINCT LOWER(TRIM(name))) FROM public.foods WHERE household_id = hh.id AND LOWER(TRIM(name)) IN ('hackfleisch', 'kidneybohnen', 'mais', 'gehackte tomaten', 'zwiebeln', 'paprika')) = 6 THEN
                INSERT INTO public.dishes (household_id, name, created_by) VALUES (hh.id, 'Chili con Carne', hh.created_by) RETURNING id INTO v_dish_id;
                INSERT INTO public.dish_items (dish_id, food_id, quantity)
                SELECT v_dish_id, f.id, 1.0
                FROM public.foods f WHERE f.household_id = hh.id AND LOWER(TRIM(f.name)) IN ('hackfleisch', 'kidneybohnen', 'mais', 'gehackte tomaten', 'zwiebeln', 'paprika');
                RAISE NOTICE '  [+] "Chili con Carne" erfolgreich wiederhergestellt.';
            ELSE
                RAISE NOTICE '  [!] "Chili con Carne" übersprungen (Zutaten fehlen).';
            END IF;
        ELSE
            RAISE NOTICE '  [=] "Chili con Carne" existiert bereits (unverändert).';
        END IF;

        -- 3. Kartoffelauflauf
        SELECT EXISTS(SELECT 1 FROM public.dishes WHERE household_id = hh.id AND LOWER(TRIM(name)) = 'kartoffelauflauf') INTO v_dish_exists;
        IF NOT v_dish_exists THEN
            IF (SELECT COUNT(DISTINCT LOWER(TRIM(name))) FROM public.foods WHERE household_id = hh.id AND LOWER(TRIM(name)) IN ('kartoffeln', 'sahne', 'reibekäse', 'zwiebeln', 'kochschinken')) = 5 THEN
                INSERT INTO public.dishes (household_id, name, created_by) VALUES (hh.id, 'Kartoffelauflauf', hh.created_by) RETURNING id INTO v_dish_id;
                INSERT INTO public.dish_items (dish_id, food_id, quantity)
                SELECT v_dish_id, f.id, 
                    CASE LOWER(TRIM(f.name))
                        WHEN 'kartoffeln' THEN 6.0
                        ELSE 1.0
                    END
                FROM public.foods f WHERE f.household_id = hh.id AND LOWER(TRIM(f.name)) IN ('kartoffeln', 'sahne', 'reibekäse', 'zwiebeln', 'kochschinken');
                RAISE NOTICE '  [+] "Kartoffelauflauf" erfolgreich wiederhergestellt.';
            ELSE
                RAISE NOTICE '  [!] "Kartoffelauflauf" übersprungen (Zutaten fehlen).';
            END IF;
        ELSE
            RAISE NOTICE '  [=] "Kartoffelauflauf" existiert bereits (unverändert).';
        END IF;

        -- 4. Nudelauflauf
        SELECT EXISTS(SELECT 1 FROM public.dishes WHERE household_id = hh.id AND LOWER(TRIM(name)) = 'nudelauflauf') INTO v_dish_exists;
        IF NOT v_dish_exists THEN
            IF (SELECT COUNT(DISTINCT LOWER(TRIM(name))) FROM public.foods WHERE household_id = hh.id AND LOWER(TRIM(name)) IN ('penne', 'kochschinken', 'sahne', 'reibekäse', 'tomaten')) = 5 THEN
                INSERT INTO public.dishes (household_id, name, created_by) VALUES (hh.id, 'Nudelauflauf', hh.created_by) RETURNING id INTO v_dish_id;
                INSERT INTO public.dish_items (dish_id, food_id, quantity)
                SELECT v_dish_id, f.id, 
                    CASE LOWER(TRIM(f.name))
                        WHEN 'tomaten' THEN 2.0
                        ELSE 1.0
                    END
                FROM public.foods f WHERE f.household_id = hh.id AND LOWER(TRIM(f.name)) IN ('penne', 'kochschinken', 'sahne', 'reibekäse', 'tomaten');
                RAISE NOTICE '  [+] "Nudelauflauf" erfolgreich wiederhergestellt.';
            ELSE
                RAISE NOTICE '  [!] "Nudelauflauf" übersprungen (Zutaten fehlen).';
            END IF;
        ELSE
            RAISE NOTICE '  [=] "Nudelauflauf" existiert bereits (unverändert).';
        END IF;

        -- 5. Gemüse-Reis-Pfanne
        SELECT EXISTS(SELECT 1 FROM public.dishes WHERE household_id = hh.id AND LOWER(TRIM(name)) = 'gemüse-reis-pfanne') INTO v_dish_exists;
        IF NOT v_dish_exists THEN
            IF (SELECT COUNT(DISTINCT LOWER(TRIM(name))) FROM public.foods WHERE household_id = hh.id AND LOWER(TRIM(name)) IN ('reis', 'paprika', 'zucchini', 'karotten', 'zwiebeln', 'erbsen')) = 6 THEN
                INSERT INTO public.dishes (household_id, name, created_by) VALUES (hh.id, 'Gemüse-Reis-Pfanne', hh.created_by) RETURNING id INTO v_dish_id;
                INSERT INTO public.dish_items (dish_id, food_id, quantity)
                SELECT v_dish_id, f.id, 
                    CASE LOWER(TRIM(f.name))
                        WHEN 'paprika' THEN 2.0
                        WHEN 'karotten' THEN 2.0
                        ELSE 1.0
                    END
                FROM public.foods f WHERE f.household_id = hh.id AND LOWER(TRIM(f.name)) IN ('reis', 'paprika', 'zucchini', 'karotten', 'zwiebeln', 'erbsen');
                RAISE NOTICE '  [+] "Gemüse-Reis-Pfanne" erfolgreich wiederhergestellt.';
            ELSE
                RAISE NOTICE '  [!] "Gemüse-Reis-Pfanne" übersprungen (Zutaten fehlen).';
            END IF;
        ELSE
            RAISE NOTICE '  [=] "Gemüse-Reis-Pfanne" existiert bereits (unverändert).';
        END IF;

        -- 6. Bratkartoffeln mit Spiegelei
        SELECT EXISTS(SELECT 1 FROM public.dishes WHERE household_id = hh.id AND LOWER(TRIM(name)) = 'bratkartoffeln mit spiegelei') INTO v_dish_exists;
        IF NOT v_dish_exists THEN
            IF (SELECT COUNT(DISTINCT LOWER(TRIM(name))) FROM public.foods WHERE household_id = hh.id AND LOWER(TRIM(name)) IN ('kartoffeln', 'eier', 'zwiebeln', 'bacon')) = 4 THEN
                INSERT INTO public.dishes (household_id, name, created_by) VALUES (hh.id, 'Bratkartoffeln mit Spiegelei', hh.created_by) RETURNING id INTO v_dish_id;
                INSERT INTO public.dish_items (dish_id, food_id, quantity)
                SELECT v_dish_id, f.id, 
                    CASE LOWER(TRIM(f.name))
                        WHEN 'kartoffeln' THEN 6.0
                        WHEN 'eier' THEN 4.0
                        ELSE 1.0
                    END
                FROM public.foods f WHERE f.household_id = hh.id AND LOWER(TRIM(f.name)) IN ('kartoffeln', 'eier', 'zwiebeln', 'bacon');
                RAISE NOTICE '  [+] "Bratkartoffeln mit Spiegelei" erfolgreich wiederhergestellt.';
            ELSE
                RAISE NOTICE '  [!] "Bratkartoffeln mit Spiegelei" übersprungen (Zutaten fehlen).';
            END IF;
        ELSE
            RAISE NOTICE '  [=] "Bratkartoffeln mit Spiegelei" existiert bereits (unverändert).';
        END IF;

        -- 7. Wraps
        SELECT EXISTS(SELECT 1 FROM public.dishes WHERE household_id = hh.id AND LOWER(TRIM(name)) = 'wraps') INTO v_dish_exists;
        IF NOT v_dish_exists THEN
            IF (SELECT COUNT(DISTINCT LOWER(TRIM(name))) FROM public.foods WHERE household_id = hh.id AND LOWER(TRIM(name)) IN ('wraps', 'hackfleisch', 'tomaten', 'gurke', 'eisbergsalat', 'reibekäse')) = 6 THEN
                INSERT INTO public.dishes (household_id, name, created_by) VALUES (hh.id, 'Wraps', hh.created_by) RETURNING id INTO v_dish_id;
                INSERT INTO public.dish_items (dish_id, food_id, quantity)
                SELECT v_dish_id, f.id, 
                    CASE LOWER(TRIM(f.name))
                        WHEN 'tomaten' THEN 2.0
                        ELSE 1.0
                    END
                FROM public.foods f WHERE f.household_id = hh.id AND LOWER(TRIM(f.name)) IN ('wraps', 'hackfleisch', 'tomaten', 'gurke', 'eisbergsalat', 'reibekäse');
                RAISE NOTICE '  [+] "Wraps" erfolgreich wiederhergestellt.';
            ELSE
                RAISE NOTICE '  [!] "Wraps" übersprungen (Zutaten fehlen).';
            END IF;
        ELSE
            RAISE NOTICE '  [=] "Wraps" existiert bereits (unverändert).';
        END IF;

        -- 8. Tomaten-Mozzarella-Pasta
        SELECT EXISTS(SELECT 1 FROM public.dishes WHERE household_id = hh.id AND LOWER(TRIM(name)) = 'tomaten-mozzarella-pasta') INTO v_dish_exists;
        IF NOT v_dish_exists THEN
            IF (SELECT COUNT(DISTINCT LOWER(TRIM(name))) FROM public.foods WHERE household_id = hh.id AND LOWER(TRIM(name)) IN ('nudeln', 'tomaten', 'mozzarella', 'basilikum', 'knoblauch')) = 5 THEN
                INSERT INTO public.dishes (household_id, name, created_by) VALUES (hh.id, 'Tomaten-Mozzarella-Pasta', hh.created_by) RETURNING id INTO v_dish_id;
                INSERT INTO public.dish_items (dish_id, food_id, quantity)
                SELECT v_dish_id, f.id, 
                    CASE LOWER(TRIM(f.name))
                        WHEN 'tomaten' THEN 4.0
                        WHEN 'mozzarella' THEN 2.0
                        ELSE 1.0
                    END
                FROM public.foods f WHERE f.household_id = hh.id AND LOWER(TRIM(f.name)) IN ('nudeln', 'tomaten', 'mozzarella', 'basilikum', 'knoblauch');
                RAISE NOTICE '  [+] "Tomaten-Mozzarella-Pasta" erfolgreich wiederhergestellt.';
            ELSE
                RAISE NOTICE '  [!] "Tomaten-Mozzarella-Pasta" übersprungen (Zutaten fehlen).';
            END IF;
        ELSE
            RAISE NOTICE '  [=] "Tomaten-Mozzarella-Pasta" existiert bereits (unverändert).';
        END IF;

        -- 9. Kartoffelsuppe
        SELECT EXISTS(SELECT 1 FROM public.dishes WHERE household_id = hh.id AND LOWER(TRIM(name)) = 'kartoffelsuppe') INTO v_dish_exists;
        IF NOT v_dish_exists THEN
            IF (SELECT COUNT(DISTINCT LOWER(TRIM(name))) FROM public.foods WHERE household_id = hh.id AND LOWER(TRIM(name)) IN ('kartoffeln', 'karotten', 'lauch', 'zwiebeln', 'gemüsebrühe', 'sahne')) = 6 THEN
                INSERT INTO public.dishes (household_id, name, created_by) VALUES (hh.id, 'Kartoffelsuppe', hh.created_by) RETURNING id INTO v_dish_id;
                INSERT INTO public.dish_items (dish_id, food_id, quantity)
                SELECT v_dish_id, f.id, 
                    CASE LOWER(TRIM(f.name))
                        WHEN 'kartoffeln' THEN 6.0
                        WHEN 'karotten' THEN 3.0
                        ELSE 1.0
                    END
                FROM public.foods f WHERE f.household_id = hh.id AND LOWER(TRIM(f.name)) IN ('kartoffeln', 'karotten', 'lauch', 'zwiebeln', 'gemüsebrühe', 'sahne');
                RAISE NOTICE '  [+] "Kartoffelsuppe" erfolgreich wiederhergestellt.';
            ELSE
                RAISE NOTICE '  [!] "Kartoffelsuppe" übersprungen (Zutaten fehlen).';
            END IF;
        ELSE
            RAISE NOTICE '  [=] "Kartoffelsuppe" existiert bereits (unverändert).';
        END IF;

        -- 10. Hähnchen-Reis-Pfanne
        SELECT EXISTS(SELECT 1 FROM public.dishes WHERE household_id = hh.id AND LOWER(TRIM(name)) = 'hähnchen-reis-pfanne') INTO v_dish_exists;
        IF NOT v_dish_exists THEN
            IF (SELECT COUNT(DISTINCT LOWER(TRIM(name))) FROM public.foods WHERE household_id = hh.id AND LOWER(TRIM(name)) IN ('hähnchenbrust', 'reis', 'paprika', 'zucchini', 'zwiebeln', 'kochsahne')) = 6 THEN
                INSERT INTO public.dishes (household_id, name, created_by) VALUES (hh.id, 'Hähnchen-Reis-Pfanne', hh.created_by) RETURNING id INTO v_dish_id;
                INSERT INTO public.dish_items (dish_id, food_id, quantity)
                SELECT v_dish_id, f.id, 
                    CASE LOWER(TRIM(f.name))
                        WHEN 'paprika' THEN 2.0
                        ELSE 1.0
                    END
                FROM public.foods f WHERE f.household_id = hh.id AND LOWER(TRIM(f.name)) IN ('hähnchenbrust', 'reis', 'paprika', 'zucchini', 'zwiebeln', 'kochsahne');
                RAISE NOTICE '  [+] "Hähnchen-Reis-Pfanne" erfolgreich wiederhergestellt.';
            ELSE
                RAISE NOTICE '  [!] "Hähnchen-Reis-Pfanne" übersprungen (Zutaten fehlen).';
            END IF;
        ELSE
            RAISE NOTICE '  [=] "Hähnchen-Reis-Pfanne" existiert bereits (unverändert).';
        END IF;

    END LOOP;
    RAISE NOTICE '=== PRODUKTIV-REPARATUR ERFOLGREICH BEENDET ===';
END $$;

-- Kontroll-Abfrage zur Überprüfung aller Gerichte und deren Zutatenanzahl pro Haushalt
SELECT 
    h.name AS haushalt_name,
    d.name AS gericht_name,
    COUNT(di.id) AS zutaten_anzahl,
    d.created_at
FROM public.dishes d
JOIN public.households h ON h.id = d.household_id
LEFT JOIN public.dish_items di ON di.dish_id = d.id
GROUP BY h.name, d.id, d.name, d.created_at
ORDER BY h.name, d.name;
