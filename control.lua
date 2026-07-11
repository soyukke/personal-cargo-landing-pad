local MOD_PREFIX = "personal-cargo-landing-pad"
local PAD_FRAME = MOD_PREFIX .. "-pad-frame"
local PLATFORM_FRAME = MOD_PREFIX .. "-platform-frame"
local CLAIM_PAD_BUTTON = MOD_PREFIX .. "-claim-pad"
local CLAIM_PLATFORM_BUTTON = MOD_PREFIX .. "-claim-platform"

local function ensure_storage()
  storage.personal_cargo_landing_pad = storage.personal_cargo_landing_pad or {}
  local state = storage.personal_cargo_landing_pad
  state.pads = state.pads or {}
  state.pad_owners = state.pad_owners or {}
  state.platform_owners = state.platform_owners or {}
end

local function state()
  ensure_storage()
  return storage.personal_cargo_landing_pad
end

local function player_surface_pads(player_index)
  local pads = state().pads
  pads[player_index] = pads[player_index] or {}
  return pads[player_index]
end

local function destroy_tag(record)
  if record and record.tag and record.tag.valid then
    record.tag.destroy()
  end
end

local function valid_pad_record(player_index, surface_index)
  local record = player_surface_pads(player_index)[surface_index]
  if record and record.entity and record.entity.valid then
    return record
  end
  if record then
    destroy_tag(record)
    player_surface_pads(player_index)[surface_index] = nil
  end
  return nil
end

local function owner_name(player_index)
  local player = game.get_player(player_index)
  return player and player.name or ("player " .. tostring(player_index))
end

local function clear_pad(entity)
  if not entity or not entity.unit_number then
    return
  end
  local owner = state().pad_owners[entity.unit_number]
  if not owner then
    return
  end
  local records = player_surface_pads(owner)
  local record = records[entity.surface.index]
  if record and record.entity == entity then
    destroy_tag(record)
    records[entity.surface.index] = nil
  end
  state().pad_owners[entity.unit_number] = nil
end

local function assign_pad(player, entity)
  if not player or not player.valid or not entity or not entity.valid then
    return false, {"personal-cargo-landing-pad.invalid-pad"}
  end
  if entity.type ~= "cargo-landing-pad" then
    return false, {"personal-cargo-landing-pad.not-pad"}
  end

  local existing = valid_pad_record(player.index, entity.surface.index)
  if existing and existing.entity ~= entity then
    return false, {"personal-cargo-landing-pad.pad-limit", entity.surface.name}
  end

  local previous_owner = state().pad_owners[entity.unit_number]
  if previous_owner and previous_owner ~= player.index and not player.admin then
    return false, {"personal-cargo-landing-pad.pad-owned", owner_name(previous_owner)}
  end
  if previous_owner and previous_owner ~= player.index then
    clear_pad(entity)
  end
  if existing and existing.entity == entity then
    destroy_tag(existing)
  end

  local record = {
    entity = entity,
    tag = player.force.add_chart_tag(entity.surface, {
      position = entity.position,
      icon = {type = "item", name = "cargo-landing-pad"},
      text = player.name .. " cargo"
    })
  }
  player_surface_pads(player.index)[entity.surface.index] = record
  state().pad_owners[entity.unit_number] = player.index
  return true
end

local function refund_rejected_pad(entity, player)
  local stack = {name = "cargo-landing-pad", count = 1}
  if entity.quality then
    stack.quality = entity.quality.name
  end
  if player and player.valid then
    local inserted = player.insert(stack)
    if inserted == 1 then
      entity.destroy()
      return
    end
  end
  entity.surface.spill_item_stack({
    position = entity.position,
    stack = stack,
    enable_looted = true,
    force = entity.force
  })
  entity.destroy()
end

local function register_built_pad(entity, player)
  if not entity or not entity.valid or entity.type ~= "cargo-landing-pad" then
    return
  end
  if not player then
    return
  end
  local ok, message = assign_pad(player, entity)
  if ok then
    player.print({"personal-cargo-landing-pad.pad-claimed", entity.surface.name})
  else
    player.print(message)
    refund_rejected_pad(entity, player)
  end
end

local function platform_for_player(player)
  if player.surface and player.surface.valid then
    return player.surface.platform
  end
  return nil
end

local function assign_platform(player, platform)
  if not player or not player.valid or not platform or not platform.valid then
    return false, {"personal-cargo-landing-pad.no-platform"}
  end
  local previous_owner = state().platform_owners[platform.index]
  if previous_owner and previous_owner ~= player.index and not player.admin then
    return false, {"personal-cargo-landing-pad.platform-owned", owner_name(previous_owner)}
  end
  state().platform_owners[platform.index] = player.index
  return true
end

local function relative_frame(player, name, relative_gui_type)
  if player.gui.relative[name] then
    player.gui.relative[name].destroy()
  end
  return player.gui.relative.add({
    type = "frame",
    name = name,
    direction = "vertical",
    anchor = {
      gui = relative_gui_type,
      position = defines.relative_gui_position.right
    }
  })
end

local function show_pad_frame(player, entity)
  local frame = relative_frame(player, PAD_FRAME, defines.relative_gui_type.cargo_landing_pad_gui)
  frame.add({type = "label", caption = {"personal-cargo-landing-pad.pad-title"}})
  local owner = entity.unit_number and state().pad_owners[entity.unit_number]
  frame.add({
    type = "label",
    caption = owner and {"personal-cargo-landing-pad.owner", owner_name(owner)}
      or {"personal-cargo-landing-pad.unowned"}
  })
  frame.add({type = "button", name = CLAIM_PAD_BUTTON, caption = {"personal-cargo-landing-pad.claim-pad"}})
end

local function show_platform_frame(player, platform)
  local frame = relative_frame(player, PLATFORM_FRAME, defines.relative_gui_type.space_platform_hub_gui)
  frame.add({type = "label", caption = {"personal-cargo-landing-pad.platform-title"}})
  local owner = platform and state().platform_owners[platform.index]
  frame.add({
    type = "label",
    caption = owner and {"personal-cargo-landing-pad.owner", owner_name(owner)}
      or {"personal-cargo-landing-pad.unowned"}
  })
  frame.add({type = "button", name = CLAIM_PLATFORM_BUTTON, caption = {"personal-cargo-landing-pad.claim-platform"}})
end

local function target_surface(destination)
  if not destination then
    return nil
  end
  if destination.type == defines.cargo_destination.station then
    local station = destination.station
    return station and station.valid and station.surface or nil
  end
  if destination.type == defines.cargo_destination.surface and destination.surface then
    return game.get_surface(destination.surface)
  end
  return nil
end

local function route_cargo_pod(cargo_pod)
  if not cargo_pod or not cargo_pod.valid then
    return
  end
  local origin = cargo_pod.cargo_pod_origin
  if not origin or not origin.valid or origin.type ~= "space-platform-hub" then
    return
  end
  local platform = origin.surface.platform
  if not platform or not platform.valid then
    return
  end
  local owner = state().platform_owners[platform.index]
  if not owner then
    return
  end

  local destination = cargo_pod.cargo_pod_destination
  local surface = target_surface(destination)
  if not surface then
    return
  end
  local record = valid_pad_record(owner, surface.index)
  if not record or record.entity.force ~= origin.force then
    return
  end

  cargo_pod.cargo_pod_destination = {
    type = defines.cargo_destination.station,
    station = record.entity,
    transform_launch_products = destination.transform_launch_products or false
  }
end

local function claim_opened_pad(player)
  local entity = player.opened
  if not entity or not entity.valid or entity.type ~= "cargo-landing-pad" then
    player.print({"personal-cargo-landing-pad.open-pad-first"})
    return
  end
  local ok, message = assign_pad(player, entity)
  if ok then
    player.print({"personal-cargo-landing-pad.pad-claimed", entity.surface.name})
    show_pad_frame(player, entity)
  else
    player.print(message)
  end
end

local function claim_current_platform(player)
  local platform = platform_for_player(player)
  local ok, message = assign_platform(player, platform)
  if ok then
    player.print({"personal-cargo-landing-pad.platform-claimed", platform.name})
    if player.opened and player.opened.valid and player.opened.type == "space-platform-hub" then
      show_platform_frame(player, platform)
    end
  else
    player.print(message)
  end
end

script.on_init(ensure_storage)
script.on_configuration_changed(ensure_storage)

script.on_event(defines.events.on_built_entity, function(event)
  register_built_pad(event.entity, event.player_index and game.get_player(event.player_index) or nil)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
  local player = event.entity and event.entity.valid and event.entity.last_user or nil
  register_built_pad(event.entity, player)
end)

script.on_event(defines.events.on_player_mined_entity, function(event)
  if event.entity and event.entity.type == "cargo-landing-pad" then
    clear_pad(event.entity)
  end
end)

script.on_event(defines.events.on_robot_mined_entity, function(event)
  if event.entity and event.entity.type == "cargo-landing-pad" then
    clear_pad(event.entity)
  end
end)

script.on_event(defines.events.on_entity_died, function(event)
  if event.entity and event.entity.type == "cargo-landing-pad" then
    clear_pad(event.entity)
  end
end)

script.on_event(defines.events.on_cargo_pod_started_ascending, function(event)
  route_cargo_pod(event.cargo_pod)
end)

script.on_event(defines.events.on_gui_opened, function(event)
  local player = game.get_player(event.player_index)
  local entity = event.entity
  if not player or not entity or not entity.valid then
    return
  end
  if entity.type == "cargo-landing-pad" then
    show_pad_frame(player, entity)
  elseif entity.type == "space-platform-hub" then
    show_platform_frame(player, entity.surface.platform)
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end
  if player.gui.relative[PAD_FRAME] then
    player.gui.relative[PAD_FRAME].destroy()
  end
  if player.gui.relative[PLATFORM_FRAME] then
    player.gui.relative[PLATFORM_FRAME].destroy()
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local player = game.get_player(event.player_index)
  if not player or not event.element or not event.element.valid then
    return
  end
  if event.element.name == CLAIM_PAD_BUTTON then
    claim_opened_pad(player)
  elseif event.element.name == CLAIM_PLATFORM_BUTTON then
    claim_current_platform(player)
  end
end)

commands.add_command("claim-cargo-pad", {"personal-cargo-landing-pad.command-pad-help"}, function(command)
  local player = command.player_index and game.get_player(command.player_index) or nil
  if player then
    claim_opened_pad(player)
  end
end)

commands.add_command("claim-platform", {"personal-cargo-landing-pad.command-platform-help"}, function(command)
  local player = command.player_index and game.get_player(command.player_index) or nil
  if player then
    claim_current_platform(player)
  end
end)
