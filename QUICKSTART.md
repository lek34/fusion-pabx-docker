# 🚀 Quick Start - 2 Minutes to Running System

## 1️⃣ Run Automated Installation

```bash
chmod +x install.sh
./install.sh
```

Wait 2-3 minutes for completion.

**OR manually:**

```bash
docker compose build
docker compose up -d
```

Wait 30 seconds, then complete web installer at `http://localhost/core/install/install.php`

## 2️⃣ Login

Open browser: **http://localhost**

```
Username: admin
Password: admin
```

## 3️⃣ Create Extension

Click **Accounts > Extensions > Add**

```
Extension: 1000
Password: test123
```

Click **Save**

## 4️⃣ Done! 

You now have a working VoIP system.

---

## Common Commands

```bash
# Stop
docker compose down

# Restart
docker compose restart

# Logs
docker compose logs -f

# Status
docker compose ps
```

## Important URLs

- Dashboard: http://localhost/core/dashboard/
- Extensions: http://localhost/app/extensions/extensions.php
- Dialplan: http://localhost/app/dialplans/dialplans.php
- IVR Menus: http://localhost/app/ivr_menus/ivr_menus.php

## Credentials

### FusionPBX
- Username: `admin`
- Password: `admin`

### Database (internal)
- Host: `postgres`
- User: `fusionpbx`
- Password: `password123`

---

**Need more details? See README.md**

