# NPCDB — static NPC definitions, dialogue trees, recruitable roster
class_name NPCDB

static func all_npcs() -> Dictionary:
	return {
		"weapon_merchant": {
			"name": "Greta Ironforge",
			"faction": "keepers",
			"color": Color("c0392b"),
			"topics": [
				{"label": "Browse Weapons", "key": "shop"},
				{"label": "Guild News", "key": "guild_news", "lore": [
					"The Keepers Guild has guarded the Lantern Line for generations. But lately, fewer young folk answer the call.",
					"Old Thatch says the Guild was founded by the first lighthouse keeper — a woman named Briar, centuries ago.",
					"Keeper Mara used to bring me ore from the mountain passes. I haven't seen her in weeks...",
				]},
				{"label": "Equipment Tips", "key": "equip_tips", "lore": [
					"Stronger steel means stronger strikes. Don't neglect your weapon upgrades.",
					"A good blade in the right hands is worth more than armor on a fool.",
					"If you're heading into the mountains, bring a blade that can cut through rock-hide.",
				]},
			],
			"dialogue": {
				"default": [
					"Steel keeps the darkness at bay. Need a new blade?",
					"The Keeper forges are running low on ore. Dangerous times.",
				],
				"beacon_lit": [
					"Ah, you've been lighting beacons! I can feel the forge burning hotter already.",
				],
				"boss_defeated": [
					"You defeated the shade in the cave?! The steel holds strong — just like my blades.",
				],
				"act2": [
					"Shadow wisps in the forest? My blades are ready. The forge burns day and night.",
					"The factions are squabbling over oil while shadows creep through the trees. Typical.",
				],
				"endgame": [
					"Whatever's beneath the mountain, I've forged blades for the occasion. The strongest steel yet.",
				],
				"low_gold": [
					"Come back when your purse is heavier. These blades don't forge themselves.",
				],
				"honored": [
					"A true friend of the Keepers! I've set aside our finest steel for you.",
				],
				"distrusted": [
					"You're no friend of the Guild. Blades will cost you extra.",
				],
			},
		},
		"armor_merchant": {
			"name": "Bram Stonecoat",
			"faction": "harbor",
			"color": Color("2980b9"),
			"topics": [
				{"label": "Browse Armor", "key": "shop"},
				{"label": "Harbor News", "key": "harbor_news", "lore": [
					"The Compact's ships bring ore from the mainland — when the fog lets them through.",
					"Captain Drel runs the harbor. Tough woman. She doesn't trust anyone who hasn't earned it.",
					"Trade routes have been opening up since the beacons started burning.",
				]},
				{"label": "Material Talk", "key": "material_talk", "lore": [
					"Chain links stop blades, leather stops claws. Know your enemy before you gear up.",
					"Iron's common, but steel needs the Compact's forges. That's why good armor costs what it does.",
					"The mountain caves have deposits of something harder than steel. The Golems are made of it.",
				]},
			],
			"dialogue": {
				"default": [
					"Leather or chain — either is better than bare skin in these woods.",
					"The Harbor Compact ships my materials. Reliable folk.",
				],
				"beacon_lit": [
					"Safe roads mean cheaper shipments. Keep those beacons lit!",
				],
				"boss_defeated": [
					"The fog's lifting! Ships are arriving with fresh materials. Business is booming.",
				],
				"act2": [
					"The oil dispute is bad for business. Compact ships carry my materials — if they stop sailing, I stop crafting.",
					"Chainmail won't protect you from what's really coming. But it's a start.",
				],
				"endgame": [
					"I've heard the rumors. Something ancient beneath the mountain. I'm forging my best armor yet — for you.",
				],
				"honored": [
					"The Compact speaks highly of you. I'll see what I can do on pricing.",
				],
				"distrusted": [
					"The Harbor Compact doesn't forget. You'll pay full price — maybe more.",
				],
			},
		},
		"innkeeper": {
			"name": "Maren Willow",
			"faction": "chapel",
			"color": Color("27ae60"),
			"topics": [
				{"label": "Rest & Heal", "key": "heal"},
				{"label": "Cook Fish", "key": "cook"},
				{"label": "Chapel Teachings", "key": "chapel_teachings", "lore": [
					"The Grey Chapel teaches that light is not just fire — it is memory. Every beacon preserves something.",
					"Sister Aldith says the Chapel was here before the village. Before the lighthouse, even.",
					"We keep candles burning at all hours. The darkness is patient, but so are we.",
				]},
				{"label": "Traveler News", "key": "traveler_news", "lore": [
					"A merchant from the mainland says the fog is spreading beyond this island. Troubling news.",
					"Folk say the Unlit village to the west has its own ways of dealing with the darkness.",
					"The fishing boats have been bringing up strange things from the deep lately.",
				]},
			],
			"dialogue": {
				"default": [
					"Rest well, traveler. The Grey Chapel watches over all who sleep beneath this roof.",
					"Another soul arrived from the mainland yesterday. These are strange times.",
				],
				"beacon_lit": [
					"The light from the beacons is visible from my window. It gives people hope.",
				],
				"boss_defeated": [
					"Rest well, hero. You've driven the darkness from the cave. The whole island sleeps easier.",
				],
				"act2": [
					"Strange dreams plague the island since the seal broke. The Chapel says it's nothing, but I'm not so sure.",
					"Travelers report shadows that move against the wind. Rest here — you'll need your strength.",
				],
				"endgame": [
					"Whatever choice you make down there... this inn will always have a room for you.",
				],
				"honored": [
					"Rest easy, honored one. The Chapel's blessings are yours tonight.",
				],
				"distrusted": [
					"The Chapel watches all. Even those who have strayed from the light.",
				],
			},
		},
		"elder": {
			"name": "Old Thatch",
			"faction": "none",
			"color": Color("9b59b6"),
			"topics": [
				{"label": "Quests", "key": "quest"},
				{"label": "Island History", "key": "island_history", "lore": [
					"This island was called Thornefell, once. Before the fog, before the Shade. People came here for the fishing and the copper mines.",
					"The first Keepers built the Lantern Line three hundred years ago. They said the light would hold back 'that which crawls in the dark.'",
					"Brindlewick was named after a trader named Brin who built the first dock. His lighthouse still stands — though it's dark now.",
				]},
				{"label": "The Lantern Line", "key": "lantern_line", "lore": [
					"Five beacons form the Line — lighthouse, north forest, hill overlook, south shore, and west point. Each one a link in the chain.",
					"The Line needs special oil to burn. The Harbor Compact sells it, but it's expensive. There may be other sources.",
					"When all five beacons burn together, the seal on the mountain cave breaks. What's inside... I'm not sure I want to say.",
				]},
				{"label": "Advice", "key": "advice", "lore": [
					"Don't venture too far from lit beacons at night. The creatures grow bolder in the dark.",
					"The forest clearing has useful herbs, if you know what to look for. The hermit there can teach you.",
					"A well-equipped party survives longer than a strong one. Visit the merchants before any expedition.",
				]},
			],
			"dialogue": {
				"default": [
					"Beware the forest to the north. The mountain cave holds great treasure — and great danger.",
					"I've lived on this island for sixty years. The fog was not always this thick.",
					"The Lantern Line was built by the first Keepers. Each beacon is a link in the chain that holds back... something.",
				],
				"beacon_lit": [
					"You've begun restoring the Line. The island remembers, even if the people have forgotten.",
				],
				"boss_defeated": [
					"You've done what no Keeper could — the Lantern Line burns brighter than ever. Brindlewick owes you everything.",
				],
				"act2": [
					"The seal is broken. Something stirs beneath the mountain that the first Keepers tried to contain. We must understand what we face.",
					"The factions squabble while the island trembles. We need answers, not arguments.",
				],
				"endgame": [
					"You've uncovered the truth of the Line. The choice that remains is the hardest one of all. I cannot make it for you.",
				],
			},
		},
		"tavern_keeper": {
			"name": "Rolf Deepbarrel",
			"faction": "harbor",
			"color": Color("8b6914"),
			"topics": [
				{"label": "Recruit Companions", "key": "recruit"},
				{"label": "Exchange Currency", "key": "exchange"},
				{"label": "Rumors", "key": "rumors", "lore": [
					"Heard the Unlit have been seen near the west beacon at night. They don't come this far east usually.",
					"Someone said they found an old journal in the forest, half-buried. Keeper Mara's, maybe.",
					"The cave sealed up tight centuries ago. But when all the beacons burn... well, the old stories say it opens.",
					"Folk in the harbor are nervous. Ships are avoiding our waters. Captain Drel is losing patience.",
				]},
				{"label": "Compact Business", "key": "compact_news", "lore": [
					"The Harbor Compact controls all trade on this island. Copper, goods, even property — it all flows through them.",
					"Compact membership has its perks. Better exchange rates, first pick of imports. But you have to earn their trust.",
					"Rumor is the Compact has a secret agreement with the Keepers Guild. Something about the beacon oil.",
				]},
			],
			"dialogue": {
				"default": [
					"Pull up a chair! Ale's two copper, stories are free.",
					"Heard there's work for hirelings if you're building a crew.",
				],
				"beacon_lit": [
					"Trade's picking up with the beacons lit. More ships docking, more coin flowing.",
				],
				"boss_defeated": [
					"Drinks are on the house tonight! You killed the shade! Songs will be written about this!",
				],
				"act2": [
					"Heard the Unlit are moving east. And shadows in the forest? Troubling times for bar gossip.",
					"The oil dispute between the Compact and the Keepers? Bad for ale prices. Bad for everyone.",
				],
				"endgame": [
					"End of the line, hero. Whatever's down there... I'll keep the ale cold. Come back alive.",
				],
				"honored": [
					"You're good people with the Compact. First round's on the house — well, discounted.",
				],
				"distrusted": [
					"Don't cause trouble. The Compact has eyes everywhere.",
				],
			},
		},
		"realtor": {
			"name": "Hale Thorngate",
			"faction": "harbor",
			"color": Color("e67e22"),
			"topics": [
				{"label": "Properties & Upgrades", "key": "realtor"},
				{"label": "Market Report", "key": "market_report", "lore": [
					"Property values rise with every beacon lit. It's simple economics — light brings safety, safety brings demand.",
					"The market fluctuates, but long-term, island real estate only goes up. If the fog ever clears fully, prices will triple.",
					"Tax rates depend on how many beacons are lit beyond the first. The Crown takes its cut, I'm afraid.",
				]},
			],
			"dialogue": {
				"default": [
					"Looking for a place of your own? Property values rise with every beacon lit.",
					"The Harbor Compact handles all property sales on the island. Trust me, I know every plot.",
				],
				"beacon_lit": [
					"Beacon light drives property values up! Great time to buy — if you can afford it.",
				],
				"boss_defeated": [
					"Property values are through the roof! The fog's clearing and everyone wants to live here now!",
				],
				"act2": [
					"The market's volatile — shadow wisps and faction feuds are scaring investors. But for a savvy buyer, that means opportunity.",
				],
				"endgame": [
					"Whatever happens beneath the mountain, property values will either soar or crash. Place your bets.",
				],
				"honored": [
					"For a friend of the Compact, I might be able to offer a better deal.",
				],
				"distrusted": [
					"The Compact has eyes on you. I can still sell, but don't expect favors.",
				],
			},
		},
		"healer": {
			"name": "Sister Aldith",
			"faction": "chapel",
			"color": Color("ecf0f1"),
			"topics": [
				{"label": "Healing", "key": "heal"},
				{"label": "The Fog", "key": "fog_lore", "lore": [
					"The fog is not natural. It has a will, a hunger. It seeks out the unwary and drains their memory.",
					"I've treated people who wandered too long in the fog. They forget their names, their pasts. Light is the only cure.",
					"The Chapel believes the fog is drawn to darkness — to unlit beacons, to sealed caves, to places where hope has died.",
				]},
				{"label": "Chapel Wisdom", "key": "chapel_wisdom", "lore": [
					"The Grey Chapel teaches that all wounds can be mended — of the body, yes, but also of the spirit.",
					"We keep records of every Keeper who tended the Line. Their names are written in the Chapel's book of light.",
					"Healing is not just magic. It is patience, care, and faith in the dawn.",
				]},
			],
			"dialogue": {
				"default": [
					"The Grey Chapel teaches that all wounds can be mended. Let me tend to yours.",
					"I've seen the fog take people's memories. Light is the only cure.",
				],
				"beacon_lit": [
					"Fewer wounded wander in since the beacons were lit. Thank you.",
				],
				"boss_defeated": [
					"The Chapel's prayers are answered. The darkness recedes. I see fewer wounded each day.",
				],
				"act2": [
					"The wounded from shadow wisp attacks carry a chill that ordinary healing can't touch. The Chapel's records may hold the answer.",
					"Something is wrong with the light itself. The beacons burn, but their glow feels... thinner.",
				],
				"endgame": [
					"The ancient grief beneath the mountain... the Chapel has known about it for centuries. I'm sorry we didn't tell you sooner.",
				],
				"honored": [
					"The Chapel's gratitude extends to those who serve. Your healing is on us today.",
				],
				"distrusted": [
					"Even those who shun the light may find healing here — but the cost is higher.",
				],
			},
		},
		"tinkerer": {
			"name": "Fenn Copperwick",
			"faction": "harbor",
			"color": Color("7f8c8d"),
			"topics": [
				{"label": "Craft Tools", "key": "tinker"},
				{"label": "Material Talk", "key": "material_talk", "lore": [
					"Scrap metal, driftwood, old ropes — the beach is full of useful junk if you know where to look.",
					"The cave Golems are made of something special. If you could bring me a chunk, I could make something amazing.",
					"I heard there are mineral deposits in the mountain paths. Beyond the hill beacon, if you can get there.",
				]},
				{"label": "Harbor News", "key": "harbor_news", "lore": [
					"The Compact's latest shipment brought copper wire and glass jars. I've got ideas for both.",
					"Captain Drel's first mate says the sea currents are changing. Something underneath the island is shifting.",
				]},
			],
			"dialogue": {
				"default": [
					"Got scrap? I turn junk into useful things. Tinkering's my trade.",
					"The harbor ships bring all sorts of broken goods. I see potential in every piece.",
				],
				"beacon_lit": [
					"With the beacons lit, more trade comes through. More materials for me!",
				],
				"boss_defeated": [
					"With the shade gone, old tech from the cave is washing up on shore. Fascinating materials!",
				],
				"act2": [
					"The seal fragments are made of something I've never seen. Not metal, not stone. It resonates with the beacons.",
					"I've been studying the old Keeper tools. They didn't just light beacons — they tuned them, like instruments.",
				],
				"endgame": [
					"If you're going down there, I made you this. My finest work. Don't break it.",
				],
				"honored": [
					"A friend of the Compact gets the best craftsmanship. Let me show you what I can make.",
				],
				"distrusted": [
					"The Compact says you're trouble. I'll still craft, but no discounts.",
				],
			},
		},
	}

static func get_dialogue(npc_id: String, context: String = "default") -> String:
	var all := all_npcs()
	if not all.has(npc_id):
		return "..."
	var npc: Dictionary = all[npc_id]
	var dialogue: Dictionary = npc.get("dialogue", {})
	if context != "default" and dialogue.has(context):
		var options: Array = dialogue[context]
		if not options.is_empty():
			return options[randi() % options.size()]
	if dialogue.has("default"):
		var options: Array = dialogue["default"]
		if not options.is_empty():
			return options[randi() % options.size()]
	return "..."

static func get_npc_name(npc_id: String) -> String:
	var all := all_npcs()
	if all.has(npc_id):
		return all[npc_id].get("name", "???")
	return "???"

static func get_npc_color(npc_id: String) -> Color:
	var all := all_npcs()
	if all.has(npc_id):
		return all[npc_id].get("color", Color.WHITE)
	return Color.WHITE


static func get_topics(npc_id: String) -> Array:
	var all := all_npcs()
	if not all.has(npc_id):
		return []
	return all[npc_id].get("topics", [])

static func get_topic_lore(npc_id: String, topic_key: String) -> String:
	var topics := get_topics(npc_id)
	for t: Dictionary in topics:
		if t["key"] == topic_key:
			var lore: Array = t.get("lore", [])
			if lore.is_empty():
				return ""
			return lore[randi() % lore.size()]
	return ""

static func npc_schedules() -> Dictionary:
	return {
		"weapon_merchant": {
			"day": Vector2i(4, 4),
			"dawn": Vector2i(4, 4),
			"dusk": Vector2i(18, 20),
			"night": Vector2i(18, 20),
		},
		"armor_merchant": {
			"day": Vector2i(29, 4),
			"dawn": Vector2i(29, 4),
			"dusk": Vector2i(25, 13),
			"night": Vector2i(25, 13),
		},
		"innkeeper": {
			"day": Vector2i(4, 13),
			"dawn": Vector2i(4, 13),
			"dusk": Vector2i(4, 13),
			"night": Vector2i(4, 13),
		},
		"elder": {
			"day": Vector2i(34, 13),
			"dawn": Vector2i(34, 13),
			"dusk": Vector2i(34, 13),
			"night": Vector2i(34, 13),
		},
		"tavern_keeper": {
			"day": Vector2i(18, 20),
			"dawn": Vector2i(18, 20),
			"dusk": Vector2i(18, 20),
			"night": Vector2i(18, 20),
		},
		"healer": {
			"day": Vector2i(25, 13),
			"dawn": Vector2i(4, 13),
			"dusk": Vector2i(25, 13),
			"night": Vector2i(4, 13),
		},
		"tinkerer": {
			"day": Vector2i(14, 4),
			"dawn": Vector2i(14, 4),
			"dusk": Vector2i(18, 20),
			"night": Vector2i(18, 20),
		},
		"realtor": {
			"day": Vector2i(36, 3),
			"dawn": Vector2i(36, 3),
			"dusk": Vector2i(18, 20),
			"night": Vector2i(18, 20),
		},
	}

static func get_npc_position(npc_id: String, phase: String) -> Vector2i:
	var schedules := npc_schedules()
	if schedules.has(npc_id):
		var sched: Dictionary = schedules[npc_id]
		if sched.has(phase):
			return sched[phase]
	return Vector2i(-1, -1)

static func recruitable_roster() -> Array:
	return [
		{
			"name": "Kael",
			"class": "Thief",
			"level": 3,
			"wage": 50,
			"loyalty": 50,
			"available": true,
			"recruited": false,
			"location": "Brindlewick",
			"dialogue": "Looking for work? I'm quick with a blade and quicker with my feet. Fifty copper a week.",
		},
		{
			"name": "Lyra",
			"class": "WhiteMage",
			"level": 2,
			"wage": 75,
			"loyalty": 50,
			"available": true,
			"recruited": false,
			"location": "Brindlewick",
			"dialogue": "The Chapel sent me to aid those who walk into darkness. My healing comes at a price, but it's worth every copper.",
		},
		{
			"name": "Brok",
			"class": "Fighter",
			"level": 5,
			"wage": 100,
			"loyalty": 50,
			"available": true,
			"recruited": false,
			"location": "Brindlewick",
			"dialogue": "I've fought in three wars and survived the Fog March. I don't come cheap, but I come home alive.",
		},
		{
			"name": "Selene",
			"class": "BlackMage",
			"level": 4,
			"wage": 80,
			"loyalty": 50,
			"available": true,
			"recruited": false,
			"location": "Brindlewick",
			"dialogue": "Fire, ice, thunder — the elements answer to me. The only question is whether you can afford my talents.",
		},
	]
