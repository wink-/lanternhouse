# FactionDB — static faction definitions
class_name FactionDB

enum Faction { KEEPERS_GUILD, HARBOR_COMPACT, GREY_CHAPEL, THE_UNLIT }

const NAMES := {
	Faction.KEEPERS_GUILD: "Keepers' Guild",
	Faction.HARBOR_COMPACT: "Harbor Compact",
	Faction.GREY_CHAPEL: "Grey Chapel",
	Faction.THE_UNLIT: "The Unlit",
}

const DESCRIPTIONS := {
	Faction.KEEPERS_GUILD: "Guardians of the beacon line. Honor-bound, tradition-obsessed.",
	Faction.HARBOR_COMPACT: "Merchants and sailors. Coin talks, cargo walks.",
	Faction.GREY_CHAPEL: "Keepers of rites and sea-knowledge. Quiet, watchful.",
	Faction.THE_UNLIT: "Those who thrive in darkness. Refugees, outcasts, the forgotten.",
}

const TIER_NAMES := {
	-3: "Hostile",
	-2: "Distrusted",
	-1: "Unfriendly",
	0: "Neutral",
	1: "Friendly",
	2: "Honored",
	3: "Exalted",
}

const CURRENCY := {
	Faction.KEEPERS_GUILD: "keeper_marks",
	Faction.HARBOR_COMPACT: "harbor_tokens",
	Faction.GREY_CHAPEL: "chapel_script",
}

static func all_factions() -> Array:
	return [Faction.KEEPERS_GUILD, Faction.HARBOR_COMPACT, Faction.GREY_CHAPEL, Faction.THE_UNLIT]

static func reputation_tier(rep: int) -> String:
	var best := 0
	for threshold: int in TIER_NAMES:
		if rep >= threshold and threshold >= best:
			best = threshold
	return TIER_NAMES[best]

static func price_modifier(rep: int) -> float:
	return 1.0 - rep * 0.05

static func quest_unlock_tier() -> int:
	return 1
