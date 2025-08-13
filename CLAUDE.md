# Project Context and Lessons Learned

## Treadmill Physics Implementation

### Key Lessons from Treadmill Movement System

**Problem**: Units were moving continuously instead of staying stationary when no input was given, despite treadmill compensation attempts.

**Root Causes Identified**:
1. **Reference Frame Confusion**: Mixed up "world position" vs "screen position" - the goal was screen-relative stationarity, not world-relative
2. **Over-Engineering**: Created complex component system with automatic treadmill compensation, then tried to layer manual compensation on top
3. **Historical Baggage**: Old hardcoded multiplier values (`PLAYER_TREADMILL_FORWARD_MULTIPLIER`, `PLAYER_TREADMILL_BACKWARD_MULTIPLIER`) conflicted with new automatic system
4. **Poor Debugging**: Spent time guessing instead of immediately adding debug output to see actual velocities

**Final Solution**:
```gdscript
# No input = zero velocity (stationary on screen)
var base_velocity = Vector2.ZERO

# Treadmill effect should be partial, not full speed
var treadmill_effect = GameController.TREADMILL_SPEED * 0.5

if input_vector.x > 0:  # Moving right (against treadmill) - harder/slower
    base_velocity.x = move_speed - treadmill_effect
elif input_vector.x < 0:  # Moving left (with treadmill) - easier/faster  
    base_velocity.x = -move_speed - treadmill_effect
```

**Key Insights**:
- Treadmill simulation is a **visual/camera problem**, not a physics compensation problem
- Units should move normally; the background/camera creates the treadmill illusion
- When stationary, apply **zero velocity** - let the world/camera handle movement
- Treadmill effects should be **partial** (< 100%) to ensure movement works in both directions
- **Debug output first** when movement feels wrong - don't guess at solutions

## Component Architecture

### Movement System Components

**Files**:
- `res://scripts/components/TreadmillAffected.gd` - Unified treadmill integration
- `res://scripts/components/MovableObject.gd` - Base movement interface
- `res://scripts/units/UnitController.gd` - Player unit movement with treadmill physics

**Design Pattern**: Component-based movement with optional treadmill integration, but avoid layering automatic + manual systems.

## Testing and Debugging

### Essential Debug Commands
- Always add velocity debug output when movement feels wrong: 
  ```gdscript
  print("🚶 Unit velocity - base: ", base_velocity, " final: ", velocity)
  ```
- Test treadmill effects in isolation using `res://scenes/test/TreadmillTest.tscn`

## Physics Configuration
- Camera uses Physics process callback
- All movement scripts use `_physics_process()` for consistency
- Removed pixel rounding/snapping for smoother movement

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