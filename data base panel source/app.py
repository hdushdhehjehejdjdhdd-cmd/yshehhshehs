import os
import requests
from urllib.parse import urlencode
from flask import Flask, redirect, request, session, render_template, url_for
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.secret_key = os.urandom(24)  # ← change this in production to a fixed secure value

# ────────────────────────────────────────
#  Config
# ────────────────────────────────────────

DISCORD_CLIENT_ID     = os.getenv("DISCORD_CLIENT_ID")
DISCORD_CLIENT_SECRET = os.getenv("DISCORD_CLIENT_SECRET")
DISCORD_REDIRECT_URI  = os.getenv("DISCORD_REDIRECT_URI", "https://rayzhub-panel.vercel.app/callback")

SUPABASE_URL    = os.getenv("SUPABASE_URL")
SUPABASE_KEY    = os.getenv("SUPABASE_ANON_KEY")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

OAUTH_AUTHORIZE_URL = "https://discord.com/api/oauth2/authorize"
OAUTH_TOKEN_URL     = "https://discord.com/api/oauth2/token"
OAUTH_USER_URL      = "https://discord.com/api/users/@me"

SCOPE = "identify"

ALLOWED_ADMIN_IDS = {1239232188797423676, 1176704913942782143, 1200497269267497123, 1271133923652403212, 1346520686507589712, 1454388467713704046}

# ────────────────────────────────────────
#  Helpers
# ────────────────────────────────────────

def get_discord_auth_url():
    params = {
        "client_id": DISCORD_CLIENT_ID,
        "redirect_uri": DISCORD_REDIRECT_URI,
        "response_type": "code",
        "scope": SCOPE,
    }
    return f"{OAUTH_AUTHORIZE_URL}?{urlencode(params)}"


def exchange_code_for_token(code: str):
    data = {
        "client_id": DISCORD_CLIENT_ID,
        "client_secret": DISCORD_CLIENT_SECRET,
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": DISCORD_REDIRECT_URI,
        "scope": SCOPE,
    }
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    r = requests.post(OAUTH_TOKEN_URL, data=data, headers=headers)
    r.raise_for_status()
    return r.json()


def get_discord_user(access_token: str):
    headers = {"Authorization": f"Bearer {access_token}"}
    r = requests.get(OAUTH_USER_URL, headers=headers)
    r.raise_for_status()
    return r.json()


# ────────────────────────────────────────
#  Routes
# ────────────────────────────────────────

@app.route("/")
def index():
    if "user" not in session:
        return render_template("login.html", login_url=get_discord_auth_url())
    return redirect(url_for("dashboard"))


@app.route("/login")
def login():
    return redirect(get_discord_auth_url())


@app.route("/callback")
def callback():
    code = request.args.get("code")
    if not code:
        return "No code provided", 400

    try:
        token_data = exchange_code_for_token(code)
        access_token = token_data["access_token"]

        user = get_discord_user(access_token)
        user_id = int(user["id"])

        session["user"] = {
            "id": user_id,
            "username": user["username"],
            "global_name": user.get("global_name"),
            "avatar": user.get("avatar"),
        }

        if user_id not in ALLOWED_ADMIN_IDS:
            session.clear()
            return "You are not authorized to view this dashboard.", 403

        return redirect(url_for("dashboard"))

    except Exception as e:
        return f"Authentication failed: {str(e)}", 500


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("index"))


@app.route("/dashboard")
def dashboard():
    if "user" not in session:
        return redirect(url_for("index"))

    try:
        res = supabase.table("user_configs").select("*").execute()
        users = res.data
        error = None
    except Exception as e:
        users = []
        error = str(e)

    return render_template(
        "dashboard.html",
        current_user=session.get("user", {}),
        users=users,
        error=error
    )


# Required for Vercel / gunicorn
application = app


if __name__ == "__main__":
    app.run(debug=True, port=5000)