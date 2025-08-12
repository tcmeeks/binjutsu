# Godot Best Practices

This document outlines essential best practices for Godot development to ensure clean, maintainable, and performant code.

## Project Structure

### Scene Organization
- Keep scenes focused on a single responsibility
- Use meaningful scene names that describe their purpose
- Organize scenes in logical folders (player, enemies, ui, levels)
- Create reusable components as separate scenes

### Script Organization
- Mirror your scene folder structure in scripts folder
- Use clear, descriptive script names
- Group related scripts together (managers, systems, ui)
- Keep autoload scripts in the autoload folder

## Coding Standards

### Naming Conventions
- Use snake_case for variables, functions, and file names
- Use PascalCase for class names and scene names
- Use UPPER_CASE for constants
- Prefix private variables with underscore (_private_var)
- Use descriptive names that explain purpose

### Code Structure
- Keep functions small and focused (under 20 lines when possible)
- Use early returns to reduce nesting
- Group related functionality into classes
- Comment complex logic and algorithms
- Use type hints for better code clarity and performance

## Performance Best Practices

### Node Management
- Use object pooling for frequently spawned/destroyed objects
- Prefer queue_free() over free() for safe node removal
- Cache node references instead of using get_node() repeatedly
- Use groups for efficient node collection management

### Resource Management
- Preload resources that are used frequently
- Use load() for resources that may not be needed immediately
- Unload unused resources to free memory
- Use ResourcePreloader for multiple small resources

### Rendering Optimization
- Use CanvasLayers to control draw order efficiently
- Minimize transparent overlays
- Use appropriate texture formats and sizes
- Consider using MultiMesh for many similar objects

## Signal Best Practices

### Signal Design
- Use descriptive signal names that indicate what happened
- Keep signal parameters minimal and meaningful
- Document signal parameters and when they're emitted
- Prefer signals over direct node references for loose coupling

### Connection Management
- Connect signals in _ready() when possible
- Always disconnect signals when nodes are freed
- Use one-shot connections for single-use events
- Group related signal connections together

## Scene Design Patterns

### Composition Over Inheritance
- Build complex objects by combining simple components
- Use scenes as components that can be reused
- Prefer has-a relationships over is-a relationships
- Create modular, interchangeable parts

### State Management
- Use state machines for complex behavior
- Keep state changes explicit and traceable
- Centralize game state in autoload singletons
- Use signals to communicate state changes

## Error Handling

### Defensive Programming
- Check for null references before using nodes
- Validate input parameters in functions
- Use assert() for debugging assumptions
- Handle edge cases gracefully

### Debugging Practices
- Use print() statements strategically for debugging
- Leverage the debugger and breakpoints
- Use the remote inspector for runtime debugging
- Log important events and state changes

## Memory Management

### Node Lifecycle
- Always call queue_free() on dynamically created nodes
- Disconnect signals before freeing nodes
- Clear references to freed nodes
- Use weak references when appropriate

### Resource Cleanup
- Unload large resources when no longer needed
- Clear arrays and dictionaries when done
- Be mindful of circular references
- Monitor memory usage in complex scenes

## Trust the Engine

### Don't Fight Godot's Natural Systems
- **Avoid forced pixel-perfect rounding** - Don't use `Vector2(round(x), round(y))` every frame
- **Let move_and_slide() work naturally** - Don't manually constrain positions after movement
- **Trust Godot's rendering** - Sub-pixel positioning and smooth movement are handled automatically
- **Simple solutions first** - Complex positioning logic often creates more problems than it solves

### Movement Best Practices
- Use Godot's built-in movement systems (move_and_slide, velocity, etc.)
- Let the engine handle smooth interpolation and sub-pixel rendering
- Only add constraints when absolutely necessary (boundaries, collision response)
- When movement looks wrong, simplify the code rather than adding complexity

### The KISS Principle for Godot
- Keep systems simple and let Godot do what it's designed for
- Straightforward logic beats "optimized" micromanagement
- Work with the engine, not against it
- If you're fighting the engine, you're probably overcomplicating

## Input Handling

### Input Architecture
- Centralize input handling in dedicated scripts
- Use input maps instead of hardcoded keys
- Support both keyboard and controller input
- Implement input buffering for responsive controls

### UI Input
- Use proper focus management for UI elements
- Implement keyboard navigation for accessibility
- Handle input events at the appropriate level
- Provide visual feedback for user interactions