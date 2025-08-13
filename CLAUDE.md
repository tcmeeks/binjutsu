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