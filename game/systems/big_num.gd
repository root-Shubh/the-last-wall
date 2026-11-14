## Safe large-number value: mantissa in [1, 10) (or 0) times 10^exponent (SVTLW-70).
## The exponent is a plain int clamped to a safe range, so storage never overflows a float.
## Only the mantissa is a float; to_float() is for display maths and may return inf.
class_name BigNum
extends RefCounted

const MAX_EXPONENT: int = 1000000
const MIN_EXPONENT: int = -1000000
## Sums whose operands differ by more orders of magnitude than this keep the larger operand (the smaller is lost to float precision anyway).
const ALIGN_CUTOFF: int = 20
const SNAP_EPSILON: float = 1.0e-12
## Suffixes for exponents 3, 6, ..., 30. Larger or negative exponents display as scientific notation.
const SUFFIXES: Array[String] = ["K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No"]

var mantissa: float = 0.0
var exponent: int = 0


static func from_int(value: int) -> BigNum:
	return BigNum.from_float(float(value))


## Zero, negative, NaN and infinite inputs all become zero.
static func from_float(value: float) -> BigNum:
	var result: BigNum = BigNum.new()
	if is_nan(value) or is_inf(value) or value <= 0.0:
		return result
	result._set_normalised(value, 0)
	return result


## Parses a dictionary written by to_dict(). Anything malformed (non-dictionary, missing keys,
## NaN, infinite, negative mantissa, non-integer exponent) loads as zero. Exponents are clamped.
static func from_dict(data: Variant) -> BigNum:
	var result: BigNum = BigNum.new()
	if typeof(data) != TYPE_DICTIONARY:
		return result
	var dict: Dictionary = data
	if not dict.has("mantissa") or not dict.has("exponent"):
		return result
	var m: float = _read_number(dict["mantissa"])
	var e: float = _read_number(dict["exponent"])
	if is_nan(m) or is_inf(m) or is_nan(e) or is_inf(e):
		return result
	if m <= 0.0 or not is_equal_approx(e, floor(e)):
		return result
	result._set_normalised(m, int(clampf(e, float(MIN_EXPONENT), float(MAX_EXPONENT))))
	return result


func is_zero() -> bool:
	return mantissa == 0.0


func copy() -> BigNum:
	var result: BigNum = BigNum.new()
	result.mantissa = mantissa
	result.exponent = exponent
	return result


func add(other: BigNum) -> BigNum:
	if other == null or other.is_zero():
		return copy()
	if is_zero():
		return other.copy()
	var big: BigNum = self if exponent >= other.exponent else other
	var small: BigNum = other if big == self else self
	var gap: int = big.exponent - small.exponent
	var result: BigNum = BigNum.new()
	if gap > ALIGN_CUTOFF:
		return big.copy()
	var aligned: float = big.mantissa + small.mantissa * pow(10.0, -gap)
	result._set_normalised(aligned, big.exponent)
	return result


func multiply(other: BigNum) -> BigNum:
	var result: BigNum = BigNum.new()
	if other == null or is_zero() or other.is_zero():
		return result
	result._set_normalised(mantissa * other.mantissa, exponent + other.exponent)
	return result


## Returns -1, 0 or 1. Zero is below every positive value.
func compare(other: BigNum) -> int:
	if other == null:
		return 0
	if is_zero() and other.is_zero():
		return 0
	if is_zero():
		return -1
	if other.is_zero():
		return 1
	if exponent != other.exponent:
		return 1 if exponent > other.exponent else -1
	if mantissa == other.mantissa:
		return 0
	return 1 if mantissa > other.mantissa else -1


func is_greater_than(other: BigNum) -> bool:
	return compare(other) > 0


## Approximate float value for maths only. Returns inf when the value is beyond float range.
func to_float() -> float:
	if is_zero():
		return 0.0
	if exponent > 308:
		return INF
	return mantissa * pow(10.0, exponent)


## The mantissa is stored as text (var_to_str) so JSON keeps all 17 significant digits.
func to_dict() -> Dictionary:
	return {"mantissa": var_to_str(mantissa), "exponent": exponent}


## Human-readable text: "0", "999", "1.00K", "25.00M", up to "100.00No", then "1.5e33".
func to_display_string() -> String:
	if is_zero():
		return "0"
	if exponent >= 0 and exponent < 3:
		var value: float = mantissa * pow(10.0, exponent)
		if is_equal_approx(value, floor(value)):
			return str(int(value))
		return "%.2f" % value
	if exponent >= 3 and exponent <= 30:
		var tier: int = exponent / 3
		var scaled: float = mantissa * pow(10.0, exponent - tier * 3)
		return "%.2f%s" % [scaled, SUFFIXES[tier - 1]]
	return _scientific()


func _scientific() -> String:
	var digits: String = "%.2f" % mantissa
	var shown_exponent: int = exponent
	if digits == "10.00":
		digits = "1.00"
		shown_exponent += 1
	if digits.contains("."):
		digits = digits.rstrip("0").rstrip(".")
	return "%se%d" % [digits, shown_exponent]


## Normalises m * 10^e into the stored form. Non-positive or non-finite m becomes zero.
func _set_normalised(m: float, e: int) -> void:
	if is_nan(m) or is_inf(m) or m <= 0.0:
		mantissa = 0.0
		exponent = 0
		return
	var shift: int = floori(log(m) / log(10.0))
	var scaled: float = m
	if shift > 0:
		scaled = m / pow(10.0, shift)
	elif shift < 0:
		# Two steps keep denormal inputs finite.
		scaled = m * pow(10.0, -shift - 150) * pow(10.0, 150)
	while scaled >= 10.0:
		scaled /= 10.0
		shift += 1
	while scaled < 1.0:
		scaled *= 10.0
		shift -= 1
	# pow() rounding can leave 9.9999999999999x; snap that to the next power of ten.
	if scaled > 10.0 - SNAP_EPSILON:
		scaled = 1.0
		shift += 1
	mantissa = scaled
	exponent = clampi(e + shift, MIN_EXPONENT, MAX_EXPONENT)


## Reads a number from a float, an int or a var_to_str() text. Anything else returns NAN.
static func _read_number(value: Variant) -> float:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)
	if typeof(value) == TYPE_STRING:
		var parsed: Variant = str_to_var(value)
		if typeof(parsed) == TYPE_INT or typeof(parsed) == TYPE_FLOAT:
			return float(parsed)
	return NAN
