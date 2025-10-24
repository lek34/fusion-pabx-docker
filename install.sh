#!/bin/bash

echo "==================================="
echo "FusionPBX VoiceBot - Auto Install"
echo "==================================="
echo ""

# Build containers
echo "📦 Building Docker images..."
docker compose build

# Start services
echo "🚀 Starting services..."
docker compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to initialize..."
sleep 10

# Create config file with correct database host
echo "⚙️  Creating configuration..."
docker compose exec fusionpbx bash -c 'cat > /etc/fusionpbx/config.conf << "EOF"
database.0.type = pgsql
database.0.host = postgres
database.0.port = 5432
database.0.sslmode = prefer
database.0.name = fusionpbx
database.0.username = fusionpbx
database.0.password = password123
EOF'

# Fix postgres password
echo "🔐 Setting up database..."
docker compose exec postgres psql -U fusionpbx -d fusionpbx -c "ALTER USER fusionpbx WITH PASSWORD 'password123';" > /dev/null 2>&1

# Install database schema
echo "📊 Installing database schema (this may take 1-2 minutes)..."
docker compose exec fusionpbx bash -c 'cd /var/www/fusionpbx && php /var/www/fusionpbx/core/upgrade/upgrade_schema.php > /dev/null 2>&1'

# Create domain
echo "🌐 Creating default domain..."
docker compose exec postgres psql -U fusionpbx -d fusionpbx << 'EOF' > /dev/null 2>&1
INSERT INTO v_domains (domain_uuid, domain_name, domain_enabled, domain_description) 
VALUES ('550e8400-e29b-41d4-a716-446655440000', 'localhost', 'true', 'Default Domain')
ON CONFLICT DO NOTHING;
EOF

# Create admin user (password: admin)
echo "👤 Creating admin user..."
ADMIN_HASH=$(docker compose exec fusionpbx php -r "echo password_hash('admin', PASSWORD_BCRYPT);")
docker compose exec postgres psql -U fusionpbx -d fusionpbx << EOF > /dev/null 2>&1
INSERT INTO v_users (user_uuid, domain_uuid, username, password, user_enabled) 
VALUES ('650e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440000', 'admin', '$ADMIN_HASH', 'true')
ON CONFLICT DO NOTHING;
EOF

# Create superadmin group
echo "🔑 Setting up permissions..."
docker compose exec postgres psql -U fusionpbx -d fusionpbx << 'EOF' > /dev/null 2>&1
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

# Run domain upgrade
echo "📦 Finalizing installation..."
docker compose exec fusionpbx bash -c 'cd /var/www/fusionpbx && php /var/www/fusionpbx/core/upgrade/upgrade.php > /dev/null 2>&1'

# Restart services
echo "🔄 Restarting services..."
docker compose restart fusionpbx nginx > /dev/null 2>&1

sleep 5

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

