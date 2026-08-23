-- The Flutter services are the single authoritative source for defaults in a
-- newly created household. These compatibility stubs neutralize older
-- server-side seeders that may still be called by an installed RPC or trigger.
--
-- This migration intentionally performs no UPDATE or DELETE and therefore
-- leaves every existing household, food and dish unchanged.

CREATE OR REPLACE FUNCTION public.seed_household_defaults(
  target_household_id UUID,
  target_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  RETURN;
END;
$$;

COMMENT ON FUNCTION public.seed_household_defaults(UUID, UUID) IS
  'Deprecated no-op. New household defaults are seeded by the Flutter services.';

CREATE OR REPLACE FUNCTION public.seed_default_dishes_for_household(
  target_household_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  RETURN;
END;
$$;

COMMENT ON FUNCTION public.seed_default_dishes_for_household(UUID) IS
  'Deprecated no-op. New household defaults are seeded by the Flutter services.';
