#!/bin/sh
# ==============================================================================
# NEOS PLATFORM - MINIO BUCKET & IAM POLICY AUTO-INITIALIZER
# ==============================================================================
# Executed by the minio-init sidecar container on startup.
set -e

# 1. Wait for MinIO service API to be online
echo "Waiting for MinIO API to start at http://object-store:9000..."
until curl -s -f http://object-store:9000/minio/health/live &>/dev/null; do
    echo "  MinIO API not ready yet, sleeping 2s..."
    sleep 2
done
echo "MinIO API service is online."

# 2. Configure administrative alias
echo "Configuring admin client alias 'local'..."
mc alias set local http://object-store:9000 "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}"

# 3. Helper to create bucket
create_bucket() {
    local bucket_name=$1
    if ! mc ls local/"$bucket_name" &>/dev/null; then
        echo "Creating bucket: $bucket_name..."
        mc mb local/"$bucket_name"
    else
        echo "Bucket '$bucket_name' already exists."
    fi
}

# Create required buckets
create_bucket "neos-erp"
create_bucket "neos-inventory"
create_bucket "neos-ai-services"
create_bucket "supabase-storage" # Supabase Storage API target

# 4. Helper to create custom IAM policy per bucket
create_bucket_policy() {
    local bucket=$1
    local policy_name="${bucket}-rw"
    local tmp_policy
    tmp_policy=$(mktemp)
    
    cat <<EOF > "$tmp_policy"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::$bucket",
                "arn:aws:s3:::$bucket/*"
            ]
        }
    ]
}
EOF
    echo "Registering read-write policy '$policy_name' for bucket '$bucket'..."
    mc admin policy create local "$policy_name" "$tmp_policy"
    rm -f "$tmp_policy"
}

create_bucket_policy "neos-erp"
create_bucket_policy "neos-inventory"
create_bucket_policy "neos-ai-services"
create_bucket_policy "supabase-storage"

# 5. Helper to provision application users and attach policies
create_app_user() {
    local username=$1
    local password=$2
    local bucket=$3
    local policy_name="${bucket}-rw"
    
    echo "Registering application credentials for '$username'..."
    mc admin user add local "$username" "$password"
    
    echo "Attaching policy '$policy_name' to user '$username'..."
    mc admin policy attach local "$policy_name" --user "$username"
}

# Provision users (password secrets fetched from container environment)
create_app_user "erp_user" "${ERP_S3_PASSWORD:-ChangeThisToASuperSecureS3Password123!}" "neos-erp"
create_app_user "inventory_user" "${INVENTORY_S3_PASSWORD:-ChangeThisToASuperSecureS3Password123!}" "neos-inventory"
create_app_user "ai_user" "${AI_S3_PASSWORD:-ChangeThisToASuperSecureS3Password123!}" "neos-ai-services"
create_app_user "supabase_user" "${SUPABASE_S3_PASSWORD:-ChangeThisToASuperSecureS3Password123!}" "supabase-storage"

# 6. Configure Object Lifecycle Management (ILM)
# Automatically expire files placed inside 'tmp/' folders after 30 days
configure_ilm() {
    local bucket=$1
    echo "Configuring 30-day expiration rules for '$bucket/tmp/'..."
    # Clear existing rules first to avoid duplications
    mc ilm rule remove --all --force local/"$bucket" || true
    mc ilm rule add --expire --days 30 --prefix "tmp/" local/"$bucket"
}

configure_ilm "neos-erp"
configure_ilm "neos-inventory"
configure_ilm "neos-ai-services"
configure_ilm "supabase-storage"

echo "=== MinIO Buckets and IAM users initialization successfully completed! ==="
