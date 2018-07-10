local tex = function(n) return "sponge_"..n..".png" end

local node_wet = "sponge:wet"



-- configuration setup
local drain_radius
local msg = "bad configuration: "
local s = minetest.settings:get("ds2.minetest.sponge.drain_radius")
if s == nil then
	-- default value
	drain_radius = 2
else
	local v = tonumber(s)
	assert(v ~= nil, msg.."drain_radius was not a valid numerical value: "..s)
	-- allow it to be zero to disable the node
	assert(v >= 0, msg.."drain_radius must be positive: "..v)
	assert((v % 1.0) == 0, msg.."drain_radius must be an integer: "..v)
	drain_radius = v
end
local r = drain_radius
local rw = function(v) return (v * 2) + 1 end
local cube = function(v) return v*v*v end
-- sanity checking to ensure water value can fit inside 8-bit param2.
-- we store it as (water - 1) as we have a separate block for dry.
-- additionally, the center of the area (the sponge itself) can never be water.
assert((cube(rw(r)) - 2) <= 255, "selected radius total volume doesn't fit into param2")



-- placement and removal logic
local p = {}
local air = { name = "air" }
local try_drain = function(x, y, z)
	p.x = x
	p.y = y
	p.z = z
	local node = minetest.get_node(p)
	local is_water = (node.name == "default:water_source")
	if is_water then
		minetest.set_node(p, air)
	end
	return is_water
end

local replace = { name = node_wet }
local on_construct = function(pos)
	local xc, yc, zc = pos.x, pos.y, pos.z
	local count = 0
	-- rip indentation
	for z = zc - r, zc + r, 1 do
	for y = yc - r, yc + r, 1 do
	for x = xc - r, xc + r, 1 do
		-- oh look, a convienient table
		if try_drain(x, y, z) then
			count = count + 1
		end
	end
	end
	end

	-- shouldn't be possible here, but guard anyway
	assert(count < 256)
	if count > 0 then
		replace.param2 = count - 1
		minetest.set_node(pos, replace)
	end
end



-- registration of nodes

-- I don't really know what groups would be appropriate for a spongy block
-- (that would be compatible with existing tools).
local groups = {
	oddly_breakable_by_hand = 3,
}

-- explicitly disable water absorption behaviour if drain_radius is zero.
local enable = (drain_radius ~= 0)
local ifdrain = function(v)
	return enable and v or nil
end

minetest.register_node("sponge:dry", {
	description = "Dry sponge",
	tiles = { tex("dry") },
	groups = groups,
	on_construct = ifdrain(on_construct),
})
minetest.register_node(node_wet, {
	description = "Wet sponge block (HACKERRRRR)",
	tiles = { tex("wet") },
	groups = groups,
})
