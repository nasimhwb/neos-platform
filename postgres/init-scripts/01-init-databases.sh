#!/bin/bash
set -e
set -u

# ==============================================================================
# POSTGRES MULTIPLE DATABASE & USER CREATION INITIALIZATION SCRIPT
# ==============================================================================
# Parses the environment variable POSTGRES_MULTIPLE_DATABASES
# Format: db_name:db_user:db_password,db_name2:db_user2:db_password ...

function create_user_and_database() {
    local db_name=$1
    local db_user=$2
    local db_pass=$3
    
    echo "  Creating user '$db_user'..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$db_user') THEN
                CREATE USER $db_user WITH PASSWORD '$db_pass';
            END IF;
        END
        \$\$;
EOSQL

    echo "  Checking if database '$db_name' exists..."
    local db_exists
    db_exists=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name'")
    
    if [ "$db_exists" != "1" ]; then
        echo "  Creating database '$db_name' owned by '$db_user'..."
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE $db_name OWNER $db_user;"
    else
        echo "  Database '$db_name' already exists, skipping creation."
    fi

    echo "  Granting privileges on database '$db_name' to user '$db_user'..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db_name" -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;"
    
    # In PostgreSQL 15+, public schema permissions are restricted by default.
    # Grant permissions to allow the application user to create tables.
    echo "  Granting schema privileges in public to '$db_user' on '$db_name'..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db_name" -c "GRANT ALL ON SCHEMA public TO $db_user;"
    
    echo "  Successfully initialized database '$db_name' for user '$db_user'."
}

# Main script execution
echo "=== Beginning Multi-Database Initialization ==="

if [ -n "${POSTGRES_MULTIPLE_DATABASES:-}" ]; then
    echo "Parsing databases from POSTGRES_MULTIPLE_DATABASES..."
    
    # Split databases list by comma
    IFS=',' read -ra DB_LIST <<< "$POSTGRES_MULTIPLE_DATABASES"
    
    for db_entry in "${DB_LIST[@]}"; do
        # Strip potential whitespaces
        db_entry=$(echo "$db_entry" | xargs)
        
        if [ -n "$db_entry" ]; then
            # Split database configuration by colon
            IFS=':' read -ra DB_PARTS <<< "$db_entry"
            
            if [ ${#DB_PARTS[@]} -eq 3 ]; then
                db_name="${DB_PARTS[0]}"
                db_user="${DB_PARTS[1]}"
                db_pass="${DB_PARTS[2]}"
                
                echo "Processing: DB='$db_name', User='$db_user'"
                create_user_and_database "$db_name" "$db_user" "$db_pass"
            else
                echo "Warning: Invalid database config entry format: '$db_entry'. Expected format 'db:user:pass'"
            fi
        fi
    done
    echo "=== Multi-Database Initialization Completed ==="
else
    echo "POSTGRES_MULTIPLE_DATABASES not set, no extra databases to create."
fi
