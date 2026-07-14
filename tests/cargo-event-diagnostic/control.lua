local rows = {}

local function cargo_names(pod)
  local inventory = pod.get_inventory(defines.inventory.cargo_unit)
  local names = {}
  if inventory then
    for index = 1, #inventory do
      local stack = inventory[index]
      if stack.valid_for_read then
        table.insert(names, stack.name .. "=" .. tostring(stack.count))
      end
    end
  end
  table.sort(names)
  return table.concat(names, ",")
end

script.on_init(function()
  local surface = game.surfaces.nauvis
  local pad = surface.create_entity({name = "cargo-landing-pad", force = "player", position = {0, 10}})
  local platform = game.forces.player.create_space_platform({
    name = "cargo-routing-diagnostic",
    planet = "nauvis",
    starter_pack = "space-platform-starter-pack"
  })
  local hub = platform.apply_starter_pack()
  hub.get_inventory(defines.inventory.hub_trash).insert({name = "wood", count = 1})
  pad.get_logistic_sections().sections[1].set_slot(1, {
    value = {type = "item", name = "space-platform-foundation", quality = "normal"},
    min = 10
  })
end)

script.on_event(defines.events.on_cargo_pod_started_ascending, function(event)
  local destination = event.cargo_pod.cargo_pod_destination
  table.insert(rows, table.concat({
    cargo_names(event.cargo_pod),
    "type=" .. tostring(destination.type),
    "station=" .. tostring(destination.station and destination.station.unit_number),
    "surface=" .. tostring(destination.surface and destination.surface.name or destination.surface),
    "position=" .. tostring(destination.position and (destination.position.x .. "," .. destination.position.y)),
    "transform=" .. tostring(destination.transform_launch_products),
    "player=" .. tostring(event.player_index),
    "pod=" .. tostring(event.cargo_pod.name)
  }, ";"))
  helpers.write_file("personal-cargo-landing-pad-cargo-event-diagnostic.txt", table.concat(rows, "\n"), false)
end)
