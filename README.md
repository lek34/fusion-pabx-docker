# FusionPBX VoiceBot System

A fully containerized FusionPBX installation with FreeSWITCH for building voice-based applications and call routing systems with working voice/audio interaction.

## 🏗️ Architecture

This project runs a complete VoIP system using Docker with the following components:

- **FusionPBX**: Web-based PBX management interface (PHP 8.1 + PHP-FPM)
- **FreeSWITCH**: VoIP/telephony engine for handling calls
- **PostgreSQL 17**: Database backend
- **Nginx**: Web server and reverse proxy

## 📋 Prerequisites

- Docker Desktop installed (minimum 8GB RAM allocated)
- Ports available: 80, 5060, 5080, 8022, 16384-16394
- **Mac users**: Ensure you know your host IP address (run `ifconfig | grep "inet "`)

## 🚀 Complete Setup Guide (From Zero to Working Audio Call)

### Step 1: Installation

Run the automated installation script:

**On Mac/Linux:**
```bash
chmod +x install.sh
./install.sh
```

**On Windows (WSL/Git Bash):**
```bash
bash install.sh
```

This will:
- Build all Docker images
- Start all services
- Install database schema
- Create admin user (username: `admin`, password: `admin`)
- **Fix FreeSWITCH event socket IPv6 issue automatically**
- **Configure RTP audio settings**

**Installation takes 2-3 minutes.**

### Step 2: Verify FreeSWITCH is Running

After installation completes, verify FreeSWITCH:

```bash
docker compose exec freeswitch fs_cli -x "status"
```

You should see output showing FreeSWITCH is running.

### Step 3: Configure Network Settings for Audio

**CRITICAL for Mac users:** FreeSWITCH needs to know your host IP for RTP (audio) to work.

1. Find your Mac's IP address:
```bash
ifconfig | grep "inet "
```
Look for something like `192.168.x.x` (NOT 127.0.0.1)

2. Update FreeSWITCH variables:
```bash
# Get your host IP first (example: 192.168.100.147)
docker compose exec freeswitch bash -c "sed -i 's/external_rtp_ip=.*/external_rtp_ip=YOUR_HOST_IP/' /usr/local/freeswitch/conf/vars.xml"
docker compose exec freeswitch bash -c "sed -i 's/external_sip_ip=.*/external_sip_ip=YOUR_HOST_IP/' /usr/local/freeswitch/conf/vars.xml"
```

Replace `YOUR_HOST_IP` with your actual IP (e.g., `192.168.100.147`)

3. Update internal SIP profile:
```bash
docker compose exec freeswitch bash -c "sed -i 's/<param name=\"ext-rtp-ip\".*/<param name=\"ext-rtp-ip\" value=\"YOUR_HOST_IP\"\/>/' /usr/local/freeswitch/conf/sip_profiles/internal.xml"
docker compose exec freeswitch bash -c "sed -i 's/<param name=\"ext-sip-ip\".*/<param name=\"ext-sip-ip\" value=\"YOUR_HOST_IP\"\/>/' /usr/local/freeswitch/conf/sip_profiles/internal.xml"
```

4. Restart FreeSWITCH:
```bash
docker compose restart freeswitch
sleep 10
```

### Step 4: Install and Configure SIP Softphone (Zoiper Recommended)

1. **Download Zoiper 5** (Free version): https://www.zoiper.com/en/voip-softphone/download/current

2. **Configure Zoiper Account:**
   - Open Zoiper
   - Settings → Accounts → Add Account
   - **Domain**: `YOUR_HOST_IP` (e.g., `192.168.100.147`)
   - **Username**: `1000`
   - **Password**: `1234`
   - **Outbound Proxy**: Leave EMPTY
   - **Transport**: UDP
   - Click "Register"

3. **Critical Audio Settings in Zoiper:**
   - Settings → Audio
   - Test your microphone and speakers work
   
   - Settings → Accounts → [Your Account] → Advanced
   - **STUN**: OFF
   - **ICE**: OFF  
   - **TURN**: OFF
   - **Outbound Proxy**: OFF
   - **Use rport**: ON (checked)
   - **Use auth username**: ON (checked)

4. **Codec Settings:**
   - Settings → Accounts → [Your Account] → Codecs
   - **Disable ALL codecs except**:
     - ✅ PCMU (G.711 μ-law)
     - ✅ PCMA (G.711 A-law)
   - Uncheck everything else (Opus, G.722, etc.)

5. **DTMF Settings:**
   - Settings → Accounts → [Your Account] → Advanced
   - **DTMF Method**: RFC 2833 (default)
   - If DTMF not working, try: Inband or SIP INFO

### Step 5: Verify Registration

Check if Zoiper successfully registered:

```bash
docker compose exec freeswitch fs_cli -x "sofia status profile internal reg"
```

You should see extension `1000` registered with your host IP.

### Step 6: Deploy Voice Bot Lua Script

1. **Create the Lua script:**
```bash
docker compose exec freeswitch bash -c 'cat > /usr/local/freeswitch/scripts/188_simple_demo.lua << "EOFLUA"
if not session then return end

local SOUNDS = "/usr/local/freeswitch/sounds/en/us/callie/ivr/16000"

session:answer()
session:sleep(500)

-- Welcome
session:streamFile(SOUNDS .. "/ivr-welcome.wav")
session:sleep(2000)

-- Ask for input
session:streamFile(SOUNDS .. "/ivr-please_enter_pin_followed_by_pound.wav")

local choice = session:getDigits(1, "#", 8000)
session:consoleLog("info", "=== User pressed: [" .. tostring(choice) .. "] ===\n")

-- Respond based on input
if choice == "1" then
    session:streamFile(SOUNDS .. "/ivr-you_are_number_one.wav")
    session:sleep(2000)
elseif choice == "2" then
    session:streamFile(SOUNDS .. "/ivr-this_is_number_two.wav")
    session:sleep(2000)
elseif choice == "3" then
    session:streamFile(SOUNDS .. "/ivr-you_have_selected_the_echo_test.wav")
    session:sleep(1000)
    session:execute("echo", "")
else
    session:streamFile(SOUNDS .. "/ivr-invalid_entry.wav")
    session:sleep(1000)
end

-- Goodbye
session:sleep(1000)
session:streamFile(SOUNDS .. "/ivr-thank_you_for_calling.wav")
session:sleep(1000)
session:streamFile(SOUNDS .. "/ivr-goodbye.wav")
session:sleep(2000)
session:hangup()
EOFLUA'
```

2. **Create dialplan entry:**
```bash
docker compose exec freeswitch bash -c 'cat > /usr/local/freeswitch/conf/dialplan/default/1888.xml << "EOF"
<include>
  <extension name="ivr_1888_simple">
    <condition field="destination_number" expression="^1888$">
      <action application="answer"/>
      <action application="lua" data="188_simple_demo.lua"/>
    </condition>
  </extension>
</include>
EOF'
```

3. **Reload dialplan:**
```bash
docker compose exec freeswitch fs_cli -x "reloadxml"
```

### Step 7: Make Your First Call! 🎉

1. **In Zoiper**, dial **1888** and press call
2. **Wait and listen**:
   - "Welcome"
   - "Please enter pin followed by pound"
3. **Press 1#** on your keyboard
   - You should hear: "**You are number one**"
4. **Or press 2#**:
   - You should hear: "**This is number two**"
5. **Or press 3#**:
   - You should hear: "You have selected the echo test"
   - **Speak into your microphone** - your voice should echo back!
6. Finally:
   - "Thank you for calling"
   - "Goodbye"
   - Call ends

### Step 8: Verify Call Logs

While on call or after, check logs:

```bash
docker compose logs freeswitch --tail=100 | grep -E "1888|User pressed|streamFile"
```

You should see entries showing your DTMF input and audio file playback.

---

## 🎯 Testing Different Scenarios

### Test Echo (9196)
```
Dial: 9196
Listen to the prompt, then speak
Your voice should echo back immediately
```

### Test Music on Hold (9664)
```
Dial: 9664
Should hear music playing
```

### Test Your Custom IVR (1888)
```
Dial: 1888
Press 1# → "You are number one"
Press 2# → "This is number two"  
Press 3# → Echo test
```

---

## 🔧 Troubleshooting Audio Issues

### Problem: No Audio / Silent Call

**Check 1: Verify RTP IP settings**
```bash
docker compose exec freeswitch fs_cli -x "sofia status profile internal"
```
Look for `ext-rtp-ip` and `ext-sip-ip` - they should be your HOST IP, not 127.0.0.1 or a public IP.

**Check 2: Verify codec negotiation**
```bash
# During a call, check active channel
docker compose exec freeswitch fs_cli -x "show channels"
```
Look for codec (should be PCMU or PCMA).

**Check 3: Check Zoiper received packets**
- During call, in Zoiper click the call
- Look at statistics: "Received packets" should be > 0
- If 0, RTP is not reaching Zoiper

**Solution:**
```bash
# Stop everything
docker compose down

# Find your host IP
ifconfig | grep "inet " 

# Edit vars.xml manually
docker compose up -d
docker compose exec freeswitch bash -c 'cat /usr/local/freeswitch/conf/vars.xml' | grep external

# Should show:
# external_rtp_ip=YOUR_HOST_IP
# external_sip_ip=YOUR_HOST_IP

# If not, fix and restart
docker compose restart freeswitch
```

### Problem: DTMF Not Detected (Pressed 1 but nothing happens)

**Solution 1: Change Zoiper DTMF method**
- Zoiper Settings → Accounts → Advanced
- Change DTMF to: **Inband** or **SIP INFO**
- Try calling again

**Solution 2: Increase getDigits timeout**
Edit Lua script, change:
```lua
local choice = session:getDigits(1, "#", 8000) -- increased to 8 seconds
```

### Problem: Zoiper Shows 403 Forbidden

**Check default password:**
```bash
docker compose exec freeswitch bash -c 'grep default_password /usr/local/freeswitch/conf/vars.xml'
```

Should show: `<X-PRE-PROCESS cmd="set" data="default_password=1234"/>`

**Re-enter credentials in Zoiper** with exact password.

### Problem: Zoiper Shows 408 Request Timeout

**Check FreeSWITCH is listening:**
```bash
docker compose exec freeswitch fs_cli -x "sofia status profile internal"
```

Should show `RUNNING` state.

**Restart internal profile:**
```bash
docker compose exec freeswitch fs_cli -x "sofia profile internal restart"
```

---

## 🎨 Customizing the Voice Bot

### Add Your Own Audio Files

1. **Record or generate audio files** (WAV format, 16kHz, 16-bit, mono)

2. **Copy to container:**
```bash
docker cp your_audio.wav fusionpbx_freeswitch:/usr/local/freeswitch/sounds/custom/
```

3. **Update Lua script** to use custom audio:
```lua
session:streamFile("/usr/local/freeswitch/sounds/custom/your_audio.wav")
```

### Add More Menu Options

Edit the Lua script:
```lua
elseif choice == "4" then
    session:streamFile(SOUNDS .. "/your-custom-prompt.wav")
    -- Add custom logic here
elseif choice == "5" then
    -- Bridge to another extension
    session:execute("bridge", "user/1001@$${domain}")
```

### Multi-Language Support

```lua
-- Language selection
session:streamFile(SOUNDS .. "/ivr-press-1-english-2-mandarin.wav")
local lang = session:getDigits(1, "#", 8000)

if lang == "1" then
    SOUNDS = "/usr/local/freeswitch/sounds/en/us/callie/ivr/16000"
elseif lang == "2" then
    SOUNDS = "/usr/local/freeswitch/sounds/zh/cn/voice/ivr/16000" -- if you have Mandarin files
end
```

---

## 🎬 Demo Script for Presentation

**Perfect flow for screen recording:**

1. Open Zoiper (already registered to extension 1000)
2. Dial **1888**
3. Wait for "Welcome"
4. Wait for "Please enter pin followed by pound"
5. Press **1** then **#**
6. Hear: "**You are number one**"
7. Hear: "Thank you for calling"
8. Hear: "Goodbye"
9. Call ends automatically

**Alternative demo - Echo test:**
1. Dial **1888**
2. Press **3#**
3. Say "Hello, this is a test"
4. Hear your own voice echo back
5. Demonstrates real-time audio processing

---

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

**Using helper script (Recommended):**
```bash
# Interactive mode
./fs_cli.sh

# Run specific command
./fs_cli.sh status
./fs_cli.sh "show channels"
./fs_cli.sh "sofia status profile external"
```

**Direct docker command:**
```bash
# Interactive mode
docker compose exec freeswitch fs_cli

# Run specific command
docker compose exec freeswitch fs_cli -x "status"
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

### FreeSWITCH not connecting / fs_cli error
**Error**: `[ERROR] fs_cli.c:1699 main() Error Connecting []`

**Solution**: Event socket IPv6 issue. Run:
```bash
# Fix event socket configuration
docker compose exec -T freeswitch bash -c 'sed -i "s/listen-ip\" value=\"::\"/listen-ip\" value=\"127.0.0.1\"/" /etc/freeswitch/autoload_configs/event_socket.conf.xml'

# Restart FreeSWITCH
docker compose restart freeswitch

# Wait 10 seconds, then test
./fs_cli.sh status
```

**Note**: The `install.sh` script automatically fixes this issue during installation.

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

