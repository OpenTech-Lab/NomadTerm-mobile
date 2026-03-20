# NomadTerm Mobile

## What Is This?

`mobile/` is the Flutter companion app for NomadTerm. It connects to the NomadTerm server running on another machine and gives you a phone-friendly interface for remote AI terminal sessions.

The app is responsible for:

- connecting to the NomadTerm WebSocket daemon
- storing the connection settings securely
- scanning the daemon QR code for quick pairing
- showing the active session list
- opening a live terminal for a selected session
- surfacing tool-call approval prompts and sending your decision back to the server

## How To Use It

### 1. Install Flutter dependencies

```bash
flutter pub get
```

### 2. Start the server first

This app expects a running NomadTerm daemon. In the `server/` directory, start it with:

```bash
cargo run --release -- --ws --bind-tailscale
```

That command prints the host, port, token, and QR code needed by the app.

### 3. Run the mobile app

```bash
flutter run
```

Use an Android or iOS device/emulator supported by your Flutter setup.

### 4. Connect to your daemon

On the connect screen, either:

- tap `scan-qr` and scan the QR code printed by the server, or
- enter the `host`, `port`, and `token` manually

The app saves this connection config for later launches.

### 5. Work with sessions

Once connected, the app lets you:

- see current sessions
- create a new session for a supported CLI
- open the terminal view and interact with the PTY
- approve or deny tool requests
- kill sessions from the session list

## Notes

- Default server port is `7681`
- The connect screen is optimized for the Tailscale flow, so the default host hint is `100.x.x.x`
- The supported session types in the UI are `claude`, `codex`, `copilot`, and `gemini`
