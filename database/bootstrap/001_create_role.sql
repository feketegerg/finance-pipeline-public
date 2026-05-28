DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'project_user') THEN
        CREATE ROLE project_user LOGIN;
    END IF;
END
$$;