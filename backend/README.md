# Psycho Chat Backend

Simple WebSocket echo/chat backend on `ws://localhost:3000`.

## Run

```powershell
npm install
npm run dev
```

## Protocol

Client sends plain text. Server broadcasts JSON:

```json
{
  "id": "...",
  "sender": "user|system",
  "text": "message",
  "timestamp": "2026-05-18T00:00:00.000Z"
}
```
