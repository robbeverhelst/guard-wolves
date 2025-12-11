guard_wolves_constants:
  type: data
  # Wolf health settings
  max_wolf_health: 40
  # Combat and patrol distances
  combat_range: 15
  max_wander_distance: 15
  home_check_distance: 3
  # Timer settings (seconds)
  stuck_teleport_time: 60
  home_teleport_time: 120
  home_check_cycles: 15

get_armor_icon:
  type: procedure
  debug: false
  definitions: wolf
  script:
  - define armor_item <[wolf].equipment_map.get[body]||air>
  - if <[armor_item]> != air:
    - determine 🛡<&sp>
  - else:
    - determine <empty>

format_wolf_display:
  type: procedure
  debug: false
  definitions: wolf
  script:
  - define variant <[wolf].variant.to_titlecase>
  - define wolf_display_name <[wolf].custom_name.if_null[Wolf]>
  - define hp <[wolf].health.round>
  - define max_hp <[wolf].health_max.round>
  - define armor_icon <proc[get_armor_icon].context[<[wolf]>]>
  - determine <[wolf_display_name]>|<[variant]>|<[hp]>|<[max_hp]>|<[armor_icon]>

guard_wolves_command:
  type: command
  name: guard_wolves
  description: Manage your guard wolves
  usage: /guard_wolves <&lt>list|toggle_logs<&gt>
  aliases:
  - gw
  script:
  # Get subcommand
  - define subcommand <context.args.get[1]||null>

  # LIST subcommand - show all player's wolves
  - if <[subcommand]> == list || <[subcommand]> == ls:
    # Find ALL wolves in the world owned by this player
    - define all_world_wolves <player.world.entities[wolf]>
    - define my_wolves <list>

    - foreach <[all_world_wolves]> as:wolf:
      - if <[wolf].is_tamed> && <[wolf].owner> == <player>:
        - define my_wolves:->:<[wolf]>
      # Also check guard wolves (they have no owner but flag)
      - else if <[wolf].has_flag[guard_mode]> && <[wolf].flag[original_owner]> == <player>:
        - define my_wolves:->:<[wolf]>

    - if <[my_wolves].is_empty>:
      - narrate "<gray>You have no wolves"
      - stop

    # Sort wolves by status: sitting first, then guarding, then following
    - define sitting_wolves <list>
    - define guarding_wolves <list>
    - define following_wolves <list>

    - foreach <[my_wolves]> as:wolf:
      - if <[wolf].has_flag[guard_mode]>:
        - define guarding_wolves:->:<[wolf]>
      - else if <[wolf].sitting>:
        - define sitting_wolves:->:<[wolf]>
      - else:
        - define following_wolves:->:<[wolf]>

    - narrate "<gold>========== Your Wolves (<[my_wolves].size>) =========="

    # Display sitting wolves
    - foreach <[sitting_wolves]> as:wolf:
      - define wolf_info <proc[format_wolf_display].context[<[wolf]>]>
      - define current_loc <[wolf].location>
      - narrate "<gray>• <aqua><[wolf_info].get[1]> <[wolf_info].get[5]><dark_gray>(<[wolf_info].get[2]>) <red>❤ <[wolf_info].get[3]>/<[wolf_info].get[4]> <gray><italic>Sitting<&r> at <[current_loc].simple>"

    # Display guarding wolves
    - foreach <[guarding_wolves]> as:wolf:
      - define wolf_info <proc[format_wolf_display].context[<[wolf]>]>
      - define guard_loc <[wolf].flag[guard_point]>
      - narrate "<green>• <aqua><[wolf_info].get[1]> <[wolf_info].get[5]><dark_gray>(<[wolf_info].get[2]>) <red>❤ <[wolf_info].get[3]>/<[wolf_info].get[4]> <green><bold>GUARDING<&r> at <[guard_loc].simple>"

    # Display following wolves
    - foreach <[following_wolves]> as:wolf:
      - define wolf_info <proc[format_wolf_display].context[<[wolf]>]>
      - define current_loc <[wolf].location>
      - narrate "<yellow>• <aqua><[wolf_info].get[1]> <[wolf_info].get[5]><dark_gray>(<[wolf_info].get[2]>) <red>❤ <[wolf_info].get[3]>/<[wolf_info].get[4]> <yellow>Following at <[current_loc].simple>"

    - stop

  # TOGGLE_LOGS subcommand - toggle debug
  - if <[subcommand]> == toggle_logs || <[subcommand]> == tl:
    - if <player.has_flag[wolf_debug]>:
      - flag <player> wolf_debug:!
      - narrate "<gray>Wolf debug logs disabled"
    - else:
      - flag <player> wolf_debug:true
      - narrate "<green>Wolf debug logs enabled"
    - stop

  # Invalid or no subcommand - show help
  - narrate "<gold>Guard Wolves Commands:"
  - narrate "<yellow>/gw list <gray>(or <yellow>ls<gray>) - List all your guard wolves"
  - narrate "<yellow>/gw toggle_logs <gray>(or <yellow>tl<gray>) - Toggle debug logs"

guard_wolf_startup:
  type: world
  debug: false
  events:
    # Rebuild guard wolves list on server startup
    on server start:
    - wait 5s

    # Find all wolves in all worlds that have guard_mode flag
    - define all_wolves <list>
    - foreach <server.worlds> as:world:
      - define world_wolves <[world].entities[wolf]>
      - foreach <[world_wolves]> as:wolf:
        - if <[wolf].has_flag[guard_mode]>:
          - define all_wolves:->:<[wolf]>
          # Restore health to tamed wolf levels
          - define max_hp <script[guard_wolves_constants].data_key[max_wolf_health]>
          - adjust <[wolf]> max_health:<[max_hp]>
          # Restore saved health if it exists
          - if <[wolf].has_flag[saved_health]>:
            - adjust <[wolf]> health:<[wolf].flag[saved_health]>
          - else:
            # If no saved health, cap current health at max
            - if <[wolf].health> > <[max_hp]>:
              - adjust <[wolf]> health:<[max_hp]>

    # Rebuild the server list
    - flag server guard_wolves:<[all_wolves]>

guard_wolf_toggle:
  type: world
  debug: false
  events:
    # Prevent healing guard wolves with meat - show warning instead
    on player right clicks wolf with:raw_beef|cooked_beef|raw_porkchop|cooked_porkchop|raw_chicken|cooked_chicken|raw_mutton|cooked_mutton|raw_rabbit|cooked_rabbit|rotten_flesh:
    - define wolf <context.entity>
    - if <[wolf].has_flag[guard_mode]>:
      - determine cancelled
      - narrate "<red>You can't heal a guarding wolf. Disable guard mode first to heal it."
      - playsound <player> sound:entity_wolf_whine pitch:0.8 volume:1

    # Player right-clicks a wolf with a STICK
    on player right clicks wolf with:stick:
    # Prevent double-firing
    - ratelimit <player> 1t

    - define wolf <context.entity>

    # Check if wolf is in guard mode (flagged, even if untamed)
    - if <[wolf].has_flag[guard_mode]>:
      # DISABLE guard mode

      # FIRST: Stop any active walking/pathfinding
      - walk <[wolf]> stop

      # Remove from global guard list IMMEDIATELY (stops new walk commands)
      - flag server guard_wolves:<-:<[wolf]>

      # Save current health before retaming
      - define current_health <[wolf].health>

      # Clear guard flags
      - flag <[wolf]> guard_mode:!
      - flag <[wolf]> guard_point:!

      # Wait a tick for pathfinding to fully stop
      - wait 1t

      # Restore owner (retame the wolf)
      - adjust <[wolf]> owner:<[wolf].flag[original_owner]>

      # Wait for retaming to process, then restore health
      - wait 3t
      - adjust <[wolf]> health:<[current_health]>

      # Clear owner and saved health flags
      - flag <[wolf]> original_owner:!
      - flag <[wolf]> saved_health:!

      - narrate "<gray>Guard mode disabled. Your wolf will follow you again."
      - playsound <player> sound:entity_wolf_ambient pitch:1.3 volume:1
      - playeffect effect:villager_happy at:<[wolf].location.add[0,0.5,0]> quantity:15 offset:0.3,0.5,0.3
      - stop

    # Only tamed wolves can ENTER guard mode
    - if !<[wolf].is_tamed>:
      - narrate "<red>That wolf isn't tamed."
      - stop

    # Only the owner can toggle guard mode
    - if <[wolf].owner> != <player>:
      - narrate "<red>That's not your wolf."
      - stop

    # ENABLE guard mode
    # Store the original owner before removing it
    - flag <[wolf]> original_owner:<player>

    # Save current health as a flag (to restore after becoming wild)
    - flag <[wolf]> saved_health:<[wolf].health>

    # Mark wolf as guarding
    - flag <[wolf]> guard_mode:true

    # Save the guard point (current location)
    - flag <[wolf]> guard_point:<[wolf].location>

    # Make wolf stand (not sit) so it can wander
    - adjust <[wolf]> sitting:false

    # Remove owner to prevent following/teleporting (makes wolf wild)
    - adjust <[wolf]> owner

    # Mark as persistent to prevent despawning (wild wolves can despawn!)
    - adjust <[wolf]> persistent:true

    # Add to global guard list
    - flag server guard_wolves:->:<[wolf]>

    # Wait for Minecraft to process owner removal, then fix health
    - wait 3t
    - adjust <[wolf]> max_health:<script[guard_wolves_constants].data_key[max_wolf_health]>
    - wait 1t
    - adjust <[wolf]> health:<[wolf].flag[saved_health]>

    - narrate "<green>Guard mode enabled! This wolf will guard this area."
    - playsound <player> sound:entity_wolf_growl pitch:0.7 volume:1
    - playsound <player> sound:item_armor_equip_netherite pitch:1.0 volume:0.8
    - playeffect effect:crit at:<[wolf].location.add[0,0.5,0]> quantity:30 offset:0.3,0.5,0.3
    - adjust <[wolf]> glowing:true
    - wait 2s
    - adjust <[wolf]> glowing:false

    # Prevent guard wolves from teleporting to owner
    on entity teleports cause:ENTITY_TELE:
    - if <context.entity.has_flag[guard_mode]>:
      - determine cancelled

    # Prevent guard wolves from targeting players or creepers
    on entity targets entity:
    - if <context.entity.has_flag[guard_mode]>:
      # Wolf is in guard mode - control what it can target
      - if <context.target.is_player>:
        # Never attack players
        - determine cancelled
      - if <context.target.type> == CREEPER:
        # Never attack creepers (explosions!)
        - determine cancelled
      - if !<context.target.is_monster>:
        # Only attack hostile mobs, not passive animals
        - determine cancelled

    # Notify owner when guard wolf dies
    on entity dies:
    - if <context.entity.type> == WOLF && <context.entity.has_flag[guard_mode]>:
      - define owner <context.entity.flag[original_owner]>
      - define wolf <context.entity>

      # Get wolf info
      - define variant <[wolf].variant.to_titlecase>
      - if <[wolf].custom_name.exists>:
        - define wolf_name <[wolf].custom_name>
      - else:
        - define wolf_name Wolf
      - define location <[wolf].location.simple>

      # Get cause of death
      - if <context.damager.exists>:
        - if <context.damager.is_player>:
          - define cause "killed by <context.damager.name>"
        - else:
          - define cause "killed by <context.damager.type.to_titlecase>"
      - else:
        - define cause <context.cause.to_titlecase.replace[_].with[ ]>

      - if <[owner].is_online>:
        - narrate "<red>⚠ Guard wolf died: <aqua><[wolf_name]> <dark_gray>(<[variant]>)<red> at <[location]> - <[cause]>" targets:<[owner]>
        - playsound <[owner]> sound:entity_wolf_death pitch:1.0 volume:1
      # Clean up from server list
      - flag server guard_wolves:<-:<context.entity>

guard_wolf_combat:
  type: world
  debug: false
  events:
    # Combat scan runs every 2 seconds for faster response
    on delta time secondly every:2:
    - define wolves <server.flag[guard_wolves]||<list>>
    - if <[wolves].is_empty>:
      - stop

    - foreach <[wolves]> as:wolf:
      - if !<[wolf].is_spawned>:
        - foreach next
      - if !<[wolf].has_flag[guard_mode]>:
        - foreach next

      # COMBAT: Check for nearby hostile mobs
      - define combat_range <script[guard_wolves_constants].data_key[combat_range]>
      - define nearby_mobs <[wolf].location.find_entities[monster].within[<[combat_range]>]>

      # Filter out creepers (don't want explosions!)
      - define valid_targets <[nearby_mobs].exclude[type.equals[CREEPER]]>

      - if !<[valid_targets].is_empty>:
        - define target <[valid_targets].get[1]>
        - attack <[wolf]> target:<[target]>

guard_wolf_wander:
  type: world
  debug: false
  events:
    # Run every 8 seconds to check on guard wolves
    on delta time secondly every:8:
    - define wolves <server.flag[guard_wolves]||<list>>

    # Always rebuild/sync the list to catch any wolves that fell out
    - define all_wolves <list>
    - foreach <server.worlds> as:world:
      - define world_wolves <[world].entities[wolf]>
      - foreach <[world_wolves]> as:wolf:
        - if <[wolf].has_flag[guard_mode]>:
          - define all_wolves:->:<[wolf]>

    # Update server list with all discovered guard wolves
    - if !<[all_wolves].is_empty>:
      - flag server guard_wolves:<[all_wolves]>
      - define wolves <[all_wolves]>
    - else:
      - stop

    - foreach <[wolves]> as:wolf:
      # Only show debug if owner has debug flag enabled
      - define owner <[wolf].flag[original_owner]>
      - define show_debug <[owner].has_flag[wolf_debug]>

      - if <[show_debug]>:
        - narrate "<gold>============ GUARD WOLF AI CYCLE ============" targets:<[owner]>

      # Clean up dead/despawned wolves
      - if !<[wolf].is_spawned>:
        - if <[show_debug]>:
          - narrate "<red>[CLEANUP] Wolf despawned, removing from list" targets:<[owner]>
        - flag server guard_wolves:<-:<[wolf]>
        - foreach next

      # Skip if guard mode was disabled
      - if !<[wolf].has_flag[guard_mode]>:
        - if <[show_debug]>:
          - narrate "<red>[CLEANUP] Guard mode disabled, removing from list" targets:<[owner]>
        - flag server guard_wolves:<-:<[wolf]>
        - foreach next

      # Fix health if it's too low (happens after server restart)
      - define max_hp <script[guard_wolves_constants].data_key[max_wolf_health]>
      - if <[wolf].health_max> < <[max_hp]>:
        - if <[show_debug]>:
          - narrate "<yellow>[HEALTH FIX] Restoring health from <[wolf].health_max> to <[max_hp]>" targets:<[owner]>
        # Restore to saved health if available, otherwise keep current health (capped at max)
        - define health_to_restore <[wolf].flag[saved_health].if_null[<[wolf].health>]>
        - if <[health_to_restore]> > <[max_hp]>:
          - define health_to_restore <[max_hp]>
        - adjust <[wolf]> max_health:<[max_hp]>
        - adjust <[wolf]> health:<[health_to_restore]>

      # Always save current health so we can restore it after restart
      - flag <[wolf]> saved_health:<[wolf].health>

      # Get guard center point
      - define center <[wolf].flag[guard_point]>

      # Check distance from guard center
      - define distance <[wolf].location.distance[<[center]>]>
      - if <[show_debug]>:
        - narrate "<blue>[DISTANCE] Wolf is <[distance].round> blocks from guard center" targets:<[owner]>

      # Check if wolf is in combat - if so, stop any walk commands and skip movement logic
      - if <[wolf].target.exists>:
        - walk <[wolf]> stop
        - if <[show_debug]>:
          - narrate "<red>[COMBAT] Wolf is fighting, stopped walk commands for natural speed" targets:<[owner]>
        - foreach next

      # Check if wolf is already moving
      - define velocity <[wolf].velocity.vector_length>
      - if <[show_debug]>:
        - narrate "<yellow>[VELOCITY] Wolf velocity: <[velocity].round_to[2]>" targets:<[owner]>

      # HOME CHECK: Only run every 2 minutes (every 15th cycle at 8s intervals)
      # Increment cycle counter
      - define cycle_count <[wolf].flag[cycle_count]||0>
      - define cycle_count <[cycle_count].add[1]>
      - flag <[wolf]> cycle_count:<[cycle_count]>

      # Only do home check every N cycles (every 2 minutes)
      - define home_check_cycles <script[guard_wolves_constants].data_key[home_check_cycles]>
      - if <[cycle_count]> >= <[home_check_cycles]>:
        - flag <[wolf]> cycle_count:0
        - if <[show_debug]>:
          - narrate "<gold>[HOME CHECK] Running home check..." targets:<[owner]>

        # If wolf is more than N blocks from home for 2+ minutes, teleport
        - define home_dist <script[guard_wolves_constants].data_key[home_check_distance]>
        - if <[distance]> > <[home_dist]>:
          # Wolf is away from home
          - if <[wolf].has_flag[away_from_home]>:
            - define time_away <util.time_now.duration_since[<[wolf].flag[away_from_home]>].in_seconds>
            - if <[show_debug]>:
              - narrate "<yellow>[HOME CHECK] Wolf away from home for <[time_away].round> seconds" targets:<[owner]>
            # If away for more than 2 minutes, teleport home
            - define home_tp_time <script[guard_wolves_constants].data_key[home_teleport_time]>
            - if <[time_away]> > <[home_tp_time]>:
              - if <[show_debug]>:
                - narrate "<red>[HOME CHECK] Wolf stuck away from home, teleporting!" targets:<[owner]>
              - walk <[wolf]> stop
              - teleport <[wolf]> <[center]>
              # Give invulnerability for 3 seconds after teleport
              - adjust <[wolf]> invulnerable:true
              - wait 3s
              - adjust <[wolf]> invulnerable:false
              - flag <[wolf]> away_from_home:!
              - foreach next
          - else:
            # Start away timer
            - flag <[wolf]> away_from_home:<util.time_now>
            - if <[show_debug]>:
              - narrate "<yellow>[HOME CHECK] Started away-from-home timer" targets:<[owner]>
        - else:
          # Wolf is home (within 3 blocks) - clear timer
          - if <[wolf].has_flag[away_from_home]>:
            - flag <[wolf]> away_from_home:!
            - if <[show_debug]>:
              - narrate "<green>[HOME CHECK] Wolf returned home, cleared timer" targets:<[owner]>

      # If wolf wandered too far, walk it back to center
      - define max_wander <script[guard_wolves_constants].data_key[max_wander_distance]>
      - if <[distance]> > <[max_wander]>:
        # Check if wolf has been trying to return for too long (stuck timer)
        - if <[wolf].has_flag[return_started]>:
          - define time_stuck <util.time_now.duration_since[<[wolf].flag[return_started]>].in_seconds>
          - if <[show_debug]>:
            - narrate "<yellow>[STUCK_TIMER] Wolf has been trying to return for <[time_stuck].round> seconds" targets:<[owner]>

          # If stuck for more than 1 minute, teleport
          - define stuck_tp_time <script[guard_wolves_constants].data_key[stuck_teleport_time]>
          - if <[time_stuck]> > <[stuck_tp_time]>:
            - if <[show_debug]>:
              - narrate "<red>[TELEPORT] Wolf stuck for 1+ minute, teleporting back!" targets:<[owner]>
            - walk <[wolf]> stop
            - teleport <[wolf]> <[center]>
            # Give invulnerability for 3 seconds after teleport to prevent fall/suffocation damage
            - adjust <[wolf]> invulnerable:true
            - wait 3s
            - adjust <[wolf]> invulnerable:false
            - flag <[wolf]> return_started:!
            - foreach next
        - else:
          # First time detecting wolf is out of range, start timer
          - flag <[wolf]> return_started:<util.time_now>
          - if <[show_debug]>:
            - narrate "<yellow>[STUCK_TIMER] Started return timer" targets:<[owner]>

        # Only issue walk command if wolf is NOT already moving back
        - if <[velocity]> < 0.1:
          - if <[show_debug]>:
            - narrate "<yellow>[RETURN] Wolf too far, walking back to guard center" targets:<[owner]>
          - walk <[wolf]> <[center]>
        - else:
          - if <[show_debug]>:
            - narrate "<gray>[SKIP] Wolf already moving (probably walking back)" targets:<[owner]>
        - foreach next
      - else:
        # Wolf is back in range - clear stuck timer if it exists
        - if <[wolf].has_flag[return_started]>:
          - flag <[wolf]> return_started:!
          - if <[show_debug]>:
            - narrate "<green>[STUCK_TIMER] Wolf returned successfully, cleared timer" targets:<[owner]>

      # Wolf is within range - let it idle naturally (no random walks)
      - if <[show_debug]>:
        - narrate "<green>[IDLE] Wolf is in range, idling naturally" targets:<[owner]>
