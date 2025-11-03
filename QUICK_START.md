# 🚀 Quick Start Guide - Voice Bot in 5 Minutes

## Prerequisites
- Docker Desktop running
- 8GB RAM minimum

## Step 1: Install (2-3 minutes)
```bash
chmod +x install.sh
./install.sh
```

## Step 2: Get Your Host IP
```bash
ifconfig | grep "inet "
```
Note down your IP (e.g., `192.168.100.147`) - NOT 127.0.0.1

## Step 3: Configure Audio
```bash
# Replace YOUR_HOST_IP with your actual IP
export HOST_IP=192.168.100.147

docker compose exec freeswitch bash -c "sed -i 's/external_rtp_ip=.*/external_rtp_ip=$HOST_IP/' /usr/local/freeswitch/conf/vars.xml"
docker compose exec freeswitch bash -c "sed -i 's/external_sip_ip=.*/external_sip_ip=$HOST_IP/' /usr/local/freeswitch/conf/vars.xml"
docker compose exec freeswitch bash -c "sed -i 's/<param name=\"ext-rtp-ip\".*/<param name=\"ext-rtp-ip\" value=\"$HOST_IP\"\/>/' /usr/local/freeswitch/conf/sip_profiles/internal.xml"
docker compose exec freeswitch bash -c "sed -i 's/<param name=\"ext-sip-ip\".*/<param name=\"ext-sip-ip\" value=\"$HOST_IP\"\/>/' /usr/local/freeswitch/conf/sip_profiles/internal.xml"

docker compose restart freeswitch
sleep 10
```

## Step 4: Install Zoiper
Download: https://www.zoiper.com/en/voip-softphone/download/current

Configure:
- Domain: `YOUR_HOST_IP` (e.g., 192.168.100.147)
- Username: `1000`
- Password: `1234`
- Transport: UDP

**Important Settings:**
- STUN/ICE/TURN: OFF
- Use rport: ON
- Codecs: ONLY PCMU and PCMA enabled

## Step 5: Test Call
Dial `1888` in Zoiper:
1. Hear "Welcome"
2. Hear "Please enter pin followed by pound"
3. Press `1#` → "You are number one"
4. Press `2#` → "This is number two"
5. Press `3#` → Echo test (speak and hear your voice back)
6. "Thank you for calling"
7. "Goodbye"

## ✅ Success!
You now have a working voice bot with:
- ✅ Audio input/output
- ✅ DTMF (keypad) input
- ✅ Interactive menu
- ✅ Echo test

## 🐛 Quick Troubleshooting

### No audio?
```bash
# Verify IP settings
docker compose exec freeswitch fs_cli -x "sofia status profile internal" | grep ext-rtp-ip
# Should show YOUR_HOST_IP, not 127.0.0.1
```

### Can't register?
```bash
# Check FreeSWITCH is running
docker compose exec freeswitch fs_cli -x "status"
```

### DTMF not working?
Change Zoiper DTMF method:
- Settings → Accounts → Advanced → DTMF: Inband

## 📖 Full Documentation
See `README.md` for complete guide with troubleshooting.

