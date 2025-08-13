# Binjutsu Game Architecture Guide

## Game Architecture Overview

This is a Godot 4 treadmill-based side-scrolling action game with data-driven systems, component-based architecture, and sophisticated enemy AI.

## Core Systems

### 1. Treadmill System - Central Movement Paradigm

The treadmill is the foundation of all movement in the game. Everything moves leftward at `GameController.TREADMILL_SPEED` (50.0 pixels/second) to create the endless runner illusion.

**Key Files**:
- `GameController.gd` - Central controller managing `TREADMILL_SPEED` with smooth transitions
- `TreadmillManager.gd` - Manages slice-based endless scrolling background 
- `TreadmillAffected.gd` - Component for objects affected by treadmill movement

**Treadmill Physics Implementation**:
```gdscript
# Units compensate for treadmill to achieve screen-relative movement
var treadmill_effect = GameController.TREADMILL_SPEED * unit_data.treadmill_effect_multiplier
if input_vector.x > 0:  # Moving right (against treadmill) - harder/slower
    base_velocity.x = unit_data.move_speed - treadmill_effect
elif input_vector.x < 0:  # Moving left (with treadmill) - easier/faster
    base_velocity.x = -unit_data.move_speed - treadmill_effect
```

**Critical Insights**:
- **No input = zero velocity** for screen-stationary behavior
- Treadmill effects should be **partial** (< 100%) to ensure bidirectional movement
- All objects subtract `TREADMILL_SPEED` from their intended movement
- Debug velocity output immediately when movement feels wrong

### 2. Data-Driven Entity Systems

**Unit System**:
- `UnitData.gd` - Resource-based configuration with programmatic animation methods
- `UnitFactory.gd` - Factory pattern for creating configured units
- `GenericUnit.gd` - Universal unit controller using UnitData
- Available types: `["player"]`

**Enemy System**:
- `EnemyData.gd` - Resource-based enemy configuration 
- `EnemyFactory.gd` - Factory pattern for creating configured enemies
- `GenericEnemy.gd` - Universal enemy controller using EnemyData
- Available types: `["slime", "snake", "raccoon", "frog", "cyclope"]`

**Example Unit Creation**:
```gdscript
var unit_instance = UnitFactory.create_unit("player")
add_child(unit_instance)
```

### 3. Component-Based Architecture

**Movement Components**:
- `MovableObject.gd` - Base movement with optional smoothing and treadmill integration
- `TreadmillAffected.gd` - Handles treadmill velocity calculations
- `ProjectileAttack.gd` - Handles projectile-based combat with auto-targeting

**Enemy Movement Components** (Factory pattern):
- `MovementComponent.gd` - Base class with factory method `create_movement_component()`
- `StraightMovementComponent` - Linear leftward movement  
- `ChaseMovementComponent` - Chase behavior (slimes)
- `TrackingMovementComponent` - Vertical tracking (cyclopes)
- `LeapChaseMovementComponent` - Leap-based chasing (frogs)
- `SnakeMovementComponent` - Sine wave movement (snakes)

### 4. Collision Layer System

**Layer Hierarchy** (higher z_index renders on top):
- **Layer 1 (Ground)**: `collision_layer = 1`
- **Layer 2 (Units)**: `collision_layer = 2, collision_mask = 3` (world + enemies)
- **Layer 3 (Enemies)**: `collision_layer = 4, collision_mask = 3` (world + units)  
- **Layer 4 (Projectiles)**: `collision_layer = 8, collision_mask = 4` (enemies only)
- **Layer 5 (Pickups)**: `collision_layer = 0, collision_mask = 0` (no physical collision)

**Z-Index Rendering Order**:
- Gibs: `z_index = 1` 
- Pickups: `z_index = 2`
- Units/Enemies: `z_index = 3`

### 5. Combat and Effects Systems

**Projectile System**:
- `ProjectileData.gd` - Data-driven projectile configurations
- `ProjectilePool.gd` - Object pooling for performance
- `Projectile.gd` - Individual projectile behavior with hit detection

**Gib System** (particle effects):
- `GibDropper.gd` - Spawns colored particles on enemy death
- `GibParticle.gd` - 3x3 pixel particles with physics and fading
- `ColorSampler.gd` - Samples center pixel colors from sprites

**Pickup System**:
- `Coin.gd` - Magnetism-based collection with tweened movement
- `CoinDropperSystem.gd` - Spawns coins on enemy death

### 6. Animation and Visual Systems

**Programmatic Animation System**:
```gdscript
# In UnitData/EnemyData
func get_walk_animation(direction: String = "") -> String:
    if direction == "":
        direction = default_facing_direction
    return "walk_" + direction
```

## Development Patterns and Best Practices

### 1. File Organization
- Units: `scripts/units/` - Player and unit systems
- Enemies: `scripts/enemies/` - Enemy systems and movement components
- Components: `scripts/components/` - Reusable component systems
- Systems: `scripts/systems/` - Global game systems (coin dropping, etc.)
- Effects: `scripts/effects/` - Visual effects and particles

### 2. Debug System Integration
All systems integrate with `DebugVisualization.debug_mode_enabled` for conditional logging:
```gdscript
if DebugVisualization.debug_mode_enabled:
    print("🚶 Unit velocity - base: ", base_velocity, " final: ", velocity)
```

### 3. Factory Pattern Usage
- Use factories (`UnitFactory`, `EnemyFactory`) for entity creation
- Data-driven configuration prevents hardcoded values
- Centralized type management in factory `get_available_*_types()` methods

### 4. Component Lifecycle Management  
- Components initialize via `initialize()` methods with parent references
- Use `call_deferred()` for collision shape setup
- Connect signals in `_ready()` with proper disconnect handling

### 5. Treadmill Integration
- All moving objects must account for `GameController.TREADMILL_SPEED`
- Use `TreadmillAffected` component for automatic integration
- Manual treadmill compensation in specialized movement systems

## Testing and Debugging

### Essential Debug Commands
```gdscript
print("🚶 Unit velocity - base: ", base_velocity, " final: ", velocity)
print("🎯 Enemy spotted target: ", target.name)
print("💀 ", get_enemy_type(), " dropping ", coin_count, " coins!")
```

### Test Scenes
- `res://scenes/test/TreadmillTest.tscn` - Treadmill physics testing

## Key Architectural Decisions

1. **Treadmill-First Design**: All movement compensates for background scrolling
2. **Data-Driven Configuration**: No hardcoded entity properties
3. **Component Composition**: Behavior through attachable components
4. **Factory Pattern Creation**: Centralized, configurable entity spawning
5. **Collision Layer Separation**: Clear interaction boundaries
6. **Debug Mode Integration**: Conditional logging throughout
7. **Resource-Based Assets**: `.tres` files for all configurations

## SpriteFrames Creation Template

### Character Animation Layout
All character spritesheets follow this standardized pattern:

**Multi-frame animations**: 4 columns × 4 rows (64×64 pixels)
- Each column = 1 direction (down, up, left, right at x=0,16,32,48)
- Each row = 1 animation frame (4 frames total per direction at y=0,16,32,48)
- Frame slicing uses **vertical strips**: Column 0 has frames at (0,0), (0,16), (0,32), (0,48)

**Single-frame animations**: 4 columns × 1 row (64×16 pixels)  
- Each column = 1 directional pose (down, up, left, right at x=0,16,32,48)
- Single row at y=0

### Standard Animation Files
- `Attack.png` - 4×1 single-frame (combat poses)
- `Walk.png` - 4×4 multi-frame (movement animation)
- `Idle.png` - 4×1 single-frame (standing poses)
- `Jump.png` - 4×1 single-frame (jumping poses)
- `Dead.png` - 1×1 single sprite (death state)
- `Item.png` - 1×1 single sprite (using items)
- `Special1.png` - 1×1 single sprite (special ability 1)
- `Special2.png` - 1×1 single sprite (special ability 2)

### Directory Structure
```
assets/sprites/units/{CharacterName}/SeparateAnim/
├── Attack.png (+ .import)
├── Walk.png (+ .import)  
├── Idle.png (+ .import)
├── Jump.png (+ .import)
├── Dead.png (+ .import)
├── Item.png (+ .import)
├── Special1.png (+ .import)
└── Special2.png (+ .import)
```

### Critical Lessons Learned
**THESE ISSUES MUST BE AVOIDED FOR ONE-SHOT SUCCESS:**

1. **ExtResource Declaration Format** (CRITICAL):
   - ✅ CORRECT: `[ext_resource type="Texture2D" uid="uid://h7gx66kjaegx" path="res://assets/sprites/units/Hunter/SeparateAnim/Attack.png" id="1_attack"]`
   - ❌ WRONG: `ExtResource("res://assets/sprites/units/Hunter/SeparateAnim/Attack.png")` in SubResources
   - **Must declare all ExtResources at top with correct UIDs from .import files**

2. **Vertical Strip Slicing** (CRITICAL):
   - ✅ CORRECT: Column-based slicing - each direction gets its own column
     - **Walk (multi-frame)**: Down: (0,0), (0,16), (0,32), (0,48) - 4 frames in column 0
     - **Attack/Idle/Jump (single-frame)**: Down: (0,0), Up: (16,0), Left: (32,0), Right: (48,0)
   - ❌ WRONG: Horizontal row slicing across directions
   - **Walk animations have 4 frames per direction; Attack/Idle/Jump have 1 frame per direction**

3. **Load Steps Count** (CRITICAL):
   - Must match actual number of ExtResources + SubResources
   - Example: 8 ExtResources + 17+ SubResources = `load_steps=25+`

4. **UID Extraction** (CRITICAL):
   - Always read .import files to get correct UIDs
   - Never guess or make up UIDs
   - Each sprite file has unique UID in its .import file

### SpriteFrames Creation Process
1. **Examine sprite files** to verify layout matches template
2. **Extract UIDs** from ALL .import files for ExtResource declarations  
3. **Create ExtResource declarations** at top with correct UIDs and proper format
4. **Create AtlasTexture SubResources** with VERTICAL STRIP slicing:
   - Walk animation: 16 textures (4 directions × 4 frames)
   - Attack/Idle/Jump animations: 4 textures each (4 directions × 1 frame)
   - **Remember: Each direction is a COLUMN, each frame is a ROW within that column**
5. **Define animations** with appropriate settings and all frames in sequence
6. **Verify load_steps count** matches total ExtResources + SubResources
7. **Save as** `{CharacterName}Animations.tres`

### Animation Naming Convention
- `attack_down`, `attack_up`, `attack_left`, `attack_right`
- `walk_down`, `walk_up`, `walk_left`, `walk_right`
- `idle_down`, `idle_up`, `idle_left`, `idle_right`
- `jump_down`, `jump_up`, `jump_left`, `jump_right`
- `dead`, `item`, `special1`, `special2`

### Usage
When creating new character animations, reference this template and say:
**"Create SpriteFrames for [CharacterName] character using the template"**

Claude will automatically:
- Verify sprite file layout
- Extract UIDs from import files
- Generate properly formatted .tres file
- Apply correct frame slicing and animation settings