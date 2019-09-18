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
	return res, ret:value(), ret:scale()
end

local function callInstance( obj, name, ... )
	obj[name]( obj, ... )
	return obj:value(), obj:scale()
end

local function callFunc( name, ... )
	return mw.bcmath[name]( ... )()
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
		expect = { false, 'string' }
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
		expect = { true, '+42.00000000000000', 14 }
	},
	{ -- 6
		name = 'Create with number -42 argument',
		func = makeInstance,
		args = { -42 },
		expect = { true, '-42.00000000000000', 14 }
	},
	{ -- 7
		name = 'Create with number 0.123 argument',
		func = makeInstance,
		args = { 0.123 },
		expect = { true, '+.1230000000000000', 16 }
	},
	{ -- 8
		name = 'Create with number -0.123 argument',
		func = makeInstance,
		args = { -0.123 },
		expect = { true, '-.1230000000000000', 16 }
	},
	{ -- 9
		name = 'Create with string 42 argument',
		func = makeInstance,
		args = { '42' },
		expect = { true, '42', 0 }
	},
	{ -- 10
		name = 'Create with string -42 argument',
		func = makeInstance,
		args = { '-42' },
		expect = { true, '-42', 0 }
	},
	{ -- 11
		name = 'Create with string 0.123 argument',
		func = makeInstance,
		args = { '0.123' },
		expect = { true, '0.123', 3 }
	},
	{ -- 12
		name = 'Create with string -0.123 argument',
		func = makeInstance,
		args = { '-0.123' },
		expect = { true, '-0.123', 3 }
	},
	{ -- 13
		name = 'Create with table 42 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '42' ) },
		expect = { true, '42', 0 }
	},
	{ -- 14
		name = 'Create with table -42 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-42' ) },
		expect = { true, '-42', 0 }
	},
	{ -- 15
		name = 'Create with table 0.123 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '0.123' ) },
		expect = { true, '0.123', 3 }
	},
	{ -- 16
		name = 'Create with table -0.123 argument',
		func = makeInstance,
		args = { mw.bcmath.new( '-0.123' ) },
		expect = { true, '-0.123', 3 }
	},
	{ -- 17
		name = 'Add 0 with 42.123',
		func = callInstance,
		args = { mw.bcmath.new( '0', 3 ), 'add', '42.123' },
		expect = { '42.123', 3 }
	},
	{ -- 18
		name = 'Sub 0 with 42.123',
		func = callInstance,
		args = { mw.bcmath.new( '0', 3 ), 'sub', '42.123' },
		expect = { '-42.123', 3 }
	},
	{ -- 19
		name = 'Mul 21 with 2',
		func = callInstance,
		args = { mw.bcmath.new( '21.0', 3 ), 'mul', '2' },
		expect = { '42.0', 3 } -- why has this one digit…
	},
	{ -- 20
		name = 'Div 42 with 2',
		func = callInstance,
		args = { mw.bcmath.new( '42.0', 3 ), 'div', '2' },
		expect = { '21.000', 3 }
	},
	{ -- 21
		name = 'Mod 42 with 6',
		func = callInstance,
		args = { mw.bcmath.new( '42.0', 3 ), 'mod', '6' },
		expect = { '0.000', 3 }
	},
	{ -- 22
		name = 'Pow 42 with 2',
		func = callInstance,
		args = { mw.bcmath.new( '42', 0 ), 'pow', '2' },
		expect = { '1764', 0 }
	},
	{ -- 23
		name = 'Powmod 42 with 2 and 6',
		func = callInstance,
		args = { mw.bcmath.new( '42', 0 ), 'powmod', '2', '6' },
		expect = { '0', 0 }
	},
	{ -- 24
		name = 'Sqrt 1764',
		func = callInstance,
		args = { mw.bcmath.new( '1764', 0 ), 'sqrt' },
		expect = { '42', 0 }
	},
	{ -- 25
		name = 'Add 21 + 21',
		func = callFunc,
		args = { 'add', '21', '21' },
		expect = { '42', 0 }
	},
	{ -- 26
		name = 'Sub 21 - 21',
		func = callFunc,
		args = { 'sub', '21', '21' },
		expect = { '0', 0 }
	},
	{ -- 27
		name = 'Mul 42 * 42',
		func = callFunc,
		args = { 'mul', '42', '42' },
		expect = { '1764', 0 }
	},
	{ -- 28
		name = 'Div 42 / 42',
		func = callFunc,
		args = { 'div', '42', '42' },
		expect = { '1', 0 }
	},
	{ -- 29
		name = 'Mod 42 % 6',
		func = callFunc,
		args = { 'mod', '42', '6' },
		expect = { '0', 0 }
	},
}

return testframework.getTestProvider( tests )
