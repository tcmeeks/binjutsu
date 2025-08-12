# Coin Drop System

## Overview
Physics-based coin dropping system that creates realistic bouncing coins when enemies die. Uses the GoldCoin.png sprite and implements a ground plane system to prevent coins from falling off-screen.

## Components

### Coin.gd
- RigidBody2D-based coin using GoldCoin.png sprite (7x7 pixels)
- 7x7 square collision shape for pixel-perfect collision
- Ground plane enforcement prevents falling off-screen
- Uses enemy death Y-position as ground level
- Collection area for player interaction
- Settles faster when on ground (1.5s vs 3s in air)
- Rotation animation that stops when settled
- Treadmill physics affect coins (moves them left at 50px/s)
- Auto-cleanup when coins move too far off-screen

### CoinDropper.gd
- Static utility class for spawning coins
- Creates arc-based launch patterns with ground plane
- Uses enemy position as ground reference
- Configurable force and spread parameters

### Physics Material
- Bounce: 0.6 (bouncy but not excessive)
- Friction: 0.3 (allows sliding to stop)

### Ground Plane System
- Each coin gets ground level set to enemy death Y-position
- Manual physics enforcement prevents falling through
- Bouncing with energy loss (50% bounce, 80% horizontal friction)
- Faster settling when on ground

### Treadmill Integration
- Settled coins are affected by treadmill movement
- Uses GameController.TREADMILL_SPEED (50px/s) for realistic movement
- Coins move left with the treadmill when on ground or settled
- Automatic cleanup prevents off-screen coin accumulation

## Usage

Coins are automatically dropped when enemies die based on their `coin_drop_count` property in EnemyData:
- Slimes: 1 coin
- Snakes & Raccoons: 2 coins  
- Frogs: 3 coins
- Cyclopes: 5 coins

## Collision Layers
- Coins: Layer 8
- Player: Layer 2 (for collection)
- World: Layer 1 (for bouncing)

## Testing
Use the TreadmillTest scene - kill enemies to see coin drops in action! Coins will bounce and settle at the enemy's death level.