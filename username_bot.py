"""
Gaming + lookup + export Discord bot.

Setup:
    pip install -U discord.py aiohttp   (discord.py 2.4 or newer)
    Put your bot token (and nothing else) in token.txt next to this file.
    Developer Portal -> Bot tab -> turn ON both:
        - Server Members Intent
        - Message Content Intent
    Run: python gaming_bot_v2.py

Commands:
    /mc <address> [edition]          Minecraft server status (players, plugins, icon, Java or Bedrock)
    /mcuser <name or UUID>           Minecraft player: skin, cape, UUID, body render
    /roblox <username or ID>         Roblox profile card + friends/followers/following .txt
    /github <username>               GitHub profile lookup
    /discorduser <ID or username>    Public Discord account info + server details if available
    /freegames [store]               Free games on Steam, Epic and GOG
    /check <username>                Is a Discord username available?
    /checkmany <names>               Check up to 5 usernames
    /lowcharacternames               Try 10 random 2-3 character names
    /specialnames                    Try 10 names from a list of cool/special ones
    /robloxgame, /robloxgroup        Roblox game and group info
    /steam <user>                    Steam profile (needs steam_key.txt)
    /steamgame <game>                Steam store info: price, reviews, players
    /deals <game>                    Price comparison across stores + historical low
    /fortnite <name>                 Fortnite stats (needs fortnite_key.txt)
    /repo, /package, /domain         GitHub repo, npm/PyPI package, domain DNS + registration
    /invite, /snowflake, /discordstatus, /permissions   Discord utilities
    /exportchannel <guild_id> <channel_id> [limit] [include_files]
                                     Export messages + embeds to .txt and attachments to .zip
"""

import asyncio
import base64
import datetime
import io
import json
import os
import random
import re
import string
import math
import tempfile
import time
import uuid
import zipfile
from typing import Optional
from urllib.parse import quote

import aiohttp
import discord
from discord import app_commands

TOKEN = open("token.txt", encoding="utf-8").read().strip()


def read_key(filename: str) -> Optional[str]:
    """Optional API key stored in a text file next to the bot. Returns None if missing/empty."""
    try:
        with open(filename, encoding="utf-8") as f:
            return f.read().strip() or None
    except FileNotFoundError:
        return None


STEAM_KEY = read_key("steam_key.txt")
FORTNITE_KEY = read_key("fortnite_key.txt")


# ---------- bot setup ----------

class Bot(discord.Client):
    def __init__(self):
        intents = discord.Intents.default()
        intents.members = True          # username search among shared servers
        intents.message_content = True  # needed to read message text for exports
        super().__init__(intents=intents)
        # Commands work anywhere for people who install the app to their account
        # (user install), as well as in servers where the bot is added.
        self.tree = app_commands.CommandTree(
            self,
            allowed_contexts=app_commands.AppCommandContext(guild=True, dm_channel=True, private_channel=True),
            allowed_installs=app_commands.AppInstallationType(guild=True, user=True),
        )
        self.web: aiohttp.ClientSession | None = None

    async def setup_hook(self):
        self.web = aiohttp.ClientSession(
            timeout=aiohttp.ClientTimeout(total=10),
            headers={"User-Agent": "gaming-discord-bot"},
        )
        await self.tree.sync()

    async def on_ready(self):
        print(f"Logged in as {self.user} - commands synced")


bot = Bot()


async def get_json(url: str, **kwargs):
    """Returns (status, json_or_None). Never raises on network problems."""
    try:
        async with bot.web.request(kwargs.pop("method", "GET"), url, **kwargs) as resp:
            try:
                data = await resp.json(content_type=None)
            except Exception:
                data = None
            return resp.status, data
    except Exception as e:
        print(f"request failed {url}: {e!r}")
        return 0, None


# ---------- gaming commands ----------

def clean_text(v) -> str:
    """Minecraft status fields come back as str, list, or {'clean': [...]}."""
    if isinstance(v, dict):
        v = v.get("clean", "")
    if isinstance(v, list):
        v = "\n".join(str(x) for x in v)
    return str(v or "")


def named_list(items: list, limit: int = 10) -> str:
    names = []
    for it in items[:limit]:
        if isinstance(it, dict):
            n, v = it.get("name", "?"), it.get("version")
            names.append(f"{n} {v}" if v else str(n))
        else:
            names.append(str(it))
    text = ", ".join(names)
    if len(items) > limit:
        text += f" (+{len(items) - limit} more)"
    return text


@bot.tree.command(name="mc", description="Check a Minecraft server's status")
@app_commands.describe(address="Server address, e.g. play.hypixel.net", edition="Java (default) or Bedrock")
@app_commands.choices(edition=[
    app_commands.Choice(name="Java", value="java"),
    app_commands.Choice(name="Bedrock", value="bedrock"),
])
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def mc(interaction: discord.Interaction, address: str, edition: Optional[app_commands.Choice[str]] = None):
    await interaction.response.defer()
    bedrock = edition is not None and edition.value == "bedrock"
    base = "https://api.mcsrvstat.us/bedrock/3/" if bedrock else "https://api.mcsrvstat.us/3/"
    status, d = await get_json(base + quote(address.strip()))
    if status != 200 or not d:
        await interaction.followup.send("Couldn't reach the status service. Try again in a moment.")
        return

    online = d.get("online", False)
    embed = discord.Embed(
        title=d.get("hostname") or address.strip(),
        color=discord.Color.green() if online else discord.Color.red(),
    )
    embed.add_field(name="Status", value="Online" if online else "Offline", inline=True)
    embed.add_field(name="Edition", value="Bedrock" if bedrock else "Java", inline=True)
    ip, port = d.get("ip"), d.get("port")
    if ip:
        embed.add_field(name="Address", value=f"{ip}:{port}" if port else str(ip), inline=True)

    if online:
        players = d.get("players") or {}
        embed.add_field(name="Players", value=f"{players.get('online', 0)}/{players.get('max', '?')}", inline=True)
        if d.get("version"):
            embed.add_field(name="Version", value=clean_text(d["version"])[:200], inline=True)
        protocol = d.get("protocol")
        if isinstance(protocol, dict) and protocol.get("version") is not None:
            embed.add_field(name="Protocol", value=str(protocol["version"]), inline=True)
        if d.get("software"):
            embed.add_field(name="Software", value=clean_text(d["software"])[:200], inline=True)
        if d.get("gamemode"):
            embed.add_field(name="Game mode", value=clean_text(d["gamemode"])[:100], inline=True)
        if d.get("map"):
            embed.add_field(name="Map", value=clean_text(d["map"])[:100], inline=True)

        names = [p.get("name") for p in (players.get("list") or []) if isinstance(p, dict) and p.get("name")]
        if names:
            embed.add_field(name="Players online", value=named_list(names, 25)[:1000], inline=False)
        if d.get("plugins"):
            embed.add_field(name=f"Plugins ({len(d['plugins'])})", value=named_list(d["plugins"], 10)[:1000], inline=False)
        if d.get("mods"):
            embed.add_field(name=f"Mods ({len(d['mods'])})", value=named_list(d["mods"], 10)[:1000], inline=False)

        motd = clean_text(d.get("motd"))
        if motd:
            embed.add_field(name="MOTD", value=motd[:1000], inline=False)
    if d.get("eula_blocked"):
        embed.add_field(name="Notice", value="This server is blocked by Mojang for EULA violations.", inline=False)

    kwargs: dict = {"embed": embed}
    icon = d.get("icon")
    if isinstance(icon, str) and icon.startswith("data:image") and "," in icon:
        try:
            raw = base64.b64decode(icon.split(",", 1)[1])
            kwargs["file"] = discord.File(io.BytesIO(raw), filename="icon.png")
            embed.set_thumbnail(url="attachment://icon.png")
        except Exception as e:
            print(f"icon decode failed: {e!r}")
    await interaction.followup.send(**kwargs)


@bot.tree.command(name="mcuser", description="Look up a Minecraft (Java) player by name or UUID")
@app_commands.describe(name="Minecraft username or UUID")
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def mcuser(interaction: discord.Interaction, name: str):
    await interaction.response.defer()
    q = name.strip()
    compact = q.replace("-", "")
    legacy = demo = False

    if re.fullmatch(r"[0-9a-fA-F]{32}", compact):
        raw = compact.lower()
    else:
        status, data = await get_json(f"https://api.mojang.com/users/profiles/minecraft/{quote(q)}")
        if status in (204, 404) or (status == 200 and not data):
            await interaction.followup.send("No Minecraft Java account found for that.")
            return
        if status != 200:
            await interaction.followup.send("Couldn't reach Mojang right now. Try again in a moment.")
            return
        raw = data["id"]
        legacy, demo = bool(data.get("legacy")), bool(data.get("demo"))

    status, prof = await get_json(f"https://sessionserver.mojang.com/session/minecraft/profile/{raw}")
    if status in (204, 404) or (status == 200 and not prof):
        await interaction.followup.send("No Minecraft Java account found for that.")
        return
    if status != 200:
        await interaction.followup.send("Couldn't load that profile from Mojang right now. Try again in a moment.")
        return

    username = prof.get("name", q)
    skin_url = cape_url = None
    model = "Classic"
    for p in prof.get("properties", []):
        if p.get("name") == "textures":
            try:
                tex = json.loads(base64.b64decode(p["value"])).get("textures", {})
                skin = tex.get("SKIN", {})
                skin_url = skin.get("url")
                model = "Slim" if skin.get("metadata", {}).get("model") == "slim" else "Classic"
                cape_url = tex.get("CAPE", {}).get("url")
            except Exception as e:
                print(f"texture decode failed: {e!r}")

    uuid = f"{raw[:8]}-{raw[8:12]}-{raw[12:16]}-{raw[16:20]}-{raw[20:]}"
    embed = discord.Embed(
        title=username,
        url=f"https://namemc.com/profile/{quote(username)}",
        color=discord.Color.dark_green(),
    )
    embed.add_field(name="Username", value=username, inline=True)
    embed.add_field(name="Skin model", value=model, inline=True)
    embed.add_field(name="Cape", value="Yes" if cape_url else "No", inline=True)
    embed.add_field(name="UUID", value=uuid, inline=False)
    embed.add_field(name="UUID (no dashes)", value=raw, inline=False)
    flags = [label for label, on in (("Legacy account", legacy), ("Demo account", demo)) if on]
    if flags:
        embed.add_field(name="Account type", value=", ".join(flags), inline=True)

    links = [f"[NameMC](https://namemc.com/profile/{quote(username)})"]
    if skin_url:
        links.append(f"[Skin file]({skin_url})")
    if cape_url:
        links.append(f"[Cape file]({cape_url})")
    embed.add_field(name="Links", value=" | ".join(links), inline=False)

    embed.set_thumbnail(url=f"https://mc-heads.net/avatar/{raw}/128")
    embed.set_image(url=f"https://mc-heads.net/body/{raw}/right")
    embed.set_footer(text="Mojang no longer provides name history.")
    await interaction.followup.send(embed=embed)


ROBLOX_LIST_CAP = 1000  # max followers / following listed per file
ROBLOX_FRIENDS = "https://friends.roblox.com/v1/users/"


async def roblox_paginated(url: str, cap: int) -> tuple[list[dict], Optional[str]]:
    """Walk a cursor-paginated Roblox list. Returns (items, problem_note_or_None)."""
    items: list[dict] = []
    cursor = None
    while len(items) < cap:
        full = f"{url}?limit=100&sortOrder=Desc" + (f"&cursor={quote(cursor)}" if cursor else "")
        status, data = await get_json(full)
        if status == 429:
            return items, "Roblox rate limited this request, so the list is incomplete."
        if status != 200 or not data:
            return items, f"Roblox returned an error ({status}), so the list may be incomplete."
        items.extend(data.get("data", []))
        cursor = data.get("nextPageCursor")
        if not cursor:
            break
        await asyncio.sleep(0.4)
    return items[:cap], None


def roblox_list_section(title: str, items: list[dict], total: Optional[int], note: Optional[str]) -> list[str]:
    shown = f"{len(items)} listed"
    head = f"{title} ({total:,} total, {shown})" if total is not None else f"{title} ({shown})"
    lines = [head, "username | display name | id"]
    for i in items:
        uname = i.get("name", "?")
        lines.append(f"{uname} | {i.get('displayName') or uname} | {i.get('id')}")
    if total is not None and total > len(items) and not note:
        lines.append(f"Note: only the first {len(items)} are listed.")
    if note:
        lines.append(f"Note: {note}")
    lines.append("")
    return lines


def roblox_image(result) -> Optional[str]:
    status, data = result
    if status == 200 and data and data.get("data"):
        d = data["data"][0]
        if d.get("state") == "Completed":
            return d.get("imageUrl")
    return None


def roblox_count(result) -> Optional[int]:
    status, data = result
    if status == 200 and data and isinstance(data.get("count"), int):
        return data["count"]
    return None


@bot.tree.command(name="roblox", description="Look up a Roblox user by username or ID")
@app_commands.describe(
    user="Roblox username or numeric user ID",
    lists="Also send a .txt with their friends, followers and following (default yes)",
)
@app_commands.checks.cooldown(1, 15.0, key=lambda i: i.user.id)
async def roblox(interaction: discord.Interaction, user: str, lists: bool = True):
    await interaction.response.defer()
    q = user.strip()

    if q.isdigit():
        user_id = int(q)
    else:
        status, data = await get_json(
            "https://users.roblox.com/v1/usernames/users",
            method="POST",
            json={"usernames": [q], "excludeBannedUsers": False},
        )
        if status != 200 or data is None:
            await interaction.followup.send("Couldn't reach Roblox right now. Try again in a moment.")
            return
        if not data.get("data"):
            await interaction.followup.send("No Roblox user with that name.")
            return
        user_id = data["data"][0]["id"]

    status, info = await get_json(f"https://users.roblox.com/v1/users/{user_id}")
    if status == 404:
        await interaction.followup.send("No Roblox user with that ID.")
        return
    if status != 200 or not info:
        await interaction.followup.send("Couldn't load that profile right now.")
        return

    avatar, headshot, friends_n, followers_n, following_n, history = await asyncio.gather(
        get_json(f"https://thumbnails.roblox.com/v1/users/avatar?userIds={user_id}&size=420x420&format=Png&isCircular=false"),
        get_json(f"https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds={user_id}&size=150x150&format=Png&isCircular=false"),
        get_json(f"{ROBLOX_FRIENDS}{user_id}/friends/count"),
        get_json(f"{ROBLOX_FRIENDS}{user_id}/followers/count"),
        get_json(f"{ROBLOX_FRIENDS}{user_id}/followings/count"),
        get_json(f"https://users.roblox.com/v1/users/{user_id}/username-history?limit=10&sortOrder=Desc"),
    )
    n_friends, n_followers, n_following = roblox_count(friends_n), roblox_count(followers_n), roblox_count(following_n)

    username = info["name"]
    display = info.get("displayName") or username
    embed = discord.Embed(
        title=f"{display} (@{username})",
        url=f"https://www.roblox.com/users/{user_id}/profile",
        description=(info.get("description") or "No description.")[:500],
        color=discord.Color.blurple(),
    )
    embed.add_field(name="Username", value=username, inline=True)
    embed.add_field(name="Display name", value=display, inline=True)
    embed.add_field(name="User ID", value=str(user_id), inline=True)
    embed.add_field(name="Created", value=str(info.get("created", "Unknown"))[:10], inline=True)
    embed.add_field(name="Friends", value=f"{n_friends:,}" if n_friends is not None else "Unknown", inline=True)
    embed.add_field(name="Followers", value=f"{n_followers:,}" if n_followers is not None else "Unknown", inline=True)
    embed.add_field(name="Following", value=f"{n_following:,}" if n_following is not None else "Unknown", inline=True)
    if info.get("isBanned"):
        embed.add_field(name="Status", value="Banned", inline=True)

    h_status, h_data = history
    if h_status == 200 and h_data and h_data.get("data"):
        past = ", ".join(x["name"] for x in h_data["data"] if x.get("name"))
        if past:
            embed.add_field(name="Past usernames", value=past[:1000], inline=False)

    if (url := roblox_image(avatar)):
        embed.set_image(url=url)
    if (url := roblox_image(headshot)):
        embed.set_thumbnail(url=url)

    send_kwargs: dict = {"embed": embed}

    if lists:
        # friends: one call returns everyone; followers/following are paginated
        f_status, f_data = await get_json(f"{ROBLOX_FRIENDS}{user_id}/friends")
        friends = f_data.get("data", []) if f_status == 200 and f_data else []
        f_note = None if f_status == 200 else f"Couldn't load friends (HTTP {f_status})."
        followers, fol_note = await roblox_paginated(f"{ROBLOX_FRIENDS}{user_id}/followers", ROBLOX_LIST_CAP)
        following, fng_note = await roblox_paginated(f"{ROBLOX_FRIENDS}{user_id}/followings", ROBLOX_LIST_CAP)

        out = [
            f"Roblox user: {display} (@{username}), ID {user_id}",
            f"Generated: {fmt_ts(datetime.datetime.now(datetime.timezone.utc))}",
            "=" * 60,
            "",
        ]
        out += roblox_list_section("FRIENDS", friends, n_friends, f_note)
        out += roblox_list_section("FOLLOWERS", followers, n_followers, fol_note)
        out += roblox_list_section("FOLLOWING", following, n_following, fng_note)
        send_kwargs["file"] = discord.File(
            io.BytesIO("\n".join(out).encode("utf-8")), filename=f"roblox_{username}_lists.txt"
        )

    await interaction.followup.send(**send_kwargs)


@bot.tree.command(name="github", description="Look up a GitHub user")
@app_commands.describe(username="GitHub username")
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def github(interaction: discord.Interaction, username: str):
    await interaction.response.defer()
    q = username.strip().lstrip("@")
    if not re.fullmatch(r"[A-Za-z0-9-]{1,39}", q):
        await interaction.followup.send("That isn't a valid GitHub username.")
        return

    status, d = await get_json(f"https://api.github.com/users/{q}")
    if status == 404:
        await interaction.followup.send("No GitHub user with that name.")
        return
    if status in (403, 429):
        await interaction.followup.send("GitHub is rate limiting the bot right now. Try again later.")
        return
    if status != 200 or not d:
        await interaction.followup.send("Couldn't reach GitHub right now.")
        return

    embed = discord.Embed(
        title=f"{d.get('name') or d['login']} (@{d['login']})",
        url=d["html_url"],
        description=(d.get("bio") or "No bio.")[:500],
        color=discord.Color.dark_grey(),
    )
    embed.add_field(name="Repos", value=str(d.get("public_repos", 0)), inline=True)
    embed.add_field(name="Followers", value=str(d.get("followers", 0)), inline=True)
    embed.add_field(name="Following", value=str(d.get("following", 0)), inline=True)
    if d.get("company"):
        embed.add_field(name="Company", value=d["company"], inline=True)
    if d.get("location"):
        embed.add_field(name="Location", value=d["location"], inline=True)
    embed.add_field(name="Joined", value=str(d.get("created_at", "Unknown"))[:10], inline=True)
    embed.set_thumbnail(url=d["avatar_url"])
    await interaction.followup.send(embed=embed)


STORE_LABELS = {"steam": "Steam", "epic-games-store": "Epic Games", "gog": "GOG"}


@bot.tree.command(name="freegames", description="Show current free game giveaways (Steam, Epic, GOG)")
@app_commands.describe(store="Which store to show (default: all)")
@app_commands.choices(store=[
    app_commands.Choice(name="All stores", value="all"),
    app_commands.Choice(name="Steam", value="steam"),
    app_commands.Choice(name="Epic Games", value="epic-games-store"),
    app_commands.Choice(name="GOG", value="gog"),
])
@app_commands.checks.cooldown(1, 15.0, key=lambda i: i.user.id)
async def freegames(interaction: discord.Interaction, store: Optional[app_commands.Choice[str]] = None):
    await interaction.response.defer()
    chosen = store.value if store else "all"
    keys = list(STORE_LABELS) if chosen == "all" else [chosen]
    per_store = 4 if chosen == "all" else 10

    results = await asyncio.gather(
        *(get_json(f"https://www.gamerpower.com/api/giveaways?type=game&platform={k}") for k in keys)
    )

    embed = discord.Embed(title="Free games right now", color=discord.Color.gold())
    found = 0
    for key, (status, data) in zip(keys, results):
        if status != 200 or not isinstance(data, list):
            continue
        for g in data[:per_store]:
            end = g.get("end_date")
            ends = f"\nEnds {end}" if end and end != "N/A" else ""
            link = g.get("open_giveaway_url", "https://www.gamerpower.com")
            embed.add_field(
                name=f"[{STORE_LABELS[key]}] {g.get('title', 'Unknown')}"[:250],
                value=f"Worth {g.get('worth', 'N/A')}{ends}\n[Claim]({link})",
                inline=False,
            )
            found += 1

    if not found:
        await interaction.followup.send("No active free games found for that store, or the service is unavailable.")
        return
    embed.set_footer(text="Free-to-keep giveaways, not discounts. Data from GamerPower.")
    await interaction.followup.send(embed=embed)


# ---------- username availability ----------

USERNAME_ENDPOINT = "https://discord.com/api/v9/unique-username/username-attempt-unauthed"
USERNAME_RE = re.compile(r"^(?!.*\.\.)[a-z0-9_.]{2,32}$")
username_blocked_until = 0.0  # unix time; while in the future we don't touch the endpoint


def fmt_wait(seconds: float) -> str:
    if seconds >= 90:
        return f"{math.ceil(seconds / 60)} minutes"
    return f"{math.ceil(seconds)} seconds"


async def username_status(name: str) -> tuple[str, float]:
    """Returns (state, retry_seconds). state is taken | available | error | limited."""
    global username_blocked_until
    remaining = username_blocked_until - time.time()
    if remaining > 0:
        return "limited", remaining
    try:
        async with bot.web.post(USERNAME_ENDPOINT, json={"username": name}) as resp:
            if resp.status == 429:
                try:
                    data = await resp.json(content_type=None)
                    retry = float(data.get("retry_after", 60))
                except Exception:
                    retry = 60.0
                username_blocked_until = time.time() + retry
                print(f"[{name}] rate limited for {retry:.0f}s")
                return "limited", retry
            if resp.status != 200:
                print(f"[{name}] HTTP {resp.status}: {(await resp.text())[:300]}")
                return "error", 0.0
            data = await resp.json(content_type=None)
            return ("taken" if data.get("taken") else "available"), 0.0
    except Exception as e:
        print(f"username check failed for {name}: {e!r}")
        return "error", 0.0


def describe(name: str, state: str, retry: float) -> str:
    if state == "available":
        return f"`{name}` - AVAILABLE"
    if state == "taken":
        return f"`{name}` - taken"
    if state == "limited":
        return f"`{name}` - not checked, Discord is rate limiting this check for about {fmt_wait(retry)}"
    return f"`{name}` - couldn't check, try again in a bit"


@bot.tree.command(name="check", description="Check if a Discord username is available")
@app_commands.describe(username="The username to check")
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def check(interaction: discord.Interaction, username: str):
    name = username.strip().lower()
    if not USERNAME_RE.match(name):
        await interaction.response.send_message(
            "Usernames must be 2-32 characters: letters, numbers, `_` and `.` (no consecutive periods).",
            ephemeral=True,
        )
        return
    await interaction.response.defer()
    state, retry = await username_status(name)
    await interaction.followup.send(describe(name, state, retry))


@bot.tree.command(name="checkmany", description="Check up to 5 usernames at once")
@app_commands.describe(usernames="Usernames separated by spaces or commas")
@app_commands.checks.cooldown(1, 30.0, key=lambda i: i.user.id)
async def checkmany(interaction: discord.Interaction, usernames: str):
    names = list(dict.fromkeys(n for n in re.split(r"[,\s]+", usernames.strip().lower()) if n))[:5]
    if not names:
        await interaction.response.send_message("Give me at least one name.", ephemeral=True)
        return

    await interaction.response.defer()
    lines = []
    for i, n in enumerate(names):
        if not USERNAME_RE.match(n):
            lines.append(f"`{n}` - invalid format")
            continue
        state, retry = await username_status(n)
        if state == "limited":
            left = [x for x in names[i:] if USERNAME_RE.match(x)]
            lines.append(
                f"Stopped: Discord is rate limiting this check for about {fmt_wait(retry)}. "
                f"Not checked: {', '.join('`' + x + '`' for x in left)}"
            )
            break
        lines.append(describe(n, state, retry))
        await asyncio.sleep(1.5)
    await interaction.followup.send("\n".join(lines))


SPECIAL_NAMES = [
    "920", "777", "999", "444", "222",
    "111", "333", "555", "888", "000",
    "void", "nox", "vex", "echo", "onyx",
    "zenith", "havoc", "phantom", "luxe",
    "aero", "nova", "omen", "blaze",
    "ghost", "reign", "frost", "drift",
    "venom", "orbit", "chaos", "myth",
]
SEARCH_BATCH = 10      # names per run
SEARCH_DELAY = 3.0     # seconds between checks
search_lock = asyncio.Lock()


async def search_names(interaction: discord.Interaction, names: list[str], title: str):
    """Check names one at a time, stop at the first rate limit, report what was found."""
    if search_lock.locked():
        await interaction.response.send_message("A search is already running. Try again in a minute.", ephemeral=True)
        return
    await interaction.response.defer()

    async with search_lock:
        available, taken, errors, unchecked = [], 0, 0, []
        wait = 0.0
        for i, n in enumerate(names):
            state, retry = await username_status(n)
            if state == "limited":
                unchecked, wait = names[i:], retry
                break
            if state == "available":
                available.append(n)
            elif state == "taken":
                taken += 1
            else:
                errors += 1
            await asyncio.sleep(SEARCH_DELAY)

    checked = len(names) - len(unchecked)
    lines = [f"{title}: checked {checked} of {len(names)}."]
    lines.append("Available: " + (", ".join(f"`{n}`" for n in available) if available else "none"))
    lines.append(f"Taken: {taken}" + (f", errors: {errors}" if errors else ""))
    if unchecked:
        lines.append(
            f"Stopped early because Discord is rate limiting this check for about {fmt_wait(wait)}. "
            f"Not checked: {', '.join('`' + n + '`' for n in unchecked)}"
        )
    await interaction.followup.send("\n".join(lines))


@bot.tree.command(name="lowcharacternames", description="Try 10 random 2-3 character usernames")
@app_commands.checks.cooldown(1, 300.0, key=lambda i: i.user.id)
async def lowcharacternames(interaction: discord.Interaction):
    chars = string.ascii_lowercase + string.digits
    candidates: set[str] = set()
    while len(candidates) < SEARCH_BATCH:
        candidates.add("".join(random.choices(chars, k=random.choice([2, 3]))))
    await search_names(interaction, list(candidates), "Low character names")


@bot.tree.command(name="specialnames", description="Try 10 special/cool usernames from a list")
@app_commands.checks.cooldown(1, 300.0, key=lambda i: i.user.id)
async def specialnames(interaction: discord.Interaction):
    await search_names(interaction, random.sample(SPECIAL_NAMES, SEARCH_BATCH), "Special names")


# ---------- Discord account lookup ----------

@bot.tree.command(name="discorduser", description="Show public info about a Discord account")
@app_commands.describe(query="A user ID, a mention, or a username (usernames only work for people in servers I'm in)")
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def discorduser(interaction: discord.Interaction, query: str):
    await interaction.response.defer()
    q = re.sub(r"[<@!>]", "", query.strip())
    user: Optional[discord.User] = None

    if q.isdigit():
        try:
            user = await bot.fetch_user(int(q))
        except discord.HTTPException:
            user = None
    else:
        needle = q.lower()
        for g in bot.guilds:
            for m in g.members:
                if needle in (m.name.lower(), (m.global_name or "").lower(), m.display_name.lower()):
                    user = m
                    break
            if user:
                break
        if user:
            try:
                user = await bot.fetch_user(user.id)  # full profile (banner, accent color)
            except discord.HTTPException:
                pass

    if user is None:
        await interaction.followup.send(
            "Couldn't find that account. Usernames only work for people in servers I'm in, so try their user ID."
        )
        return

    created = user.created_at
    age_days = (datetime.datetime.now(datetime.timezone.utc) - created).days
    embed = discord.Embed(title=str(user), color=user.accent_colour or discord.Color.blurple())

    account_type = "Bot" if user.bot else "Human"
    if getattr(user, "system", False):
        account_type += " (Discord system account)"
    embed.add_field(name="Username", value=user.name, inline=True)
    embed.add_field(name="Display name", value=user.global_name or "None", inline=True)
    embed.add_field(name="User ID", value=str(user.id), inline=True)
    embed.add_field(name="Type", value=account_type, inline=True)
    embed.add_field(name="Account age", value=f"{age_days:,} days", inline=True)
    embed.add_field(
        name="Account created",
        value=f"{discord.utils.format_dt(created, 'F')} ({discord.utils.format_dt(created, 'R')})",
        inline=False,
    )

    avatar_kind = "Custom" if user.avatar else "Default"
    if user.avatar and user.avatar.is_animated():
        avatar_kind += " (animated)"
    embed.add_field(name="Avatar", value=avatar_kind, inline=True)
    embed.add_field(name="Banner", value="Yes" if getattr(user, "banner", None) else "No", inline=True)
    embed.add_field(name="Accent color", value=str(user.accent_colour) if user.accent_colour else "None", inline=True)
    if getattr(user, "avatar_decoration", None):
        embed.add_field(name="Avatar decoration", value="Yes", inline=True)

    try:
        pg = getattr(user, "primary_guild", None)
        if pg and getattr(pg, "tag", None) and getattr(pg, "identity_enabled", True):
            embed.add_field(name="Server tag", value=f"[{pg.tag}]", inline=True)
    except Exception:
        pass

    badges = [f.name.replace("_", " ").title() for f in user.public_flags.all()]
    embed.add_field(name="Badges", value=", ".join(badges) if badges else "None", inline=False)

    # server-specific info, only if the bot is in the server this was run in
    g = interaction.guild
    member = g.get_member(user.id) if g else None
    if member:
        if member.nick:
            embed.add_field(name="Nickname here", value=member.nick, inline=True)
        if member.joined_at:
            embed.add_field(name="Joined this server", value=discord.utils.format_dt(member.joined_at, "F"), inline=False)
            if g.chunked:
                ordered = sorted((m for m in g.members if m.joined_at), key=lambda m: m.joined_at)
                pos = next((i for i, m in enumerate(ordered, 1) if m.id == member.id), None)
                if pos:
                    embed.add_field(name="Join position", value=f"#{pos:,} of {len(ordered):,}", inline=True)
        if member.premium_since:
            embed.add_field(name="Boosting since", value=discord.utils.format_dt(member.premium_since, "D"), inline=True)
        until = getattr(member, "timed_out_until", None)
        if until and until > datetime.datetime.now(datetime.timezone.utc):
            embed.add_field(name="Timed out until", value=discord.utils.format_dt(until, "R"), inline=True)

        p = member.guild_permissions
        if g.owner_id == member.id:
            staff = "Server owner"
        elif p.administrator:
            staff = "Administrator"
        else:
            staff = ", ".join(
                label for flag, label in (
                    ("manage_guild", "Manage Server"), ("manage_roles", "Manage Roles"),
                    ("manage_channels", "Manage Channels"), ("manage_messages", "Manage Messages"),
                    ("kick_members", "Kick"), ("ban_members", "Ban"), ("moderate_members", "Timeout"),
                ) if getattr(p, flag)
            )
        if staff:
            embed.add_field(name="Staff permissions", value=staff, inline=False)

        roles = [r.mention for r in member.roles if r != g.default_role]
        if roles:
            top = member.top_role.mention if member.top_role != g.default_role else None
            embed.add_field(name=f"Roles here ({len(roles)})", value=" ".join(roles)[:1000], inline=False)
            if top:
                embed.add_field(name="Top role", value=top, inline=True)

    view = discord.ui.View()
    try:
        avatar_url = user.display_avatar.replace(size=1024).url
    except ValueError:
        avatar_url = user.display_avatar.url
    embed.set_thumbnail(url=avatar_url)
    view.add_item(discord.ui.Button(label="Avatar", url=avatar_url))
    if getattr(user, "banner", None):
        banner_url = user.banner.url
        embed.set_image(url=banner_url)
        view.add_item(discord.ui.Button(label="Banner", url=banner_url))

    await interaction.followup.send(embed=embed, view=view)


# ---------- channel export ----------

SAFE_NAME = re.compile(r"[^A-Za-z0-9._-]")


def fmt_ts(dt: datetime.datetime) -> str:
    return dt.astimezone(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")


def render_embed(e: discord.Embed, idx: int) -> list[str]:
    out = [f"  [Embed {idx}]"]
    if e.author and e.author.name:
        out.append(f"    Author: {e.author.name}")
    if e.title:
        out.append(f"    Title: {e.title}")
    if e.url:
        out.append(f"    URL: {e.url}")
    if e.description:
        out.append("    Description: " + e.description.replace("\n", "\n      "))
    for f in e.fields:
        out.append(f"    Field - {f.name}: " + str(f.value).replace("\n", "\n      "))
    if e.image and e.image.url:
        out.append(f"    Image: {e.image.url}")
    if e.thumbnail and e.thumbnail.url:
        out.append(f"    Thumbnail: {e.thumbnail.url}")
    if e.footer and e.footer.text:
        out.append(f"    Footer: {e.footer.text}")
    if e.timestamp:
        out.append(f"    Timestamp: {fmt_ts(e.timestamp)}")
    return out


def render_message(m: discord.Message) -> list[str]:
    head = f"[{fmt_ts(m.created_at)}] {m.author} ({m.author.id}) [msg {m.id}]"
    if m.reference and m.reference.message_id:
        head += f" (reply to {m.reference.message_id})"
    if m.edited_at:
        head += " (edited)"
    out = [head]

    content = m.content or (m.system_content if m.is_system() else "")
    if content:
        out.append("  " + content.replace("\n", "\n  "))
    for a in m.attachments:
        out.append(f"  [Attachment] {a.filename} ({a.size} bytes) {a.url}")
    for i, e in enumerate(m.embeds, 1):
        out.extend(render_embed(e, i))
    out.append("")
    return out


def chunk_text(lines: list[str], max_bytes: int) -> list[str]:
    """Split lines into chunks whose UTF-8 size stays under max_bytes."""
    chunks, current, size = [], [], 0
    for line in lines:
        b = len(line.encode("utf-8")) + 1
        if current and size + b > max_bytes:
            chunks.append("\n".join(current))
            current, size = [], 0
        current.append(line)
        size += b
    if current:
        chunks.append("\n".join(current))
    return chunks


class ZipSplitter:
    """Writes files into attachments zips, starting a new zip when the size limit would be exceeded."""

    def __init__(self, folder: str, max_bytes: int):
        self.folder, self.max, self.paths = folder, max_bytes, []
        self.zf, self.size = None, 0

    def add(self, name: str, data: bytes):
        if self.zf is None or self.size + len(data) > self.max:
            self.close()
            path = os.path.join(self.folder, f"attachments_part{len(self.paths) + 1}.zip")
            self.paths.append(path)
            self.zf = zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED)
            self.size = 0
        self.zf.writestr(name, data)
        self.size += len(data)

    def close(self):
        if self.zf:
            self.zf.close()
            self.zf = None

    def finalize(self) -> list[str]:
        self.close()
        if len(self.paths) == 1:
            final = os.path.join(self.folder, "attachments.zip")
            os.replace(self.paths[0], final)
            self.paths = [final]
        return self.paths


async def send_files(interaction: discord.Interaction, text: str, paths: list[str]):
    """Send files (max 10 per message) as ephemeral follow-ups; fall back to DM if that fails."""
    batches = [paths[i:i + 10] for i in range(0, len(paths), 10)] or [[]]
    for n, batch in enumerate(batches):
        files = [discord.File(p, filename=os.path.basename(p)) for p in batch]
        msg = text if n == 0 else f"More files ({n + 1}/{len(batches)})"
        try:
            await interaction.followup.send(msg, files=files, ephemeral=True)
        except discord.HTTPException:
            files = [discord.File(p, filename=os.path.basename(p)) for p in batch]
            await interaction.user.send(msg, files=files)


@bot.tree.command(
    name="exportchannel",
    description="Export a channel's messages and embeds to a .txt, with attachments in a .zip",
)
@app_commands.describe(
    guild_id="ID of the server",
    channel_id="ID of the channel (or thread)",
    limit="How many of the most recent messages to export (1-10000, default 1000)",
    include_files="Also download attachments into a zip (default yes)",
)
@app_commands.allowed_installs(guilds=True, users=False)  # needs the bot inside the server
@app_commands.allowed_contexts(guilds=True, dms=True, private_channels=False)
@app_commands.checks.cooldown(1, 60.0, key=lambda i: i.user.id)
async def exportchannel(
    interaction: discord.Interaction,
    guild_id: str,
    channel_id: str,
    limit: app_commands.Range[int, 1, 10000] = 1000,
    include_files: bool = True,
):
    await interaction.response.defer(ephemeral=True)

    async def fail(msg: str):
        await interaction.followup.send(msg, ephemeral=True)

    if not (guild_id.strip().isdigit() and channel_id.strip().isdigit()):
        return await fail("Guild ID and channel ID must both be numbers.")

    guild = bot.get_guild(int(guild_id))
    if guild is None:
        return await fail("I'm not in that server, so I can't read it. The bot has to be invited there first.")

    try:
        member = guild.get_member(interaction.user.id) or await guild.fetch_member(interaction.user.id)
    except discord.HTTPException:
        return await fail("You're not a member of that server.")

    if not (member.guild_permissions.manage_guild or member.guild_permissions.administrator):
        return await fail("You need the Manage Server permission in that server to export its channels.")

    try:
        channel = await guild.fetch_channel(int(channel_id))
    except discord.HTTPException:
        return await fail("I couldn't find that channel in that server.")
    if not hasattr(channel, "history"):
        return await fail("That channel type doesn't have a message history I can export.")

    for who, perms in (("You", channel.permissions_for(member)), ("I", channel.permissions_for(guild.me))):
        if not (perms.view_channel and perms.read_message_history):
            return await fail(f"{who} can't view that channel's message history.")

    try:
        msgs = [m async for m in channel.history(limit=limit)]
    except discord.HTTPException as e:
        return await fail(f"Discord refused the request: {e}")
    msgs.reverse()  # oldest first
    if not msgs:
        return await fail("That channel has no messages.")

    send_limit = (interaction.guild.filesize_limit if interaction.guild else 10 * 1024 * 1024) - 300_000

    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
        # --- text transcript ---
        lines = [
            f"Server: {guild.name} ({guild.id})",
            f"Channel: #{getattr(channel, 'name', channel.id)} ({channel.id})",
            f"Exported: {fmt_ts(datetime.datetime.now(datetime.timezone.utc))}",
            f"Messages: {len(msgs)} (most recent {limit} requested)",
            "=" * 60,
            "",
        ]
        for m in msgs:
            lines.extend(render_message(m))

        chunks = chunk_text(lines, send_limit)
        paths = []
        for i, chunk in enumerate(chunks, 1):
            name = "transcript.txt" if len(chunks) == 1 else f"transcript_part{i}.txt"
            p = os.path.join(tmp, name)
            with open(p, "w", encoding="utf-8") as f:
                f.write(chunk)
            paths.append(p)

        # --- attachments ---
        saved = skipped = 0
        if include_files:
            splitter = ZipSplitter(tmp, send_limit)
            for m in msgs:
                for a in m.attachments:
                    if a.size > send_limit:
                        skipped += 1
                        continue
                    try:
                        data = await a.read()
                    except discord.HTTPException:
                        skipped += 1
                        continue
                    splitter.add(f"{a.id}_{SAFE_NAME.sub('_', a.filename)}", data)
                    saved += 1
            paths.extend(splitter.finalize())

        summary = f"Exported {len(msgs)} messages from #{getattr(channel, 'name', channel.id)}."
        if include_files:
            summary += f" Attachments saved: {saved}."
            if skipped:
                summary += f" Skipped (too large or failed): {skipped}."
        if not any(m.content for m in msgs) and any(not m.author.bot for m in msgs):
            summary += " Message text looks empty. Make sure Message Content Intent is enabled in the Developer Portal."

        await send_files(interaction, summary, paths)


# ---------- shared helpers for the info commands ----------

UTC = datetime.timezone.utc

NEED_STEAM_KEY = (
    "This command needs a free Steam Web API key. Get one at https://steamcommunity.com/dev/apikey, "
    "paste it (nothing else) into a file called `steam_key.txt` next to `token.txt`, then restart the bot."
)
NEED_FORTNITE_KEY = (
    "This command needs a free fortnite-api.com key. Get one at https://dash.fortnite-api.com, "
    "paste it (nothing else) into a file called `fortnite_key.txt` next to `token.txt`, then restart the bot."
)


def parse_iso(s) -> Optional[datetime.datetime]:
    if not s:
        return None
    try:
        d = datetime.datetime.fromisoformat(str(s).replace("Z", "+00:00"))
    except ValueError:
        return None
    return d if d.tzinfo else d.replace(tzinfo=UTC)


def dstamp(s, style: str = "D") -> str:
    d = parse_iso(s)
    return discord.utils.format_dt(d, style) if d else "Unknown"


def num(n) -> str:
    return f"{n:,}" if isinstance(n, (int, float)) else "Unknown"


# ---------- Roblox: games and groups ----------

async def roblox_universe_from(q: str) -> Optional[int]:
    """Accepts a game URL, place ID, universe ID, or a name (best effort)."""
    q = q.strip()
    m = re.search(r"roblox\.com/(?:[a-z-]+/)?games/(\d+)", q)
    if m:
        q = m.group(1)
    if q.isdigit():
        status, data = await get_json(f"https://apis.roblox.com/universes/v1/places/{q}/universe")
        if status == 200 and data and data.get("universeId"):
            return int(data["universeId"])
        return int(q)  # assume it is already a universe ID
    status, data = await get_json(
        "https://apis.roblox.com/search-api/omni-search",
        params={"searchQuery": q, "sessionId": str(uuid.uuid4()), "pageType": "all"},
    )
    if status == 200 and isinstance(data, dict):
        for group in data.get("searchResults", []):
            for c in group.get("contents", []):
                if c.get("contentType") == "Game":
                    uid = c.get("universeId") or c.get("contentId")
                    if uid:
                        return int(uid)
    return None


@bot.tree.command(name="robloxgame", description="Look up a Roblox game")
@app_commands.describe(game="Game name, game URL, place ID or universe ID")
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def robloxgame(interaction: discord.Interaction, game: str):
    await interaction.response.defer()
    uid = await roblox_universe_from(game)
    if not uid:
        await interaction.followup.send("Couldn't find that game. Try pasting the game's URL or its place ID.")
        return

    info, votes, icon = await asyncio.gather(
        get_json(f"https://games.roblox.com/v1/games?universeIds={uid}"),
        get_json(f"https://games.roblox.com/v1/games/votes?universeIds={uid}"),
        get_json(f"https://thumbnails.roblox.com/v1/games/icons?universeIds={uid}&size=256x256&format=Png&isCircular=false"),
    )
    status, d = info
    if status != 200 or not d or not d.get("data"):
        await interaction.followup.send("No Roblox game found for that.")
        return
    g = d["data"][0]

    embed = discord.Embed(
        title=g.get("name", "Unknown game"),
        url=f"https://www.roblox.com/games/{g.get('rootPlaceId', '')}",
        description=(g.get("description") or "No description.")[:500],
        color=discord.Color.blurple(),
    )
    embed.add_field(name="Playing now", value=num(g.get("playing")), inline=True)
    embed.add_field(name="Visits", value=num(g.get("visits")), inline=True)
    embed.add_field(name="Favorites", value=num(g.get("favoritedCount")), inline=True)

    v_status, v_data = votes
    if v_status == 200 and v_data and v_data.get("data"):
        up, down = v_data["data"][0].get("upVotes", 0), v_data["data"][0].get("downVotes", 0)
        pct = f" ({up / (up + down) * 100:.0f}% liked)" if up + down else ""
        embed.add_field(name="Likes / dislikes", value=f"{num(up)} / {num(down)}{pct}", inline=True)

    creator = g.get("creator") or {}
    if creator.get("name"):
        embed.add_field(name="Creator", value=f"{creator['name']} ({creator.get('type', 'Unknown')})", inline=True)
    embed.add_field(name="Max players", value=num(g.get("maxPlayers")), inline=True)
    if g.get("genre"):
        embed.add_field(name="Genre", value=str(g["genre"]), inline=True)
    embed.add_field(name="Created", value=dstamp(g.get("created")), inline=True)
    embed.add_field(name="Last updated", value=dstamp(g.get("updated")), inline=True)
    if g.get("price"):
        embed.add_field(name="Price", value=f"{g['price']} Robux", inline=True)
    embed.add_field(name="Universe ID", value=str(uid), inline=True)

    url = roblox_image(icon)
    if url:
        embed.set_thumbnail(url=url)
    await interaction.followup.send(embed=embed)


@bot.tree.command(name="robloxgroup", description="Look up a Roblox group")
@app_commands.describe(group="Group name, group URL or group ID")
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def robloxgroup(interaction: discord.Interaction, group: str):
    await interaction.response.defer()
    q = group.strip()
    m = re.search(r"roblox\.com/(?:[a-z-]+/)?groups/(\d+)", q)
    if m:
        q = m.group(1)

    if q.isdigit():
        gid = int(q)
    else:
        status, data = await get_json("https://groups.roblox.com/v1/groups/search", params={"keyword": q, "limit": 10})
        results = data.get("data", []) if status == 200 and data else []
        if not results:
            await interaction.followup.send("No Roblox group found with that name.")
            return
        exact = [r for r in results if r.get("name", "").lower() == q.lower()]
        gid = (exact or results)[0]["id"]

    info, icon = await asyncio.gather(
        get_json(f"https://groups.roblox.com/v1/groups/{gid}"),
        get_json(f"https://thumbnails.roblox.com/v1/groups/icons?groupIds={gid}&size=420x420&format=Png&isCircular=false"),
    )
    status, g = info
    if status != 200 or not g or not g.get("name"):
        await interaction.followup.send("No Roblox group found for that.")
        return

    embed = discord.Embed(
        title=g["name"],
        url=f"https://www.roblox.com/communities/{gid}",
        description=(g.get("description") or "No description.")[:500],
        color=discord.Color.blurple(),
    )
    embed.add_field(name="Members", value=num(g.get("memberCount")), inline=True)
    embed.add_field(name="Group ID", value=str(gid), inline=True)
    owner = g.get("owner")
    if owner:
        embed.add_field(name="Owner", value=f"{owner.get('displayName') or owner.get('username')} (@{owner.get('username')})", inline=True)
    else:
        embed.add_field(name="Owner", value="No owner", inline=True)
    embed.add_field(name="Joining", value="Open" if g.get("publicEntryAllowed") else "Approval required", inline=True)
    embed.add_field(name="Verified badge", value="Yes" if g.get("hasVerifiedBadge") else "No", inline=True)
    shout = g.get("shout")
    if shout and shout.get("body"):
        embed.add_field(name="Group shout", value=shout["body"][:300], inline=False)

    url = roblox_image(icon)
    if url:
        embed.set_thumbnail(url=url)
    await interaction.followup.send(embed=embed)


# ---------- Steam ----------

STEAM_API = "https://api.steampowered.com"
STEAM_STATES = {0: "Offline", 1: "Online", 2: "Busy", 3: "Away", 4: "Snooze", 5: "Looking to trade", 6: "Looking to play"}


@bot.tree.command(name="steam", description="Look up a Steam profile")
@app_commands.describe(user="Steam ID, profile URL, or custom URL name")
@app_commands.checks.cooldown(1, 10.0, key=lambda i: i.user.id)
async def steam(interaction: discord.Interaction, user: str):
    if not STEAM_KEY:
        await interaction.response.send_message(NEED_STEAM_KEY, ephemeral=True)
        return
    await interaction.response.defer()

    q = user.strip()
    m = re.search(r"steamcommunity\.com/(?:id|profiles)/([^/?#]+)", q)
    if m:
        q = m.group(1)

    if re.fullmatch(r"\d{17}", q):
        sid = q
    else:
        status, data = await get_json(f"{STEAM_API}/ISteamUser/ResolveVanityURL/v1/", params={"key": STEAM_KEY, "vanityurl": q})
        if status in (401, 403):
            await interaction.followup.send("Steam rejected the API key. Check `steam_key.txt`.")
            return
        resp = (data or {}).get("response", {})
        if status != 200 or resp.get("success") != 1:
            await interaction.followup.send("No Steam profile found for that.")
            return
        sid = resp["steamid"]

    summ, lvl, owned, bans = await asyncio.gather(
        get_json(f"{STEAM_API}/ISteamUser/GetPlayerSummaries/v2/", params={"key": STEAM_KEY, "steamids": sid}),
        get_json(f"{STEAM_API}/IPlayerService/GetSteamLevel/v1/", params={"key": STEAM_KEY, "steamid": sid}),
        get_json(f"{STEAM_API}/IPlayerService/GetOwnedGames/v1/", params={"key": STEAM_KEY, "steamid": sid, "include_appinfo": 1}),
        get_json(f"{STEAM_API}/ISteamUser/GetPlayerBans/v1/", params={"key": STEAM_KEY, "steamids": sid}),
    )
    players = ((summ[1] or {}).get("response") or {}).get("players", []) if summ[0] == 200 else []
    if not players:
        await interaction.followup.send("No Steam profile found for that.")
        return
    p = players[0]
    public = p.get("communityvisibilitystate") == 3

    embed = discord.Embed(title=p.get("personaname", "Unknown"), url=p.get("profileurl"), color=discord.Color.dark_blue())
    embed.add_field(name="Steam ID", value=sid, inline=True)
    embed.add_field(name="Status", value=STEAM_STATES.get(p.get("personastate"), "Unknown"), inline=True)
    embed.add_field(name="Profile", value="Public" if public else "Private", inline=True)

    level = ((lvl[1] or {}).get("response") or {}).get("player_level") if lvl[0] == 200 else None
    if level is not None:
        embed.add_field(name="Level", value=str(level), inline=True)
    if p.get("timecreated"):
        embed.add_field(name="Created", value=discord.utils.format_dt(datetime.datetime.fromtimestamp(p["timecreated"], UTC), "D"), inline=True)
    if p.get("loccountrycode"):
        embed.add_field(name="Country", value=p["loccountrycode"], inline=True)
    if p.get("gameextrainfo"):
        embed.add_field(name="Playing now", value=p["gameextrainfo"], inline=False)

    games_resp = ((owned[1] or {}).get("response") or {}) if owned[0] == 200 else {}
    games = games_resp.get("games") or []
    if games:
        total_h = sum(g.get("playtime_forever", 0) for g in games) / 60
        embed.add_field(name="Games owned", value=num(games_resp.get("game_count", len(games))), inline=True)
        embed.add_field(name="Total playtime", value=f"{total_h:,.0f} hours", inline=True)
        top = sorted(games, key=lambda g: g.get("playtime_forever", 0), reverse=True)[:5]
        embed.add_field(
            name="Most played",
            value="\n".join(f"{g.get('name', g.get('appid'))} - {g.get('playtime_forever', 0) / 60:,.1f}h" for g in top),
            inline=False,
        )
    elif not public:
        embed.add_field(name="Games", value="Hidden (private profile)", inline=True)

    b_list = (bans[1] or {}).get("players", []) if bans[0] == 200 else []
    if b_list:
        b = b_list[0]
        parts = []
        if b.get("NumberOfVACBans"):
            parts.append(f"{b['NumberOfVACBans']} VAC ban(s)")
        if b.get("NumberOfGameBans"):
            parts.append(f"{b['NumberOfGameBans']} game ban(s)")
        if b.get("CommunityBanned"):
            parts.append("Community banned")
        if b.get("EconomyBan") and b["EconomyBan"] != "none":
            parts.append(f"Trade ban: {b['EconomyBan']}")
        text = ", ".join(parts) if parts else "None"
        if parts and b.get("DaysSinceLastBan") is not None and (b.get("NumberOfVACBans") or b.get("NumberOfGameBans")):
            text += f" (last {b['DaysSinceLastBan']} days ago)"
        embed.add_field(name="Bans", value=text, inline=False)

    if p.get("avatarfull"):
        embed.set_thumbnail(url=p["avatarfull"])
    await interaction.followup.send(embed=embed)


@bot.tree.command(name="steamgame", description="Look up a Steam game: price, reviews, players")
@app_commands.describe(game="Game name, store URL or app ID", country="2-letter country code for the price (default us)")
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def steamgame(interaction: discord.Interaction, game: str, country: str = "us"):
    await interaction.response.defer()
    cc = country.strip().lower()
    if not re.fullmatch(r"[a-z]{2}", cc):
        cc = "us"

    q = game.strip()
    m = re.search(r"store\.steampowered\.com/app/(\d+)", q)
    if m:
        q = m.group(1)

    if q.isdigit():
        appid = int(q)
    else:
        status, data = await get_json("https://store.steampowered.com/api/storesearch/", params={"term": q, "l": "english", "cc": cc})
        items = data.get("items", []) if status == 200 and data else []
        if not items:
            await interaction.followup.send("No Steam game found with that name.")
            return
        appid = items[0]["id"]

    details, reviews, players = await asyncio.gather(
        get_json("https://store.steampowered.com/api/appdetails", params={"appids": appid, "cc": cc, "l": "english"}),
        get_json(f"https://store.steampowered.com/appreviews/{appid}", params={"json": 1, "language": "all", "purchase_type": "all", "num_per_page": 0}),
        get_json(f"{STEAM_API}/ISteamUserStats/GetNumberOfCurrentPlayers/v1/", params={"appid": appid}),
    )
    entry = (details[1] or {}).get(str(appid), {}) if details[0] == 200 else {}
    if not entry.get("success"):
        await interaction.followup.send("Couldn't load that game from the Steam store.")
        return
    d = entry["data"]

    embed = discord.Embed(
        title=d.get("name", "Unknown"),
        url=f"https://store.steampowered.com/app/{appid}",
        description=(d.get("short_description") or "")[:300] or None,
        color=discord.Color.dark_blue(),
    )

    price = d.get("price_overview")
    if d.get("is_free"):
        price_text = "Free"
    elif price:
        price_text = price.get("final_formatted", "Unknown")
        if price.get("discount_percent"):
            price_text += f" (was {price.get('initial_formatted')}, -{price['discount_percent']}%)"
    else:
        price_text = "Not available"
    embed.add_field(name="Price", value=price_text, inline=True)
    embed.add_field(name="Release date", value=(d.get("release_date") or {}).get("date", "Unknown"), inline=True)

    r_status, r_data = reviews
    summary = (r_data or {}).get("query_summary") if r_status == 200 else None
    if summary and summary.get("total_reviews"):
        pos, tot = summary.get("total_positive", 0), summary["total_reviews"]
        embed.add_field(name="Reviews", value=f"{summary.get('review_score_desc', '')} - {pos / tot * 100:.0f}% positive ({num(tot)})", inline=True)
    else:
        embed.add_field(name="Reviews", value="No reviews yet", inline=True)

    p_count = ((players[1] or {}).get("response") or {}).get("player_count") if players[0] == 200 else None
    if p_count is not None:
        embed.add_field(name="Playing right now", value=num(p_count), inline=True)
    if (d.get("metacritic") or {}).get("score"):
        embed.add_field(name="Metacritic", value=str(d["metacritic"]["score"]), inline=True)
    if d.get("developers"):
        embed.add_field(name="Developer", value=", ".join(d["developers"])[:200], inline=True)
    if d.get("publishers"):
        embed.add_field(name="Publisher", value=", ".join(d["publishers"])[:200], inline=True)
    if d.get("genres"):
        embed.add_field(name="Genres", value=", ".join(x["description"] for x in d["genres"])[:300], inline=False)
    plats = [n for n, on in (("Windows", (d.get("platforms") or {}).get("windows")), ("Mac", (d.get("platforms") or {}).get("mac")), ("Linux", (d.get("platforms") or {}).get("linux"))) if on]
    if plats:
        embed.add_field(name="Platforms", value=", ".join(plats), inline=True)
    embed.add_field(name="App ID", value=str(appid), inline=True)

    if d.get("header_image"):
        embed.set_image(url=d["header_image"])
    await interaction.followup.send(embed=embed)


CHEAPSHARK = "https://www.cheapshark.com/api/1.0"
STORE_NAMES: dict[str, str] = {}


@bot.tree.command(name="deals", description="Compare a game's price across stores")
@app_commands.describe(game="Game name")
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def deals(interaction: discord.Interaction, game: str):
    await interaction.response.defer()

    if not STORE_NAMES:
        status, stores = await get_json(f"{CHEAPSHARK}/stores")
        if status == 200 and isinstance(stores, list):
            STORE_NAMES.update({s["storeID"]: s["storeName"] for s in stores})

    status, found = await get_json(f"{CHEAPSHARK}/games", params={"title": game.strip(), "limit": 1})
    if status != 200 or not isinstance(found, list) or not found:
        await interaction.followup.send("No deals found for that game.")
        return

    status, d = await get_json(f"{CHEAPSHARK}/games", params={"id": found[0]["gameID"]})
    if status != 200 or not d or not d.get("deals"):
        await interaction.followup.send("Couldn't load prices for that game right now.")
        return

    info = d.get("info", {})
    embed = discord.Embed(title=info.get("title", found[0].get("external", "Unknown")), color=discord.Color.green())
    if info.get("steamAppID"):
        embed.url = f"https://store.steampowered.com/app/{info['steamAppID']}"

    ranked = sorted(d["deals"], key=lambda x: float(x.get("price", 0)))[:8]
    lines = []
    for x in ranked:
        store = STORE_NAMES.get(x.get("storeID"), f"Store {x.get('storeID')}")
        sav = float(x.get("savings", 0))
        sale = f" (was ${x.get('retailPrice')}, -{sav:.0f}%)" if sav >= 1 else ""
        lines.append(f"{store}: ${x.get('price')}{sale} - [Buy](https://www.cheapshark.com/redirect?dealID={x.get('dealID')})")
    embed.add_field(name="Cheapest right now", value="\n".join(lines)[:1000], inline=False)

    low = d.get("cheapestPriceEver") or {}
    if low.get("price"):
        when = discord.utils.format_dt(datetime.datetime.fromtimestamp(low["date"], UTC), "D") if low.get("date") else "Unknown date"
        embed.add_field(name="Historical low", value=f"${low['price']} ({when})", inline=False)
    if info.get("thumb"):
        embed.set_thumbnail(url=info["thumb"])
    embed.set_footer(text="Prices in USD. Data from CheapShark.")
    await interaction.followup.send(embed=embed)


# ---------- Fortnite ----------

def fortnite_line(s) -> Optional[str]:
    if not s:
        return None
    return (
        f"{num(s.get('wins'))} wins | {num(s.get('matches'))} matches | "
        f"K/D {(s.get('kd') or 0):.2f} | win rate {(s.get('winRate') or 0):.1f}%"
    )


@bot.tree.command(name="fortnite", description="Look up Fortnite battle royale stats")
@app_commands.describe(name="Player display name", platform="Account type (default Epic)")
@app_commands.choices(platform=[
    app_commands.Choice(name="Epic", value="epic"),
    app_commands.Choice(name="PlayStation", value="psn"),
    app_commands.Choice(name="Xbox", value="xbl"),
])
@app_commands.checks.cooldown(1, 10.0, key=lambda i: i.user.id)
async def fortnite(interaction: discord.Interaction, name: str, platform: Optional[app_commands.Choice[str]] = None):
    if not FORTNITE_KEY:
        await interaction.response.send_message(NEED_FORTNITE_KEY, ephemeral=True)
        return
    await interaction.response.defer()

    status, d = await get_json(
        "https://fortnite-api.com/v2/stats/br/v2",
        params={"name": name.strip(), "accountType": platform.value if platform else "epic"},
        headers={"Authorization": FORTNITE_KEY},
    )
    if status == 404:
        await interaction.followup.send("No Fortnite player found with that name.")
        return
    if status == 403:
        await interaction.followup.send("That player's stats are private.")
        return
    if status == 401:
        await interaction.followup.send("fortnite-api.com rejected the key. Check `fortnite_key.txt`.")
        return
    if status == 429:
        await interaction.followup.send("Rate limited by fortnite-api.com. Try again shortly.")
        return
    if status != 200 or not d or not d.get("data"):
        await interaction.followup.send("Couldn't load Fortnite stats right now.")
        return

    data = d["data"]
    stats_all = (data.get("stats") or {}).get("all") or {}
    overall = stats_all.get("overall")
    embed = discord.Embed(title=(data.get("account") or {}).get("name", name), color=discord.Color.purple())
    bp = data.get("battlePass") or {}
    if bp.get("level") is not None:
        embed.add_field(name="Battle pass level", value=str(bp["level"]), inline=True)
    if overall:
        embed.add_field(name="Kills", value=num(overall.get("kills")), inline=True)
        embed.add_field(name="Hours played", value=f"{(overall.get('minutesPlayed') or 0) / 60:,.0f}", inline=True)
        embed.add_field(name="Overall", value=fortnite_line(overall), inline=False)
    for key, label in (("solo", "Solo"), ("duo", "Duos"), ("squad", "Squads"), ("ltm", "Limited time modes")):
        line = fortnite_line(stats_all.get(key))
        if line:
            embed.add_field(name=label, value=line, inline=False)
    if not overall:
        embed.description = "No stats recorded for this account yet."
    embed.set_footer(text="Lifetime battle royale stats. Data from fortnite-api.com.")
    await interaction.followup.send(embed=embed)


# ---------- dev: repos, packages, domains ----------

@bot.tree.command(name="repo", description="Look up a GitHub repository")
@app_commands.describe(repo="owner/name or a GitHub URL")
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def repo(interaction: discord.Interaction, repo: str):
    await interaction.response.defer()
    q = repo.strip()
    m = re.search(r"github\.com/([^/\s]+)/([^/\s?#]+)", q) or re.fullmatch(r"([\w.-]+)/([\w.-]+)", q)
    if not m:
        await interaction.followup.send("Use the format `owner/name`, for example `python/cpython`.")
        return
    owner, name = m.group(1), re.sub(r"\.git$", "", m.group(2))

    (status, r), (rel_status, rel) = await asyncio.gather(
        get_json(f"https://api.github.com/repos/{owner}/{name}"),
        get_json(f"https://api.github.com/repos/{owner}/{name}/releases/latest"),
    )
    if status == 404:
        await interaction.followup.send("No GitHub repository found for that.")
        return
    if status in (403, 429):
        await interaction.followup.send("GitHub is rate limiting the bot right now. Try again later.")
        return
    if status != 200 or not r:
        await interaction.followup.send("Couldn't reach GitHub right now.")
        return

    embed = discord.Embed(
        title=r["full_name"],
        url=r["html_url"],
        description=(r.get("description") or "No description.")[:500],
        color=discord.Color.dark_grey(),
    )
    embed.add_field(name="Stars", value=num(r.get("stargazers_count")), inline=True)
    embed.add_field(name="Forks", value=num(r.get("forks_count")), inline=True)
    embed.add_field(name="Watchers", value=num(r.get("subscribers_count")), inline=True)
    embed.add_field(name="Open issues + PRs", value=num(r.get("open_issues_count")), inline=True)
    embed.add_field(name="Language", value=r.get("language") or "Unknown", inline=True)
    embed.add_field(name="License", value=((r.get("license") or {}).get("name")) or "None", inline=True)
    embed.add_field(name="Created", value=dstamp(r.get("created_at")), inline=True)
    embed.add_field(name="Last push", value=dstamp(r.get("pushed_at"), "R"), inline=True)
    embed.add_field(name="Default branch", value=r.get("default_branch", "Unknown"), inline=True)
    embed.add_field(name="Size", value=f"{(r.get('size') or 0) / 1024:,.1f} MB", inline=True)
    if rel_status == 200 and rel and rel.get("tag_name"):
        embed.add_field(name="Latest release", value=f"{rel['tag_name']} ({dstamp(rel.get('published_at'))})", inline=True)
    if r.get("topics"):
        embed.add_field(name="Topics", value=", ".join(r["topics"][:8]), inline=False)
    if r.get("homepage"):
        embed.add_field(name="Homepage", value=r["homepage"][:300], inline=False)
    if r.get("archived"):
        embed.add_field(name="Notice", value="This repository is archived.", inline=False)
    embed.set_thumbnail(url=r["owner"]["avatar_url"])
    await interaction.followup.send(embed=embed)


@bot.tree.command(name="package", description="Look up an npm or PyPI package")
@app_commands.describe(name="Package name", registry="npm (default) or PyPI")
@app_commands.choices(registry=[
    app_commands.Choice(name="npm", value="npm"),
    app_commands.Choice(name="PyPI", value="pypi"),
])
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def package(interaction: discord.Interaction, name: str, registry: Optional[app_commands.Choice[str]] = None):
    await interaction.response.defer()
    pkg = name.strip()
    reg = registry.value if registry else "npm"

    if reg == "npm":
        enc = quote(pkg, safe="@")
        (status, d), (d_status, dl) = await asyncio.gather(
            get_json(f"https://registry.npmjs.org/{enc}/latest"),
            get_json(f"https://api.npmjs.org/downloads/point/last-week/{enc}"),
        )
        if status == 404:
            await interaction.followup.send("No npm package found with that name.")
            return
        if status != 200 or not d:
            await interaction.followup.send("Couldn't reach npm right now.")
            return
        lic = d.get("license")
        author = d.get("author")
        embed = discord.Embed(
            title=f"{d.get('name', pkg)} {d.get('version', '')}".strip(),
            url=f"https://www.npmjs.com/package/{pkg}",
            description=(d.get("description") or "No description.")[:500],
            color=discord.Color.red(),
        )
        embed.add_field(name="Weekly downloads", value=num((dl or {}).get("downloads")) if d_status == 200 else "Unknown", inline=True)
        embed.add_field(name="License", value=(lic if isinstance(lic, str) else (lic or {}).get("type")) or "Unknown", inline=True)
        embed.add_field(name="Dependencies", value=str(len(d.get("dependencies") or {})), inline=True)
        if author:
            embed.add_field(name="Author", value=(author if isinstance(author, str) else author.get("name", "Unknown"))[:200], inline=True)
        if d.get("keywords"):
            embed.add_field(name="Keywords", value=", ".join(d["keywords"][:10])[:300], inline=False)
        if d.get("homepage"):
            embed.add_field(name="Homepage", value=d["homepage"][:300], inline=False)
        embed.add_field(name="Install", value=f"`npm install {pkg}`", inline=False)
    else:
        (status, d), (s_status, st) = await asyncio.gather(
            get_json(f"https://pypi.org/pypi/{quote(pkg)}/json"),
            get_json(f"https://pypistats.org/api/packages/{quote(pkg.lower())}/recent"),
        )
        if status == 404:
            await interaction.followup.send("No PyPI package found with that name.")
            return
        if status != 200 or not d:
            await interaction.followup.send("Couldn't reach PyPI right now.")
            return
        i = d["info"]
        embed = discord.Embed(
            title=f"{i.get('name', pkg)} {i.get('version', '')}".strip(),
            url=i.get("package_url") or f"https://pypi.org/project/{pkg}/",
            description=(i.get("summary") or "No description.")[:500],
            color=discord.Color.blue(),
        )
        recent = (st or {}).get("data") if s_status == 200 else None
        embed.add_field(name="Weekly downloads", value=num((recent or {}).get("last_week")), inline=True)
        embed.add_field(name="Monthly downloads", value=num((recent or {}).get("last_month")), inline=True)
        embed.add_field(name="License", value=(i.get("license") or "Unknown")[:100], inline=True)
        embed.add_field(name="Python", value=i.get("requires_python") or "Any", inline=True)
        embed.add_field(name="Releases", value=str(len(d.get("releases") or {})), inline=True)
        files = d.get("urls") or []
        if files:
            embed.add_field(name="Latest upload", value=dstamp(files[0].get("upload_time_iso_8601")), inline=True)
        if i.get("author"):
            embed.add_field(name="Author", value=i["author"][:200], inline=True)
        embed.add_field(name="Install", value=f"`pip install {pkg}`", inline=False)
    await interaction.followup.send(embed=embed)


DOMAIN_RE = re.compile(r"^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$")
DNS_TYPES = {"A": 1, "AAAA": 28, "MX": 15, "NS": 2, "TXT": 16}


async def dns_query(domain: str, rtype: str) -> tuple[Optional[int], list[str]]:
    status, data = await get_json("https://dns.google/resolve", params={"name": domain, "type": rtype})
    if status != 200 or not data:
        return None, []
    return data.get("Status"), [a.get("data", "") for a in data.get("Answer", []) if a.get("type") == DNS_TYPES[rtype]]


def parse_rdap(d: dict) -> tuple[dict, Optional[str], list]:
    events = {e.get("eventAction"): e.get("eventDate") for e in d.get("events", [])}
    registrar = None
    for ent in d.get("entities", []):
        if "registrar" in ent.get("roles", []):
            for item in (ent.get("vcardArray") or [None, []])[1]:
                if item and item[0] == "fn":
                    registrar = item[3]
    return events, registrar, d.get("status", [])


@bot.tree.command(name="domain", description="Show DNS records and registration info for a domain")
@app_commands.describe(name="Domain, e.g. example.com")
@app_commands.checks.cooldown(1, 10.0, key=lambda i: i.user.id)
async def domain(interaction: discord.Interaction, name: str):
    d = re.sub(r"^[a-z]+://", "", name.strip().lower())
    d = re.split(r"[/?#]", d)[0]
    d = re.sub(r"^www\.", "", d)
    if not DOMAIN_RE.match(d):
        await interaction.response.send_message("That doesn't look like a valid domain. Try something like `example.com`.", ephemeral=True)
        return
    await interaction.response.defer()

    (a_code, a), (_, aaaa), (_, mx), (_, ns), (_, txt), (r_status, rdap) = await asyncio.gather(
        *(dns_query(d, t) for t in DNS_TYPES),
        get_json(f"https://rdap.org/domain/{d}", headers={"Accept": "application/rdap+json"}),
    )

    embed = discord.Embed(title=d, color=discord.Color.teal())
    if r_status == 200 and isinstance(rdap, dict):
        events, registrar, statuses = parse_rdap(rdap)
        if registrar:
            embed.add_field(name="Registrar", value=registrar[:200], inline=False)
        reg, exp, chg = events.get("registration"), events.get("expiration"), events.get("last changed")
        if reg:
            embed.add_field(name="Registered", value=dstamp(reg), inline=True)
        if exp:
            embed.add_field(name="Expires", value=dstamp(exp) + f" ({dstamp(exp, 'R')})", inline=True)
        if chg:
            embed.add_field(name="Last changed", value=dstamp(chg), inline=True)
        if statuses:
            embed.add_field(name="Status", value=", ".join(statuses[:4])[:300], inline=False)
    else:
        embed.add_field(name="Registration", value="Registration data unavailable for this domain.", inline=False)

    if a_code == 3:
        embed.add_field(name="DNS", value="Doesn't resolve (NXDOMAIN).", inline=False)
    for label, recs, cap in (("A", a, 5), ("AAAA", aaaa, 3), ("MX", mx, 5), ("NS", ns, 6), ("TXT", txt, 3)):
        if recs:
            shown = "\n".join(r[:180] for r in recs[:cap])
            if len(recs) > cap:
                shown += f"\n(+{len(recs) - cap} more)"
            embed.add_field(name=label, value=shown[:1000], inline=False)
    await interaction.followup.send(embed=embed)


# ---------- Discord: invites, snowflakes, status, permissions ----------

@bot.tree.command(name="invite", description="Look up a Discord invite without joining")
@app_commands.describe(code="Invite code or link")
@app_commands.checks.cooldown(1, 5.0, key=lambda i: i.user.id)
async def invite(interaction: discord.Interaction, code: str):
    await interaction.response.defer()
    try:
        inv = await bot.fetch_invite(code.strip(), with_counts=True, with_expiration=True)
    except discord.NotFound:
        await interaction.followup.send("That invite is invalid or has expired.")
        return
    except discord.HTTPException:
        await interaction.followup.send("Couldn't look that invite up right now.")
        return

    g = inv.guild
    embed = discord.Embed(title=getattr(g, "name", "Unknown server"), color=discord.Color.blurple())
    if getattr(g, "description", None):
        embed.description = g.description[:500]
    if g is not None:
        embed.add_field(name="Server ID", value=str(g.id), inline=True)
    embed.add_field(name="Members", value=num(inv.approximate_member_count), inline=True)
    embed.add_field(name="Online", value=num(inv.approximate_presence_count), inline=True)
    if g is not None:
        embed.add_field(name="Boosts", value=num(getattr(g, "premium_subscription_count", None)), inline=True)
        vl = getattr(g, "verification_level", None)
        if vl is not None:
            embed.add_field(name="Verification", value=str(vl.name).replace("_", " ").title(), inline=True)
        if getattr(g, "vanity_url_code", None):
            embed.add_field(name="Vanity URL", value=f"discord.gg/{g.vanity_url_code}", inline=True)
    ch = inv.channel
    if ch is not None and getattr(ch, "name", None):
        embed.add_field(name="Invite channel", value=f"#{ch.name}", inline=True)
    if inv.inviter:
        embed.add_field(name="Invited by", value=str(inv.inviter), inline=True)
    embed.add_field(name="Expires", value=discord.utils.format_dt(inv.expires_at, "R") if inv.expires_at else "Never", inline=True)
    feats = getattr(g, "features", None)
    if feats:
        embed.add_field(name="Features", value=", ".join(f.replace("_", " ").title() for f in feats[:15])[:1000], inline=False)
    if g is not None and getattr(g, "icon", None):
        embed.set_thumbnail(url=g.icon.url)
    if g is not None and getattr(g, "banner", None):
        embed.set_image(url=g.banner.url)
    await interaction.followup.send(embed=embed)


@bot.tree.command(name="snowflake", description="Decode a Discord ID into its creation date")
@app_commands.describe(id="Any Discord ID (user, server, channel, message...)")
@app_commands.checks.cooldown(1, 3.0, key=lambda i: i.user.id)
async def snowflake(interaction: discord.Interaction, id: str):
    raw = id.strip()
    if not raw.isdigit() or not (0 < int(raw) < 2 ** 63):
        await interaction.response.send_message("That isn't a valid Discord ID.", ephemeral=True)
        return
    sid = int(raw)
    ms = (sid >> 22) + 1420070400000
    created = datetime.datetime.fromtimestamp(ms / 1000, UTC)
    await interaction.response.defer()

    embed = discord.Embed(title=f"Snowflake {sid}", color=discord.Color.blurple())
    embed.add_field(name="Created", value=f"{discord.utils.format_dt(created, 'F')} ({discord.utils.format_dt(created, 'R')})", inline=False)
    embed.add_field(name="Unix timestamp", value=str(ms // 1000), inline=True)
    embed.add_field(name="Worker ID", value=str((sid & 0x3E0000) >> 17), inline=True)
    embed.add_field(name="Process ID", value=str((sid & 0x1F000) >> 12), inline=True)
    embed.add_field(name="Increment", value=str(sid & 0xFFF), inline=True)

    try:
        u = await bot.fetch_user(sid)
        embed.add_field(name="This ID is a", value=f"{'Bot' if u.bot else 'User'} account: {u}", inline=False)
    except discord.HTTPException:
        pass
    await interaction.followup.send(embed=embed)


@bot.tree.command(name="discordstatus", description="Check whether Discord is having problems")
@app_commands.checks.cooldown(1, 10.0, key=lambda i: i.user.id)
async def discordstatus(interaction: discord.Interaction):
    await interaction.response.defer()
    status, d = await get_json("https://discordstatus.com/api/v2/summary.json")
    if status != 200 or not d:
        await interaction.followup.send("Couldn't reach Discord's status page.")
        return

    colors = {"none": discord.Color.green(), "minor": discord.Color.gold(), "major": discord.Color.orange(), "critical": discord.Color.red()}
    ind = (d.get("status") or {}).get("indicator", "none")
    embed = discord.Embed(title="Discord status", description=(d.get("status") or {}).get("description", "Unknown"), color=colors.get(ind, discord.Color.greyple()))

    comps = [c for c in d.get("components", []) if not c.get("group")]
    if comps:
        embed.add_field(
            name="Components",
            value="\n".join(f"{c['name']}: {c.get('status', 'unknown').replace('_', ' ').title()}" for c in comps)[:1000],
            inline=False,
        )
    incidents = d.get("incidents", [])
    if incidents:
        embed.add_field(
            name="Active incidents",
            value="\n".join(f"{i.get('name', 'Incident')} ({i.get('status', '').replace('_', ' ')})" for i in incidents[:5])[:1000],
            inline=False,
        )
    maint = d.get("scheduled_maintenances", [])
    if maint:
        embed.add_field(name="Scheduled maintenance", value="\n".join(m.get("name", "Maintenance") for m in maint[:3])[:1000], inline=False)
    embed.set_footer(text="Data from discordstatus.com")
    await interaction.followup.send(embed=embed)


@bot.tree.command(name="permissions", description="Decode a Discord permissions number")
@app_commands.describe(number="The permissions integer, e.g. 8 or 1099511627775")
@app_commands.checks.cooldown(1, 3.0, key=lambda i: i.user.id)
async def permissions(interaction: discord.Interaction, number: str):
    raw = number.strip()
    if not raw.isdigit() or int(raw) >= 2 ** 64:
        await interaction.response.send_message("Give me the permissions as a whole number, like `8`.", ephemeral=True)
        return
    value = int(raw)
    perms = discord.Permissions(value)
    names = [n.replace("_", " ").title() for n, on in perms if on]

    embed = discord.Embed(title=f"Permissions {value}", color=discord.Color.blurple())
    embed.description = ", ".join(names)[:3900] if names else "No permissions."
    embed.add_field(name="Total", value=str(len(names)), inline=True)
    if perms.administrator:
        embed.add_field(name="Note", value="Administrator grants every permission and bypasses channel overrides.", inline=False)
    unknown = value & ~discord.Permissions.all().value
    if unknown:
        embed.add_field(name="Unknown bits", value=f"This number includes bits this library doesn't recognize ({unknown}).", inline=False)
    await interaction.response.send_message(embed=embed)


# ---------- errors ----------

@bot.tree.error
async def on_app_error(interaction: discord.Interaction, error: app_commands.AppCommandError):
    if isinstance(error, app_commands.CommandOnCooldown):
        msg = f"Slow down, try again in {error.retry_after:.0f}s."
    else:
        print(f"command error: {error!r}")
        msg = "Something went wrong."
    if interaction.response.is_done():
        await interaction.followup.send(msg, ephemeral=True)
    else:
        await interaction.response.send_message(msg, ephemeral=True)


bot.run(TOKEN)