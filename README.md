# Albanian-Hub
This is a grow a garden script if it works feel free to use it

## Albanian Hub — Main.lua

Added `Main.lua` — a cleaned and enhanced Grow-a-Garden script.

- Features: WindUI loading with fallback, auto-remote detection (harvest/plant/water/sell), character handlers (WalkSpeed/Noclip), Anti-AFK, Teleport helper.
- Where to customize: open `Main.lua` and replace the WindUI URL, update `Settings.ShopPosition`, and insert game-specific remote arguments if required.

To use: copy the raw file content from GitHub (or use the file directly in your executor) and ensure WindUI is available at one of the loader URLs or as a ModuleScript named `WindUI` in `ReplicatedStorage`.

### Configuring remotes

You can explicitly configure remote names by setting the global `AlbanianHubRemotes` before loading `Main.lua` in your executor. Example:

```lua
getgenv().AlbanianHubRemotes = {
	Harvest = "HarvestRemoteName",
	Plant = "PlantRemoteName",
	Water = "WaterRemoteName",
	Sell = "SellRemoteName"
}
-- then load Main.lua
```

If you do not configure remotes, the script will attempt to detect common remote names automatically.

