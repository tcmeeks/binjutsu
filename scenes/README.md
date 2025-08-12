# Scenes Organization

## Structure:
- `levels/` - Game level scenes
- `ui/` - User interface scenes (menus, HUD)
- `player/` - Player character scene
- `enemies/` - Enemy prefab scenes
- `pickups/` - Collectible item scenes

## Scene Naming:
- Use PascalCase: `Player.tscn`, `MainMenu.tscn`
- Be descriptive: `Level01Forest.tscn`, `HealthPickup.tscn`

## Best Practices:
- Keep scenes focused and modular
- Use instancing for reusable objects
- Separate UI from game logic scenes
- Create prefabs for common objects (enemies, pickups)