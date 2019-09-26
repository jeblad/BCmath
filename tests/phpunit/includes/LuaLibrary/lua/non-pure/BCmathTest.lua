--- Tests for the BCmath library.
-- @license GPL-2.0-or-later
-- @author John Erling Blad < jeblad@gmail.com >

local testframework = require 'Module:TestFramework'

local function testExists()
	return type( mw.bcmath )
end

local function makeInstance( ... )
	local res,ret = pcall( function( ... )
		return mw.bcmath.new( ... )
	end, ... )
	if not res then
		return res, type( ret ) -- never mind the actual content
	end
	return res, ret:value(), ret:scale(), tostring( ret )
end

local function makeCall( obj, ... )
	assert( obj )
	return obj( ... )
end

local function callMet( obj, name, ... )
	assert( obj )
	return obj[name]( obj, ... )
end

local function callInstance( obj, name, ... )
	assert( obj )
	obj[name]( obj, ... )
	return obj:value(), obj:scale()
end

local function callFunc( name, ... )
	local obj = mw.bcmath[name]( ... )
	assert( obj )
	return obj:value(), obj:scale()
end

local function compFunc( name, ... )
	return mw.bcmath[name]( ... )
end

local tests = {
	{ -- 1
		name = 'Verify the lib is loaded and exists',
		func = testExists,
		type = 'ToString',
		expect = { 'table' }
	},
	{ -- 2
		name = 'Create with nil argument',
		func = makeInstance,
		args = { nil },
		expect = { true, nil, 0, 'nan' }
	},
	{ -- 3
		name = 'Create with empty string argument',
		func = makeInstance,
		args = { '' },
		expect = { true, '', 0, '0' }
	},
	{ -- 4
		name = 'Create with empty string argument',
		func = makeInstance,
		args = { '0' },
		expect = { true, '0', 0, '0' }
	},
	{ -- 5
		name = 'Create with false argument',
		func = makeInstance,
		args = { false },
		expect = { false, 'string' }
	},
	{ -- 6
		name = 'Create with true argument',
		func = makeInstance,
		args = { true },
		expect = { false, 'string' }
	},
	{ -- 7
		name = 'Create with number 42 argument',
		func = makeInstance,
		args = { 42 },
		expect = { true, '+42.00000000000000', 14, '+42' }
	},
	{ -- 8
		name = 'Create with number -42 argument',
		func = makeInstance,
		args = { -42 },
		expect = { true, '-42.00000000000000', 14, '-42' }
	},
	{ -- 9
		name = 'Create with number 0.123 argument',
		func = makeInstance,
		args = { 0.123 },
		expect = { true, '+.1230000000000000', 16, '+.1230000000000000' }
	},
	{ -- 10
		name = 'Create with number -0.123 argument',
		func = makeInstance,
		args = { -0.123 },
		expect = { true, '-.1230000000000000', 16, '-.1230000000000000' }
	},
	{ -- 11
		name = 'Create with string 42 argument',
		func = makeInstance,
		args = { '42' },
		expect = { true, '42', 0, '42' }
	},
	{ -- 12
		name = 'Create with string -42 argument',
		func = makeInstance,
		args = { '-42' },
		expect = { true, '-42', 0, '-42' }
	},
	{ -- 13
		name = 'Create with string 0.123 argument',
		func = makeInstance,
		args = { '0.123' },
		expect = { true, '0.123', 3, '.123' }
	},
	{ -- 14
		name = 'Create with string -0.123 argument',
		func = makeInstance,
		args = { '-0.123' },
		expect = { true, '-0.123', 3, '-.123' }
	},
	{ -- 15
		name = 'Create with string 0.123e9 argument',
		func = makeInstance,
		args = { '0.123e9' },
		expect = { true, '0123000000.', 0, '123000000' }
	},
	{ -- 16
		name = 'Create with string -0.123e9 argument',
		func = makeInstance,
		args = { '-0.123e9' },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 17
		name = 'Create with string 0.123e-9 argument',
		func = makeInstance,
		args = { '0.123e-9' },
		expect = { true, '.000000000123', 12, '.000000000123' }
	},
	{ -- 18
		name = 'Create with string -0.123e-9 argument',
		func = makeInstance,
		args = { '-0.123e-9' },
		expect = { true, '-.000000000123', 12, '-.000000000123' }
	},
	{ -- 19
		name = 'Create with string 0.123×10-9 argument',
		func = makeInstance,
		args = { '0.123×10-9' },
		expect = { true, '.000000000123', 12, '.000000000123' }
	},
	{ -- 20
		name = 'Create with string 0.123×10+9 argument',
		func = makeInstance,
		args = { '0.123×10+9' },
		expect = { true, '0123000000.', 0, '123000000' }
	},
	{ -- 21
		name = 'Create without argument',
		func = makeInstance,
		args = { mw.bcmath.new() },
		expect = { true, nil, 0, 'nan' }
	},
	{ -- 22
		name = 'Create with table 42 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '42' ) },
		expect = { true, '42', 0, '42' }
	},
	{ -- 23
		name = 'Create with table -42 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-42' ) },
		expect = { true, '-42', 0, '-42' }
	},
	{ -- 24
		name = 'Create with table 0.123 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '0.123' ) },
		expect = { true, '0.123', 3, '.123' }
	},
	{ -- 25
		name = 'Create with table -0.123 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123' ) },
		expect = { true, '-0.123', 3, '-.123' }
	},
	{ -- 26
		name = 'Create with table 0.123e⁹ argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123e⁹' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 27
		name = 'Create with table 0.123 × 10⁹ argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123 × 10⁹' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 28
		name = 'Create with table 0.123E9 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123E9' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 29
		name = 'Create with table 0.123D9 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123D9' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 30
		name = 'Create with table 0.123&9 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123&9' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 31
		name = 'Create with table 0.123𝗘9 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123𝗘9' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 32
		name = 'Create with table 0.123⏨9 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123⏨9' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 33
		name = 'Exists without argument',
		func = callMet,
		args = { mw.bcmath.new(), 'exists' },
		expect = { false }
	},
	{ -- 34
		name = 'IsNaN without argument',
		func = callMet,
		args = { mw.bcmath.new(), 'isNaN' },
		expect = { true }
	},
	{ -- 35
		name = 'Exists with empty string argument',
		func = callMet,
		args = { mw.bcmath.new( '' ), 'exists' },
		expect = { true }
	},
	{ -- 36
		name = 'IsNaN with empty string argument',
		func = callMet,
		args = { mw.bcmath.new( '' ), 'isNaN' },
		expect = { false }
	},
	{ -- 37
		name = 'Add 0 with 42.123',
		func = callInstance,
		args = { mw.bcmath.new( '0', 3 ), 'add', '42.123' },
		expect = { '42.123', 3 }
	},
	{ -- 38
		name = 'Add 0 with ∞',
		func = callInstance,
		args = { mw.bcmath.new( '0', 3 ), 'add', '+∞' },
		expect = { '+∞', 3 }
	},
	{ -- 39
		name = 'Add ∞ with 0',
		func = callInstance,
		args = { mw.bcmath.new( '+∞', 3 ), 'add', '0' },
		expect = { '+∞', 3 }
	},
	{ -- 40
		name = 'Add ∞ with ∞',
		func = callInstance,
		args = { mw.bcmath.new( '+∞', 3 ), 'add', '+∞' },
		expect = { '+∞', 3 }
	},
	{ -- 41
		name = 'Add ∞ with -∞',
		func = callInstance,
		args = { mw.bcmath.new( '∞', 3 ), 'add', '-∞' },
		expect = { nil, 3 }
	},
	{ -- 42
		name = 'Sub 0 with 42.123',
		func = callInstance,
		args = { mw.bcmath.new( '0', 3 ), 'sub', '42.123' },
		expect = { '-42.123', 3 }
	},
	{ -- 43
		name = 'Sub 0 with ∞',
		func = callInstance,
		args = { mw.bcmath.new( '0', 3 ), 'sub', '+∞' },
		expect = { '-∞', 3 }
	},
	{ -- 44
		name = 'Sub ∞ with 0',
		func = callInstance,
		args = { mw.bcmath.new( '+∞', 3 ), 'sub', '0' },
		expect = { '+∞', 3 }
	},
	{ -- 45
		name = 'Sub ∞ with ∞',
		func = callInstance,
		args = { mw.bcmath.new( '+∞', 3 ), 'sub', '+∞' },
		expect = { nil, 3 }
	},
	{ -- 46
		name = 'Sub ∞ with -∞',
		func = callInstance,
		args = { mw.bcmath.new( '+∞', 3 ), 'sub', '-∞' },
		expect = { '+∞', 3 }
	},
	{ -- 47
		name = 'Mul 21 with 2',
		func = callInstance,
		args = { mw.bcmath.new( '21.0', 3 ), 'mul', '2' },
		expect = { '42.0', 3 }
	},
	{ -- 47
		name = 'Mul 42 with 0',
		func = callInstance,
		args = { mw.bcmath.new( '42.0', 3 ), 'mul', '0' },
		expect = { '0.0', 3 }
	},
	{ -- 47
		name = 'Mul 0 with 42',
		func = callInstance,
		args = { mw.bcmath.new( '0', 3 ), 'mul', '42.0' },
		expect = { '0.0', 3 }
	},
	{ -- 47
		name = 'Mul ∞ with 0',
		func = callInstance,
		args = { mw.bcmath.new( '∞', 3 ), 'mul', '0' },
		expect = { nil, 3 }
	},
	{ -- 47
		name = 'Mul 0 with ∞',
		func = callInstance,
		args = { mw.bcmath.new( '0', 3 ), 'mul', '∞' },
		expect = { nil, 3 }
	},
	{ -- 47
		name = 'Mul +∞ with -∞',
		func = callInstance,
		args = { mw.bcmath.new( '+∞', 3 ), 'mul', '-∞' },
		expect = { '-∞', 3 }
	},
	{ -- 47
		name = 'Mul +∞ with +∞',
		func = callInstance,
		args = { mw.bcmath.new( '+∞', 3 ), 'mul', '+∞' },
		expect = { '+∞', 3 }
	},
	{ -- 48
		name = 'Div 42 with 2',
		func = callInstance,
		args = { mw.bcmath.new( '42.0', 3 ), 'div', '2' },
		expect = { '21.000', 3 }
	},
	{ -- 49
		name = 'Mod 42 with 6',
		func = callInstance,
		args = { mw.bcmath.new( '42.0', 3 ), 'mod', '6' },
		expect = { '0.000', 3 }
	},
	{ -- 50
		name = 'Pow 42 with 2',
		func = callInstance,
		args = { mw.bcmath.new( '42', 0 ), 'pow', '2' },
		expect = { '1764', 0 }
	},
	{ -- 51
		name = 'Powmod 42 with 2 and 6',
		func = callInstance,
		args = { mw.bcmath.new( '42', 0 ), 'powmod', '2', '6' },
		expect = { '0', 0 }
	},
	{ -- 52
		name = 'Sqrt 1764',
		func = callInstance,
		args = { mw.bcmath.new( '1764', 0 ), 'sqrt' },
		expect = { '42', 0 }
	},
	{ -- 53
		name = 'Add 21 + 21',
		func = callFunc,
		args = { 'add', '21', '21' },
		expect = { '42', 0 }
	},
	{ -- 54
		name = 'Add ∞ + 42',
		func = callFunc,
		args = { 'add', '+∞', '42' },
		expect = { '+∞', 0 }
	},
	{ -- 55
		name = 'Add 42 + ∞',
		func = callFunc,
		args = { 'add', '42', '+∞' },
		expect = { '+∞', 0 }
	},
	{ -- 56
		name = 'Add ∞ + ∞',
		func = callFunc,
		args = { 'add', '+∞', '+∞' },
		expect = { '+∞', 0 }
	},
	{ -- 57
		name = 'Add -∞ + ∞',
		func = callFunc,
		args = { 'add', '-∞', '+∞' },
		expect = { nil, 0 }
	},
	{ -- 58
		name = 'Sub 21 - 21',
		func = callFunc,
		args = { 'sub', '21', '21' },
		expect = { '0', 0 }
	},
	{ -- 59
		name = 'Sub 42 - ∞',
		func = callFunc,
		args = { 'sub', '42', '+∞' },
		expect = { '-∞', 0 }
	},
	{ -- 60
		name = 'Sub ∞ - ∞',
		func = callFunc,
		args = { 'sub', '+∞', '+∞' },
		expect = { nil, 0 }
	},
	{ -- 61
		name = 'Sub -∞ + ∞',
		func = callFunc,
		args = { 'sub', '-∞', '+∞' },
		expect = { '-∞', 0 }
	},
	{ -- 62
		name = 'Mul 42 * 42',
		func = callFunc,
		args = { 'mul', '42', '42' },
		expect = { '1764', 0 }
	},
	{ -- 63
		name = 'Div 42 / 42',
		func = callFunc,
		args = { 'div', '42', '42' },
		expect = { '1', 0 }
	},
	{ -- 64
		name = 'Mod 42 % 6',
		func = callFunc,
		args = { 'mod', '42', '6' },
		expect = { '0', 0 }
	},
	{ -- 65
		name = 'Pow 3 ^ 2',
		func = callFunc,
		args = { 'pow', '3', '2' },
		expect = { '9', 0 }
	},
	{ -- 66
		name = 'Powmod 3 ^ 2 % 7',
		func = callFunc,
		args = { 'powmod', '3', '2', '7' },
		expect = { '2', 0 }
	},
	{ -- 67
		name = 'Sqrt 9',
		func = callFunc,
		args = { 'sqrt', '9' },
		expect = { '3', 0 }
	},
	{ -- 68
		name = 'Comp 41 and 42',
		func = compFunc,
		args = { 'comp', '41', '42' },
		expect = { -1 }
	},
	{ -- 69
		name = 'Comp 42 and 42',
		func = compFunc,
		args = { 'comp', '42', '42' },
		expect = { 0 }
	},
	{ -- 70
		name = 'Comp 43 and 42',
		func = compFunc,
		args = { 'comp', '43', '42' },
		expect = { 1 }
	},
	{ -- 71
		name = 'Eq 42 == 42',
		func = compFunc,
		args = { 'eq', '42', '42' },
		expect = { true }
	},
	{ -- 72
		name = 'Eq 41 == 42',
		func = compFunc,
		args = { 'eq', '41', '42' },
		expect = { false }
	},
	{ -- 73
		name = 'Lt 41 < 42',
		func = compFunc,
		args = { 'lt', '41', '42' },
		expect = { true }
	},
	{ -- 74
		name = 'Lt 42 < 42',
		func = compFunc,
		args = { 'lt', '42', '42' },
		expect = { false }
	},
	{ -- 75
		name = 'Lt 43 < 42',
		func = compFunc,
		args = { 'lt', '43', '42' },
		expect = { false }
	},
	{ -- 76
		name = 'Le 41 <= 42',
		func = compFunc,
		args = { 'le', '41', '42' },
		expect = { true }
	},
	{ -- 77
		name = 'Le 42 <= 42',
		func = compFunc,
		args = { 'le', '42', '42' },
		expect = { true }
	},
	{ -- 78
		name = 'Le 43 <= 42',
		func = compFunc,
		args = { 'le', '43', '42' },
		expect = { false }
	},
	{ -- 79
		name = 'Gt 41 > 42',
		func = compFunc,
		args = { 'gt', '41', '42' },
		expect = { false }
	},
	{ -- 80
		name = 'Gt 42 > 42',
		func = compFunc,
		args = { 'gt', '42', '42' },
		expect = { false }
	},
	{ -- 81
		name = 'Gt 43 > 42',
		func = compFunc,
		args = { 'gt', '43', '42' },
		expect = { true }
	},
	{ -- 82
		name = 'Ge 41 >= 42',
		func = compFunc,
		args = { 'ge', '41', '42' },
		expect = { false }
	},
	{ -- 83
		name = 'Ge 42 >= 42',
		func = compFunc,
		args = { 'ge', '42', '42' },
		expect = { true }
	},
	{ -- 84
		name = 'Ge 43 >= 42',
		func = compFunc,
		args = { 'ge', '43', '42' },
		expect = { true }
	},
	{ -- 85
		name = 'fix 1.23456',
		func = makeCall,
		args = { mw.bcmath.new('1.23456'), 'fix' },
		expect = { '1.23456' }
	},
	{ -- 86
		name = 'fix -1.23456',
		func = makeCall,
		args = { mw.bcmath.new('-1.23456'), 'fix' },
		expect = { '-1.23456' }
	},
	{ -- 87
		name = 'fix -12.3456',
		func = makeCall,
		args = { mw.bcmath.new('-12.3456'), 'fix', 3 },
		expect = { '-12.3' }
	},
	{ -- 88
		name = 'fix -12.3456',
		func = makeCall,
		args = { mw.bcmath.new('-12.3456'), 'fix', 3 },
		expect = { '-12.3' }
	},
	{ -- 89
		name = 'fix -123.456',
		func = makeCall,
		args = { mw.bcmath.new('-123.456'), 'fix', 3 },
		expect = { '-123' }
	},
	{ -- 90
		name = 'fix -123.456',
		func = makeCall,
		args = { mw.bcmath.new('-123.456'), 'fix', 3 },
		expect = { '-123' }
	},
	{ -- 91
		name = 'eng 1.23456',
		func = makeCall,
		args = { mw.bcmath.new('1.23456'), 'eng' },
		expect = { '1.23456' }
	},
	{ -- 92
		name = 'eng -1.23456',
		func = makeCall,
		args = { mw.bcmath.new('-1.23456'), 'eng' },
		expect = { '-1.23456' }
	},
	{ -- 93
		name = 'eng 12.3456',
		func = makeCall,
		args = { mw.bcmath.new('12.3456'), 'eng', 3 },
		expect = { '12.34e1' }
	},
	{ -- 94
		name = 'eng -12.3456',
		func = makeCall,
		args = { mw.bcmath.new('-12.3456'), 'eng', 3 },
		expect = { '-12.34e1' }
	},
	{ -- 95
		name = 'eng 123.456',
		func = makeCall,
		args = { mw.bcmath.new('123.456'), 'eng', 3 },
		expect = { '123.45e2' }
	},
	{ -- 96
		name = 'eng -123.456',
		func = makeCall,
		args = { mw.bcmath.new('-123.456'), 'eng', 3 },
		expect = { '-123.45e2' }
	},
	{ -- 97
		name = 'eng 1234.56',
		func = makeCall,
		args = { mw.bcmath.new('1234.56'), 'eng', 3 },
		expect = { '1.23e3' }
	},
	{ -- 98
		name = 'eng -1234.56',
		func = makeCall,
		args = { mw.bcmath.new('-1234.56'), 'eng', 3 },
		expect = { '-1.23e3' }
	},
	{ -- 99
		name = 'sci 1.23456',
		func = makeCall,
		args = { mw.bcmath.new('1.23456'), 'sci' },
		expect = { '1.23456' }
	},
	{ -- 100
		name = 'sci -1.23456',
		func = makeCall,
		args = { mw.bcmath.new('-1.23456'), 'sci' },
		expect = { '-1.23456' }
	},
	{ -- 101
		name = 'sci -12.3456',
		func = makeCall,
		args = { mw.bcmath.new('-12.3456'), 'sci', 3 },
		expect = { '-1.23e1' }
	},
	{ -- 102
		name = 'sci -12.3456',
		func = makeCall,
		args = { mw.bcmath.new('-12.3456'), 'sci', 3 },
		expect = { '-1.23e1' }
	},
	{ -- 103
		name = 'sci -123.456',
		func = makeCall,
		args = { mw.bcmath.new('-123.456'), 'sci', 3 },
		expect = { '-1.23e2' }
	},
	{ -- 104
		name = 'sci -123.456',
		func = makeCall,
		args = { mw.bcmath.new('-123.456'), 'sci', 3 },
		expect = { '-1.23e2' }
	},
}

return testframework.getTestProvider( tests )
