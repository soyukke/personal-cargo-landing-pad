local routing = require("__personal-cargo-landing-pad__/routing")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or "values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

script.on_init(function()
  local player_force = {name = "player"}
  local enemy_force = {name = "enemy"}
  local alice_pad = {valid = true, force = player_force, unit_number = 101}
  local bob_pad = {valid = true, force = player_force, unit_number = 102}
  local invalid_pad = {valid = false, force = player_force, unit_number = 103}
  local platform_owners = {[11] = 1, [22] = 2, [33] = 3}
  local pads = {
    [1] = {[5] = {entity = alice_pad}},
    [2] = {[5] = {entity = bob_pad}},
    [3] = {[5] = {entity = invalid_pad}}
  }

  local selected, owner = routing.choose_pad(platform_owners, pads, 11, 5, player_force)
  assert_equal(selected, alice_pad, "Alice platform routes to Alice pad")
  assert_equal(owner, 1, "Alice remains the route owner")

  selected = routing.choose_pad(platform_owners, pads, 22, 5, player_force)
  assert_equal(selected, bob_pad, "Bob platform routes to Bob pad")
  assert_equal(routing.choose_pad(platform_owners, pads, 99, 5, player_force), nil, "Unowned platform falls back")
  assert_equal(routing.choose_pad(platform_owners, pads, 11, 6, player_force), nil, "Missing surface pad falls back")
  assert_equal(routing.choose_pad(platform_owners, pads, 11, 5, enemy_force), nil, "Wrong force pad is rejected")
  assert_equal(routing.choose_pad(platform_owners, pads, 33, 5, player_force), nil, "Invalid pad is rejected")

  local destination = routing.station_destination(alice_pad, {transform_launch_products = true}, 7)
  assert_equal(destination.type, 7, "Station destination type is preserved")
  assert_equal(destination.station, alice_pad, "Selected pad becomes the station")
  assert_equal(destination.transform_launch_products, true, "Product transformation flag is preserved")

  helpers.write_file("personal-cargo-landing-pad-routing-test.txt", "PASS", false)
end)
