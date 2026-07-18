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

Working poller against real hardware — no UI yet.

- `ZSAAssistCore`
  - `KeymappClient` — protocol both clients implement.
  - `StubKeymappClient` — simulates layer holds on a repeating schedule.
  - `LayerPoller` — polls a client every 50 ms and emits `connected` /
    `layerChanged` / `connectionLost` events as an `AsyncStream`.
- `KeymappGRPC`
  - `GRPCKeymappClient` — real client over Keymapp's Unix domain socket
    (`$KEYMAPP_SOCKET`, `~/Library/Application Support/.keymapp/keymapp.sock`,
    or the App Store container path). Stubs are generated at build time from
    the vendored `keymapp.proto` (requires `protoc`: `brew install protobuf`).
- `zsa-poller-demo` — prints the event stream:

```
swift run zsa-poller-demo 6          # real Keymapp, ~6 seconds (omit for Ctrl-C)
swift run zsa-poller-demo 6 --stub   # simulated layer holds
swift test
```

## Next steps

1. Menu-bar app with a non-activating, click-through `NSPanel` overlay
   driven by `LayerPoller.events()`.
2. Layout data from Oryx (GraphQL) rendered as per-layer keyboard SVGs.
