-- Weapons and armor. Enhancement level +N raises the main stat by 10% per
-- level (see statFor). Phase 4 adds forged gear and armor.

export type GearItem = {
	displayName: string,
	slot: string, -- "weapon" | "armor"
	tier: string,
	damage: number?,
	defense: number?, -- fraction of damage blocked, e.g. 0.1
	health: number?, -- extra max health
	color: Color3,
	order: number,
}

local Gear: { [string]: GearItem } = {
	WoodenSword = {
		displayName = "Wooden Sword",
		slot = "weapon",
		tier = "Common",
		damage = 10,
		color = Color3.fromRGB(160, 115, 70),
		order = 1,
	},
}

local MAX_LEVEL = 10

-- Damage (weapon) or health (armor) with enhancement applied.
local function statFor(id: string, level: number): number
	local item = Gear[id]
	if not item then
		return 0
	end
	local base = item.damage or item.health or 0
	return math.floor(base * (1 + 0.1 * math.clamp(level, 0, MAX_LEVEL)) + 0.5)
end

return {
	list = Gear,
	statFor = statFor,
	MAX_LEVEL = MAX_LEVEL,
}
