class_name TileBag
extends RefCounted


static func build(ruleset: WordRuleset, seed: int) -> Dictionary:
	var tiles: Array = []
	for letter in ruleset.letters:
		var info: Dictionary = ruleset.letters[letter]
		for _index in range(int(info["count"])):
			tiles.append({"letter": letter, "value": int(info["value"]), "blank": false})
	for _index in range(ruleset.blank_count):
		tiles.append({"letter": "", "value": 0, "blank": true})
	var random := RandomNumberGenerator.new()
	random.seed = seed
	shuffle(tiles, random)
	return {"tiles": tiles, "rng_state": random.state}


static func shuffle(tiles: Array, random: RandomNumberGenerator) -> void:
	for index in range(tiles.size() - 1, 0, -1):
		var swap_index := random.randi_range(0, index)
		var held: Variant = tiles[index]
		tiles[index] = tiles[swap_index]
		tiles[swap_index] = held


static func refill(rack: Array, tiles: Array, rack_size: int) -> void:
	while rack.size() < rack_size and not tiles.is_empty():
		rack.append(tiles.pop_back())
