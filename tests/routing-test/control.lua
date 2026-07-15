local routing = require("__personal-cargo-landing-pad__/routing")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

script.on_init(function()
  local player_force = {name = "player"}
  local enemy_force = {name = "enemy"}
  local alice_pad = {valid = true, force = player_force, type = "cargo-landing-pad", unit_number = 101}
  local bob_pad = {valid = true, force = player_force, type = "cargo-landing-pad", unit_number = 102}
  local invalid_pad = {valid = false, force = player_force, unit_number = 103}
  local platform_owners = {[11] = 1, [22] = 2, [33] = 3}
  local pads = {
    [1] = {[5] = {entity = alice_pad}},
    [2] = {[5] = {entity = bob_pad}},
    [3] = {[5] = {entity = invalid_pad}}
  }

  local vulcanus = {valid = true, index = 5, name = "vulcanus"}
  local resolved = routing.target_surface({type = 8, surface = vulcanus}, 7, 8, function()
    error("LuaSurface must not be passed to game.get_surface")
  end)
  assert_equal(resolved, vulcanus, "A LuaSurface destination is used directly")

  resolved = routing.target_surface({type = 8, surface = "vulcanus"}, 7, 8, function(identifier)
    assert_equal(identifier, "vulcanus", "Surface name is passed to the resolver")
    return vulcanus
  end)
  assert_equal(resolved, vulcanus, "A named surface destination is resolved")

  resolved = routing.target_surface({type = 7, station = {valid = true, surface = vulcanus}}, 7, 8, function()
    error("A station surface must not be passed to game.get_surface")
  end)
  assert_equal(resolved, vulcanus, "A station destination uses its station surface")

  local selected, owner = routing.choose_pad(platform_owners, pads, 11, 5, player_force)
  assert_equal(selected, alice_pad, "Alice platform routes to Alice pad")
  assert_equal(owner, 1, "Alice remains the route owner")

  selected = routing.choose_pad(platform_owners, pads, 22, 5, player_force)
  assert_equal(selected, bob_pad, "Bob platform routes to Bob pad")
  assert_equal(routing.choose_pad(platform_owners, pads, 99, 5, player_force), nil, "Unowned platform falls back")
  assert_equal(routing.choose_pad(platform_owners, pads, 11, 6, player_force), nil, "Missing surface pad falls back")
  assert_equal(routing.choose_pad(platform_owners, pads, 11, 5, enemy_force), nil, "Wrong force pad is rejected")
  assert_equal(routing.choose_pad(platform_owners, pads, 33, 5, player_force), nil, "Invalid pad is rejected")

  local pad_owners = {[101] = 1, [102] = 2}
  assert_equal(
    routing.requested_pad_owner(pad_owners, {type = 7, station = alice_pad}, 7),
    1,
    "An explicit request remains assigned to Alice's pad"
  )
  assert_equal(
    routing.requested_pad_owner(pad_owners, {type = 7, station = bob_pad}, 7),
    2,
    "An explicit request remains assigned to Bob's pad"
  )
  assert_equal(
    routing.requested_pad_owner(pad_owners, {type = 8, station = alice_pad}, 7),
    nil,
    "A surface destination can still be routed by platform owner"
  )
  assert_equal(
    routing.requested_pad_owner(pad_owners, {type = 7, station = {valid = true, type = "space-platform-hub"}}, 7),
    nil,
    "A platform hub is not treated as a landing pad request"
  )
  assert_equal(
    routing.matches_requested_item({["space-platform-foundation"] = true}, {["space-platform-foundation"] = true}),
    true,
    "An automatically requested item is recognized"
  )
  assert_equal(
    routing.matches_requested_item({wood = true}, {["space-platform-foundation"] = true}),
    false,
    "A manual trash drop is not mistaken for a landing pad request"
  )

  -- Regression: Factorio may initially select Bob's pad for Alice's player pod.
  -- The rider must take priority over both that station and the platform owner.
  local route_owner, preserve = routing.route_owner(1, 2, 1)
  assert_equal(route_owner, 1, "Alice riding the pod routes to Alice's pad")
  assert_equal(preserve, false, "Bob's preselected pad is overridden for Alice")
  assert_equal(
    routing.choose_pad_for_owner(pads, route_owner, 5, player_force),
    alice_pad,
    "Alice lands at Alice's owned pad"
  )

  route_owner, preserve = routing.route_owner(nil, 2, 1)
  assert_equal(route_owner, 1, "Alice's platform keeps cargo away from Bob's requesting pad")
  assert_equal(preserve, false, "A claimed platform overrides another player's request")

  route_owner, preserve = routing.route_owner(nil, 1, 2)
  assert_equal(route_owner, 2, "Cetusk's platform keeps cargo away from Soyukke's requesting pad")
  assert_equal(preserve, false, "Soyukke cannot take cargo from Cetusk's platform")

  route_owner, preserve = routing.route_owner(nil, 2, nil)
  assert_equal(route_owner, 2, "An unclaimed platform can still fulfill Bob's request")
  assert_equal(preserve, true, "An unclaimed platform preserves an explicit request")

  route_owner, preserve = routing.route_owner(nil, nil, 1)
  assert_equal(route_owner, 1, "An unaddressed cargo drop uses the platform owner")
  assert_equal(preserve, false, "An unaddressed cargo drop is routed")

  local destination = routing.station_destination(alice_pad, {transform_launch_products = true}, 7)
  assert_equal(destination.type, 7, "Station destination type is preserved")
  assert_equal(destination.station, alice_pad, "Selected pad becomes the station")
  assert_equal(destination.transform_launch_products, true, "Product transformation flag is preserved")

  helpers.write_file("personal-cargo-landing-pad-routing-test.txt", "PASS", false)
end)
