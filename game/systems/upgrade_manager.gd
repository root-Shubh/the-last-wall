## Owns upgrade levels, costs, prerequisites and purchases (SVTLW-38, SVTLW-39).
## Spending goes through the gold source, so every purchase is one ledger transaction.
## The battlefield reads effect_total() and applies the numbers to the game systems.
class_name UpgradeManager
extends Node

signal upgrade_purchased(upgrade_id: String, level: int)
signal effects_changed

@export var definitions: Array[UpgradeDefinition] = []

var state: Node = null
var levels: Dictionary = {}
var _by_id: Dictionary = {}


func _ready() -> void:
	_rebuild_index()


func _rebuild_index() -> void:
	_by_id.clear()
	for definition: UpgradeDefinition in definitions:
		_by_id[definition.upgrade_id] = definition


func definition(upgrade_id: String) -> UpgradeDefinition:
	if _by_id.is_empty():
		_rebuild_index()
	return _by_id.get(upgrade_id, null)


func level(upgrade_id: String) -> int:
	return int(levels.get(upgrade_id, 0))


## Cost of the next level. Level 0 costs the base cost; each further level multiplies it.
func cost_for(upgrade_id: String) -> int:
	var data: UpgradeDefinition = definition(upgrade_id)
	if data == null:
		return -1
	return int(floor(data.base_cost * pow(data.cost_multiplier, level(upgrade_id))))


## Empty string when the upgrade can be bought now. Otherwise the reason it cannot.
func purchase_block_reason(upgrade_id: String) -> String:
	var data: UpgradeDefinition = definition(upgrade_id)
	if data == null:
		return "unknown upgrade"
	if level(upgrade_id) >= data.max_level:
		return "max level reached"
	if data.prerequisite_id != "" and level(data.prerequisite_id) < 1:
		return "requires %s" % data.prerequisite_id
	if not _gold().can_afford(cost_for(upgrade_id)):
		return "not enough gold"
	return ""


## Buys one level. Returns false and changes nothing if the purchase is blocked.
func purchase(upgrade_id: String) -> bool:
	if purchase_block_reason(upgrade_id) != "":
		return false
	var cost: int = cost_for(upgrade_id)
	if not _gold().spend_gold(cost):
		return false
	levels[upgrade_id] = level(upgrade_id) + 1
	upgrade_purchased.emit(upgrade_id, level(upgrade_id))
	effects_changed.emit()
	return true


## What the next level costs and gives, for the upgrade panel preview.
func preview(upgrade_id: String) -> Dictionary:
	var data: UpgradeDefinition = definition(upgrade_id)
	if data == null:
		return {}
	return {
		"cost": cost_for(upgrade_id),
		"next_level": level(upgrade_id) + 1,
		"gain_per_level": data.effect_per_level,
		"effect": data.effect,
		"blocked_by": purchase_block_reason(upgrade_id),
	}


## Sum of effect_per_level x level over every upgrade that changes this effect.
func effect_total(effect_name: String) -> float:
	var total: float = 0.0
	for data: UpgradeDefinition in definitions:
		if data.effect == effect_name:
			total += data.effect_per_level * level(data.upgrade_id)
	return total


func _gold() -> Node:
	return state
