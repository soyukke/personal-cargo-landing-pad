local routing = {}

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
