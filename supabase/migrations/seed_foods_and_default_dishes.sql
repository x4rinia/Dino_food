-- ==============================================================================
-- Dino_food Seed & Migration: Große Lebensmittelliste & 10 Standard-Gerichte
-- Datei: supabase/migrations/seed_foods_and_default_dishes.sql
-- ==============================================================================

-- 1. Eindeutigen Constraint auf foods(name) sicherstellen (ohne Fehler wenn vorhanden)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'foods_name_unique'
    ) THEN
        ALTER TABLE public.foods ADD CONSTRAINT foods_name_unique UNIQUE (name);
    END IF;
EXCEPTION
    WHEN duplicate_table THEN NULL;
    WHEN others THEN NULL;
END $$;


-- 2. Große Lebensmittelliste (über 170 gebräuchliche Lebensmittel, idempotent)
INSERT INTO public.foods (name, category, default_unit) VALUES
-- Gemüse
('Tomaten', 'Gemüse', ''),
('Cherrytomaten', 'Gemüse', ''),
('Gurke', 'Gemüse', ''),
('Paprika', 'Gemüse', ''),
('Zwiebeln', 'Gemüse', ''),
('Rote Zwiebeln', 'Gemüse', ''),
('Frühlingszwiebeln', 'Gemüse', ''),
('Knoblauch', 'Gemüse', ''),
('Karotten', 'Gemüse', ''),
('Brokkoli', 'Gemüse', ''),
('Blumenkohl', 'Gemüse', ''),
('Zucchini', 'Gemüse', ''),
('Aubergine', 'Gemüse', ''),
('Champignons', 'Gemüse', ''),
('Lauch', 'Gemüse', ''),
('Sellerie', 'Gemüse', ''),
('Weißkohl', 'Gemüse', ''),
('Rotkohl', 'Gemüse', ''),
('Wirsing', 'Gemüse', ''),
('Rosenkohl', 'Gemüse', ''),
('Spinat', 'Gemüse', ''),
('Feldsalat', 'Gemüse', ''),
('Kopfsalat', 'Gemüse', ''),
('Eisbergsalat', 'Gemüse', ''),
('Rucola', 'Gemüse', ''),
('Mais', 'Gemüse', ''),
('Erbsen', 'Gemüse', ''),
('Grüne Bohnen', 'Gemüse', ''),
('Kidneybohnen', 'Gemüse', ''),
('Kichererbsen', 'Gemüse', ''),
('Linsen', 'Gemüse', ''),
('Kürbis', 'Gemüse', ''),
('Süßkartoffeln', 'Gemüse', ''),
('Radieschen', 'Gemüse', ''),
('Spargel', 'Gemüse', ''),
('Rote Bete', 'Gemüse', ''),
('Avocado', 'Gemüse', ''),
('Ingwer', 'Gemüse', ''),
('Peperoni', 'Gemüse', ''),
('Chinakohl', 'Gemüse', ''),
('Kohlrabi', 'Gemüse', ''),
('Fenchel', 'Gemüse', ''),

-- Obst
('Äpfel', 'Obst', ''),
('Bananen', 'Obst', ''),
('Birnen', 'Obst', ''),
('Orangen', 'Obst', ''),
('Mandarinen', 'Obst', ''),
('Zitronen', 'Obst', ''),
('Limetten', 'Obst', ''),
('Erdbeeren', 'Obst', ''),
('Himbeeren', 'Obst', ''),
('Heidelbeeren', 'Obst', ''),
('Brombeeren', 'Obst', ''),
('Weintrauben', 'Obst', ''),
('Kirschen', 'Obst', ''),
('Pfirsiche', 'Obst', ''),
('Nektarinen', 'Obst', ''),
('Pflaumen', 'Obst', ''),
('Kiwi', 'Obst', ''),
('Ananas', 'Obst', ''),
('Mango', 'Obst', ''),
('Wassermelone', 'Obst', ''),
('Honigmelone', 'Obst', ''),
('Grapefruit', 'Obst', ''),
('Granatapfel', 'Obst', ''),

-- Kartoffeln
('Kartoffeln', 'Kartoffeln', ''),
('Kartoffelpüree', 'Kartoffeln', ''),
('Kartoffelklöße', 'Kartoffeln', ''),
('Schupfnudeln', 'Kartoffeln', ''),
('Gnocchi', 'Kartoffeln', ''),

-- Fleisch
('Hackfleisch', 'Fleisch', ''),
('Rinderhackfleisch', 'Fleisch', ''),
('Schweinehackfleisch', 'Fleisch', ''),
('Hähnchenbrust', 'Fleisch', ''),
('Hähnchenschenkel', 'Fleisch', ''),
('Putenbrust', 'Fleisch', ''),
('Schweineschnitzel', 'Fleisch', ''),
('Schweinefilet', 'Fleisch', ''),
('Rindfleisch', 'Fleisch', ''),
('Rindersteak', 'Fleisch', ''),
('Gulaschfleisch', 'Fleisch', ''),
('Frikadellen', 'Fleisch', ''),
('Suppenfleisch', 'Fleisch', ''),

-- Wurst
('Kochschinken', 'Wurst', ''),
('Rohschinken', 'Wurst', ''),
('Salami', 'Wurst', ''),
('Fleischwurst', 'Wurst', ''),
('Bratwurst', 'Wurst', ''),
('Wiener Würstchen', 'Wurst', ''),
('Bacon', 'Wurst', ''),
('Aufschnitt', 'Wurst', ''),
('Leberkäse', 'Wurst', ''),
('Schinkenwürfel', 'Wurst', ''),

-- Fisch
('Lachs', 'Fisch', ''),
('Thunfisch', 'Fisch', ''),
('Thunfisch in Dose', 'Fisch', ''),
('Fischstäbchen', 'Fisch', ''),
('Seelachs', 'Fisch', ''),
('Garnelen', 'Fisch', ''),
('Forelle', 'Fisch', ''),
('Kabeljau', 'Fisch', ''),

-- Milchprodukte
('Milch', 'Milchprodukte', ''),
('Hafermilch', 'Milchprodukte', ''),
('Sahne', 'Milchprodukte', ''),
('Kochsahne', 'Milchprodukte', ''),
('Saure Sahne', 'Milchprodukte', ''),
('Schmand', 'Milchprodukte', ''),
('Joghurt', 'Milchprodukte', ''),
('Naturjoghurt', 'Milchprodukte', ''),
('Griechischer Joghurt', 'Milchprodukte', ''),
('Quark', 'Milchprodukte', ''),
('Butter', 'Milchprodukte', ''),
('Margarine', 'Milchprodukte', ''),
('Crème fraîche', 'Milchprodukte', ''),
('Buttermilch', 'Milchprodukte', ''),

-- Käse
('Käse', 'Käse', ''),
('Gouda', 'Käse', ''),
('Emmentaler', 'Käse', ''),
('Mozzarella', 'Käse', ''),
('Parmesan', 'Käse', ''),
('Feta', 'Käse', ''),
('Frischkäse', 'Käse', ''),
('Scheibenkäse', 'Käse', ''),
('Reibekäse', 'Käse', ''),
('Camembert', 'Käse', ''),
('Schafskäse', 'Käse', ''),
('Halloumi', 'Käse', ''),

-- Eier
('Eier', 'Eier', ''),

-- Brot & Backwaren
('Brot', 'Brot & Backwaren', ''),
('Toast', 'Brot & Backwaren', ''),
('Brötchen', 'Brot & Backwaren', ''),
('Baguette', 'Brot & Backwaren', ''),
('Vollkornbrot', 'Brot & Backwaren', ''),
('Knäckebrot', 'Brot & Backwaren', ''),
('Wraps', 'Brot & Backwaren', ''),
('Burgerbrötchen', 'Brot & Backwaren', ''),
('Hot-Dog-Brötchen', 'Brot & Backwaren', ''),
('Pizzateig', 'Brot & Backwaren', ''),
('Blätterteig', 'Brot & Backwaren', ''),
('Fladenbrot', 'Brot & Backwaren', ''),

-- Nudeln & Reis
('Nudeln', 'Nudeln & Reis', ''),
('Spaghetti', 'Nudeln & Reis', ''),
('Penne', 'Nudeln & Reis', ''),
('Fusilli', 'Nudeln & Reis', ''),
('Makkaroni', 'Nudeln & Reis', ''),
('Lasagneplatten', 'Nudeln & Reis', ''),
('Tortellini', 'Nudeln & Reis', ''),
('Reis', 'Nudeln & Reis', ''),
('Basmatireis', 'Nudeln & Reis', ''),
('Jasminreis', 'Nudeln & Reis', ''),
('Risottoreis', 'Nudeln & Reis', ''),
('Couscous', 'Nudeln & Reis', ''),
('Bulgur', 'Nudeln & Reis', ''),

-- Konserven & Gläser
('Passierte Tomaten', 'Konserven & Gläser', ''),
('Gehackte Tomaten', 'Konserven & Gläser', ''),
('Tomatenmark', 'Konserven & Gläser', ''),
('Weiße Bohnen', 'Konserven & Gläser', ''),
('Gewürzgurken', 'Konserven & Gläser', ''),
('Apfelmus', 'Konserven & Gläser', ''),
('Kokosmilch', 'Konserven & Gläser', ''),
('Sauerkraut', 'Konserven & Gläser', ''),
('Oliven', 'Konserven & Gläser', ''),

-- Tiefkühl
('Tiefkühlpizza', 'Tiefkühl', ''),
('Pommes', 'Tiefkühl', ''),
('Kroketten', 'Tiefkühl', ''),
('Tiefkühlgemüse', 'Tiefkühl', ''),
('Tiefkühlbrokkoli', 'Tiefkühl', ''),
('Tiefkühlspinat', 'Tiefkühl', ''),
('Tiefkühlerbsen', 'Tiefkühl', ''),
('Tiefkühlbeeren', 'Tiefkühl', ''),
('Eis', 'Tiefkühl', ''),

-- Gewürze
('Salz', 'Gewürze', ''),
('Pfeffer', 'Gewürze', ''),
('Paprikapulver', 'Gewürze', ''),
('Curry', 'Gewürze', ''),
('Knoblauchpulver', 'Gewürze', ''),
('Zwiebelpulver', 'Gewürze', ''),
('Oregano', 'Gewürze', ''),
('Basilikum', 'Gewürze', ''),
('Petersilie', 'Gewürze', ''),
('Schnittlauch', 'Gewürze', ''),
('Muskat', 'Gewürze', ''),
('Chili', 'Gewürze', ''),
('Kreuzkümmel', 'Gewürze', ''),
('Rosmarin', 'Gewürze', ''),
('Thymian', 'Gewürze', ''),
('Zimt', 'Gewürze', ''),
('Gemüsebrühe', 'Gewürze', ''),
('Fleischbrühe', 'Gewürze', ''),

-- Saucen
('Ketchup', 'Saucen', ''),
('Mayonnaise', 'Saucen', ''),
('Senf', 'Saucen', ''),
('BBQ-Sauce', 'Saucen', ''),
('Sojasauce', 'Saucen', ''),
('Sweet-Chili-Sauce', 'Saucen', ''),
('Currysauce', 'Saucen', ''),
('Tomatensauce', 'Saucen', ''),
('Pesto', 'Saucen', ''),
('Pesto Rosso', 'Saucen', ''),
('Remoulade', 'Saucen', ''),

-- Öle & Fette
('Olivenöl', 'Öle & Fette', ''),
('Sonnenblumenöl', 'Öle & Fette', ''),
('Rapsöl', 'Öle & Fette', ''),
('Essig', 'Öle & Fette', ''),
('Balsamico-Essig', 'Öle & Fette', ''),

-- Frühstück
('Haferflocken', 'Frühstück', ''),
('Cornflakes', 'Frühstück', ''),
('Müsli', 'Frühstück', ''),
('Marmelade', 'Frühstück', ''),
('Honig', 'Frühstück', ''),
('Nutella', 'Frühstück', ''),
('Erdnussbutter', 'Frühstück', ''),

-- Backen
('Mehl', 'Backen', ''),
('Zucker', 'Backen', ''),
('Puderzucker', 'Backen', ''),
('Backpulver', 'Backen', ''),
('Vanillezucker', 'Backen', ''),
('Kakao', 'Backen', ''),
('Schokolade', 'Backen', ''),
('Kuvertüre', 'Backen', ''),
('Hefe', 'Backen', ''),
('Speisestärke', 'Backen', ''),

-- Getränke
('Wasser', 'Getränke', ''),
('Mineralwasser', 'Getränke', ''),
('Cola', 'Getränke', ''),
('Limonade', 'Getränke', ''),
('Orangensaft', 'Getränke', ''),
('Apfelsaft', 'Getränke', ''),
('Kaffee', 'Getränke', ''),
('Tee', 'Getränke', ''),
('Bier', 'Getränke', ''),

-- Snacks
('Chips', 'Snacks', ''),
('Salzstangen', 'Snacks', ''),
('Nüsse', 'Snacks', ''),
('Kekse', 'Snacks', ''),
('Gummibärchen', 'Snacks', ''),
('Popcorn', 'Snacks', ''),
('Tortilla-Chips', 'Snacks', ''),

-- Sonstiges
('Paniermehl', 'Sonstiges', ''),
('Semmelbrösel', 'Sonstiges', ''),
('Backpapier', 'Sonstiges', ''),
('Alufolie', 'Sonstiges', ''),
('Küchenrolle', 'Sonstiges', ''),
('Mülltüten', 'Sonstiges', ''),
('Spülmittel', 'Sonstiges', '')

ON CONFLICT (name) DO UPDATE 
SET category = EXCLUDED.category;


-- 3. Prozedur zur Erstellung der 10 Standardgerichte für einen Haushalt
CREATE OR REPLACE FUNCTION public.seed_default_dishes_for_household(target_household_id UUID)
RETURNS void AS $$
DECLARE
    d_id UUID;
    f_id UUID;
BEGIN
    -- 1. Spaghetti Bolognese
    IF NOT EXISTS (SELECT 1 FROM public.dishes WHERE household_id = target_household_id AND name = 'Spaghetti Bolognese') THEN
        INSERT INTO public.dishes (household_id, name) VALUES (target_household_id, 'Spaghetti Bolognese') RETURNING id INTO d_id;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Spaghetti' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Hackfleisch' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Passierte Tomaten' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Tomatenmark' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Zwiebeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Knoblauch' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
    END IF;

    -- 2. Chili con Carne
    IF NOT EXISTS (SELECT 1 FROM public.dishes WHERE household_id = target_household_id AND name = 'Chili con Carne') THEN
        INSERT INTO public.dishes (household_id, name) VALUES (target_household_id, 'Chili con Carne') RETURNING id INTO d_id;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Hackfleisch' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Kidneybohnen' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Mais' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Gehackte Tomaten' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Zwiebeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Paprika' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
    END IF;

    -- 3. Kartoffelauflauf
    IF NOT EXISTS (SELECT 1 FROM public.dishes WHERE household_id = target_household_id AND name = 'Kartoffelauflauf') THEN
        INSERT INTO public.dishes (household_id, name) VALUES (target_household_id, 'Kartoffelauflauf') RETURNING id INTO d_id;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Kartoffeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 6); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Sahne' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Reibekäse' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Zwiebeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Kochschinken' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
    END IF;

    -- 4. Nudelauflauf
    IF NOT EXISTS (SELECT 1 FROM public.dishes WHERE household_id = target_household_id AND name = 'Nudelauflauf') THEN
        INSERT INTO public.dishes (household_id, name) VALUES (target_household_id, 'Nudelauflauf') RETURNING id INTO d_id;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Penne' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Kochschinken' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Sahne' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Reibekäse' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Tomaten' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 2); END IF;
    END IF;

    -- 5. Gemüse-Reis-Pfanne
    IF NOT EXISTS (SELECT 1 FROM public.dishes WHERE household_id = target_household_id AND name = 'Gemüse-Reis-Pfanne') THEN
        INSERT INTO public.dishes (household_id, name) VALUES (target_household_id, 'Gemüse-Reis-Pfanne') RETURNING id INTO d_id;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Reis' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Paprika' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 2); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Zucchini' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Karotten' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 2); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Zwiebeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Erbsen' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
    END IF;

    -- 6. Bratkartoffeln mit Spiegelei
    IF NOT EXISTS (SELECT 1 FROM public.dishes WHERE household_id = target_household_id AND name = 'Bratkartoffeln mit Spiegelei') THEN
        INSERT INTO public.dishes (household_id, name) VALUES (target_household_id, 'Bratkartoffeln mit Spiegelei') RETURNING id INTO d_id;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Kartoffeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 6); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Eier' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 4); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Zwiebeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Bacon' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
    END IF;

    -- 7. Wraps
    IF NOT EXISTS (SELECT 1 FROM public.dishes WHERE household_id = target_household_id AND name = 'Wraps') THEN
        INSERT INTO public.dishes (household_id, name) VALUES (target_household_id, 'Wraps') RETURNING id INTO d_id;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Wraps' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Hackfleisch' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Tomaten' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 2); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Gurke' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Eisbergsalat' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Reibekäse' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
    END IF;

    -- 8. Tomaten-Mozzarella-Pasta
    IF NOT EXISTS (SELECT 1 FROM public.dishes WHERE household_id = target_household_id AND name = 'Tomaten-Mozzarella-Pasta') THEN
        INSERT INTO public.dishes (household_id, name) VALUES (target_household_id, 'Tomaten-Mozzarella-Pasta') RETURNING id INTO d_id;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Nudeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Tomaten' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 4); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Mozzarella' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 2); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Basilikum' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Knoblauch' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
    END IF;

    -- 9. Kartoffelsuppe
    IF NOT EXISTS (SELECT 1 FROM public.dishes WHERE household_id = target_household_id AND name = 'Kartoffelsuppe') THEN
        INSERT INTO public.dishes (household_id, name) VALUES (target_household_id, 'Kartoffelsuppe') RETURNING id INTO d_id;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Kartoffeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 6); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Karotten' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 3); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Lauch' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Zwiebeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Gemüsebrühe' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Sahne' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
    END IF;

    -- 10. Hähnchen-Reis-Pfanne
    IF NOT EXISTS (SELECT 1 FROM public.dishes WHERE household_id = target_household_id AND name = 'Hähnchen-Reis-Pfanne') THEN
        INSERT INTO public.dishes (household_id, name) VALUES (target_household_id, 'Hähnchen-Reis-Pfanne') RETURNING id INTO d_id;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Hähnchenbrust' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Reis' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Paprika' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 2); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Zucchini' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Zwiebeln' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
        
        SELECT id INTO f_id FROM public.foods WHERE name = 'Kochsahne' LIMIT 1;
        IF f_id IS NOT NULL THEN INSERT INTO public.dish_items (dish_id, food_id, quantity) VALUES (d_id, f_id, 1); END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 4. Standardgerichte für alle bestehenden Haushalte befüllen
DO $$
DECLARE
    h RECORD;
BEGIN
    FOR h IN SELECT id FROM public.households LOOP
        PERFORM public.seed_default_dishes_for_household(h.id);
    END LOOP;
END $$;


-- 5. Automatisches Anlegen der 10 Gerichte bei neuen Haushalten in RPC Funktion
CREATE OR REPLACE FUNCTION public.create_household_and_join(
    name text,
    postal_code text DEFAULT ''
)
RETURNS json AS $$
DECLARE
    new_household public.households;
    current_uid uuid := auth.uid();
BEGIN
    IF current_uid IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF trim(name) = '' THEN
        RAISE EXCEPTION 'Haushaltsname darf nicht leer sein';
    END IF;

    INSERT INTO public.households (name, postal_code, created_by, invite_code)
    VALUES (trim(name), trim(postal_code), current_uid, public.generate_dino_invite_code())
    RETURNING * INTO new_household;

    INSERT INTO public.household_members (household_id, user_id, role)
    VALUES (new_household.id, current_uid, 'owner');

    -- Automatisch die 10 Standardgerichte initialisieren
    PERFORM public.seed_default_dishes_for_household(new_household.id);

    RETURN row_to_json(new_household);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
