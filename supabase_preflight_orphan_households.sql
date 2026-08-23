-- READ-ONLY preflight: households with zero memberships and their dependent
-- row counts. Review this result before running the orphan cleanup migration.
select
  h.id as household_id,
  h.name as household_name,
  h.created_by,
  h.created_at,
  (select count(*) from public.foods f
   where f.household_id = h.id) as foods_count,
  (select count(*) from public.household_stock hs
   where hs.household_id = h.id) as stock_count,
  (select count(*) from public.shopping_items si
   where si.household_id = h.id) as shopping_items_count,
  (select count(*) from public.dishes d
   where d.household_id = h.id) as dishes_count,
  (select count(*) from public.dish_items di
   join public.dishes d on d.id = di.dish_id
   where d.household_id = h.id) as dish_items_count,
  (select count(*) from public.dish_favorites df
   join public.dishes d on d.id = df.dish_id
   where d.household_id = h.id) as dish_favorites_count
from public.households h
where not exists (
  select 1 from public.household_members hm
  where hm.household_id = h.id
)
order by h.created_at, h.id;
