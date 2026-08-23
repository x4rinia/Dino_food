-- Dino Food: delete existing households only when they have zero memberships.
-- Run supabase_preflight_orphan_households.sql first and review its result.
-- Names and created_by are deliberately not part of the deletion predicate.

begin;

-- Preflight repeated inside the migration so the exact candidates are visible
-- immediately before deletion.
select h.id, h.name, h.created_by, h.created_at
from public.households h
where not exists (
  select 1 from public.household_members hm
  where hm.household_id = h.id
)
order by h.created_at, h.id;

delete from public.households h
where not exists (
  select 1 from public.household_members hm
  where hm.household_id = h.id
);

commit;
