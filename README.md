# Personal Cargo Landing Pad

A Factorio 2.0 Space Age multiplayer mod that routes cargo from a claimed space
platform to its owner's personal cargo landing pad.

## Behavior

- each player may own one cargo landing pad per surface
- each space platform may have one player owner
- cargo descending from a claimed platform is redirected to that player's pad
  on the destination surface
- vanilla routing remains unchanged when the platform or destination pad is
  unclaimed
- admins may transfer ownership by claiming an object owned by another player

The mod depends on `All the Landing Pads` (`a_lot_of_cargo_pads`) 1.0.0 to
allow multiple landing pads on one Factorio 2.0 surface. Version 1.0.1 of that
dependency requires Factorio 2.1 and is intentionally not selected here.

## Use

1. Open a cargo landing pad and press **Claim this landing pad**.
2. Open the hub while standing on a space platform and press
   **Claim this platform**.
3. Configure normal Space Age orbital requests or drop cargo from the platform.

Existing pads and platforms can be claimed after adding the mod to a save.
Commands are also available as a fallback:

- `/claim-cargo-pad`
- `/claim-platform`

When installing dependencies manually on Factorio 2.0, select
`a_lot_of_cargo_pads` version `1.0.0`.

## Build

```powershell
just build
```

The Mod Portal zip is written to `target/`.

## Checks

```powershell
just precommit
```
