-- =====================================================================
-- 04_dbt_keypair_auth.sql : let dbt sign in with a key pair
-- =====================================================================
-- Needed when you sign in to Snowflake with Google (no password, no SAML SSO).
--
-- 1) Generate keys (Git Bash), kept OUTSIDE the repo:
--      cd ~/.dbt
--      openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
--      openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
--
-- 2) Register the public key (the text between BEGIN/END, on one line).
--    User names created in lowercase must be double-quoted.

SELECT CURRENT_USER();

ALTER USER "<your_user>" SET RSA_PUBLIC_KEY = '<PUBLIC_KEY_BODY>';

-- 3) dbt must connect with the LOGIN_NAME (often your e-mail), not the user name,
--    otherwise Snowflake returns "JWT token is invalid".
DESC USER "<your_user>";     -- check LOGIN_NAME and RSA_PUBLIC_KEY_FP
