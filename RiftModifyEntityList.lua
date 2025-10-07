local riftedSchema = require "Rifted.RiftedSchema"
local riftedFieldType = require "Rifted.RiftedFieldType"
local enum = require "system.utils.Enum"

riftedFieldType.Counterpart.extend( "DLC_1", enum.entry(17, { id = "Apricot",  name = L("Meatboy",  "char.apricot")  , visible = true } )   )
riftedFieldType.Counterpart.extend( "DLC_2", enum.entry(18, { id = "Banana",  name = L("Madeline",  "char.banana")  , visible = true } )   )
riftedFieldType.Counterpart.extend( "DLC_3", enum.entry(19, { id = "Banana02",  name = L("Badeline",  "char.banana02")  , visible = true } )   )
riftedFieldType.Counterpart.extend( "DLC_4", enum.entry(19, { id = "Cherry",  name = L("Peppino",  "char.chery")  , visible = true } )   )


local function create_spawn_enemy( selID, enemyId, internalId, friendlyName, spritePath, facing )
	local brushdata = {}

	local brush = {}
	brush.attr = {}
	brush.attr.Rifted_object = {}

	local data = {}
	data.audioEvents = {}
	data.data = {}
	data.group = 0
	data.length = 1
	data.parameters = {}
	data.parameters.EnemyId = enemyId
	data.parameters.ShouldStartFacingRight = facing

	if internalId == 7288 then
		data.parameters.BlademasterAttackRow = 4
	end

	data.start = 0
	data.track = 2
	data.type = "SpawnEnemy"

	brush.attr.Rifted_object.data = data
	brush.cmd = 2
	brush.selID = selID
	brush.type = "Rifted_Object"

	brushdata.internalName = internalId
	brushdata.name = friendlyName
	brushdata.visId = enemyId
	brushdata.visualOverride = {}
	brushdata.visualOverride.rect = {0,0,24,24}
	if facing then
		brushdata.visualOverride.texRect = {128,0,-128,128}
	else
		brushdata.visualOverride.texRect = {0,0,128,128}
	end
	brushdata.visualOverride.texture = "mods/Rifted/gfx/rift/" .. spritePath
	brushdata.visualOverride.z = 0

	brushdata.brush = brush

	return brushdata
end

local function create_trap( selID, trapID, friendlyName, spritePath, colour, intcolour )
	local brushdata = create_spawn_enemy( selID, trapID, -1, friendlyName, spritePath, false)

	local parameters = {}
    parameters.TrapChildSpawnRow = 1
    parameters.TrapColor = intcolour
    parameters.TrapDropRow = 2
    parameters.TrapHealthInBeats = 2
    parameters.TrapTypeToSpawn = "PortalOut"

    brushdata.brush.attr.Rifted_object.data.parameters = parameters
    brushdata.brush.attr.Rifted_object.data.type = "SpawnTrap"

    brushdata.visualOverride.texRect = {0,0,512,512}
    brushdata.visualOverride.color = colour
    brushdata.internalName = "SpawnTrap"
    return brushdata
end

local function test()
	print( "test" )
end

event.Rifted_categoryInit.add("riftutil", "rift", function (ev)

	ev.result[1].brushes[ #ev.result[1].brushes+1 ] = create_spawn_enemy( "Rifted_E1235R", "Rifted_E1235", 1235, "Blue Zombie", "Monster_Zombie_Blue_00.png", true )
	ev.result[1].brushes[ #ev.result[1].brushes+1 ] = create_spawn_enemy( "Rifted_E1235L", "Rifted_E1235", 1235, "Blue Zombie", "Monster_Zombie_Blue_00.png", false )
	
	ev.result[1].brushes[ #ev.result[1].brushes+1 ] = create_spawn_enemy( "Rifted_E7288R", "Rifted_E7288", 7288, "Yellow Blademaster", "RR_Monster_Blademaster_gold_idle_00.png", true )
	ev.result[1].brushes[ #ev.result[1].brushes+1 ] = create_spawn_enemy( "Rifted_E7288L", "Rifted_E7288", 7288, "Yellow Blademaster", "RR_Monster_Blademaster_gold_idle_00.png", false )

	ev.result[1].brushes[ #ev.result[1].brushes+1 ] = create_spawn_enemy( "Rifted_E8079R", "Rifted_E8079", 8079, "Wyrm Body", "RR_Monster_Wyrm_Middle_Body.png", true )
	ev.result[1].brushes[ #ev.result[1].brushes+1 ] = create_spawn_enemy( "Rifted_E8079L", "Rifted_E8079", 8079, "Wyrm Body", "RR_Monster_Wyrm_Middle_Body.png", false )

	ev.result[1].brushes[ #ev.result[1].brushes+1 ] = create_spawn_enemy( "Rifted_E9888R", "Rifted_E9888", 9888, "Wyrm Body", "RR_Monster_Wyrm_Middle_Tail.png", true )
	ev.result[1].brushes[ #ev.result[1].brushes+1 ] = create_spawn_enemy( "Rifted_E9888L", "Rifted_E9888", 9888, "Wyrm Body", "RR_Monster_Wyrm_Middle_Tail.png", false )

	ev.result[3].brushes[ #ev.result[3].brushes+1 ] = create_trap( "TPortalOutR_0", "PortalOut", "Portal Exit", "trap/RR_Trap_Portal_Crack_Base.png", -30686, 0 )
	ev.result[3].brushes[ #ev.result[3].brushes+1 ] = create_trap( "TPortalOutR_1", "PortalOut", "Portal Exit", "trap/RR_Trap_Portal_Crack_Base.png", -7799006, 1 )
	ev.result[3].brushes[ #ev.result[3].brushes+1 ] = create_trap( "TPortalOutR_2", "PortalOut", "Portal Exit", "trap/RR_Trap_Portal_Crack_Base.png", -7855361, 2 )
	ev.result[3].brushes[ #ev.result[3].brushes+1 ] = create_trap( "TPortalOutR_3", "PortalOut", "Portal Exit", "trap/RR_Trap_Portal_Crack_Base.png", -256, 3 )
	ev.result[3].brushes[ #ev.result[3].brushes+1 ] = create_trap( "TPortalOutR_4", "PortalOut", "Portal Exit", "trap/RR_Trap_Portal_Crack_Base.png", -65281, 4 )
	ev.result[3].brushes[ #ev.result[3].brushes+1 ] = create_trap( "TPortalOutR_5", "PortalOut", "Portal Exit", "trap/RR_Trap_Portal_Crack_Base.png", -16711681, 5 )
end)




--[[
	Rifted_E1722    = color.hex(0x17FFA4), -- Green Slime
	Rifted_E4355    = color.hex(0x4DBEFF), -- Blue Slime
	Rifted_E9189    = color.hex(0xFEF214), -- Yellow Slime
	Rifted_E8675309 = color.hex(0xC8C6C5), -- Blue Bat
	Rifted_E717     = color.hex(0xBFC0C3), -- Yellow Bat
	Rifted_E911     = color.hex(0xBFC2C2), -- Red Bat
	Rifted_E1234    = color.hex(0x00FF9E), -- Green Zombie
	Rifted_E1235    = color.hex(0x59C1FF), -- Blue Zombie
	Rifted_E1236    = color.hex(0xF9487A), -- Red Zombie
	Rifted_E2202    = color.hex(0x8886A7), -- Base Skeleton
	Rifted_E1911    = color.hex(0x4FFF00), -- Shielded Base Skeleton
	Rifted_E6471    = color.hex(0x2BB800), -- Triple Shield Base Skeleton
	Rifted_E7831    = color.hex(0x3291FF), -- Blue Armadillo
	Rifted_E1707    = color.hex(0xCF2B32), -- Red Armadillo
	Rifted_E6311    = color.hex(0xFEBD13), -- Yellow Armadillo
	Rifted_E6803    = color.hex(0xB5740E), -- Yellow Skeleton
	Rifted_E4871    = color.hex(0x25AD00), -- Shielded Yellow Skeleton
	Rifted_E2716    = color.hex(0xDD6481), -- Black Skeleton
	Rifted_E3307    = color.hex(0x25AD00), -- Shielded Black Skeleton
	Rifted_E7794    = color.hex(0x16FFA4), -- Base Wyrm
	Rifted_E8079    = color.hex(0x16FFA4), -- Base Wyrm Body
	Rifted_E9888    = color.hex(0xD4BF99), -- Base Wyrm Tail
	Rifted_E8519    = color.hex(0x88F788), -- Base Harpy
	Rifted_E3826    = color.hex(0xE68888), -- Red Harpy
	Rifted_E8156    = color.hex(0x8888FF), -- Blue Harpy
	Rifted_E7358    = color.hex(0xFF3503), -- Apple
	Rifted_E2054    = color.hex(0xF88C24), -- Cheese
	Rifted_E1817    = color.hex(0xB12C09), -- Drumstick
	Rifted_E3211    = color.hex(0xBE7D90), -- Ham
	Rifted_E929     = color.hex(0x2288DA), -- Base Blademaster
	Rifted_E3685    = color.hex(0x3366FF), -- Strong Blademaster
	Rifted_E7288    = color.hex(0xFF8F1F), -- Yellow Blademaster
	Rifted_E4601    = color.hex(0xFFFFFF), -- Base Skull
	Rifted_E3543    = color.hex(0x4DBEFF), -- Blue Skull
	Rifted_E7685    = color.hex(0xF64778), -- Red Skull
	TCoals          = color.hex(0xE14126), -- Hot Coals
	TBounce         = color.hex(0xF37100), -- Bounce Trap
	TPortalIn       = color.hex(0xFFFFFF), -- Portal entrance
	TPortalOut      = color.hex(0xFFFFFF), -- Portal exit
	VibeChain       = color.hex(0xFFFF00), -- Vibe chain
	AdjustBPM       = color.hex(0xEC035A), -- BPM change
	AnimTrigger     = color.hex(0xFFFFFF), -- Animation trigger
]]--