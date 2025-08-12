---
inclusion: always
---

# Binjutsu Project Patterns & Lessons

This document captures project-specific patterns, architectural decisions, and lessons learned from the Binjutsu Godot project.

## Project Architecture

### Core Systems
- **Treadmill System**: Endless sidescrolling using tile slices with dynamic spawning/despawning
- **Unit Controllers**: Player-controlled characters with animation state management
- **Input Management**: Centralized input handling through InputManager autoload
- **MCP Integration**: Uses GDAI MCP plugin for AI-assisted development

### Key Autoloads
- `GDAIMCPRuntime`: AI development assistance runtime
- `InputManager`: Global input handling and fullscreen toggle

## Animation Patterns

### Directional Animation System
Both VillagerController and UnitController use a consistent pattern:
- 8-directional animations: walk_up, walk_down, walk_left, walk_right, idle_up, idle_down, idle_left, idle_right
- Animation selection based on movement vector comparison: `abs(direction.x) > abs(direction.y)`
- Pixel-perfect positioning: `global_position = Vector2(round(global_position.x), round(global_position.y))`

### Treadmill-Specific Animation Logic
- Units on treadmill always show walking animation when idle (simulating running in place)
- Use `is_on_treadmill` flag to control idle behavior
- Default to "walk_right" for treadmill idle state
- **Lesson**: For treadmill units, simplified animation logic (always walk_right) can be more effective than complex directional systems
- Consider gameplay context when deciding animation complexity - sometimes less is more

## State Management Patterns

### Character State Machines
VillagerController demonstrates clean state machine pattern:
```gdscript
enum State { IDLE, WALKING, WAITING }
var current_state: State = State.IDLE

func _physics_process(delta):
    match current_state:
        State.WALKING: _handle_walking(delta)
        State.IDLE: _handle_idle()
        State.WAITING: _handle_waiting()
```

### Movement Direction Tracking
- Always track `last_movement_direction` for proper idle animations
- Use normalized input vectors for consistent diagonal movement
- Separate movement logic from animation logic

## Treadmill System Architecture

### Slice-Based Scrolling
- Fixed-width slices (128px = 8 tiles × 16px)
- Dynamic spawning based on camera position
- Buffer zones to prevent pop-in
- Slice recycling to manage memory

### Performance Optimizations
- Remove off-screen slices automatically
- Avoid repeating consecutive slice types
- Camera-relative positioning calculations
- Configurable scroll speed

## Input Handling Patterns

### Global Input Management
- Centralized in InputManager autoload
- Dynamic InputMap action creation
- Event consumption with `get_viewport().set_input_as_handled()`
- Fullscreen toggle as example of global input handling

### Character Input
- Use built-in input actions (ui_right, ui_left, ui_up, ui_down)
- Normalize diagonal movement vectors
- Separate input gathering from movement application

## Code Quality Patterns

### Defensive Programming
- Null checks for node references: `if not camera:`
- Graceful fallbacks: `camera = get_node("../Camera2D")`
- Array bounds checking before access
- Resource loading validation

### Debug-Friendly Code
- Strategic print statements for system initialization
- State change logging in complex systems
- Clear error messages with context

### Export Variables
- Use `@export` for designer-configurable values
- Provide sensible defaults
- Group related exports together
- Use type hints: `@export var speed: float = 50.0`

## Scene Organization Lessons

### Component-Based Design
- UnitController as reusable character controller
- TreadmillManager as self-contained system
- Separate concerns (input, animation, movement)

### Node Structure Patterns
- Use @onready for child node references
- Cache frequently accessed nodes
- Prefer composition over deep inheritance

## Performance Considerations

### Pixel-Perfect Movement
- Always round positions for crisp pixel art
- Apply after physics calculations
- Consistent across all character controllers

### Memory Management
- Use queue_free() for dynamic objects
- Remove off-screen elements promptly
- Avoid creating unnecessary temporary objects

## Project-Specific Best Practices

### Animation Consistency
- Always implement all 8 directional animations
- Use consistent naming: walk_direction, idle_direction
- Handle edge cases (no movement direction)

### Treadmill Integration
- Check `is_on_treadmill` flag for special behavior
- Default to appropriate idle animations
- Consider treadmill speed in movement calculations

### Treadmill Movement Physics
- Implement speed adjustments to simulate treadmill effect:
  - Moving right (with treadmill): `move_speed * 0.8` (slower, fighting against forward momentum)
  - Moving left (against treadmill): `move_speed * 2.0` (faster, aided by backward momentum)
  - Vertical movement: normal speed (unaffected by treadmill)
- This creates realistic physics where moving against the treadmill direction feels more responsive
- **CRITICAL**: Apply speed adjustments only to horizontal movement component, not the entire velocity vector
- **Current Implementation Pattern**:
  ```gdscript
  velocity = Vector2.ZERO
  if input_vector.x > 0:  # Moving right (forward) - slower but noticeable
      velocity.x = move_speed * 0.8
  elif input_vector.x < 0:  # Moving left (backward) - double speed
      velocity.x = -move_speed * 2.0
  velocity.y = input_vector.y * move_speed
  ```
- **Lesson**: Moderate speed differences (0.8x vs 2.0x) provide good gameplay feel without being jarring
- **Lesson**: Component-wise velocity adjustment preserves vertical movement while only affecting horizontal treadmill physics
- **Lesson**: Direct velocity assignment can be cleaner than multiplying input vectors when dealing with asymmetric movement speeds

### MCP Development Workflow
- Use GDAI MCP plugin for AI-assisted development
- Maintain clean code structure for better AI understanding
- Document complex systems for AI context

### Input System Evolution
- **Current Pattern**: Direct key checking with `Input.is_key_pressed(KEY_*)`
- **Lesson**: For treadmill-specific controls, direct key input can be more responsive than InputMap actions
- **Implementation**:
  ```gdscript
  var input_vector = Vector2.ZERO
  if Input.is_key_pressed(KEY_RIGHT):
      input_vector.x += 1
  if Input.is_key_pressed(KEY_LEFT):
      input_vector.x -= 1
  # etc...
  ```
- **Trade-off**: Less flexible than InputMap but more direct control for specialized movement systems

### Animation Simplification Lessons
- **Current Approach**: Single animation state (`walk_right`) for treadmill units
- **Lesson**: Context-specific animation logic can be more effective than generic directional systems
- **Rationale**: On a treadmill, the character is always "running in place" regardless of input direction
- **Implementation**: `sprite.play("walk_right")` in `_update_animation()` regardless of movement
- **Benefit**: Simpler code, consistent visual feedback, matches gameplay context

### Slice Management Patterns
- **Buffer Strategy**: Maintain slices beyond screen boundaries (2x slice_width buffer)
- **Performance**: Remove off-screen slices immediately to prevent memory buildup
- **Spawning Logic**: Use rightmost position tracking for continuous slice generation
- **Anti-repetition**: Simple heuristic to avoid consecutive identical slices
- **Lesson**: Camera-relative calculations are essential for proper slice positioning

## Data-Driven Enemy System

### Architecture Overview
The project uses a data-driven enemy system that separates configuration from implementation, allowing for scalable enemy creation without scene file explosion.

### Core Components
- **EnemyData.gd**: Resource-based configuration system defining enemy properties
- **MovementComponent.gd**: Base class for reusable movement behaviors
- **GenericEnemy.gd**: Single configurable enemy class that works for all enemy types
- **EnemyFactory.gd**: Factory pattern for creating enemies from data definitions

### Enemy Creation Pattern
```gdscript
// Adding a new enemy type - just add to EnemyData.get_enemy_definitions():
"new_enemy": {
    "enemy_name": "NewEnemy",
    "move_speed": 35.0,
    "health": 2,
    "sprite_frames": load("res://path/to/sprites.tres"),
    "movement_type": MovementType.STRAIGHT
}
```

### Movement Component Pattern
- **Straight Movement**: Use `StraightMovementComponent` for basic left-moving enemies
- **Sine Wave Movement**: Use `SineWaveMovementComponent` for enemies with vertical oscillation
- **Custom Movement**: Create new component extending `MovementComponent` for unique behaviors

### Best Practices for Enemy System
- **Avoid Scene Files**: Don't create individual .tscn files for simple enemy variants
- **Use Components**: Create reusable movement components for shared behaviors
- **Data-Driven Config**: Define enemy properties in `EnemyData.get_enemy_definitions()`
- **Factory Pattern**: Always use `EnemyFactory.create_enemy()` for spawning
- **Shared Resources**: Reuse SpriteFrames resources when enemies share sprite sheets

### When to Break the Pattern
- **Complex Collision**: If enemy needs unique collision shapes, consider a custom scene
- **Special Child Nodes**: If enemy requires unique child node structure
- **Highly Custom Logic**: If movement/behavior is too complex for components

## Recent Session Insights

### Treadmill Physics Refinement
- **Speed Balance**: Found that 0.8x forward and 2.0x backward speeds provide optimal gameplay feel
- **Implementation Clarity**: Direct velocity assignment is clearer than complex input vector multiplication
- **Testing Approach**: Iterative speed adjustment based on gameplay feel rather than theoretical physics

### Animation State Management
- **Simplification Success**: Single `walk_right` animation for treadmill context works better than complex directional logic
- **Context-Driven Design**: Animation complexity should match gameplay context, not follow generic patterns
- **Performance Benefit**: Simplified animation logic reduces computational overhead

### Enemy System Evolution
- **Data-Driven Success**: Refactored from individual scene files to single configurable system
- **Component Benefits**: Movement components provide reusable, testable behavior modules
- **Scalability Achievement**: Can now support 20+ enemy types without scene file explosion
- **Maintenance Improvement**: Single enemy template reduces update overhead

### MCP Integration Patterns
- **Development Flow**: MCP tools enable rapid iteration on game mechanics
- **Code Structure**: Clean, well-documented code improves AI assistance effectiveness
- **Testing Integration**: MCP tools can help with rapid prototyping and testing

### Project Architecture Maturity
- **Component Stability**: UnitController and TreadmillManager are well-established, stable components
- **Scene Organization**: Test scenes (TreadmillTest.tscn) provide good isolation for feature development
- **Autoload Usage**: InputManager and GDAIMCPRuntime provide solid foundation for global systems
- **Data-Driven Systems**: Enemy system demonstrates successful pattern for scalable game content

## Common Pitfalls to Avoid

### Animation Issues
- Don't forget to handle zero movement direction
- Always normalize diagonal input vectors
- Remember to update last_movement_direction

### Treadmill System
- Don't spawn slices without camera reference
- Always check array bounds before access
- Buffer zones are critical for smooth scrolling

### Input Handling
- Consume input events to prevent double-processing
- Validate InputMap actions exist before use
- Handle both keyboard and potential controller input

### Speed Tuning Pitfalls
- Avoid extreme speed differences that feel jarring (stick to 0.5x-2.5x range)
- Test speed adjustments in actual gameplay context, not isolation
- Remember that player perception of speed is relative to visual feedback