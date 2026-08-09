CREATE OR REPLACE FUNCTION public.check_vps_auth_hash(user_email text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    u_rec RECORD;
BEGIN
    SELECT id, email, encrypted_password, email_confirmed_at, instance_id, aud, role
    INTO u_rec
    FROM auth.users
    WHERE email = user_email;

    IF u_rec.id IS NULL THEN
        RETURN jsonb_build_object('status', 'NOT_FOUND');
    END IF;

    RETURN jsonb_build_object(
        'status', 'FOUND',
        'id', u_rec.id,
        'email', u_rec.email,
        'has_hash', u_rec.encrypted_password IS NOT NULL,
        'hash_length', char_length(COALESCE(u_rec.encrypted_password, '')),
        'hash_prefix', substring(COALESCE(u_rec.encrypted_password, '') from 1 for 10),
        'email_confirmed_at', u_rec.email_confirmed_at,
        'instance_id', u_rec.instance_id,
        'aud', u_rec.aud,
        'role', u_rec.role
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_vps_auth_hash TO service_role, postgres;
