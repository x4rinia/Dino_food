-- Restore the authenticated startup read path after household hardening.
-- Access remains membership-only; created_by and the legacy role are not used.

begin;

-- RLS policies call this helper for all household-scoped tables. Recreate it
-- with a fixed search_path and SECURITY DEFINER so querying household_members
-- from a household_members policy cannot recurse through RLS.
create or replace function public.is_household_member(h_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.household_members hm
    where hm.household_id = h_id
      and hm.user_id = auth.uid()
  );
$$;

revoke all on function public.is_household_member(uuid) from public;
grant execute on function public.is_household_member(uuid) to authenticated;

-- A user can always discover their own membership rows directly. Co-member
-- rows stay readable only after membership in the same household is proven.
drop policy if exists "Members can view co-members" on public.household_members;
create policy "Members can view co-members"
  on public.household_members for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_household_member(household_id)
  );

drop policy if exists "Members can view their households" on public.households;
create policy "Members can view their households"
  on public.households for select to authenticated
  using (public.is_household_member(id));

-- The favorite/current household is read from the authenticated user's own
-- profile during startup. This is additive to any co-member profile policy.
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile"
  on public.profiles for select to authenticated
  using (id = auth.uid());

commit;
