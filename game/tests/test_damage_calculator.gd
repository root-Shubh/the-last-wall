## Headless tests for DamageCalculator (SVTLW-35).
## Run: godot --headless --path game -s res://tests/test_damage_calculator.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_plain_hit()
	_test_upgrades_and_crit()
	_test_armour()
	_test_resistance()
	_test_crit_roll()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _approx(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001


func _test_plain_hit() -> void:
	print("plain hit")
	var damage: float = DamageCalculator.calculate(10.0, 1.0, 0.0, 2.0, 0.0, 1.0, 0.99)
	_check(_approx(damage, 10.0), "no modifiers returns base damage")


func _test_upgrades_and_crit() -> void:
	print("upgrades and crit")
	var upgraded: float = DamageCalculator.calculate(10.0, 1.5, 0.0, 2.0, 0.0, 1.0, 0.99)
	_check(_approx(upgraded, 15.0), "upgrade multiplier scales base damage")
	var crit: float = DamageCalculator.calculate(10.0, 1.0, 0.5, 2.0, 0.0, 1.0, 0.2)
	_check(_approx(crit, 20.0), "roll under crit chance applies crit multiplier")
	var no_crit: float = DamageCalculator.calculate(10.0, 1.0, 0.5, 2.0, 0.0, 1.0, 0.8)
	_check(_approx(no_crit, 10.0), "roll over crit chance does not crit")


func _test_armour() -> void:
	print("armour")
	var reduced: float = DamageCalculator.calculate(10.0, 1.0, 0.0, 2.0, 4.0, 1.0, 0.99)
	_check(_approx(reduced, 6.0), "armour subtracts flat damage")
	var floored: float = DamageCalculator.calculate(3.0, 1.0, 0.0, 2.0, 50.0, 1.0, 0.99)
	_check(_approx(floored, 0.0), "armour cannot make damage negative")


func _test_resistance() -> void:
	print("resistance")
	var immune: float = DamageCalculator.calculate(10.0, 1.0, 0.0, 2.0, 0.0, 0.0, 0.99)
	_check(_approx(immune, 0.0), "zero resistance blocks all damage")
	var weak: float = DamageCalculator.calculate(10.0, 1.0, 0.0, 2.0, 0.0, 1.5, 0.99)
	_check(_approx(weak, 15.0), "vulnerability above 1.0 increases damage")
	var order: float = DamageCalculator.calculate(10.0, 1.0, 0.0, 2.0, 4.0, 0.5, 0.99)
	_check(_approx(order, 3.0), "armour applies before resistance")


func _test_crit_roll() -> void:
	print("crit roll")
	_check(DamageCalculator.is_critical(1.0, 0.999), "100 percent chance always crits")
	_check(not DamageCalculator.is_critical(0.0, 0.0), "0 percent chance never crits")
	_check(DamageCalculator.is_critical(0.25, 0.1) and not DamageCalculator.is_critical(0.25, 0.3), "crit threshold is the chance")
