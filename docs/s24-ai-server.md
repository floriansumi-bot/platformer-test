# Galaxy S24 → Local AI Server (Ollama)

Turn a broken-screen Samsung Galaxy S24 into an always-on, private AI server
on your home network. Once set up, any device in your house (laptop, phone,
tablet) can chat with a local LLM — no subscription, no cloud, fully offline.

> **Reality check:** This guide cannot be run remotely. Every step below
> happens *on the phone* or on a computer physically connected to it. The goal
> here is to make the hands-on part as close to "paste one command" as
> possible. The included script (`scripts/setup-ollama-termux.sh`) does all the
> software setup; you just need to get a terminal open on the phone.

---

## Part 1 — Getting into a phone with a broken screen

You can't tap a dead screen, so you need another way to see and control it.
Pick the option that matches your situation.

### Option A — Samsung DeX (RECOMMENDED, works even with a fully dead screen)

The S24 can output a full desktop to an external monitor, independent of its
own broken display.

**You'll need:**
- A USB-C → HDMI cable/adapter (DeX works over this), into any monitor or TV.
- A USB-C hub with HDMI **and** USB-A ports, *or* a Bluetooth keyboard + mouse.
- A keyboard and mouse.

**Steps:**
1. Plug the phone into the monitor via USB-C → HDMI. DeX should auto-launch and
   show a desktop on the monitor.
2. Connect keyboard + mouse (through the hub, or pair over Bluetooth).
3. Unlock the phone — the lock screen appears on the monitor; type/enter your
   PIN with the keyboard.
4. You now have a full, mouse-driven desktop. Proceed to **Part 2**.

> This is the cleanest path. If DeX works, you never need USB debugging at all.

### Option B — scrcpy over USB (if USB debugging is ALREADY enabled)

If you previously turned on Developer Options → USB debugging while the screen
still worked, you can mirror and control the phone from a PC.

1. On a PC, install `scrcpy` and `adb` (Android platform-tools).
2. Plug the phone in via USB. Run `adb devices` — accept the prompt if one
   appears (you may need DeX/monitor to accept it the first time).
3. Run `scrcpy`. The phone's screen mirrors to your PC; control it with your
   mouse and keyboard.

> If USB debugging was **never** enabled, this won't work — and you can't
> enable it on a dead screen without an external display. Use Option A instead.

### Option C — Pair a Bluetooth mouse + cast

Sometimes a "broken" screen still *displays* but doesn't accept touch. A
Bluetooth mouse gives you a pointer, and you can cast/mirror to a TV to see
better. If the screen is fully black, use Option A.

---

## Part 2 — Install Termux (the Linux environment)

1. On the phone, install **Termux** from **F-Droid** or the official GitHub
   releases (https://github.com/termux/termux-app/releases).
   **Do NOT** use the Play Store version — it's outdated and broken.
2. Open Termux. You now have a Linux shell.
3. (Optional but recommended) Set up SSH so you can finish everything from your
   laptop and never touch the phone again:
   ```sh
   pkg update -y && pkg install -y openssh
   passwd                 # set a password
   whoami                 # note the username (e.g. u0_a123)
   sshd                   # start the SSH server
   ifconfig 2>/dev/null | grep "inet "   # find the phone's IP, e.g. 192.168.1.42
   ```
   Then from your laptop: `ssh -p 8022 <username>@<phone-ip>`
   (Termux SSH uses port **8022**.)

---

## Part 3 — Run the setup script (the "do everything" part)

From the Termux shell (or over SSH), run:

```sh
curl -fsSL https://raw.githubusercontent.com/floriansumi-bot/platformer-test/claude/old-smartphone-diy-projects-f6z5nd/scripts/setup-ollama-termux.sh -o setup.sh
bash setup.sh
```

The script will:
- Update Termux packages.
- Install Ollama.
- Acquire a wake-lock so the phone keeps serving when idle.
- Configure Ollama to listen on the network (not just localhost).
- Start the Ollama server.
- Pull a small, S24-appropriate model (`llama3.2:3b` by default).
- Optionally install `termux-services` + Termux:Boot so it auto-starts on
  reboot.

When it finishes, it prints the address other devices should use, e.g.
`http://192.168.1.42:11434`.

---

## Part 4 — Use it from your other devices

Ollama exposes an API on port **11434**. Point any Ollama-compatible client at
`http://<phone-ip>:11434`:

- **Laptop CLI:** install Ollama, then
  `OLLAMA_HOST=http://<phone-ip>:11434 ollama run llama3.2:3b`
- **Phone/tablet apps:** any app with a "custom Ollama URL" field
  (e.g. Enchanted, Ollama clients, Open WebUI).
- **Web UI:** run **Open WebUI** on your laptop (Docker) pointed at the phone's
  Ollama URL for a ChatGPT-style interface.

### Good models for an S24 (8–12GB RAM)
| Model | Pull command | Notes |
|---|---|---|
| Llama 3.2 3B | `ollama pull llama3.2:3b` | Solid all-rounder, default |
| Gemma 2 2B | `ollama pull gemma2:2b` | Fast, light |
| Qwen 2.5 3B | `ollama pull qwen2.5:3b` | Strong for size |
| Phi-3 Mini | `ollama pull phi3:mini` | Good reasoning |

Avoid 7B+ models — they'll be slow and may run out of RAM. Stick to 2–3B.

---

## Keeping it healthy (important for an always-on phone)

- **Heat & battery:** charging 24/7 degrades and can swell the battery. Keep
  the phone cool and ventilated. If you root later, look into battery-bypass
  charging. Otherwise, monitor it and don't enclose it.
- **Stay awake:** the wake-lock (set by the script) and "stay awake while
  charging" (Developer Options) keep it serving.
- **Network safety:** an old phone stops getting security updates. Keep it on a
  guest/IoT VLAN, and do **not** expose port 11434 to the public internet
  without authentication in front of it.

---

## Troubleshooting

- **Other devices can't connect:** confirm `OLLAMA_HOST=0.0.0.0:11434` is set
  (the script does this), the phone and client are on the same WiFi, and the
  phone isn't on a "guest" network that blocks device-to-device traffic.
- **Server stops when screen locks:** ensure the wake-lock is held
  (`termux-wake-lock`) and Termux is exempt from battery optimization
  (Android Settings → Apps → Termux → Battery → Unrestricted).
- **Out of memory / very slow:** use a smaller model (2B), and close other
  apps. The S24 is capable but it's not a GPU server.
