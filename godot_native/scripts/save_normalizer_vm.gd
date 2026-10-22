extends RefCounted
## Closed evaluator for the build-generated save normalization instruction table.
## It never parses code from saves and exposes no IO, OS, object calls, or dynamic loading.
const MAX_STEPS := 2000000
class Undefined extends RefCounted:
	pass
class Scope extends RefCounted:
	var values: Dictionary = {}
	var parent: Scope
	func _init(outer: Scope = null) -> void: parent = outer
class FunctionValue extends RefCounted:
	var parameters: Array
	var body: Array
	var environment: Scope
	func _init(p: Array, b: Array, e: Scope) -> void:
		parameters = p; body = b; environment = e
class SetValue extends RefCounted:
	var entries: Array = []
class Builtin extends RefCounted:
	var id: String
	var receiver: Variant
	func _init(value: String, target: Variant = null) -> void:
		id = value; receiver = target
var undefined := Undefined.new()
var failure := ""
var steps := 0
var functions: Array = []
var global: Scope

func initialize(program: Array) -> bool:
	failure = ""; steps = 0
	global = Scope.new()
	global.values["undefined"] = undefined
	global.values["NaN"] = NAN
	global.values["Infinity"] = INF
	for id in ["Object", "Array", "Number", "Math"]: global.values[id] = Builtin.new(id)
	_run(program, global, false)
	return failure.is_empty()

func invoke(id: String, arguments: Array) -> Variant:
	return _call(_lookup(global, id), arguments)

func release() -> void:
	# Break the deliberately retained lexical-environment references.
	for function in functions: function.environment = null
	functions.clear()
	global = null

func _fail(message: String) -> Variant:
	if failure.is_empty(): failure = message
	return undefined

func _tick() -> bool:
	steps += 1
	if steps > MAX_STEPS: _fail("Normalization instruction budget exceeded")
	return failure.is_empty()

func _lookup(scope: Scope, id: String) -> Variant:
	var current := scope
	while current != null:
		if current.values.has(id): return current.values[id]
		current = current.parent
	return _fail("Unknown normalization symbol: " + id)

func _function(parameters: Array, body: Array, scope: Scope) -> FunctionValue:
	var value := FunctionValue.new(parameters, body, scope)
	functions.append(value)
	return value

func _truth(value: Variant) -> bool:
	if value == null or value is Undefined: return false
	if value is bool: return value
	if value is int or value is float: return value != 0 and not is_nan(float(value))
	if value is String: return not value.is_empty()
	return true

func _type(value: Variant) -> String:
	if value is Undefined: return "undefined"
	if value is bool: return "boolean"
	if value is int or value is float: return "number"
	if value is String: return "string"
	if value is FunctionValue or value is Builtin: return "function"
	return "object"

func _equal(a: Variant, b: Variant) -> bool:
	if _type(a) != _type(b): return false
	if a is float and is_nan(a) or b is float and is_nan(b): return false
	if a is Dictionary or a is Array or a is Object: return is_same(a, b)
	return a == b

func _string(value: Variant) -> String:
	if value is Undefined: return "undefined"
	if value == null: return "null"
	if value is bool: return "true" if value else "false"
	if value is String: return value
	if value is Array:
		var parts: PackedStringArray = []
		for item in value: parts.append("" if item == null or item is Undefined else _string(item))
		return ",".join(parts)
	if value is Dictionary: return "[object Object]"
	if value is int or value is float:
		if is_nan(float(value)): return "NaN"
		if is_inf(float(value)): return "Infinity" if value > 0 else "-Infinity"
		if value == floor(float(value)): return str(int(value))
	return str(value)

func _js_trim(value: String) -> String:
	var start := 0
	var end := value.length()
	while start < end and _js_whitespace(value.unicode_at(start)): start += 1
	while end > start and _js_whitespace(value.unicode_at(end-1)): end -= 1
	return value.substr(start,end-start)

func _js_whitespace(code: int) -> bool:
	return code in [9,10,11,12,13,32,160,5760,8232,8233,8239,8287,12288,65279] or (code >= 8192 and code <= 8202)

func _number(value: Variant) -> float:
	if value is int or value is float: return float(value)
	if value == null: return 0.0
	if value is bool: return 1.0 if value else 0.0
	if value is Undefined: return NAN
	var string := _js_trim(_string(value))
	if string.is_empty(): return 0.0
	if string == "Infinity" or string == "+Infinity": return INF
	if string == "-Infinity": return -INF
	if string.begins_with("0x") or string.begins_with("0X"): return float(string.hex_to_int()) if string.substr(2).is_valid_hex_number() else NAN
	if string.begins_with("0b") or string.begins_with("0B") or string.begins_with("0o") or string.begins_with("0O"):
		var base := 2 if string.substr(1,1).to_lower() == "b" else 8
		var digits := string.substr(2)
		if digits.is_empty(): return NAN
		var value_number := 0.0
		for digit in digits:
			if digit < "0" or digit > str(base - 1): return NAN
			value_number = value_number * base + int(digit)
		return value_number
	return string.to_float() if string.is_valid_float() else NAN

func _iterable(value: Variant) -> Array:
	if value is Array: return value
	if value is SetValue: return value.entries
	_fail("Unsupported normalization iterable")
	return []

func _property(target: Variant, property: Variant, optional: bool = false) -> Variant:
	if target == null or target is Undefined:
		return undefined if optional else _fail("Property access on null or undefined")
	var key := _string(property)
	if target is Dictionary: return target.get(key, undefined)
	if target is Builtin: return Builtin.new(target.id + "." + key)
	if target is Array:
		if key == "length": return target.size()
		if key.is_valid_int():
			var index := int(key)
			return target[index] if index >= 0 and index < target.size() else undefined
		if key in ["map","filter","find","some","every","forEach","includes","indexOf","slice","push"]: return Builtin.new("array." + key, target)
	if target is String:
		if key == "length": return target.length()
		if key in ["trim","includes"]: return Builtin.new("string." + key, target)
	if target is SetValue and key == "size": return target.entries.size()
	if target is SetValue and key in ["has","add","delete"]: return Builtin.new("set." + key, target)
	return undefined

func _assign(node: Array, value: Variant, scope: Scope) -> Variant:
	if node[0] == "name":
		var current := scope
		while current != null:
			if current.values.has(node[1]): current.values[node[1]] = value; return value
			current = current.parent
		return _fail("Assignment to unknown symbol")
	if node[0] == "get":
		var target = _eval(node[1], scope)
		var key = _eval(node[2], scope)
		if target is Dictionary: target[_string(key)] = value; return value
		if target is Array:
			var index := int(_number(key))
			if index < 0 or index > 10000: return _fail("Invalid array assignment")
			while target.size() <= index: target.append(undefined)
			target[index] = value; return value
	return _fail("Invalid normalization assignment")

func _eval(node: Array, scope: Scope) -> Variant:
	if not _tick(): return undefined
	match node[0]:
		"undefined": return undefined
		"literal": return node[1].duplicate(true) if node[1] is Dictionary or node[1] is Array else node[1]
		"name": return _lookup(scope, node[1])
		"get": return _property(_eval(node[1],scope),_eval(node[2],scope),node[3])
		"function": return _function(node[1],node[2],scope)
		"typeof": return _type(_eval(node[1],scope))
		"conditional": return _eval(node[2] if _truth(_eval(node[1],scope)) else node[3],scope)
		"unary":
			var operand = _eval(node[2],scope)
			match node[1]:
				"!": return not _truth(operand)
				"-": return -_number(operand)
				"+": return _number(operand)
			return _fail("Unsupported unary operation")
		"binary":
			var op: String = node[1]
			if op == "=": return _assign(node[2],_eval(node[3],scope),scope)
			var left = _eval(node[2],scope)
			if op == "&&": return _eval(node[3],scope) if _truth(left) else left
			if op == "||": return left if _truth(left) else _eval(node[3],scope)
			if op == "??": return _eval(node[3],scope) if left == null or left is Undefined else left
			var right = _eval(node[3],scope)
			match op:
				"===": return _equal(left,right)
				"!==": return not _equal(left,right)
				"<": return left < right if left is String and right is String else _number(left) < _number(right)
				"<=": return left <= right if left is String and right is String else _number(left) <= _number(right)
				">": return left > right if left is String and right is String else _number(left) > _number(right)
				">=": return left >= right if left is String and right is String else _number(left) >= _number(right)
				"-": return _number(left) - _number(right)
				"+": return _string(left) + _string(right) if left is String or right is String else _number(left) + _number(right)
			return _fail("Unsupported binary operation: " + op)
		"array":
			var array: Array = []
			for element in node[1]:
				if element[0] == "spread": array.append_array(_iterable(_eval(element[1],scope)))
				else: array.append(_eval(element,scope))
			return array
		"object":
			var object: Dictionary = {}
			for property in node[1]:
				if property[0] == "spread":
					var other = _eval(property[1],scope)
					if other is Dictionary: object.merge(other,true)
					elif other != null and not other is Undefined: return _fail("Unsupported object spread")
				else: object[_string(_eval(property[1],scope))] = _eval(property[2],scope)
			return object
		"call":
			var function = _eval(node[1],scope)
			var arguments: Array = []
			for argument in node[2]: arguments.append(_eval(argument,scope))
			return _call(function,arguments)
		"new":
			var arguments: Array = []
			for argument in node[2]: arguments.append(_eval(argument,scope))
			if node[1] == "Set":
				var set := SetValue.new()
				if not arguments.is_empty():
					for value in _iterable(arguments[0]):
						if _index(set.entries,value) < 0: set.entries.append(value)
				return set
			if node[1] == "Error": return _string(arguments[0]) if not arguments.is_empty() else "Normalization error"
			return _fail("Unsupported constructor")
		"template":
			var result: String = node[1]
			for span in node[2]: result += _string(_eval(span[0],scope)) + str(span[1])
			return result
	return _fail("Unsupported normalization expression: " + str(node[0]))

func _run(node: Array, scope: Scope, nested: bool = true) -> Dictionary:
	if not _tick(): return {"kind":"abort"}
	match node[0]:
		"block":
			var block := Scope.new(scope) if nested else scope
			# Function declarations are hoisted, matching the source language.
			for statement in node[1]:
				if statement[0] == "declare": block.values[statement[1]] = _function(statement[2],statement[3],block)
			for statement in node[1]:
				if statement[0] == "declare": continue
				var completion := _run(statement,block)
				if not completion.is_empty(): return completion
		"variables":
			for variable in node[1]: scope.values[variable[0]] = _eval(variable[1],scope)
		"expression": _eval(node[1],scope)
		"return": return {"kind":"return","value":_eval(node[1],scope)}
		"if": return _run(node[2] if _truth(_eval(node[1],scope)) else node[3],scope)
		"for":
			for value in _iterable(_eval(node[2],scope)).duplicate():
				var iteration := Scope.new(scope)
				iteration.values[node[1]] = value
				var completion := _run(node[3],iteration)
				if completion.get("kind","") == "continue": continue
				if not completion.is_empty(): return completion
		"continue": return {"kind":"continue"}
		"throw": _fail(_string(_eval(node[1],scope))); return {"kind":"abort"}
		"empty": pass
		_: _fail("Unsupported normalization statement: " + str(node[0]))
	return {} if failure.is_empty() else {"kind":"abort"}

func _index(array: Array, value: Variant) -> int:
	for i in range(array.size()):
		if _equal(array[i],value): return i
	return -1

func _call(function: Variant, arguments: Array) -> Variant:
	if not _tick(): return undefined
	if function is FunctionValue:
		var local := Scope.new(function.environment)
		for index in range(function.parameters.size()):
			var parameter: Array = function.parameters[index]
			var value = arguments[index] if index < arguments.size() else undefined
			local.values[parameter[0]] = _eval(parameter[1],local) if value is Undefined else value
		var completion := _run(function.body,local,false)
		return completion.get("value",undefined)
	if function is Builtin: return _builtin(function,arguments)
	return _fail("Call to a non-function")

func _builtin(function: Builtin, args: Array) -> Variant:
	var first = args[0] if not args.is_empty() else undefined
	match function.id:
		"Number": return _number(first)
		"Array.isArray": return first is Array
		"Number.isInteger": return (first is int or first is float) and is_finite(float(first)) and floor(float(first)) == first
		"Number.isSafeInteger": return (first is int or first is float) and is_finite(float(first)) and floor(float(first)) == first and abs(float(first)) <= 9007199254740991.0
		"Number.isFinite": return (first is int or first is float) and is_finite(float(first))
		"Number.isNaN": return first is float and is_nan(first)
		"Object.freeze": return first
		"Object.keys": return first.keys() if first is Dictionary else _fail("Object.keys requires an object")
		"Object.values": return first.values() if first is Dictionary else _fail("Object.values requires an object")
		"Object.fromEntries":
			var result: Dictionary = {}
			for entry in _iterable(first):
				if not entry is Array or entry.size() != 2: return _fail("Invalid object entry")
				result[_string(entry[0])] = entry[1]
			return result
		"Object.prototype.hasOwnProperty.call": return first is Dictionary and first.has(_string(args[1]))
		"Math.max":
			var result := -INF
			for value in args: result = maxf(result,_number(value))
			return result
		"Math.min":
			var result := INF
			for value in args: result = minf(result,_number(value))
			return result
		"Math.abs": return absf(_number(first))
		"set.has": return _index(function.receiver.entries,first) >= 0
		"set.add":
			if _index(function.receiver.entries,first) < 0: function.receiver.entries.append(first)
			return function.receiver
		"set.delete":
			var index := _index(function.receiver.entries,first)
			if index >= 0: function.receiver.entries.remove_at(index)
			return index >= 0
		"string.trim": return _js_trim(str(function.receiver))
		"string.includes": return str(function.receiver).contains(_string(first))
		"array.includes": return _index(function.receiver,first) >= 0
		"array.indexOf": return _index(function.receiver,first)
		"array.push":
			function.receiver.append_array(args)
			return function.receiver.size()
		"array.slice":
			var size: int = function.receiver.size()
			var start := int(_number(first)) if not args.is_empty() else 0
			var end := int(_number(args[1])) if args.size() > 1 else size
			start = clampi(size+start if start < 0 else start,0,size)
			end = clampi(size+end if end < 0 else end,0,size)
			return function.receiver.slice(start,maxi(start,end))
		"array.map", "array.filter", "array.find", "array.some", "array.every", "array.forEach":
			var output: Array = []
			var source: Array = function.receiver
			for index in range(source.size()):
				var value = source[index]
				var result = _call(first,[value,index,source])
				if not failure.is_empty(): return undefined
				match function.id:
					"array.map": output.append(result)
					"array.filter":
						if _truth(result): output.append(value)
					"array.find":
						if _truth(result): return value
					"array.some":
						if _truth(result): return true
					"array.every":
						if not _truth(result): return false
			if function.id == "array.some": return false
			if function.id == "array.every": return true
			if function.id in ["array.find","array.forEach"]: return undefined
			return output
	return _fail("Unsupported normalization builtin: " + function.id)
