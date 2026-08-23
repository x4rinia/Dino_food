-- Dino Food: equal household membership and safe account deletion.
-- All household permissions depend on membership only. The legacy role column
-- remains for schema compatibility, but no longer grants special permissions.

begin;

alter table public.household_members
  alter column role set default 'member';

update public.household_members
set role = 'member'
where role is distinct from 'member';

create or replace function public.normalize_household_member_role()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.role := 'member';
  return new;
end;
$$;

drop trigger if exists normalize_household_member_role
  on public.household_members;
create trigger normalize_household_member_role
before insert or update of role on public.household_members
for each row execute function public.normalize_household_member_role();

-- Fail before installing account deletion if the expected cascade chain is not
-- present. No cleanup should rely on guessed constraint names.
do $$
declare
  expected record;
begin
  for expected in
    select * from (values
      ('public.foods', 'household_id', 'public.households'),
      ('public.household_stock', 'household_id', 'public.households'),
      ('public.shopping_items', 'household_id', 'public.households'),
      ('public.dishes', 'household_id', 'public.households'),
      ('public.dish_items', 'dish_id', 'public.dishes'),
      ('public.dish_favorites', 'dish_id', 'public.dishes')
    ) as required_fk(child_table, child_column, parent_table)
  loop
    if not exists (
      select 1
      from pg_constraint c
      join pg_attribute child_attribute
        on child_attribute.attrelid = c.conrelid
       and child_attribute.attname = expected.child_column::name
       and child_attribute.attnum > 0
       and not child_attribute.attisdropped
      where c.contype = 'f'
        and c.conrelid = expected.child_table::regclass
        and c.confrelid = expected.parent_table::regclass
        and c.confdeltype = 'c'
        and child_attribute.attnum = any(c.conkey)
    ) then
      raise exception 'Required ON DELETE CASCADE missing: %.% -> %',
        expected.child_table, expected.child_column, expected.parent_table;
    end if;
  end loop;
end;
$$;

-- Whenever the final membership disappears, delete exactly that household.
-- Direct household deletion already cascades memberships, so nested trigger
-- execution is ignored.
create or replace function public.delete_household_when_empty()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if pg_trigger_depth() > 1 then
    return old;
  end if;

  -- Serialize final-member decisions for concurrent leaves/account deletions.
  perform 1 from public.households h
  where h.id = old.household_id
  for update;

  if not exists (
    select 1 from public.household_members hm
    where hm.household_id = old.household_id
  ) then
    delete from public.households h
    where h.id = old.household_id;
  end if;
  return old;
end;
$$;

drop trigger if exists delete_household_when_empty
  on public.household_members;
create trigger delete_household_when_empty
after delete on public.household_members
for each row execute function public.delete_household_when_empty();

-- The client calls this RPC while the authenticated user still exists. It
-- removes all memberships first, letting the trigger keep shared households
-- and delete only newly empty ones, then removes the auth user.
create or replace function public.delete_user_account()
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  current_uid uuid := auth.uid();
begin
  if current_uid is null then
    raise exception 'Nicht authentifiziert';
  end if;

  -- Lock every affected household in a stable order. This prevents two members
  -- deleting their accounts concurrently from both observing a non-empty
  -- household and leaving it orphaned.
  perform h.id
  from public.households h
  join public.household_members hm on hm.household_id = h.id
  where hm.user_id = current_uid
  order by h.id
  for update of h;

  delete from public.household_members
  where user_id = current_uid;

  delete from auth.users
  where id = current_uid;
end;
$$;

revoke all on function public.delete_user_account() from public;
grant execute on function public.delete_user_account() to authenticated;

commit;
