## Headless tests for BigNum: formatting, arithmetic, comparison and safe save data (SVTLW-70).
## Run: godot --headless --path game -s res://tests/test_big_num.gd
extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	_test_display()
	_test_arithmetic()
	_test_compare()
	_test_save()
	_test_no_nan()
	print("RESULT: %s (%d failure(s))" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   - %s" % label)
	else:
		_failures += 1
		print("  FAIL - %s" % label)


func _same(a: BigNum, b: BigNum) -> bool:
	return a.mantissa == b.mantissa and a.exponent == b.exponent


func _test_display() -> void:
	print("display")
	_check(BigNum.from_int(0).to_display_string() == "0", "zero shows 0")
	_check(BigNum.from_int(999).to_display_string() == "999", "999 shows as an integer")
	_check(BigNum.from_int(1000).to_display_string() == "1.00K", "1000 shows 1.00K")
	_check(BigNum.from_int(1000000).to_display_string() == "1.00M", "1e6 shows 1.00M")
	_check(BigNum.from_int(1500000000000).to_display_string() == "1.50T", "1.5e12 shows 1.50T")
	_check(BigNum.from_float(1.0e20).to_display_string() == "100.00Qi", "1e20 shows 100.00Qi")
	_check(BigNum.from_float(1.5e33).to_display_string() == "1.5e33", "1.5e33 uses scientific notation")
	_check(BigNum.from_float(1.0e-5).to_display_string() == "1e-5", "small fractions use scientific notation")
	_check(BigNum.from_int(-5).is_zero(), "negative input becomes zero")
	_check(BigNum.from_float(NAN).is_zero() and BigNum.from_float(INF).is_zero(), "NaN and inf become zero")


func _test_arithmetic() -> void:
	print("arithmetic")
	var sum: BigNum = BigNum.from_int(1000).add(BigNum.from_float(2.5e7))
	_check(sum.to_display_string() == "25.00M", "1e3 + 2.5e7 shows 25.00M (mixed exponents)")
	var tiny: BigNum = BigNum.from_float(1.0e40)
	_check(_same(tiny.add(BigNum.from_int(1)), tiny), "adding 1 to 1e40 keeps the exact value")
	_check(BigNum.from_int(1000).multiply(BigNum.from_int(1000)).to_display_string() == "1.00M", "1e3 * 1e3 is 1e6")
	var product: BigNum = BigNum.from_int(2000).multiply(BigNum.from_float(3.0e30))
	_check(product.to_display_string() == "6e33", "2e3 * 3e30 is 6e33")
	_check(BigNum.from_int(0).add(BigNum.from_int(7)).to_display_string() == "7", "zero plus 7 is 7")
	_check(BigNum.from_int(7).multiply(BigNum.from_int(0)).is_zero(), "anything times zero is zero")


func _test_compare() -> void:
	print("compare")
	_check(BigNum.from_int(999).compare(BigNum.from_int(1000)) == -1, "999 is less than 1000")
	_check(BigNum.from_int(5).compare(BigNum.from_int(5)) == 0, "equal values compare 0")
	_check(BigNum.from_float(1.5e33).is_greater_than(BigNum.from_float(9.0e32)), "1.5e33 is greater than 9e32")
	_check(BigNum.from_float(2.0e10).is_greater_than(BigNum.from_int(3)), "larger exponent wins over mantissa")
	_check(BigNum.from_int(0).compare(BigNum.from_int(1)) == -1, "zero is below positive values")
	_check(not BigNum.new().is_greater_than(BigNum.new()), "zero is not greater than zero")


func _test_save() -> void:
	print("save")
	var original: BigNum = BigNum.from_float(1.2345678901234567e37)
	var restored: BigNum = BigNum.from_dict(original.to_dict())
	_check(_same(restored, original), "in-memory round trip keeps mantissa and exponent")
	var parsed: Variant = JSON.parse_string(JSON.stringify(original.to_dict()))
	_check(_same(BigNum.from_dict(parsed), original), "JSON text round trip keeps mantissa and exponent")
	_check(BigNum.from_dict({"mantissa": 1.5, "exponent": 2.5}).is_zero(), "non-integer exponent loads as zero")
	_check(BigNum.from_dict({"mantissa": NAN, "exponent": 3}).is_zero(), "NaN mantissa loads as zero")
	_check(BigNum.from_dict({"mantissa": 2.0, "exponent": INF}).is_zero(), "infinite exponent loads as zero")
	_check(BigNum.from_dict({"mantissa": -2.0, "exponent": 3}).is_zero(), "negative mantissa loads as zero")
	_check(BigNum.from_dict({"mantissa": 2.0}).is_zero(), "missing exponent loads as zero")
	_check(BigNum.from_dict({"mantissa": "abc", "exponent": 3}).is_zero(), "non-numeric text mantissa loads as zero")
	_check(BigNum.from_dict({"mantissa": 2.0, "exponent": "x"}).is_zero(), "non-numeric text exponent loads as zero")
	_check(BigNum.from_dict("garbage").is_zero(), "non-dictionary loads as zero")
	_check(BigNum.from_dict(null).is_zero(), "null loads as zero")
	var clamped: BigNum = BigNum.from_dict({"mantissa": 1.0, "exponent": 1.0e300})
	_check(clamped.exponent == BigNum.MAX_EXPONENT, "huge exponent is clamped to the maximum")


func _test_no_nan() -> void:
	print("no NaN")
	var value: BigNum = BigNum.from_float(7.7)
	var bad: bool = false
	for i: int in 300:
		value = value.multiply(BigNum.from_float(9.9)).add(BigNum.from_float(1.0e-300))
		if is_nan(value.mantissa) or is_inf(value.mantissa) or value.to_display_string().contains("nan"):
			bad = true
	_check(not bad, "300 multiplications and additions stay finite")
	_check(value.mantissa >= 1.0 and value.mantissa < 10.0, "mantissa stays normalised")
	var tiny: float = 1.0e-300 * 1.0e-20  # a subnormal float; literals this small parse as zero
	var denormal: BigNum = BigNum.from_float(tiny)
	_check(not denormal.is_zero() and not is_nan(denormal.mantissa) and denormal.exponent < -300, "denormal input stays finite")
	var huge: BigNum = BigNum.from_float(1.0e308).multiply(BigNum.from_float(1.0e308))
	_check(huge.exponent == 616 and is_equal_approx(huge.mantissa, 1.0), "1e308 * 1e308 is 1e616, no float overflow")
	_check(BigNum.from_float(1.0e308).to_float() > 0.0, "to_float of a large value is positive")
