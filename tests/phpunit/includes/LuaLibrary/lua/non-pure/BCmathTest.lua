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

local function makeCall( instance, ... )
	return instance( ... )
end

local function callInstance( obj, name, ... )
	obj[name]( obj, ... )
	return obj:value(), obj:scale()
end

local function callFunc( name, ... )
	local obj = mw.bcmath[name]( ... )
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
		expect = { true, nil, 0, '' }
	},
	{ -- 3
		name = 'Create with false argument',
		func = makeInstance,
		args = { false },
		expect = { false, 'string' }
	},
	{ -- 4
		name = 'Create with true argument',
		func = makeInstance,
		args = { true },
		expect = { false, 'string' }
	},
	{ -- 5
		name = 'Create with number 42 argument',
		func = makeInstance,
		args = { 42 },
		expect = { true, '+42.00000000000000', 14, '+42.00000000000000' }
	},
	{ -- 6
		name = 'Create with number -42 argument',
		func = makeInstance,
		args = { -42 },
		expect = { true, '-42.00000000000000', 14, '-42.00000000000000' }
	},
	{ -- 7
		name = 'Create with number 0.123 argument',
		func = makeInstance,
		args = { 0.123 },
		expect = { true, '+.1230000000000000', 16, '+.1230000000000000' }
	},
	{ -- 8
		name = 'Create with number -0.123 argument',
		func = makeInstance,
		args = { -0.123 },
		expect = { true, '-.1230000000000000', 16, '-.1230000000000000' }
	},
	{ -- 9
		name = 'Create with string 42 argument',
		func = makeInstance,
		args = { '42' },
		expect = { true, '42', 0, '42' }
	},
	{ -- 10
		name = 'Create with string -42 argument',
		func = makeInstance,
		args = { '-42' },
		expect = { true, '-42', 0, '-42' }
	},
	{ -- 11
		name = 'Create with string 0.123 argument',
		func = makeInstance,
		args = { '0.123' },
		expect = { true, '0.123', 3, '.123' }
	},
	{ -- 12
		name = 'Create with string -0.123 argument',
		func = makeInstance,
		args = { '-0.123' },
		expect = { true, '-0.123', 3, '-.123' }
	},
	{ -- 13
		name = 'Create with string 0.123e9 argument',
		func = makeInstance,
		args = { '0.123e9' },
		expect = { true, '0123000000.', 0, '123000000' }
	},
	{ -- 14
		name = 'Create with string -0.123e9 argument',
		func = makeInstance,
		args = { '-0.123e9' },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 15
		name = 'Create with string 0.123e-9 argument',
		func = makeInstance,
		args = { '0.123e-9' },
		expect = { true, '.000000000123', 12, '.000000000123' }
	},
	{ -- 16
		name = 'Create with string -0.123e-9 argument',
		func = makeInstance,
		args = { '-0.123e-9' },
		expect = { true, '-.000000000123', 12, '-.000000000123' }
	},
	{ -- 17
		name = 'Create with string 0.123×10-9 argument',
		func = makeInstance,
		args = { '0.123×10-9' },
		expect = { true, '.000000000123', 12, '.000000000123' }
	},
	{ -- 18
		name = 'Create with string 0.123×10+9 argument',
		func = makeInstance,
		args = { '0.123×10+9' },
		expect = { true, '0123000000.', 0, '123000000' }
	},
	{ -- 19
		name = 'Create with table 42 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '42' ) },
		expect = { true, '42', 0, '42' }
	},
	{ -- 20
		name = 'Create with table -42 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-42' ) },
		expect = { true, '-42', 0, '-42' }
	},
	{ -- 21
		name = 'Create with table 0.123 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '0.123' ) },
		expect = { true, '0.123', 3, '.123' }
	},
	{ -- 22
		name = 'Create with table -0.123 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123' ) },
		expect = { true, '-0.123', 3, '-.123' }
	},
	{ -- 23
		name = 'Create with table 0.123e⁹ argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123e⁹' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 24
		name = 'Create with table 0.123 × 10⁹ argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123 × 10⁹' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 25
		name = 'Create with table 0.123E9 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123E9' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 26
		name = 'Create with table 0.123D9 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123D9' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 27
		name = 'Create with table 0.123&9 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123&9' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 28
		name = 'Create with table 0.123𝗘9 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123𝗘9' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 29
		name = 'Create with table 0.123⏨9 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123⏨9' ) },
		expect = { true, '-0123000000.', 0, '-123000000' }
	},
	{ -- 30
		name = 'Add 0 with 42.123',
		func = callInstance,
		args = { mw.bcmath.new( '0', 3 ), 'add', '42.123' },
		expect = { '42.123', 3 }
	},
	{ -- 31
		name = 'Sub 0 with 42.123',
		func = callInstance,
		args = { mw.bcmath.new( '0', 3 ), 'sub', '42.123' },
		expect = { '-42.123', 3 }
	},
	{ -- 32
		name = 'Mul 21 with 2',
		func = callInstance,
		args = { mw.bcmath.new( '21.0', 3 ), 'mul', '2' },
		expect = { '42.0', 3 }
	},
	{ -- 33
		name = 'Div 42 with 2',
		func = callInstance,
		args = { mw.bcmath.new( '42.0', 3 ), 'div', '2' },
		expect = { '21.000', 3 }
	},
	{ -- 34
		name = 'Mod 42 with 6',
		func = callInstance,
		args = { mw.bcmath.new( '42.0', 3 ), 'mod', '6' },
		expect = { '0.000', 3 }
	},
	{ -- 35
		name = 'Pow 42 with 2',
		func = callInstance,
		args = { mw.bcmath.new( '42', 0 ), 'pow', '2' },
		expect = { '1764', 0 }
	},
	{ -- 36
		name = 'Powmod 42 with 2 and 6',
		func = callInstance,
		args = { mw.bcmath.new( '42', 0 ), 'powmod', '2', '6' },
		expect = { '0', 0 }
	},
	{ -- 37
		name = 'Sqrt 1764',
		func = callInstance,
		args = { mw.bcmath.new( '1764', 0 ), 'sqrt' },
		expect = { '42', 0 }
	},
	{ -- 38
		name = 'Add 21 + 21',
		func = callFunc,
		args = { 'add', '21', '21' },
		expect = { '42', 0 }
	},
	{ -- 39
		name = 'Sub 21 - 21',
		func = callFunc,
		args = { 'sub', '21', '21' },
		expect = { '0', 0 }
	},
	{ -- 40
		name = 'Mul 42 * 42',
		func = callFunc,
		args = { 'mul', '42', '42' },
		expect = { '1764', 0 }
	},
	{ -- 41
		name = 'Div 42 / 42',
		func = callFunc,
		args = { 'div', '42', '42' },
		expect = { '1', 0 }
	},
	{ -- 42
		name = 'Mod 42 % 6',
		func = callFunc,
		args = { 'mod', '42', '6' },
		expect = { '0', 0 }
	},
	{ -- 43
		name = 'Pow 3 ^ 2',
		func = callFunc,
		args = { 'pow', '3', '2' },
		expect = { '9', 0 }
	},
	{ -- 44
		name = 'Powmod 3 ^ 2 % 7',
		func = callFunc,
		args = { 'powmod', '3', '2', '7' },
		expect = { '2', 0 }
	},
	{ -- 45
		name = 'Sqrt 9',
		func = callFunc,
		args = { 'sqrt', '9' },
		expect = { '3', 0 }
	},
	{ -- 46
		name = 'Comp 41 and 42',
		func = compFunc,
		args = { 'comp', '41', '42' },
		expect = { -1 }
	},
	{ -- 47
		name = 'Comp 42 and 42',
		func = compFunc,
		args = { 'comp', '42', '42' },
		expect = { 0 }
	},
	{ -- 48
		name = 'Comp 43 and 42',
		func = compFunc,
		args = { 'comp', '43', '42' },
		expect = { 1 }
	},
	{ -- 49
		name = 'Eq 42 == 42',
		func = compFunc,
		args = { 'eq', '42', '42' },
		expect = { true }
	},
	{ -- 50
		name = 'Eq 41 == 42',
		func = compFunc,
		args = { 'eq', '41', '42' },
		expect = { false }
	},
	{ -- 51
		name = 'Lt 41 < 42',
		func = compFunc,
		args = { 'lt', '41', '42' },
		expect = { true }
	},
	{ -- 52
		name = 'Lt 42 < 42',
		func = compFunc,
		args = { 'lt', '42', '42' },
		expect = { false }
	},
	{ -- 53
		name = 'Lt 43 < 42',
		func = compFunc,
		args = { 'lt', '43', '42' },
		expect = { false }
	},
	{ -- 54
		name = 'Le 41 <= 42',
		func = compFunc,
		args = { 'le', '41', '42' },
		expect = { true }
	},
	{ -- 55
		name = 'Le 42 <= 42',
		func = compFunc,
		args = { 'le', '42', '42' },
		expect = { true }
	},
	{ -- 56
		name = 'Le 43 <= 42',
		func = compFunc,
		args = { 'le', '43', '42' },
		expect = { false }
	},
	{ -- 57
		name = 'Gt 41 > 42',
		func = compFunc,
		args = { 'gt', '41', '42' },
		expect = { false }
	},
	{ -- 58
		name = 'Gt 42 > 42',
		func = compFunc,
		args = { 'gt', '42', '42' },
		expect = { false }
	},
	{ -- 59
		name = 'Gt 43 > 42',
		func = compFunc,
		args = { 'gt', '43', '42' },
		expect = { true }
	},
	{ -- 60
		name = 'Ge 41 >= 42',
		func = compFunc,
		args = { 'ge', '41', '42' },
		expect = { false }
	},
	{ -- 61
		name = 'Ge 42 >= 42',
		func = compFunc,
		args = { 'ge', '42', '42' },
		expect = { true }
	},
	{ -- 62
		name = 'Ge 43 >= 42',
		func = compFunc,
		args = { 'ge', '43', '42' },
		expect = { true }
	},
	{ -- 63
		name = 'fix 1.23456',
		func = makeCall,
		args = { mw.bcmath.new('1.23456'), 'fix' },
		expect = { '1.23456' }
	},
	{ -- 64
		name = 'fix -1.23456',
		func = makeCall,
		args = { mw.bcmath.new('-1.23456'), 'fix' },
		expect = { '-1.23456' }
	},
	{ -- 65
		name = 'fix -12.3456',
		func = makeCall,
		args = { mw.bcmath.new('-12.3456'), 'fix', 3 },
		expect = { '-12.3' }
	},
	{ -- 66
		name = 'fix -12.3456',
		func = makeCall,
		args = { mw.bcmath.new('-12.3456'), 'fix', 3 },
		expect = { '-12.3' }
	},
	{ -- 67
		name = 'fix -123.456',
		func = makeCall,
		args = { mw.bcmath.new('-123.456'), 'fix', 3 },
		expect = { '-123' }
	},
	{ -- 68
		name = 'fix -123.456',
		func = makeCall,
		args = { mw.bcmath.new('-123.456'), 'fix', 3 },
		expect = { '-123' }
	},
	{ -- 69
		name = 'eng 1.23456',
		func = makeCall,
		args = { mw.bcmath.new('1.23456'), 'eng' },
		expect = { '1.23456' }
	},
	{ -- 70
		name = 'eng -1.23456',
		func = makeCall,
		args = { mw.bcmath.new('-1.23456'), 'eng' },
		expect = { '-1.23456' }
	},
	{ -- 71
		name = 'eng 12.3456',
		func = makeCall,
		args = { mw.bcmath.new('12.3456'), 'eng', 3 },
		expect = { '12.34e1' }
	},
	{ -- 72
		name = 'eng -12.3456',
		func = makeCall,
		args = { mw.bcmath.new('-12.3456'), 'eng', 3 },
		expect = { '-12.34e1' }
	},
	{ -- 73
		name = 'eng 123.456',
		func = makeCall,
		args = { mw.bcmath.new('123.456'), 'eng', 3 },
		expect = { '123.45e2' }
	},
	{ -- 74
		name = 'eng -123.456',
		func = makeCall,
		args = { mw.bcmath.new('-123.456'), 'eng', 3 },
		expect = { '-123.45e2' }
	},
	{ -- 75
		name = 'eng 1234.56',
		func = makeCall,
		args = { mw.bcmath.new('1234.56'), 'eng', 3 },
		expect = { '1.23e3' }
	},
	{ -- 76
		name = 'eng -1234.56',
		func = makeCall,
		args = { mw.bcmath.new('-1234.56'), 'eng', 3 },
		expect = { '-1.23e3' }
	},
	{ -- 77
		name = 'sci 1.23456',
		func = makeCall,
		args = { mw.bcmath.new('1.23456'), 'sci' },
		expect = { '1.23456' }
	},
	{ -- 78
		name = 'sci -1.23456',
		func = makeCall,
		args = { mw.bcmath.new('-1.23456'), 'sci' },
		expect = { '-1.23456' }
	},
	{ -- 79
		name = 'sci -12.3456',
		func = makeCall,
		args = { mw.bcmath.new('-12.3456'), 'sci', 3 },
		expect = { '-1.23e1' }
	},
	{ -- 80
		name = 'sci -12.3456',
		func = makeCall,
		args = { mw.bcmath.new('-12.3456'), 'sci', 3 },
		expect = { '-1.23e1' }
	},
	{ -- 81
		name = 'sci -123.456',
		func = makeCall,
		args = { mw.bcmath.new('-123.456'), 'sci', 3 },
		expect = { '-1.23e2' }
	},
	{ -- 82
		name = 'sci -123.456',
		func = makeCall,
		args = { mw.bcmath.new('-123.456'), 'sci', 3 },
		expect = { '-1.23e2' }
	},
}

return testframework.getTestProvider( tests )
