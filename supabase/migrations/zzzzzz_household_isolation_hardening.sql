-- Dino Food: strict household isolation hardening
-- Review and run manually after supabase_diagnose_household_links.sql returns
-- no cross-household references. This migration never repairs or deletes data.

begin;

-- Household creation records attribution for bootstrap only. created_by never
-- grants read/update/delete access after membership has been initialized.
drop policy if exists "Authenticated users can create households" on public.households;
create policy "Authenticated users can create households"
  on public.households for insert to authenticated
  with check (created_by = auth.uid());

-- Legacy global foods are no longer readable or writable by normal clients.
drop policy if exists "Household members can view foods" on public.foods;
drop policy if exists "Household members can add foods" on public.foods;
drop policy if exists "Household members can update foods" on public.foods;
drop policy if exists "Household members can delete foods" on public.foods;

create policy "Household members can view foods"
  on public.foods for select to authenticated
  using (household_id is not null and public.is_household_member(household_id));
create policy "Household members can add foods"
  on public.foods for insert to authenticated
  with check (household_id is not null and public.is_household_member(household_id));
create policy "Household members can update foods"
  on public.foods for update to authenticated
  using (household_id is not null and public.is_household_member(household_id))
  with check (household_id is not null and public.is_household_member(household_id));
create policy "Household members can delete foods"
  on public.foods for delete to authenticated
  using (household_id is not null and public.is_household_member(household_id));

-- Reject mismatched food links even for users who belong to both households and
-- for privileged writers which bypass RLS.
create or replace function public.enforce_household_food_link()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  target_household_id uuid;
  food_household_id uuid;
begin
  if tg_table_name = 'dish_items' then
    select household_id into target_household_id
    from public.dishes where id = new.dish_id;
  else
    target_household_id := new.household_id;
  end if;

  if target_household_id is null then
    raise exception 'A household-scoped record requires a household';
  end if;

  if new.food_id is null then
    return new;
  end if;

  select household_id into food_household_id
  from public.foods where id = new.food_id;

  if food_household_id is null or food_household_id <> target_household_id then
    raise exception 'Food % does not belong to household %',
      new.food_id, target_household_id;
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_household_food_link on public.household_stock;
create trigger enforce_household_food_link
before insert or update on public.household_stock
for each row execute function public.enforce_household_food_link();

drop trigger if exists enforce_household_food_link on public.shopping_items;
create trigger enforce_household_food_link
before insert or update of household_id, food_id on public.shopping_items
for each row execute function public.enforce_household_food_link();

drop trigger if exists enforce_household_food_link on public.dish_items;
create trigger enforce_household_food_link
before insert or update of dish_id, food_id on public.dish_items
for each row execute function public.enforce_household_food_link();

-- Ownership keys are immutable. Moving an existing row between households can
-- otherwise modify the destination household for a user who belongs to both.
create or replace function public.prevent_household_reassignment()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if old.household_id is distinct from new.household_id then
    raise exception 'Changing household_id is not allowed';
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_household_reassignment on public.foods;
create trigger prevent_household_reassignment
before update of household_id on public.foods
for each row execute function public.prevent_household_reassignment();
drop trigger if exists prevent_household_reassignment on public.dishes;
create trigger prevent_household_reassignment
before update of household_id on public.dishes
for each row execute function public.prevent_household_reassignment();
drop trigger if exists prevent_household_reassignment on public.shopping_items;
create trigger prevent_household_reassignment
before update of household_id on public.shopping_items
for each row execute function public.prevent_household_reassignment();
drop trigger if exists prevent_household_reassignment on public.household_stock;
create trigger prevent_household_reassignment
before update of household_id on public.household_stock
for each row execute function public.prevent_household_reassignment();

create or replace function public.prevent_dish_item_reassignment()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if old.dish_id is distinct from new.dish_id then
    raise exception 'Changing dish_id is not allowed';
  end if;
  return new;
end;
$$;
drop trigger if exists prevent_dish_item_reassignment on public.dish_items;
create trigger prevent_dish_item_reassignment
before update of dish_id on public.dish_items
for each row execute function public.prevent_dish_item_reassignment();

-- RLS repeats the same relationship checks at the API boundary.
drop policy if exists "Members can view household stock" on public.household_stock;
drop policy if exists "Members can insert household stock" on public.household_stock;
drop policy if exists "Members can delete household stock" on public.household_stock;
create policy "Members can view household stock"
  on public.household_stock for select to authenticated
  using (
    public.is_household_member(household_id)
    and exists (select 1 from public.foods f
                where f.id = food_id and f.household_id = household_id)
  );
create policy "Members can insert household stock"
  on public.household_stock for insert to authenticated
  with check (
    public.is_household_member(household_id)
    and exists (select 1 from public.foods f
                where f.id = food_id and f.household_id = household_id)
  );
create policy "Members can delete household stock"
  on public.household_stock for delete to authenticated
  using (public.is_household_member(household_id));

drop policy if exists "Members can view shopping items" on public.shopping_items;
drop policy if exists "Members can add shopping items" on public.shopping_items;
drop policy if exists "Members can update shopping items" on public.shopping_items;
drop policy if exists "Members can delete shopping items" on public.shopping_items;
create policy "Members can view shopping items"
  on public.shopping_items for select to authenticated
  using (
    public.is_household_member(household_id)
    and (food_id is null or exists (select 1 from public.foods f
         where f.id = food_id and f.household_id = household_id))
  );
create policy "Members can add shopping items"
  on public.shopping_items for insert to authenticated
  with check (
    public.is_household_member(household_id)
    and (food_id is null or exists (select 1 from public.foods f
         where f.id = food_id and f.household_id = household_id))
  );
create policy "Members can update shopping items"
  on public.shopping_items for update to authenticated
  using (public.is_household_member(household_id))
  with check (
    public.is_household_member(household_id)
    and (food_id is null or exists (select 1 from public.foods f
         where f.id = food_id and f.household_id = household_id))
  );
create policy "Members can delete shopping items"
  on public.shopping_items for delete to authenticated
  using (public.is_household_member(household_id));

drop policy if exists "Household members can view dish items" on public.dish_items;
drop policy if exists "Household members can insert dish items" on public.dish_items;
drop policy if exists "Household members can update dish items" on public.dish_items;
drop policy if exists "Household members can delete dish items" on public.dish_items;
create policy "Household members can view dish items"
  on public.dish_items for select to authenticated
  using (exists (
    select 1 from public.dishes d
    where d.id = dish_id and public.is_household_member(d.household_id)
      and (food_id is null or exists (select 1 from public.foods f
           where f.id = food_id and f.household_id = d.household_id))
  ));
create policy "Household members can insert dish items"
  on public.dish_items for insert to authenticated
  with check (exists (
    select 1 from public.dishes d
    where d.id = dish_id and public.is_household_member(d.household_id)
      and (food_id is null or exists (select 1 from public.foods f
           where f.id = food_id and f.household_id = d.household_id))
  ));
create policy "Household members can update dish items"
  on public.dish_items for update to authenticated
  using (exists (select 1 from public.dishes d
                 where d.id = dish_id and public.is_household_member(d.household_id)))
  with check (exists (
    select 1 from public.dishes d
    where d.id = dish_id and public.is_household_member(d.household_id)
      and (food_id is null or exists (select 1 from public.foods f
           where f.id = food_id and f.household_id = d.household_id))
  ));
create policy "Household members can delete dish items"
  on public.dish_items for delete to authenticated
  using (exists (select 1 from public.dishes d
                 where d.id = dish_id and public.is_household_member(d.household_id)));

-- Favorites may only point at a dish visible through household membership.
drop policy if exists "Users can view own favorites" on public.dish_favorites;
drop policy if exists "Users can insert own favorites" on public.dish_favorites;
drop policy if exists "Users can delete own favorites" on public.dish_favorites;
create policy "Users can view own favorites"
  on public.dish_favorites for select to authenticated
  using (auth.uid() = user_id and exists (
    select 1 from public.dishes d
    where d.id = dish_id and public.is_household_member(d.household_id)
  ));
create policy "Users can insert own favorites"
  on public.dish_favorites for insert to authenticated
  with check (auth.uid() = user_id and exists (
    select 1 from public.dishes d
    where d.id = dish_id and public.is_household_member(d.household_id)
  ));
create policy "Users can delete own favorites"
  on public.dish_favorites for delete to authenticated
  using (auth.uid() = user_id and exists (
    select 1 from public.dishes d
    where d.id = dish_id and public.is_household_member(d.household_id)
  ));

-- Self-joining by an arbitrary household UUID was too broad. Joining remains
-- available only through the SECURITY DEFINER invite-code RPC. A direct insert
-- is allowed solely to initialize the first membership of a household which
-- the same authenticated user has just created. This is bootstrap logic, not a
-- privileged role.
drop policy if exists "Authenticated users can join household" on public.household_members;
drop policy if exists "Household creator can add self as owner" on public.household_members;
drop policy if exists "Household creator can initialize membership" on public.household_members;

create or replace function public.can_initialize_household_membership(
  h_id uuid,
  candidate_user_id uuid
)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select candidate_user_id = auth.uid()
    and exists (
      select 1 from public.households h
      where h.id = h_id and h.created_by = auth.uid()
    )
    and not exists (
      select 1 from public.household_members existing
      where existing.household_id = h_id
    );
$$;

create policy "Household creator can initialize membership"
  on public.household_members for insert to authenticated
  with check (
    role = 'member'
    and public.can_initialize_household_membership(household_id, user_id)
  );

drop policy if exists "Members can leave or owners remove" on public.household_members;
drop policy if exists "Members can remove household memberships" on public.household_members;
create policy "Members can remove household memberships"
  on public.household_members for delete to authenticated
  using (public.is_household_member(household_id));
drop function if exists public.is_household_owner(uuid);

drop policy if exists "Owners can delete household" on public.households;
drop policy if exists "Members can delete household" on public.households;
create policy "Members can delete household"
  on public.households for delete to authenticated
  using (public.is_household_member(id));

revoke all on function public.join_household_by_code(text) from public;
grant execute on function public.join_household_by_code(text) to authenticated;

commit;
