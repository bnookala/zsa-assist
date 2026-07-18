# zsa-assist

Hold-to-show layer HUD for the ZSA Moonlander: press a momentary-layer key
on the keyboard and a click-through overlay previews the active layer on top
of whatever app is focused; release and it disappears.

## How it works

The keyboard itself is the trigger. A momentary layer switch (`MO(n)` in
Oryx) activates a layer while held. [Keymapp](https://www.zsa.io/flash)
tracks the active layer and exposes it over a local gRPC API (enable it in
Keymapp's settings — see [Kontroll](https://github.com/zsa/kontroll) and its
`keymapp.proto`). This app polls that API and shows/hides the overlay on
layer transitions.

## Current state

Stub poller only — no gRPC, no UI yet.

- `ZSAAssistCore`
  - `KeymappClient` — protocol the real gRPC client will implement.
  - `StubKeymappClient` — simulates layer holds on a repeating schedule.
  - `LayerPoller` — polls a client every 50 ms and emits `connected` /
    `layerChanged` / `connectionLost` events as an `AsyncStream`.
- `zsa-poller-demo` — prints the event stream:

```
swift run zsa-poller-demo 6   # run for ~6 seconds (omit for Ctrl-C)
swift test
```

## Next steps

1. Real `KeymappClient` backed by grpc-swift + `keymapp.proto` from Kontroll.
2. Menu-bar app with a non-activating, click-through `NSPanel` overlay
   driven by `LayerPoller.events()`.
3. Layout data from Oryx (GraphQL) rendered as per-layer keyboard SVGs.
