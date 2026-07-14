local routing = {}

function routing.target_surface(destination, station_destination_type, surface_destination_type, get_surface)
  if not destination then
    return nil
  end
  if destination.type == station_destination_type then
    local station = destination.station
    return station and station.valid and station.surface or nil
  end
  if destination.type ~= surface_destination_type or not destination.surface then
    return nil
  end
  local destination_surface = destination.surface
  if type(destination_surface) == "string" or type(destination_surface) == "number" then
    return get_surface(destination_surface)
  end
  -- Factorio 2.0 can provide LuaSurface directly for a surface destination.
  return destination_surface
end

function routing.requested_pad_owner(pad_owners, destination, station_destination_type)
  if not destination or destination.type ~= station_destination_type then
    return nil
  end
  local station = destination.station
  if not station or not station.valid or station.type ~= "cargo-landing-pad" or not station.unit_number then
    return nil
  end
  return pad_owners[station.unit_number]
end

function routing.choose_pad(platform_owners, pads, platform_index, surface_index, origin_force)
  local owner = platform_owners[platform_index]
  if not owner then
    return nil
  end
  local owner_pads = pads[owner]
  local record = owner_pads and owner_pads[surface_index] or nil
  local entity = record and record.entity or nil
  if not entity or not entity.valid or entity.force ~= origin_force then
    return nil
  end
  return entity, owner
end

function routing.station_destination(station, previous_destination, station_destination_type)
  if not station then
    return nil
  end
  return {
    type = station_destination_type,
    station = station,
    transform_launch_products = previous_destination.transform_launch_products or false
  }
end

return routing
