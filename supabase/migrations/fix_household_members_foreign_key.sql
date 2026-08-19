-- ==============================================================================
-- Dino_food Migration: Foreign Key household_members -> profiles
-- Datei: supabase/migrations/fix_household_members_foreign_key.sql
-- ==============================================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'household_members_user_id_fkey'
    ) THEN
        ALTER TABLE public.household_members DROP CONSTRAINT household_members_user_id_fkey;
    END IF;
END $$;

ALTER TABLE public.household_members
    ADD CONSTRAINT household_members_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
