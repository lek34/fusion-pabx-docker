# FusionPBX VoiceBot System

A fully containerized FusionPBX installation with FreeSWITCH for building voice-based applications and call routing systems.

## 🏗️ Architecture

This project runs a complete VoIP system using Docker with the following components:

- **FusionPBX**: Web-based PBX management interface (PHP 8.1 + PHP-FPM)
- **FreeSWITCH**: VoIP/telephony engine for handling calls
- **PostgreSQL 17**: Database backend
- **Nginx**: Web server and reverse proxy

## 📋 Prerequisites

- Docker Desktop installed
- Ports available: 80, 5060, 5080, 8022, 16384-16394

## 🚀 Quick Start

### Automated Installation (Recommended)

Run the automated installation script:

```bash
chmod +x install.sh
./install.sh
```

This will:
- Build all Docker images
- Start all services
- Install database schema
- Create admin user (username: `admin`, password: `admin`)
- Complete all configuration

**Takes 2-3 minutes. Then login at http://localhost**

---

### Manual Installation (Advanced)

If you prefer manual setup:

1. Build and start services:
```bash
docker compose build
docker compose up -d
```

2. Wait 30 seconds, then go to: `http://localhost/core/install/install.php`

3. Fill in database details and create admin account

---

### 3. Login

**Username**: `admin`  
**Password**: `admin`

> ⚠️ **Change the default password after first login!**

## 📦 Services

| Service | Container Name | Ports | Purpose |
|---------|---------------|-------|---------|
| FusionPBX | `fusionpbx_app` | 9000 (internal) | Web UI and PBX logic |
| FreeSWITCH | `fusionpbx_freeswitch` | 5060, 5080, 8022, 16384-16394 | VoIP engine |
| PostgreSQL | `fusionpbx_postgres` | 5432 (internal) | Database |
| Nginx | `fusionpbx_nginx` | 80 | Web server |

## 🔧 Configuration

### Database Connection
- **Host**: `postgres`
- **Port**: `5432`
- **Database**: `fusionpbx`
- **Username**: `fusionpbx`
- **Password**: `password123`

### FreeSWITCH Event Socket
- **Host**: `freeswitch`
- **Port**: `8021` (mapped to host port `8022`)
- **Password**: `ClueCon`

## 📁 Project Structure

```
fusionpbx-voicebot/
├── docker-compose.yml          # Main orchestration file
├── fusionpbx/
│   └── Dockerfile              # FusionPBX + PHP-FPM container
├── freeswitch/
│   └── Dockerfile              # FreeSWITCH container (compiled from source)
├── nginx/
│   └── default.conf            # Nginx reverse proxy config
└── data/
    └── postgres/               # PostgreSQL data (persisted)
```

## 🛠️ Common Commands

### Start Services
```bash
docker compose up -d
```

### Stop Services
```bash
docker compose down
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f fusionpbx
docker compose logs -f freeswitch
docker compose logs -f nginx
```

### Restart Services
```bash
docker compose restart fusionpbx
docker compose restart freeswitch
docker compose restart nginx
```

### Check Status
```bash
docker compose ps
```

### Access FreeSWITCH CLI
```bash
docker compose exec freeswitch fs_cli
```

## 🎯 Next Steps

### 1. Create Extensions (Phone Numbers)
- Go to **Accounts > Extensions**
- Click **Add (+)** button
- Fill in extension number (e.g., 1000) and password
- Save

### 2. Configure SIP Phone
Use any SIP softphone (X-Lite, Zoiper, Linphone) with:
- **Server**: `localhost` or your server IP
- **Port**: `5060`
- **Username**: Extension number (e.g., 1000)
- **Password**: Extension password you created

### 3. Create IVR Menu (Voice Menu)
- Go to **Apps > IVR Menus**
- Create interactive voice menus for your voicebot

### 4. Set Up Call Flows
- Go to **Apps > Call Flows**
- Define call routing logic

### 5. Configure Dialplan
- Go to **Dialplan > Dialplan Manager**
- Create custom call routing rules

## 🔐 Security Notes

**⚠️ IMPORTANT**: This setup is for development/testing only!

For production:
1. Change default passwords:
   - Admin password
   - Database password (`docker-compose.yml`)
2. Use HTTPS (add SSL certificates to nginx)
3. Restrict network access to SIP ports
4. Enable firewall rules
5. Regular backups of PostgreSQL data

## 🐛 Troubleshooting

### Web UI shows blank page
- Clear browser cache (Ctrl+Shift+Del)
- Check logs: `docker compose logs fusionpbx`
- Restart services: `docker compose restart`

### Cannot connect to database
- Verify postgres is running: `docker compose ps`
- Check config: `docker compose exec fusionpbx cat /etc/fusionpbx/config.conf`
- Should show `database.0.host = postgres` (not localhost)

### FreeSWITCH not connecting
- Check if running: `docker compose exec freeswitch fs_cli -x "status"`
- View logs: `docker compose logs freeswitch`

### Menu not showing
- Clear cache: `docker compose exec fusionpbx rm -rf /var/cache/fusionpbx/*`
- Restart: `docker compose restart fusionpbx nginx`
- Hard refresh browser (Ctrl+F5)

## 📊 Resource Usage

### Memory Requirements
- **PHP Memory Limit**: 4GB (configured for large installations)
- **Recommended System RAM**: 8GB minimum
- **Docker Resources**: Allocate at least 6GB to Docker Desktop

### Disk Space
- **PostgreSQL Data**: ~500MB-2GB (grows with usage)
- **FreeSWITCH Data**: ~1GB
- **Docker Images**: ~2GB

## 🔄 Backup & Restore

### Backup Database
```bash
docker compose exec postgres pg_dump -U fusionpbx fusionpbx > backup.sql
```

### Restore Database
```bash
cat backup.sql | docker compose exec -T postgres psql -U fusionpbx fusionpbx
```

### Backup All Data
```bash
docker compose down
tar -czf fusionpbx-backup.tar.gz data/
docker compose up -d
```

## 🔗 Useful URLs

- **Dashboard**: http://localhost/core/dashboard/
- **Extensions**: http://localhost/app/extensions/extensions.php
- **Dialplan**: http://localhost/app/dialplans/dialplans.php
- **IVR Menus**: http://localhost/app/ivr_menus/ivr_menus.php
- **Settings**: http://localhost/core/default_settings/default_settings.php

## 📝 Notes

- **PHP Memory**: Increased to 4GB to handle FusionPBX installation
- **PHP-FPM**: Configured to listen on port 9000 (TCP) instead of Unix socket
- **Named Volumes**: Used for data persistence instead of bind mounts
- **FreeSWITCH**: Compiled from source (v1.10.10)
- **Database Host**: Set to `postgres` container name for inter-container communication

## 📚 Documentation

- [FusionPBX Official Docs](https://docs.fusionpbx.com/)
- [FreeSWITCH Documentation](https://freeswitch.org/confluence/)

## 🆘 Support

If you encounter issues:
1. Check logs: `docker compose logs`
2. Verify all containers are running: `docker compose ps`
3. Restart services: `docker compose restart`
4. For database issues, check config file maps to `postgres` not `localhost`

## 📜 License

This is a Docker deployment of FusionPBX and FreeSWITCH. Please refer to their respective licenses:
- FusionPBX: MPL 1.1
- FreeSWITCH: MPL 1.1

