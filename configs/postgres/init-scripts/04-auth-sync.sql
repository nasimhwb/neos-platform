-- ==============================================================================
-- NEOS PLATFORM — PHASE 3 AUTHENTICATION SYNCHRONIZATION TRANSACTION
-- ==============================================================================
BEGIN;

-- 1. Synchronize auth.users (33 Production Users)
INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '1bf192c9-cfa8-4264-875e-5ff48b2c4e70'::uuid, 'asif@neosfacility.com', '$2a$10$/ihH/8j46Gkolw9x6Hwi8ORtXrmY2gct1LqP63QHrkuPxC.AiKVxG', NULL, '2026-01-01 08:27:10.659999+00:00'::timestamptz, NULL,
    '', 'pkce_e4a5050372db5c7d09edb38373273190bebfb5e851eb43354fb0dae8', '', '2026-06-29 05:10:01.455801+00:00'::timestamptz,
    NULL, '', '', '',
    NULL, '2026-07-03 03:51:19.906116+00:00'::timestamptz, NULL, '2026-07-03 03:51:19.954688+00:00'::timestamptz, '2026-01-01 08:27:10.655897+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '6be9276d-8851-4558-8b82-403ad6e5c584'::uuid, 'aftab@neosfacility.com', '$2a$10$pntxYp1Ga.XYKDUiDCO0/OLn7Ltxq7rZKylH4f/wNbARDsWnuaxuq', NULL, '2025-12-31 12:44:17.616917+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, NULL, NULL, '2025-12-31 12:44:17.617782+00:00'::timestamptz, '2025-12-31 12:44:17.611038+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '03cabdfc-1712-417d-94ed-b121dd63b187'::uuid, 'alisa@neosfacility.com', '$2a$10$ZyWPUMSDAk9nvcZVIf.MF.CRs0thBme09CMousGCjsJwKzf.1IIUG', NULL, '2026-01-01 08:26:05.684159+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, NULL, NULL, '2026-01-01 08:26:05.685004+00:00'::timestamptz, '2026-01-01 08:26:05.666350+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '3bb15848-0534-49ca-b301-c343b5d6982c'::uuid, 'masum@neosfacility.com', '$2a$10$QCVWBz4BE/SrAWTWXejZ.uLQKAPNn2lfeqAtWb7A5k0L9A1Pa4tvC', NULL, '2026-01-01 08:27:06.148615+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-01-05 05:52:44.171721+00:00'::timestamptz, NULL, '2026-06-15 04:46:35.378520+00:00'::timestamptz, '2026-01-01 08:27:06.146143+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'bcf31c4f-12be-4565-8cf0-69ab261ae31e'::uuid, 'ravi@neosfacility.com', '$2a$10$vBP0WFeH1nSP0XdOK4sdgOm3aLinNOfr67EsxN63s67klgQm6qYl6', NULL, '2026-01-01 08:27:07.244408+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-07-24 07:34:42.936087+00:00'::timestamptz, NULL, '2026-07-24 07:34:42.941195+00:00'::timestamptz, '2026-01-01 08:27:07.241749+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '79d6bba0-be58-4616-a271-ece6b159abe6'::uuid, 'admin@neosfacility.com', '$2a$10$MnvNK0mhdrdAQva6WjFVz.rHwv3XZWkl8b/APThFvJGJTf.ljseBS', NULL, '2026-01-01 08:27:03.659960+00:00'::timestamptz, NULL,
    '', '8f5aa9016ed205e170a456acc8a49c59bf4dfa681f4e146f31d5373a', '', '2026-07-29 13:34:44.975211+00:00'::timestamptz,
    NULL, '', '', '',
    NULL, '2026-07-01 07:03:07.864546+00:00'::timestamptz, NULL, '2026-07-29 13:34:44.976292+00:00'::timestamptz, '2026-01-01 08:27:03.650785+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '0404268d-535d-4862-86df-3d6ddb896b8e'::uuid, 'shabbir@neosfacility.com', '$2a$10$H5dm6pTc/S0X1Dqa7Lps/OmihCVTvcWDaiZL1wx5V2n1qQV4M7x/O', NULL, '2026-01-01 08:27:05.448136+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, NULL, NULL, '2026-01-01 08:27:05.448852+00:00'::timestamptz, '2026-01-01 08:27:05.445642+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'adffc29d-81c6-4039-85e7-cb4476543407'::uuid, 'kalyan@neosfacility.com', '$2a$10$KO0ZFDNmdm8fKb5L.NutIek7tq03MDigT95Y.HZR3oh.4T.f1go3m', NULL, '2026-01-01 08:27:07.654289+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, NULL, NULL, '2026-01-01 08:27:07.654957+00:00'::timestamptz, '2026-01-01 08:27:07.651935+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'a7971045-3f3f-41a8-a293-19370ee62d18'::uuid, 'fatma@neosfacility.com', '$2a$10$XPC52EaZSNhmtR8jeo02tuSenw3UuHtsWHU0vlD2KZvCJMffqgi3C', NULL, '2026-01-01 08:27:08.769335+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-08-05 16:05:09.784232+00:00'::timestamptz, NULL, '2026-08-05 16:05:09.831986+00:00'::timestamptz, '2026-01-01 08:27:08.767069+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true, "force_password_change": false}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'e32c7f0f-f9b8-4163-abec-686528e5538d'::uuid, 'kaushik@neosfacility.com', '$2a$10$ioghNNA.xLlyi0v7xAkEDOhPXjYNqcW9pgNKdkabzfvlTbmjBoqIS', NULL, '2026-01-01 08:27:10.182724+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, NULL, NULL, '2026-01-01 08:27:10.184018+00:00'::timestamptz, '2026-01-01 08:27:10.178800+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '3d3c8379-bb09-4b03-9e15-8bdbccd08233'::uuid, 'nasim@neosfacility.com', '$2a$10$lIJG4xCVpB0PZM5zfPndO.O07l0L2sPFoLuRi4qZBEa8jqqaYFBwq', NULL, '2025-12-31 12:43:48.310747+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-08-03 17:11:41.679594+00:00'::timestamptz, NULL, '2026-08-05 14:51:06.273301+00:00'::timestamptz, '2025-12-31 12:43:48.279825+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '09717648-ce58-4fb9-93c9-2a99131710d4'::uuid, 'jay@neosfacility.com', '$2a$10$6DsejsZV7AY5EIyiNHM/M.9gpFB4ENWmXoBUdWROUTIgnTNjIIsEK', NULL, '2026-01-01 08:27:09.340930+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, NULL, NULL, '2026-01-01 08:27:09.341585+00:00'::timestamptz, '2026-01-01 08:27:09.335407+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'd3a0eda9-1b2b-4acf-99ef-343a7e200934'::uuid, 'shushil@neosfacility.com', '$2a$10$4b9buRSec958x/YGPGHEjuzPXr1cDHuSGsYLUFqd4cmhLW4xKOxwO', NULL, '2026-01-01 08:27:06.836635+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, NULL, NULL, '2026-01-01 08:27:06.837474+00:00'::timestamptz, '2026-01-01 08:27:06.833196+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '51f7b478-e617-4ca6-a269-6cb28411b74e'::uuid, 'azhar@neosfacility.com', '$2a$10$vNyFnTVBPBGl6iaRoISUduCacpFamWRFCIyFGBVGa1BoI7ZN/rndm', NULL, '2026-01-01 08:27:08.062251+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, NULL, NULL, '2026-01-01 08:27:08.063946+00:00'::timestamptz, '2026-01-01 08:27:08.059923+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '2942a8c8-90d3-4c10-9ae1-efddd0857fdb'::uuid, 'anjali@neosfacility.com', '$2a$10$M2/w.M6PX6t.myQCY11ixeYzENZrfovFi5MTzM2aspfEwauNW/In.', NULL, '2026-01-01 08:27:08.420542+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, NULL, NULL, '2026-01-01 08:27:08.421212+00:00'::timestamptz, '2026-01-01 08:27:08.418253+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'b365443b-09a9-44de-a4a1-8126bb267e4c'::uuid, 'sukanto@neosfacility.com', '$2a$10$vYBoUedt9ZYIpC.elrSu3OIZTgmeZLBMr.SRB2Gu1D9za7.vSGvde', NULL, '2026-01-01 08:34:58.663815+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, NULL, NULL, '2026-01-01 08:34:58.674191+00:00'::timestamptz, '2026-01-01 08:34:58.612983+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '3ab5cbf3-67a3-4380-936c-c7ad6f3908f0'::uuid, 'lallu@neosfacility.com', '$2a$10$/0J.XuZvCHdsop3gVDZq0uzT5ODMgDc64jt8quVxJQjQ1Pp2eg.L6', NULL, '2026-02-05 07:42:26.946113+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-02-05 07:43:04.117469+00:00'::timestamptz, NULL, '2026-02-06 04:09:31.894472+00:00'::timestamptz, '2026-02-05 07:42:26.905724+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '979b4154-a557-45de-8713-92bcb6e6a3fc'::uuid, 'puja@neosfacility.com', '$2a$10$uo8JAdWD5RBqFA/HvEbLs.45x4g4/SvG5OIsKrH5FlYKxcVKlcYce', NULL, '2026-01-01 08:27:09.709299+00:00'::timestamptz, NULL,
    '', '54034c156554672444b613f574608afdaab37bd309daa9ac427e1f90', '', '2026-07-29 13:34:44.660773+00:00'::timestamptz,
    NULL, '', '', '',
    NULL, '2026-06-30 09:46:51.849088+00:00'::timestamptz, NULL, '2026-08-05 11:55:35.285892+00:00'::timestamptz, '2026-01-01 08:27:09.707007+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae'::uuid, 'tester@neosfacility.com', '$2a$10$L/nF.7KZtWnQOUf1L1VYP.ABxTV/gJZ2i2lRBDqCMtMRfpOwfTn6.', NULL, '2026-08-05 15:38:35.376180+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-08-03 03:49:36.971416+00:00'::timestamptz, NULL, '2026-08-05 15:38:35.378518+00:00'::timestamptz, '2026-01-14 09:36:38.376080+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true, "force_password_change": false}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'c2da6f59-9133-4590-b802-656ac3d2b137'::uuid, 'sam417366@gmail.com', '$2a$10$ZDloZPucMc6cRhJNUHMalusrfO0B7G84cSDO6DsNRrAoJPLWSE9Lq', NULL, '2026-06-22 12:01:17.580937+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-07-31 04:01:48.944950+00:00'::timestamptz, NULL, '2026-08-05 06:07:22.073968+00:00'::timestamptz, '2026-06-22 12:01:17.479508+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"username": null, "full_name": "Gangesh Mishra-Ravi", "email_verified": true, "force_password_change": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '552b2935-6ca1-4069-88ac-23346cd6d620'::uuid, 'toptrading021984@gmail.com', '$2a$10$f30sERzVSe4Zdx8sfqhNAeO4qNLgjMYBMHVyb2XO3TsLU/s1W10Zm', NULL, '2026-06-04 09:15:47.670415+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-06-04 10:51:03.002075+00:00'::timestamptz, NULL, '2026-06-09 04:13:51.342298+00:00'::timestamptz, '2026-06-04 09:15:19.931994+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'fc6a68de-f1e9-452a-862a-1477cb16b580'::uuid, 'testwfo123@example.com', '$2a$10$hvo8NAFOOOT8KamR0UBM6eyhvC3/5mFR2BJazYx7E/26fE2rgS2v6', NULL, NULL, NULL,
    '20993d9795156b5d4be94ba71517852665f8bf0ad634b50a95f51228', '', '', NULL,
    '2026-06-12 05:35:08.270748+00:00'::timestamptz, '', '', '',
    NULL, NULL, NULL, '2026-06-12 05:35:11.334928+00:00'::timestamptz, '2026-06-12 05:35:08.221976+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"sub": "fc6a68de-f1e9-452a-862a-1477cb16b580", "email": "testwfo123@example.com", "email_verified": false, "phone_verified": false}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '053b6905-36db-4205-8cc4-e40c7f4247ae'::uuid, 'toptradingongem@gmail.com', '$2a$10$dmIDi6QlP9ZWcTQs1K9KIu4Q7nU06.C2T0343AQoK9vtKMnvk7rIu', NULL, '2026-06-13 19:27:50.573860+00:00'::timestamptz, NULL,
    '', 'pkce_192ea67cb72fddd479b29ddf70d9d8aef2635059765b2a40647f78ad', '', '2026-06-15 04:43:59.810603+00:00'::timestamptz,
    NULL, '', '', '',
    NULL, '2026-06-15 04:56:16.783914+00:00'::timestamptz, NULL, '2026-06-15 04:56:16.925651+00:00'::timestamptz, '2026-06-13 19:27:50.511172+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'f21325af-553c-4d60-8024-c99187173656'::uuid, 'nasim@corebitpc.com', '$2a$10$Qczbt9x5mmEwrOo0dRNV9e8R5IIflU//PRIAAl76XnzTxSOiYx.6W', NULL, '2026-08-05 15:38:34.911796+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-08-05 15:52:51.011415+00:00'::timestamptz, NULL, '2026-08-05 15:52:51.115835+00:00'::timestamptz, '2026-06-04 09:43:13.909049+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '6c12b8a4-16f8-4156-b8f8-ff0e9cfaccdd'::uuid, 'muhammadasifhussainn@gmail.com', '$2a$10$dtJpPELSA1kdcFoxP4Xhwe9zZXavd3Bjournn/rDt0fzOBJJkoa7a', NULL, '2026-05-22 05:42:09.733012+00:00'::timestamptz, NULL,
    '', '', '', '2026-07-14 04:03:43.813040+00:00'::timestamptz,
    NULL, '', '', '',
    NULL, '2026-08-03 03:54:55.038826+00:00'::timestamptz, NULL, '2026-08-05 13:38:56.706106+00:00'::timestamptz, '2026-05-22 05:42:09.716681+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '3fe70416-a4ab-4735-80a5-32b53342b039'::uuid, 'md.nasim96@gmail.com', '$2a$10$gHA81N5rpaKsRbyFgGb./ebvamLjzRNbL8yZir5lSMjrq1VWLqp96', NULL, '2026-06-13 17:26:08.259801+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-06-13 17:28:15.090878+00:00'::timestamptz, NULL, '2026-06-14 03:12:28.650659+00:00'::timestamptz, '2026-06-13 17:26:08.152020+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'b8f0ff37-bf27-4308-9ad6-3aff6399a043'::uuid, 'najirhossain1308@gmail.com', '$2a$10$9GmPhPUVaQwRHv2HHqTEhOsFQhlmtpMMhsyjd8oqpimVBPKeT60Z2', NULL, '2026-06-19 10:04:27.115909+00:00'::timestamptz, NULL,
    '', 'fbea5f21f60bd5ba1524ac9176f0066b1e95ccfe2ab940f3954c2716', '', '2026-07-29 13:34:45.795586+00:00'::timestamptz,
    NULL, '', '', '',
    NULL, '2026-07-15 09:05:23.490373+00:00'::timestamptz, NULL, '2026-08-05 11:54:34.808569+00:00'::timestamptz, '2026-06-19 10:04:27.081305+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '83181070-5a08-4c8c-b926-61c8219b229c'::uuid, 'rahul@neosfacility.com', '$2a$10$qeVXqBgl9CTqkRZ8a8ImN.Sj/wNnFDkaB7eQNhKsURnXuZP0xEGm2', NULL, '2026-08-05 15:38:35.140563+00:00'::timestamptz, NULL,
    '', '', '', NULL,
    NULL, '', '', '',
    NULL, '2026-02-05 07:11:50.371602+00:00'::timestamptz, NULL, '2026-08-05 15:38:35.143711+00:00'::timestamptz, '2026-02-05 06:57:54.716906+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '4e0cbcc6-9803-4871-9377-7af34ed6aa30'::uuid, 'koushikneos08@gmail.com', '$2a$10$3eB6RMIhxsw1Z20WGE7PDui1O5Q2ARlnSBmC.Z8iLnObL73jXgrLG', NULL, '2026-05-22 05:44:14.212423+00:00'::timestamptz, NULL,
    '', '', '', '2026-08-05 10:08:52.794684+00:00'::timestamptz,
    NULL, '', '', '',
    NULL, '2026-08-05 10:09:12.437847+00:00'::timestamptz, NULL, '2026-08-05 14:30:48.683859+00:00'::timestamptz, '2026-05-22 05:44:14.204785+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'f9348a68-1ebb-4574-ae6e-dc0be62a92a5'::uuid, 'sushilmanjhi514@gmail.com', '$2a$10$t/wBJzPslGUN0C3doA4/juPU95x02XPKxD.8ss9puuGNtMLyHRd4S', NULL, '2026-05-22 05:41:28.731057+00:00'::timestamptz, NULL,
    '', 'pkce_88c3f60c00dea545a7e65274a84660058e863b763de2fa3b0ce74877', '', '2026-07-28 04:30:06.332847+00:00'::timestamptz,
    NULL, '', '', '',
    NULL, '2026-07-24 04:32:08.349984+00:00'::timestamptz, NULL, '2026-08-05 15:46:52.230174+00:00'::timestamptz, '2026-05-22 05:41:28.691445+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"email_verified": true}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '65a33b60-aff9-44fa-a3fc-2c7c7e78d90e'::uuid, 'superadmin@neosfacility.com', '$2a$10$Dne3pyBZ1pZgDMcwCspULO22jLv7IFdxm3hUc1bmPDegMNDKwR4RW', NULL, NULL, NULL,
    '19787ba166afc483b13c8d6a22ce5fe2ad93b59151c4128034c2a474', '', '', NULL,
    '2026-06-30 06:09:05.461787+00:00'::timestamptz, '', '', '',
    NULL, NULL, '2126-06-06 10:22:38.101255+00:00'::timestamptz, '2026-06-30 10:22:38.103052+00:00'::timestamptz, '2026-06-30 06:09:05.452831+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"sub": "65a33b60-aff9-44fa-a3fc-2c7c7e78d90e", "email": "superadmin@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    'cd333d02-32b9-49d7-be11-9f79d43d5aa4'::uuid, 'admin@neos.com', '$2a$10$hoGv0PLvZpd0HHOU4rrCyuy7BbZpCFBFu4L5fW01.ORc7wYEAmIuq', NULL, NULL, NULL,
    '97321ea88dc97cad86e3733c2c27bcdc922e6c1d920c2b9b883b8ed1', '', '', NULL,
    '2026-06-30 06:07:56.749788+00:00'::timestamptz, '', '', '',
    NULL, NULL, '2126-06-06 10:22:46.625322+00:00'::timestamptz, '2026-06-30 10:22:46.625513+00:00'::timestamptz, '2026-06-30 06:07:56.353900+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"sub": "cd333d02-32b9-49d7-be11-9f79d43d5aa4", "email": "admin@neos.com", "email_verified": false, "phone_verified": false}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;

INSERT INTO auth.users (
    id, email, encrypted_password, phone, email_confirmed_at, phone_confirmed_at,
    confirmation_token, recovery_token, reauthentication_token, recovery_sent_at,
    confirmation_sent_at, email_change, email_change_token_new, email_change_token_current,
    email_change_sent_at, last_sign_in_at, banned_until, updated_at, created_at,
    raw_app_meta_data, raw_user_meta_data, aud, role
) VALUES (
    '282daf4a-c10d-45e6-9327-13ce25b1b91f'::uuid, 'user@neosfacility.com', '$2a$10$qM7fcIEvmZIVCbt2y0XLTO3gnKwPOXrZd6TYiEFzzvo/J7Fa4vEG6', NULL, NULL, NULL,
    '333546509e6a28a91cc22f0e007bbe49eb7500359afa681b9abb28db', '', '', NULL,
    '2026-06-30 06:08:57.185297+00:00'::timestamptz, '', '', '',
    NULL, NULL, '2126-06-06 10:22:53.317275+00:00'::timestamptz, '2026-06-30 10:22:53.318143+00:00'::timestamptz, '2026-06-30 06:08:57.158072+00:00'::timestamptz,
    '{"provider": "email", "providers": ["email"]}'::jsonb, '{"sub": "282daf4a-c10d-45e6-9327-13ce25b1b91f", "email": "user@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'authenticated', 'authenticated'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    encrypted_password = EXCLUDED.encrypted_password,
    phone = EXCLUDED.phone,
    email_confirmed_at = EXCLUDED.email_confirmed_at,
    phone_confirmed_at = EXCLUDED.phone_confirmed_at,
    confirmation_token = EXCLUDED.confirmation_token,
    recovery_token = EXCLUDED.recovery_token,
    reauthentication_token = EXCLUDED.reauthentication_token,
    recovery_sent_at = EXCLUDED.recovery_sent_at,
    confirmation_sent_at = EXCLUDED.confirmation_sent_at,
    email_change = EXCLUDED.email_change,
    email_change_token_new = EXCLUDED.email_change_token_new,
    email_change_token_current = EXCLUDED.email_change_token_current,
    email_change_sent_at = EXCLUDED.email_change_sent_at,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    banned_until = EXCLUDED.banned_until,
    updated_at = EXCLUDED.updated_at,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    raw_user_meta_data = EXCLUDED.raw_user_meta_data,
    aud = EXCLUDED.aud,
    role = EXCLUDED.role;


-- 2. Synchronize auth.identities (33 Production Identities)
INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '5510e636-df4f-4ef9-9673-1c4f3c5ff05d'::uuid, '3d3c8379-bb09-4b03-9e15-8bdbccd08233'::uuid, '{"sub": "3d3c8379-bb09-4b03-9e15-8bdbccd08233", "email": "nasim@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2025-12-31 12:43:48.298586+00:00'::timestamptz, '2025-12-31 12:43:48.299844+00:00'::timestamptz, '2025-12-31 12:43:48.299844+00:00'::timestamptz, 'nasim@neosfacility.com', '3d3c8379-bb09-4b03-9e15-8bdbccd08233'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'cd14a78c-585a-491a-baec-f715db3c4fb4'::uuid, '6be9276d-8851-4558-8b82-403ad6e5c584'::uuid, '{"sub": "6be9276d-8851-4558-8b82-403ad6e5c584", "email": "aftab@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2025-12-31 12:44:17.613697+00:00'::timestamptz, '2025-12-31 12:44:17.613750+00:00'::timestamptz, '2025-12-31 12:44:17.613750+00:00'::timestamptz, 'aftab@neosfacility.com', '6be9276d-8851-4558-8b82-403ad6e5c584'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '80a54d4d-0e92-4968-ae54-b11afa8a9008'::uuid, '03cabdfc-1712-417d-94ed-b121dd63b187'::uuid, '{"sub": "03cabdfc-1712-417d-94ed-b121dd63b187", "email": "alisa@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:26:05.676293+00:00'::timestamptz, '2026-01-01 08:26:05.676349+00:00'::timestamptz, '2026-01-01 08:26:05.676349+00:00'::timestamptz, 'alisa@neosfacility.com', '03cabdfc-1712-417d-94ed-b121dd63b187'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '03b41296-9b01-4a72-8b45-47466e9ad153'::uuid, '79d6bba0-be58-4616-a271-ece6b159abe6'::uuid, '{"sub": "79d6bba0-be58-4616-a271-ece6b159abe6", "email": "admin@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:03.652504+00:00'::timestamptz, '2026-01-01 08:27:03.652553+00:00'::timestamptz, '2026-01-01 08:27:03.652553+00:00'::timestamptz, 'admin@neosfacility.com', '79d6bba0-be58-4616-a271-ece6b159abe6'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'd6f9062b-724f-41a4-88d1-5111940acdec'::uuid, '0404268d-535d-4862-86df-3d6ddb896b8e'::uuid, '{"sub": "0404268d-535d-4862-86df-3d6ddb896b8e", "email": "shabbir@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:05.446696+00:00'::timestamptz, '2026-01-01 08:27:05.446743+00:00'::timestamptz, '2026-01-01 08:27:05.446743+00:00'::timestamptz, 'shabbir@neosfacility.com', '0404268d-535d-4862-86df-3d6ddb896b8e'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '07a92b54-7368-4289-8fba-a58443651e66'::uuid, '3bb15848-0534-49ca-b301-c343b5d6982c'::uuid, '{"sub": "3bb15848-0534-49ca-b301-c343b5d6982c", "email": "masum@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:06.147213+00:00'::timestamptz, '2026-01-01 08:27:06.147263+00:00'::timestamptz, '2026-01-01 08:27:06.147263+00:00'::timestamptz, 'masum@neosfacility.com', '3bb15848-0534-49ca-b301-c343b5d6982c'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '993c7cd9-7e37-4e26-9159-1ca1d0fd496e'::uuid, 'd3a0eda9-1b2b-4acf-99ef-343a7e200934'::uuid, '{"sub": "d3a0eda9-1b2b-4acf-99ef-343a7e200934", "email": "shushil@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:06.834212+00:00'::timestamptz, '2026-01-01 08:27:06.834276+00:00'::timestamptz, '2026-01-01 08:27:06.834276+00:00'::timestamptz, 'shushil@neosfacility.com', 'd3a0eda9-1b2b-4acf-99ef-343a7e200934'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'f679ef47-5bea-468f-8ebe-cb2efc227075'::uuid, 'bcf31c4f-12be-4565-8cf0-69ab261ae31e'::uuid, '{"sub": "bcf31c4f-12be-4565-8cf0-69ab261ae31e", "email": "ravi@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:07.242902+00:00'::timestamptz, '2026-01-01 08:27:07.242951+00:00'::timestamptz, '2026-01-01 08:27:07.242951+00:00'::timestamptz, 'ravi@neosfacility.com', 'bcf31c4f-12be-4565-8cf0-69ab261ae31e'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'dd446bf1-93db-4cfb-bd24-d0a0a6398bd7'::uuid, 'adffc29d-81c6-4039-85e7-cb4476543407'::uuid, '{"sub": "adffc29d-81c6-4039-85e7-cb4476543407", "email": "kalyan@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:07.652988+00:00'::timestamptz, '2026-01-01 08:27:07.653040+00:00'::timestamptz, '2026-01-01 08:27:07.653040+00:00'::timestamptz, 'kalyan@neosfacility.com', 'adffc29d-81c6-4039-85e7-cb4476543407'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '047ee011-a606-430e-818c-221ee9ec7fb4'::uuid, '51f7b478-e617-4ca6-a269-6cb28411b74e'::uuid, '{"sub": "51f7b478-e617-4ca6-a269-6cb28411b74e", "email": "azhar@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:08.060992+00:00'::timestamptz, '2026-01-01 08:27:08.061044+00:00'::timestamptz, '2026-01-01 08:27:08.061044+00:00'::timestamptz, 'azhar@neosfacility.com', '51f7b478-e617-4ca6-a269-6cb28411b74e'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'cc3c501b-37fa-4522-8969-d6e13526b62e'::uuid, '2942a8c8-90d3-4c10-9ae1-efddd0857fdb'::uuid, '{"sub": "2942a8c8-90d3-4c10-9ae1-efddd0857fdb", "email": "anjali@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:08.419327+00:00'::timestamptz, '2026-01-01 08:27:08.419382+00:00'::timestamptz, '2026-01-01 08:27:08.419382+00:00'::timestamptz, 'anjali@neosfacility.com', '2942a8c8-90d3-4c10-9ae1-efddd0857fdb'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'a68be072-41a1-4100-884d-009e91950c27'::uuid, 'a7971045-3f3f-41a8-a293-19370ee62d18'::uuid, '{"sub": "a7971045-3f3f-41a8-a293-19370ee62d18", "email": "fatma@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:08.768086+00:00'::timestamptz, '2026-01-01 08:27:08.768155+00:00'::timestamptz, '2026-01-01 08:27:08.768155+00:00'::timestamptz, 'fatma@neosfacility.com', 'a7971045-3f3f-41a8-a293-19370ee62d18'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '6c460a50-59a6-4b9a-9d14-3f1d54eb26ef'::uuid, '09717648-ce58-4fb9-93c9-2a99131710d4'::uuid, '{"sub": "09717648-ce58-4fb9-93c9-2a99131710d4", "email": "jay@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:09.337760+00:00'::timestamptz, '2026-01-01 08:27:09.337811+00:00'::timestamptz, '2026-01-01 08:27:09.337811+00:00'::timestamptz, 'jay@neosfacility.com', '09717648-ce58-4fb9-93c9-2a99131710d4'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '9fd453e0-52e5-460f-bcae-06949e3ab099'::uuid, '979b4154-a557-45de-8713-92bcb6e6a3fc'::uuid, '{"sub": "979b4154-a557-45de-8713-92bcb6e6a3fc", "email": "puja@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:09.708004+00:00'::timestamptz, '2026-01-01 08:27:09.708051+00:00'::timestamptz, '2026-01-01 08:27:09.708051+00:00'::timestamptz, 'puja@neosfacility.com', '979b4154-a557-45de-8713-92bcb6e6a3fc'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '0a171241-e882-48e8-a9e3-6491155aa466'::uuid, 'e32c7f0f-f9b8-4163-abec-686528e5538d'::uuid, '{"sub": "e32c7f0f-f9b8-4163-abec-686528e5538d", "email": "kaushik@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:10.179881+00:00'::timestamptz, '2026-01-01 08:27:10.179934+00:00'::timestamptz, '2026-01-01 08:27:10.179934+00:00'::timestamptz, 'kaushik@neosfacility.com', 'e32c7f0f-f9b8-4163-abec-686528e5538d'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'c8618198-a2bc-4fbb-9361-b43fccb4b8fb'::uuid, '1bf192c9-cfa8-4264-875e-5ff48b2c4e70'::uuid, '{"sub": "1bf192c9-cfa8-4264-875e-5ff48b2c4e70", "email": "asif@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:27:10.657526+00:00'::timestamptz, '2026-01-01 08:27:10.657580+00:00'::timestamptz, '2026-01-01 08:27:10.657580+00:00'::timestamptz, 'asif@neosfacility.com', '1bf192c9-cfa8-4264-875e-5ff48b2c4e70'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '14910d76-e464-469f-9863-ddab9144fb54'::uuid, 'b365443b-09a9-44de-a4a1-8126bb267e4c'::uuid, '{"sub": "b365443b-09a9-44de-a4a1-8126bb267e4c", "email": "sukanto@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-01 08:34:58.646225+00:00'::timestamptz, '2026-01-01 08:34:58.646837+00:00'::timestamptz, '2026-01-01 08:34:58.646837+00:00'::timestamptz, 'sukanto@neosfacility.com', 'b365443b-09a9-44de-a4a1-8126bb267e4c'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'c125c971-d41a-41c2-858d-090e9fb3367d'::uuid, '05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae'::uuid, '{"sub": "05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae", "email": "tester@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-01-14 09:36:38.407291+00:00'::timestamptz, '2026-01-14 09:36:38.408425+00:00'::timestamptz, '2026-01-14 09:36:38.408425+00:00'::timestamptz, 'tester@neosfacility.com', '05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'c7cf3626-3882-4a60-8b6f-db8f93e9fb53'::uuid, '83181070-5a08-4c8c-b926-61c8219b229c'::uuid, '{"sub": "83181070-5a08-4c8c-b926-61c8219b229c", "email": "rahul@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-02-05 06:57:54.763945+00:00'::timestamptz, '2026-02-05 06:57:54.764014+00:00'::timestamptz, '2026-02-05 06:57:54.764014+00:00'::timestamptz, 'rahul@neosfacility.com', '83181070-5a08-4c8c-b926-61c8219b229c'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'be24db89-a074-4472-8102-6960251f5efa'::uuid, '3ab5cbf3-67a3-4380-936c-c7ad6f3908f0'::uuid, '{"sub": "3ab5cbf3-67a3-4380-936c-c7ad6f3908f0", "email": "lallu@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-02-05 07:42:26.940134+00:00'::timestamptz, '2026-02-05 07:42:26.940197+00:00'::timestamptz, '2026-02-05 07:42:26.940197+00:00'::timestamptz, 'lallu@neosfacility.com', '3ab5cbf3-67a3-4380-936c-c7ad6f3908f0'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '98657f83-74f8-4a4c-adb0-712f5b51bc14'::uuid, 'f9348a68-1ebb-4574-ae6e-dc0be62a92a5'::uuid, '{"sub": "f9348a68-1ebb-4574-ae6e-dc0be62a92a5", "email": "sushilmanjhi514@gmail.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-05-22 05:41:28.725259+00:00'::timestamptz, '2026-05-22 05:41:28.725327+00:00'::timestamptz, '2026-05-22 05:41:28.725327+00:00'::timestamptz, 'sushilmanjhi514@gmail.com', 'f9348a68-1ebb-4574-ae6e-dc0be62a92a5'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'e89d5e02-d02b-4bbd-b6db-416dbed32154'::uuid, '6c12b8a4-16f8-4156-b8f8-ff0e9cfaccdd'::uuid, '{"sub": "6c12b8a4-16f8-4156-b8f8-ff0e9cfaccdd", "email": "muhammadasifhussainn@gmail.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-05-22 05:42:09.725758+00:00'::timestamptz, '2026-05-22 05:42:09.726437+00:00'::timestamptz, '2026-05-22 05:42:09.726437+00:00'::timestamptz, 'muhammadasifhussainn@gmail.com', '6c12b8a4-16f8-4156-b8f8-ff0e9cfaccdd'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '94749175-dc13-454f-8021-fefdf565c7fa'::uuid, '4e0cbcc6-9803-4871-9377-7af34ed6aa30'::uuid, '{"sub": "4e0cbcc6-9803-4871-9377-7af34ed6aa30", "email": "koushikneos08@gmail.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-05-22 05:44:14.209765+00:00'::timestamptz, '2026-05-22 05:44:14.209815+00:00'::timestamptz, '2026-05-22 05:44:14.209815+00:00'::timestamptz, 'koushikneos08@gmail.com', '4e0cbcc6-9803-4871-9377-7af34ed6aa30'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '234d11a5-e26f-4a45-960f-878ee74a2dab'::uuid, '552b2935-6ca1-4069-88ac-23346cd6d620'::uuid, '{"sub": "552b2935-6ca1-4069-88ac-23346cd6d620", "email": "toptrading021984@gmail.com", "email_verified": true, "phone_verified": false}'::jsonb, 'email', '2026-06-04 09:15:19.981665+00:00'::timestamptz, '2026-06-04 09:15:19.982896+00:00'::timestamptz, '2026-06-04 09:15:19.982896+00:00'::timestamptz, 'toptrading021984@gmail.com', '552b2935-6ca1-4069-88ac-23346cd6d620'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '8cba03ac-7e34-4bf8-bcff-11ee6fce7169'::uuid, 'f21325af-553c-4d60-8024-c99187173656'::uuid, '{"sub": "f21325af-553c-4d60-8024-c99187173656", "email": "nasim@corebitpc.com", "email_verified": true, "phone_verified": false}'::jsonb, 'email', '2026-06-04 09:43:13.930850+00:00'::timestamptz, '2026-06-04 09:43:13.930897+00:00'::timestamptz, '2026-06-04 09:43:13.930897+00:00'::timestamptz, 'nasim@corebitpc.com', 'f21325af-553c-4d60-8024-c99187173656'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '0cb7d55c-cbac-49dc-8417-5e00f19c9376'::uuid, 'fc6a68de-f1e9-452a-862a-1477cb16b580'::uuid, '{"sub": "fc6a68de-f1e9-452a-862a-1477cb16b580", "email": "testwfo123@example.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-06-12 05:35:08.259855+00:00'::timestamptz, '2026-06-12 05:35:08.259906+00:00'::timestamptz, '2026-06-12 05:35:08.259906+00:00'::timestamptz, 'testwfo123@example.com', 'fc6a68de-f1e9-452a-862a-1477cb16b580'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '23f727e8-2a88-40ce-8338-8101c350d813'::uuid, '3fe70416-a4ab-4735-80a5-32b53342b039'::uuid, '{"sub": "3fe70416-a4ab-4735-80a5-32b53342b039", "email": "md.nasim96@gmail.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-06-13 17:26:08.242060+00:00'::timestamptz, '2026-06-13 17:26:08.242765+00:00'::timestamptz, '2026-06-13 17:26:08.242765+00:00'::timestamptz, 'md.nasim96@gmail.com', '3fe70416-a4ab-4735-80a5-32b53342b039'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'ccbba30b-7355-4c86-8613-9e3b2bb6c066'::uuid, '053b6905-36db-4205-8cc4-e40c7f4247ae'::uuid, '{"sub": "053b6905-36db-4205-8cc4-e40c7f4247ae", "email": "toptradingongem@gmail.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-06-13 19:27:50.563223+00:00'::timestamptz, '2026-06-13 19:27:50.563278+00:00'::timestamptz, '2026-06-13 19:27:50.563278+00:00'::timestamptz, 'toptradingongem@gmail.com', '053b6905-36db-4205-8cc4-e40c7f4247ae'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '9ebb6f48-e526-4435-80a8-6f615871dfe5'::uuid, 'b8f0ff37-bf27-4308-9ad6-3aff6399a043'::uuid, '{"sub": "b8f0ff37-bf27-4308-9ad6-3aff6399a043", "email": "najirhossain1308@gmail.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-06-19 10:04:27.109864+00:00'::timestamptz, '2026-06-19 10:04:27.109936+00:00'::timestamptz, '2026-06-19 10:04:27.109936+00:00'::timestamptz, 'najirhossain1308@gmail.com', 'b8f0ff37-bf27-4308-9ad6-3aff6399a043'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '94f32d11-aef4-4312-beb7-9b5af8137ad4'::uuid, 'c2da6f59-9133-4590-b802-656ac3d2b137'::uuid, '{"sub": "c2da6f59-9133-4590-b802-656ac3d2b137", "email": "sam417366@gmail.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-06-22 12:01:17.570762+00:00'::timestamptz, '2026-06-22 12:01:17.570819+00:00'::timestamptz, '2026-06-22 12:01:17.570819+00:00'::timestamptz, 'sam417366@gmail.com', 'c2da6f59-9133-4590-b802-656ac3d2b137'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'b17639f7-08a2-4243-9913-c4d514807bd7'::uuid, 'cd333d02-32b9-49d7-be11-9f79d43d5aa4'::uuid, '{"sub": "cd333d02-32b9-49d7-be11-9f79d43d5aa4", "email": "admin@neos.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-06-30 06:07:56.705239+00:00'::timestamptz, '2026-06-30 06:07:56.705297+00:00'::timestamptz, '2026-06-30 06:07:56.705297+00:00'::timestamptz, 'admin@neos.com', 'cd333d02-32b9-49d7-be11-9f79d43d5aa4'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    'd1cfaf61-72d8-4650-8014-03dabf9305d3'::uuid, '282daf4a-c10d-45e6-9327-13ce25b1b91f'::uuid, '{"sub": "282daf4a-c10d-45e6-9327-13ce25b1b91f", "email": "user@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-06-30 06:08:57.181527+00:00'::timestamptz, '2026-06-30 06:08:57.181584+00:00'::timestamptz, '2026-06-30 06:08:57.181584+00:00'::timestamptz, 'user@neosfacility.com', '282daf4a-c10d-45e6-9327-13ce25b1b91f'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

INSERT INTO auth.identities (
    id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, email, provider_id
) VALUES (
    '6de3c3aa-5062-40f1-8b3a-6ae51a072b01'::uuid, '65a33b60-aff9-44fa-a3fc-2c7c7e78d90e'::uuid, '{"sub": "65a33b60-aff9-44fa-a3fc-2c7c7e78d90e", "email": "superadmin@neosfacility.com", "email_verified": false, "phone_verified": false}'::jsonb, 'email', '2026-06-30 06:09:05.458927+00:00'::timestamptz, '2026-06-30 06:09:05.458971+00:00'::timestamptz, '2026-06-30 06:09:05.458971+00:00'::timestamptz, 'superadmin@neosfacility.com', '65a33b60-aff9-44fa-a3fc-2c7c7e78d90e'
)
ON CONFLICT (provider, provider_id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    identity_data = EXCLUDED.identity_data,
    last_sign_in_at = EXCLUDED.last_sign_in_at,
    updated_at = EXCLUDED.updated_at,
    email = EXCLUDED.email;

COMMIT;