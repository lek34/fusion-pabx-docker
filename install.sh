#!/bin/bash

set -e  # Exit on error

echo "==================================="
echo "FusionPBX VoiceBot - Auto Install"
echo "==================================="
echo ""

# Function to check if command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        echo "   ✓ Done"
    else
        echo "   ✗ Failed"
        exit 1
    fi
}

# Function to wait for postgres
wait_for_postgres() {
    echo "⏳ Waiting for PostgreSQL to be ready..."
    for i in {1..30}; do
        if docker compose exec -T postgres pg_isready -U fusionpbx > /dev/null 2>&1; then
            echo "   ✓ PostgreSQL is ready"
            return 0
        fi
        echo "   Attempt $i/30..."
        sleep 2
    done
    echo "   ✗ PostgreSQL failed to start"
    exit 1
}

# Build containers
echo "📦 Building Docker images..."
docker compose build
check_success

# Start services
echo "🚀 Starting services..."
docker compose up -d
check_success

# Wait for PostgreSQL
wait_for_postgres

# Wait a bit more for FusionPBX container
echo "⏳ Waiting for FusionPBX container..."
sleep 5

# Fix FreeSWITCH event_socket IPv6 issue
echo "🔧 Configuring FreeSWITCH event socket..."
docker compose exec -T freeswitch bash -c 'sed -i "s/listen-ip\" value=\"::\"/listen-ip\" value=\"127.0.0.1\"/" /etc/freeswitch/autoload_configs/event_socket.conf.xml' 2>/dev/null || true
docker compose restart freeswitch > /dev/null 2>&1
echo "   Waiting for FreeSWITCH to restart..."
sleep 10

# Create config file with correct database host
echo "⚙️  Creating configuration..."
docker compose exec -T fusionpbx bash -c 'cat > /etc/fusionpbx/config.conf << "EOF"
database.0.type = pgsql
database.0.host = postgres
database.0.port = 5432
database.0.sslmode = prefer
database.0.name = fusionpbx
database.0.username = fusionpbx
database.0.password = password123
EOF'
check_success

# Fix postgres password
echo "🔐 Setting up database..."
docker compose exec -T postgres psql -U fusionpbx -d fusionpbx -c "ALTER USER fusionpbx WITH PASSWORD 'password123';" 2>&1 | grep -v "ALTER ROLE" || true
check_success

# Install database schema
echo "📊 Installing database schema (this may take 1-2 minutes)..."
echo "   Please wait, showing progress..."
docker compose exec -T fusionpbx bash -c 'cd /var/www/fusionpbx && php /var/www/fusionpbx/core/upgrade/upgrade_schema.php' 2>&1 | grep -E "error|Error|fail|Fail|success|Success|CREATE|INSERT" || echo "   Processing..."
check_success

# Create domain
echo "🌐 Creating default domain..."
docker compose exec -T postgres psql -U fusionpbx -d fusionpbx << 'EOF' 2>&1 | grep -v "INSERT" || true
INSERT INTO v_domains (domain_uuid, domain_name, domain_enabled, domain_description) 
VALUES ('550e8400-e29b-41d4-a716-446655440000', 'localhost', 'true', 'Default Domain')
ON CONFLICT DO NOTHING;
EOF
check_success

# Create admin user (password: admin)
echo "👤 Creating admin user..."
ADMIN_HASH=$(docker compose exec -T fusionpbx php -r "echo password_hash('admin', PASSWORD_BCRYPT);")
docker compose exec -T postgres psql -U fusionpbx -d fusionpbx << EOF 2>&1 | grep -v "INSERT\|UPDATE" || true
INSERT INTO v_users (user_uuid, domain_uuid, username, password, salt, user_enabled) 
VALUES ('650e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440000', 'admin', '$ADMIN_HASH', '', 'true')
ON CONFLICT (user_uuid) DO UPDATE SET password = '$ADMIN_HASH', salt = '';
EOF
check_success

# Create superadmin group
echo "🔑 Setting up permissions..."
docker compose exec -T postgres psql -U fusionpbx -d fusionpbx << 'EOF' 2>&1 | grep -v "INSERT" || true
INSERT INTO v_groups (group_uuid, domain_uuid, group_name, group_level, group_description) 
VALUES ('750e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440000', 'superadmin', 90, 'Super Administrator')
ON CONFLICT DO NOTHING;

INSERT INTO v_user_groups (user_group_uuid, user_uuid, group_name, domain_uuid, group_uuid)
VALUES ('850e8400-e29b-41d4-a716-446655440000', '650e8400-e29b-41d4-a716-446655440000', 'superadmin', '550e8400-e29b-41d4-a716-446655440000', '750e8400-e29b-41d4-a716-446655440000')
ON CONFLICT DO NOTHING;

INSERT INTO v_group_permissions (group_permission_uuid, domain_uuid, permission_name, group_uuid, permission_assigned) 
VALUES ('950e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440000', '*', '750e8400-e29b-41d4-a716-446655440000', 'true')
ON CONFLICT DO NOTHING;
EOF
check_success

# Install menu and app defaults
echo "📋 Installing menu and applications..."
echo "   → Installing app config..."
docker compose exec -T fusionpbx bash -c 'cd /var/www/fusionpbx && timeout 60 php /var/www/fusionpbx/core/menu/app_config.php' 2>&1 | head -5 || true

echo "   → Upgrading menu..."
docker compose exec -T fusionpbx bash -c 'cd /var/www/fusionpbx && timeout 60 php /var/www/fusionpbx/core/upgrade/upgrade_menu.php' 2>&1 | head -5 || true

echo "   → Upgrading apps..."
docker compose exec -T fusionpbx bash -c 'cd /var/www/fusionpbx && timeout 60 php /var/www/fusionpbx/core/upgrade/upgrade_apps.php' 2>&1 | head -5 || true

echo "   → Upgrading domains..."
docker compose exec -T fusionpbx bash -c 'cd /var/www/fusionpbx && timeout 60 php /var/www/fusionpbx/core/upgrade/upgrade_domains.php' 2>&1 | head -5 || true
echo "   ✓ Done"

# Run domain upgrade
echo "📦 Finalizing installation..."
docker compose exec -T fusionpbx bash -c 'cd /var/www/fusionpbx && timeout 90 php /var/www/fusionpbx/core/upgrade/upgrade.php' 2>&1 | head -10 || true
echo "   ✓ Done"

# Clear cache
echo "🧹 Clearing cache..."
docker compose exec -T fusionpbx bash -c 'cd /var/www/fusionpbx && php /var/www/fusionpbx/core/cache/cache_clear.php' > /dev/null 2>&1 || true
echo "   ✓ Done"

# Restart services
echo "🔄 Restarting services..."
docker compose restart fusionpbx nginx > /dev/null 2>&1
check_success

sleep 3

echo ""
echo "✅ Installation Complete!"
echo ""
echo "==================================="
echo "Access FusionPBX:"
echo "  URL: http://localhost"
echo "  Username: admin"
echo "  Password: admin"
echo "==================================="
echo ""
echo "⚠️  Please change the default password after login!"
echo ""

