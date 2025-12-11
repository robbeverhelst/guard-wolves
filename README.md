# Guard Wolves

> Transform your tamed wolves into stationary guardians that patrol and defend your territory

A Denizen script for Minecraft that enables tamed wolves to guard specific locations without following you, complete with smart AI, combat behavior, and beautiful visual effects.

![Minecraft Version](https://img.shields.io/badge/Minecraft-1.20.5+-green.svg)
![Denizen](https://img.shields.io/badge/Denizen-Required-blue.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## Features

### Core Functionality
- 🛡️ **Guard Mode Toggle** - Right-click with a stick to enable/disable guard mode
- 🎯 **Smart AI** - Wolves patrol within a 15-block radius and automatically return to their guard point
- ⚔️ **Combat System** - Detects and attacks hostile mobs within range
- 🔄 **Automatic Recovery** - Teleports stuck wolves back to their guard point with invulnerability
- 📋 **Wolf Management** - List all your wolves with status, health, location, and armor indicators

### Combat Behavior
- ✅ Attacks hostile mobs within 15 blocks
- ❌ Never attacks players
- ❌ Never attacks creepers (prevents explosions)
- ❌ Never attacks passive animals

### Visual & Audio Effects
- **Enabling Guard Mode:** Critical hit particles and 2-second glowing effect
- **Disabling Guard Mode:** Happy green sparkles

## Installation

### Requirements
- Minecraft 1.20.5 or higher
- [Denizen](https://denizenscript.com/) plugin installed on your server

### Setup
1. Download `guard_wolves.dsc`
2. Place it in your server's `plugins/Denizen/scripts/` folder
3. Restart your server or run `/denizen reload scripts`
4. Verify installation with `/denizen scripts` - you should see `guard_wolves_command`, `guard_wolf_startup`, `guard_wolf_toggle`, `guard_wolf_combat`, and `guard_wolf_wander`

## Usage

### Enabling Guard Mode
1. Tame a wolf
2. Position the wolf where you want it to guard
3. Right-click the wolf with a **stick**
4. The wolf will guard a 15-block radius around that location

### Disabling Guard Mode
1. Right-click the guarding wolf with a **stick**
2. The wolf becomes tamed again and will follow you

### Commands

| Command | Aliases | Description |
|---------|---------|-------------|
| `/guard_wolves list` | `/gw ls` | List all your wolves with status, health, location, and armor 🛡️ |
| `/guard_wolves toggle_logs` | `/gw tl` | Enable/disable debug logs for troubleshooting |

**Example output:**
```
========== Your Wolves (5) ==========
• Fang 🛡️ (Pale) ❤ 32/40 GUARDING at -487,78,-18,world
• Rex (Ashen) ❤ 20/20 Following at 123,65,456,world
• Scout (Woods) ❤ 8/8 Sitting at -200,70,300,world
```

## How It Works

### Guard Mode Mechanics
When a wolf enters guard mode:
- Owner is removed (prevents following/teleporting)
- Max health set to 40 HP (tamed wolf stats)
- Current health is preserved
- Wolf becomes persistent (won't despawn)
- Movement speed remains natural
- Guard point saved at current location

### AI Behavior
The AI runs every **8 seconds** for each guard wolf:

1. **Distance Check** - Monitors distance from guard point
2. **Return Logic** - Walks back slowly if >15 blocks away
3. **Stuck Detection** - Teleports wolf home if stuck for 1+ minute
4. **Home Check** - Every 2 minutes, teleports if >3 blocks away for 4+ minutes
5. **Combat Scan** - Every 2 seconds, detects nearby hostile mobs

### Teleport Safety
All teleports include:
- 3 seconds of invulnerability
- Protection from fall damage
- Protection from suffocation
- Protection from mob attacks

### Health System
- **Guard wolves cannot be healed with meat** (shows warning message)
- **Must disable guard mode to heal**

### Death Notifications
When a guard wolf dies, you receive:
```
⚠ Guard wolf died: Fang (Pale) at -487,78,-18,world - killed by Zombie
```

## Configuration & Customization

### Adjusting Guard Radius
Edit the `15` value in these lines:
```yaml
- define nearby_mobs <[wolf].location.find_entities[monster].within[15]>
- if <[distance]> > 15:
```

### Changing Return Speed
Edit line 468:
```yaml
- walk <[wolf]> <[safe_center]> speed:0.3
```
Lower = slower (0.1-1.0 range)

### Customizing Visual Effects

**Guard Mode Enable:** Edit particle effects and glowing duration around line 241
**Guard Mode Disable:** Edit particle effects around line 194

### Changing Health Values
Edit the max health (default 40):
```yaml
- adjust <[wolf]> max_health:40
```

### Adjusting Timers
```yaml
# Combat scan frequency (line 294)
on delta time secondly every:2

# AI loop frequency (line 305)
on delta time secondly every:8

# Stuck timeout (line 442)
- if <[time_stuck]> > 60:  # 60 seconds

# Home check timeout (line 410)
- if <[time_away]> > 120:  # 120 seconds
```

## Troubleshooting

### Wolf isn't attacking mobs
- Enable debug logs: `/gw tl`
- Check if wolf is in combat mode in logs
- Verify mob is hostile and not a creeper
- Ensure mob is within 15 blocks

### Wolf keeps teleporting
- Check debug logs for stuck/home check messages
- Wolf may be in an area with poor pathfinding
- Consider placing guard point in more open area

### Wolf health not saving
- Check that server restarts cleanly (not crashed)
- Verify Denizen is saving flags properly
- Health saves every 8 seconds during AI cycles

### Can't heal guard wolf
- This is intentional! Disable guard mode first with a stick
- Then feed the wolf meat to heal
- Re-enable guard mode after healing

### Wolf moving too fast/slow
- The script doesn't modify base movement speed
- Combat and natural movement use vanilla speeds

## Technical Details

- **AI Frequency:** Every 8 seconds
- **Combat Scan Frequency:** Every 2 seconds
- **Guard Radius:** 15 blocks
- **Home Radius:** 3 blocks (for stuck detection)
- **Return Walk Speed:** 0.3
- **Stuck Timeout:** 60 seconds
- **Home Check Timeout:** 240 seconds
- **Invulnerability Duration:** 3 seconds (after teleport)

## Credits

Created by [Robbe Verhelst](https://github.com/robbeverhelst)

Built with [Denizen Script](https://denizenscript.com/)

## License

MIT License - see [LICENSE](LICENSE) file for details

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ideas for Future Enhancements
- Custom guard messages/alerts
- Wolf formations/groups
- Territory claiming integration
- Experience/leveling system
- Different guard behaviors (aggressive/passive/defensive)
- Integration with other protection plugins

## Support

Found a bug? Have a suggestion? [Open an issue](https://github.com/robbeverhelst/guard-wolves/issues)!
