# FusionPBX Setup Guide

## Step-by-Step Installation

### Step 1: Build Docker Images

This will take 10-20 minutes (FreeSWITCH is compiled from source):

```bash
docker compose build
```

### Step 2: Start All Services

```bash
docker compose up -d
```

Wait 30 seconds for all services to initialize.

### Step 3: Access the Web Interface

Open your browser:
```
http://localhost
```

You should see the FusionPBX login page.

### Step 4: Login with Default Credentials

```
Username: admin
Password: admin
```

> ⚠️ **IMPORTANT**: Change this password immediately after login!

### Step 5: Change Default Password

After login:
1. Click on **admin** (top right corner)
2. Go to **Accounts > Users**
3. Click on your admin user
4. Update the password
5. Save

### Step 6: Verify FreeSWITCH Connection

1. Go to **Status > SIP Status**
2. You should see FreeSWITCH is connected and running

### Step 7: Create Your First Extension

1. Go to **Accounts > Extensions**
2. Click **Add (+)** button
3. Fill in:
   - **Extension**: `1000`
   - **Password**: Choose a strong password
   - **Description**: `Test Extension`
4. Click **Save**

### Step 8: Test with a SIP Phone

Use any SIP softphone (X-Lite, Zoiper, Linphone):

```
SIP Server: localhost (or your server IP)
Port: 5060
Username: 1000
Password: (the password you set)
```

## 🔄 Managing Services

### Stop All Services
```bash
docker compose down
```

### Restart Specific Service
```bash
docker compose restart fusionpbx
docker compose restart freeswitch
docker compose restart nginx
```

### View Logs
```bash
# All logs
docker compose logs -f

# Specific service
docker compose logs -f fusionpbx
docker compose logs -f freeswitch
```

### Check Service Status
```bash
docker compose ps
```

## 🗄️ Database Information

### Connection Details
- **Host**: postgres (container name)
- **Port**: 5432
- **Database**: fusionpbx
- **Username**: fusionpbx
- **Password**: password123

### Access Database Directly
```bash
docker compose exec postgres psql -U fusionpbx -d fusionpbx
```

### Backup Database
```bash
docker compose exec postgres pg_dump -U fusionpbx fusionpbx > fusionpbx-backup-$(date +%Y%m%d).sql
```

### Restore Database
```bash
cat backup.sql | docker compose exec -T postgres psql -U fusionpbx fusionpbx
```

## ⚙️ Advanced Configuration

### Increase PHP Memory (if needed)
Edit `fusionpbx/Dockerfile` line 46:
```dockerfile
sed -i 's/memory_limit = 128M/memory_limit = 4096M/' /etc/php/8.1/fpm/php.ini
```

Then rebuild:
```bash
docker compose build fusionpbx
docker compose up -d fusionpbx
```

### Add More Ports for RTP (if needed)
Edit `docker-compose.yml` under freeswitch service:
```yaml
ports:
  - "16384-16584:16384-16584/udp"  # Increase range
```

## 🔧 Troubleshooting

### Problem: 403 Forbidden Error
**Solution**: The FusionPBX files are missing from the volume
```bash
docker compose down
docker compose up -d
```

### Problem: 502 Bad Gateway
**Solution**: PHP-FPM is not running
```bash
docker compose logs fusionpbx
docker compose restart fusionpbx
```

### Problem: Cannot access menu/Access Denied
**Solution**: Permissions not set up
```bash
docker compose exec fusionpbx bash -c 'cd /var/www/fusionpbx && php /var/www/fusionpbx/core/upgrade/upgrade.php'
```

### Problem: Database connection failed
**Solution**: Config file has wrong host
```bash
docker compose exec fusionpbx cat /etc/fusionpbx/config.conf | grep database.0.host
# Should show: database.0.host = postgres

# If it shows localhost, fix it:
docker compose exec fusionpbx sed -i 's/database.0.host = localhost/database.0.host = postgres/' /etc/fusionpbx/config.conf
docker compose restart fusionpbx
```

### Problem: Memory exhausted during installation
Already fixed in Dockerfile (4GB memory limit).

### Problem: Menu is collapsed/not showing
1. Clear browser cache
2. Look for hamburger menu icon (☰) on left
3. Click to expand menu
4. Or go directly to URLs like: http://localhost/app/extensions/extensions.php

## 🎨 Customization

### Change Theme
1. Go to **Advanced > Default Settings**
2. Search for "theme"
3. Modify theme settings
4. Save and refresh browser

### Add Dashboard Widgets
1. Go to **Advanced > Default Settings**
2. Search for "dashboard"
3. Enable widgets you want:
   - `dashboard_system_status_enabled`
   - `dashboard_recent_calls_enabled`
4. Save and go back to Dashboard

## 📞 VoiceBot Use Cases

1. **IVR System**: Create interactive voice menus
2. **Call Center**: Queue management and agent routing
3. **Voicemail**: Automated voicemail systems
4. **Call Recording**: Record all calls automatically
5. **Conference Bridges**: Multi-party calling
6. **Auto Attendant**: Automated receptionist

## 🏁 Quick Reset (Start Fresh)

If you need to completely reset:

```bash
# Stop everything
docker compose down

# Remove volumes (this deletes ALL data!)
docker volume rm fusionpbx-voicebot2_fusionpbx_data
docker volume rm fusionpbx-voicebot2_freeswitch_data

# Remove postgres data
rm -rf data/postgres/*

# Start fresh
docker compose up -d
```

Then go through the installation wizard again.

## 🎓 Learning Resources

- [FusionPBX Documentation](https://docs.fusionpbx.com/)
- [FreeSWITCH Wiki](https://freeswitch.org/confluence/)
- [SIP Protocol Basics](https://www.3cx.com/pbx/sip/)

## 💡 Tips

1. **Always use Incognito/Private window** when testing login issues
2. **Check Docker logs** before asking for help
3. **Backup before making changes** to production systems
4. **Use extensions 1000-1999** for internal phones
5. **Document your dialplan** as it gets complex quickly

---

**Built with ❤️ for VoIP enthusiasts**

