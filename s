#!/bin/bash

echo "🔄 [1/3] Updating FENRIR..."
if [ -d "/opt/fenrir/.git" ]; then
    cd /opt/fenrir
    git reset --hard HEAD || true
    git pull origin main || true
    systemctl daemon-reload || true
    systemctl restart fenrir.service || true
    systemctl restart cloudflared-tunnel.service || true
fi

echo "⏳ [2/3] Checking services..."
sleep 3
systemctl is-active fenrir.service && echo "✅ FENRIR SERVICE: ACTIVE & RUNNING!" || echo "⚠️ FENRIR SERVICE NOT RUNNING"
systemctl is-active cloudflared-tunnel.service && echo "✅ CLOUDFLARED TUNNEL: ACTIVE!" || echo "⚠️ TUNNEL NOT RUNNING"

python3 - << 'PYEOF'
import time, re, urllib.request, json, os

url = None
for i in range(15):
    try:
        if os.path.exists("/var/log/cloudflared.log"):
            with open("/var/log/cloudflared.log", "r") as f:
                content = f.read()
            matches = re.findall(r"https://[a-zA-Z0-9-]+\.trycloudflare\.com", content)
            if matches:
                url = matches[-1]
                break
    except Exception:
        pass
    time.sleep(1)

if url:
    print(f"✅ TUNNEL IS LIVE: {url}")
    app_url = f"{url}/app"
    token = "8248107394:AAHQ_bjEDbiVwiyOd5CCzvswRPxidUU1doc"
    chat_id = "5953981409"
    
    try:
        req = urllib.request.Request(
            f"https://api.telegram.org/bot{token}/setChatMenuButton",
            data=json.dumps({"menu_button": {"type": "web_app", "text": "🚀 War Room", "web_app": {"url": app_url}}}).encode(),
            headers={"Content-Type": "application/json"}
        )
        urllib.request.urlopen(req)
        print("📱 [3/3] Telegram Menu Button Updated!")
    except Exception as e:
        print(f"⚠️ Notice: {e}")

    try:
        msg = f"🐺 <b>فرمانده، وب‌اپلیکیشن ۱۰۰٪ زنده و متصل شد!</b> 🚀⚡️\n\n🔗 <b>لینک مستقیم وب‌اپلیکیشن:</b>\n{app_url}\n\nروی دکمه‌ی <b>🚀 War Room</b> در پایین تلگرام بزن و وارد شو!"
        req2 = urllib.request.Request(
            f"https://api.telegram.org/bot{token}/sendMessage",
            data=json.dumps({"chat_id": chat_id, "text": msg, "parse_mode": "HTML"}).encode(),
            headers={"Content-Type": "application/json"}
        )
        urllib.request.urlopen(req2)
        print("🎉 Telegram Notification Sent! ALL OPERATIONAL!")
    except Exception as e:
        pass
else:
    print("⚠️ Tunnel URL pending...")

PYEOF
