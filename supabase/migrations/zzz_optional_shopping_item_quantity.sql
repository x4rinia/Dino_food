-- Reuse the legacy shopping_items.quantity column exclusively as an optional
-- shopping-list count. It must not default to 1 and must be a positive integer.

ALTER TABLE public.shopping_items
ADD COLUMN IF NOT EXISTS quantity NUMERIC;

ALTER TABLE public.shopping_items
ALTER COLUMN quantity DROP DEFAULT;

ALTER TABLE public.shopping_items
ALTER COLUMN quantity DROP NOT NULL;

-- Values of 1 came from the former mandatory database default and were never
-- entered through the current shopping UI. Clear them so existing rows do not
-- suddenly display an artificial count. Invalid legacy values are cleared as
-- well; meaningful positive whole numbers above 1 are retained.
UPDATE public.shopping_items
SET quantity = NULL
WHERE quantity = 1
   OR quantity <= 0
   OR quantity <> TRUNC(quantity);

ALTER TABLE public.shopping_items
ALTER COLUMN quantity TYPE INTEGER
USING quantity::INTEGER;

ALTER TABLE public.shopping_items
DROP CONSTRAINT IF EXISTS shopping_items_quantity_check;

ALTER TABLE public.shopping_items
DROP CONSTRAINT IF EXISTS shopping_items_quantity_positive_integer;

ALTER TABLE public.shopping_items
ADD CONSTRAINT shopping_items_quantity_positive_integer
CHECK (quantity IS NULL OR quantity > 0);

COMMENT ON COLUMN public.shopping_items.quantity IS
  'Optional positive whole-number count shown only on the shopping list.';
