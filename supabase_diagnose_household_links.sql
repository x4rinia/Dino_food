-- ==============================================================================
-- Dino_food: Diagnose-Skript (REINE ABFRAGE - VERÄNDERT KEINE DATEN)
-- Dateiname: supabase_diagnose_household_links.sql
-- ==============================================================================

-- 1. Übersicht der Lebensmittel (Foods)
SELECT 
    COUNT(*) AS total_foods,
    COUNT(*) FILTER (WHERE household_id IS NULL) AS foods_with_null_household,
    COUNT(*) FILTER (WHERE household_id IS NOT NULL) AS foods_with_household
FROM public.foods;

-- 2. Lebensmittel pro Haushalt
SELECT 
    COALESCE(h.name, 'OHNE HAUSHALT (NULL)') AS haushalt_name,
    f.household_id,
    COUNT(*) AS anzahl_lebensmittel
FROM public.foods f
LEFT JOIN public.households h ON f.household_id = h.id
GROUP BY h.name, f.household_id
ORDER BY anzahl_lebensmittel DESC;

-- 3. Übersicht des Vorrats (household_stock)
SELECT 
    COALESCE(h.name, 'Unbekannter Haushalt') AS haushalt_name,
    hs.household_id,
    COUNT(*) AS anzahl_vorratseintraege
FROM public.household_stock hs
LEFT JOIN public.households h ON hs.household_id = h.id
GROUP BY h.name, hs.household_id;

-- 4. Vorratseinträge mit inkonsistenten oder alten Food-Referenzen
-- (z. B. wenn food_id auf ein globales Lebensmittel ohne household_id oder eines anderen Haushalts zeigt)
SELECT 
    hs.household_id AS stock_household_id,
    h.name AS haushalt_name,
    hs.food_id AS stock_food_id,
    f.name AS food_name,
    f.household_id AS food_actual_household_id,
    CASE 
        WHEN f.id IS NULL THEN 'LEBENSMITTEL EXISTIERT NICHT MEHR'
        WHEN f.household_id IS NULL THEN 'ZEIGT AUF GLOBALES/ALTES LEBENSMITTEL (NULL)'
        WHEN f.household_id != hs.household_id THEN 'ZEIGT AUF ANDEREN HAUSHALT'
        ELSE 'OK'
    END AS status
FROM public.household_stock hs
LEFT JOIN public.households h ON hs.household_id = h.id
LEFT JOIN public.foods f ON hs.food_id = f.id
WHERE f.id IS NULL OR f.household_id IS NULL OR f.household_id != hs.household_id;

-- 5. Gerichte-Zutaten (dish_items) mit inkonsistenten Food-Referenzen
SELECT 
    d.household_id AS dish_household_id,
    d.name AS gericht_name,
    di.food_id AS dish_item_food_id,
    f.name AS food_name,
    f.household_id AS food_actual_household_id,
    CASE 
        WHEN f.id IS NULL THEN 'LEBENSMITTEL EXISTIERT NICHT MEHR'
        WHEN f.household_id IS NULL THEN 'ZEIGT AUF GLOBALES/ALTES LEBENSMITTEL (NULL)'
        WHEN f.household_id != d.household_id THEN 'ZEIGT AUF ANDEREN HAUSHALT'
        ELSE 'OK'
    END AS status
FROM public.dish_items di
JOIN public.dishes d ON di.dish_id = d.id
LEFT JOIN public.foods f ON di.food_id = f.id
WHERE di.food_id IS NOT NULL AND (f.id IS NULL OR f.household_id IS NULL OR f.household_id != d.household_id);

-- 6. Einkaufsliste (shopping_items) mit inkonsistenten Food-Referenzen
SELECT 
    si.household_id AS shopping_household_id,
    si.custom_name,
    si.food_id AS shopping_food_id,
    f.name AS food_name,
    f.household_id AS food_actual_household_id,
    CASE 
        WHEN f.id IS NULL THEN 'LEBENSMITTEL EXISTIERT NICHT MEHR'
        WHEN f.household_id IS NULL THEN 'ZEIGT AUF GLOBALES/ALTES LEBENSMITTEL (NULL)'
        WHEN f.household_id != si.household_id THEN 'ZEIGT AUF ANDEREN HAUSHALT'
        ELSE 'OK'
    END AS status
FROM public.shopping_items si
LEFT JOIN public.foods f ON si.food_id = f.id
WHERE si.food_id IS NOT NULL AND (f.id IS NULL OR f.household_id IS NULL OR f.household_id != si.household_id);
