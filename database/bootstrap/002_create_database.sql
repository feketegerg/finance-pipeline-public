SELECT 'CREATE DATABASE project_db OWNER project_user'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_database WHERE datname = 'project_db'
)\gexec