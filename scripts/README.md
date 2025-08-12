# Scripts Organization

## Structure:
- `player/` - Player controller and related scripts
- `enemies/` - Enemy AI and behavior scripts
- `ui/` - UI controllers and menu scripts
- `managers/` - Game state, audio, input managers
- `systems/` - Reusable game systems (health, inventory)
- `autoload/` - Singleton scripts for global access

## Best Practices:
- Use PascalCase for class names
- Use snake_case for file names
- Keep scripts focused on single responsibility
- Use signals for loose coupling between systems

## Common Patterns:
- State machines for character behavior
- Observer pattern with signals
- Singletons for managers (GameManager, AudioManager)
- Component-based architecture for reusable functionality