--- Tests for the BCmath library.
-- @license GPL-2.0-or-later
-- @author John Erling Blad < jeblad@gmail.com >

local testframework = require 'Module:TestFramework'

local function testExists()
	return type( mw.bcmath )
end

local function makeInstance( ... )
	local results = {}
	for i,v in ipairs( { ... } ) do
		local res,ret = pcall( function( ... )
			return mw.bcmath.new( ... )
		end, unpack( v ) )
		if not res then
			results[i] = { res, type( ret ) } -- never mind the actual content
		else
			results[i] = { res, ret:value(), ret:scale(), tostring( ret ) }
		end
	end
	return unpack( results )
end

local function makeCall( ... )
	local results = {}
	for i,v in ipairs( { ... } ) do
		local obj = table.remove( v, 1 )
		assert( obj, 'makeCall could not find object' )
		results[i] = { obj( unpack( v ) ) }
	end
	return unpack( results )
end

local function callMet( name, ... )
	assert( name, 'callMet is missing name' )
	local results = {}
	for i,v in ipairs( { ... } ) do
		local obj = table.remove( v, 1 )
		assert( obj, 'callMet could not find object' )
		assert( obj[name], 'callMet is missing method' )
		results[i] = { obj[name]( obj, unpack( v ) ) }
	end
	return unpack( results )
end

local function callInstance( name, ... )
	assert( name, 'callInstance is missing name' )
	local results = {}
	for i,v in ipairs( { ... } ) do
		local obj = table.remove( v, 1 )
		assert( obj, 'callInstance could not find object' )
		assert( obj[name], 'callInstance is missing method' )
		obj[name]( obj, unpack( v ) )
		results[i] = { obj:value(), obj:scale() }
	end
	return unpack( results )
end

local function compInstance( name, ... )
	assert( name, 'compInstance is missing name' )
	local results = {}
	for i,v in ipairs( { ... } ) do
		local obj = table.remove( v, 1 )
		assert( obj, 'compInstance could not find object' )
		assert( obj[name], 'compInstance is missing method' )
		results[i] = { obj[name]( obj, unpack( v ) ) }
	end
	return unpack( results )
end

local function callFunc( name, ... )
	assert( name, 'callFunc is missing name' )
	local results = {}
	for i,v in ipairs( { ... } ) do
		local obj = mw.bcmath[name]( unpack( v ) )
		assert( obj, 'callFunc could not create object' )
		results[i] = { obj:value(), obj:scale() }
	end
	return unpack( results )
end

local function compFunc( name, ... )
	assert( name, 'compFunc is missing name' )
	assert( mw.bcmath[name], 'compFunc is missing function' )
	local results = {}
	for i,v in ipairs( { ...} ) do
		results[i] = { mw.bcmath[name]( unpack( v ) ) }
	end
	return unpack( results )
end

local tests = {
	{ -- 1
		name = 'Verify the lib is loaded and exists',
		func = testExists,
		type = 'ToString',
		expect = { 'table' }
	},
	{ -- 2
		name = 'Create',
		func = makeInstance,
		args = {
			{ nil },
			{ '' },
			{ '0' },
			{ false },
			{ true },
			{ 42 },
			{ -42 },
			{ 0.123 },
			{ -0.123 },
			{ '42' },
			{ '-42' },
			{ '0.123' },
			{ '-0.123' },
			{ '0.123e9' },
			{ '-0.123e9' },
			{ '0.123e-9' },
			{ '-0.123e-9' },
			{ '0.123×10-9' },
			{ '0.123×10+9' },
			{ mw.bcmath.new() },
			{ mw.bcmath.new( '42' ) },
			{ mw.bcmath.new( '-42' ) },
			{ mw.bcmath.new( '0.123' ) },
			{ mw.bcmath.new( '-0.123' ) },
			{ mw.bcmath.new( '-0.123e⁹' ) },
			{ mw.bcmath.new( '-0.123 × 10⁹' ) },
			{ mw.bcmath.new( '-0.123E9' ) },
			{ mw.bcmath.new( '-0.123D9' ) },
			{ mw.bcmath.new( '-0.123&9' ) },
			{ mw.bcmath.new( '-0.123𝗘9' ) },
			{ mw.bcmath.new( '-0.123⏨9' ) },
		},
		expect = {
			{ true, nil, 0, 'nan' },
			{ true, '', 0, '0' },
			{ true, '0', 0, '0' },
			{ false, 'string' },
			{ false, 'string' },
			{ true, '+42.00000000000000', 14, '+42' },
			{ true, '-42.00000000000000', 14, '-42' },
			{ true, '+.1230000000000000', 16, '+.1230000000000000' },
			{ true, '-.1230000000000000', 16, '-.1230000000000000' },
			{ true, '42', 0, '42' },
			{ true, '-42', 0, '-42' },
			{ true, '0.123', 3, '.123' },
			{ true, '-0.123', 3, '-.123' },
			{ true, '0123000000.', 0, '123000000' },
			{ true, '-0123000000.', 0, '-123000000' },
			{ true, '.000000000123', 12, '.000000000123' },
			{ true, '-.000000000123', 12, '-.000000000123' },
			{ true, '.000000000123', 12, '.000000000123' },
			{ true, '0123000000.', 0, '123000000' },
			{ true, nil, 0, 'nan' },
			{ true, '42', 0, '42' },
			{ true, '-42', 0, '-42' },
			{ true, '0.123', 3, '.123' },
			{ true, '-0.123', 3, '-.123' },
			{ true, '-0123000000.', 0, '-123000000' },
			{ true, '-0123000000.', 0, '-123000000' },
			{ true, '-0123000000.', 0, '-123000000' },
			{ true, '-0123000000.', 0, '-123000000' },
			{ true, '-0123000000.', 0, '-123000000' },
			{ true, '-0123000000.', 0, '-123000000' },
			{ true, '-0123000000.', 0, '-123000000' },
		}
	},
	{ -- 3
		name = 'Exists',
		func = callMet,
		args = { 'exists',
			{ mw.bcmath.new() },
			{ mw.bcmath.new( '' ) },
		},
		expect = {
			{ false },
			{ true },
		}
	},
	{ -- 4
		name = 'IsNaN',
		func = callMet,
		args = { 'isNaN',
			{ mw.bcmath.new() },
			{ mw.bcmath.new( '' ) },
		},
		expect = {
			{ true },
			{ false },
		}
	},
	{ -- 5
		name = 'Negative',
		func = callInstance,
		args = { 'neg',
			{ mw.bcmath.new( '42' ) },
			{ mw.bcmath.new( '+42' ) },
			{ mw.bcmath.new( '-42' ) },
		},
		expect = {
			{ '-42', 0 },
			{ '-42', 0 },
			{ '+42', 0 },
		}
	},
	{ -- 6
		name = 'Addition',
		func = callInstance,
		args = { 'add',
			{ mw.bcmath.new( '0', 3 ), '42.123' },
			{ mw.bcmath.new( '0', 3 ), '+∞' },
			{ mw.bcmath.new( '+∞', 3 ), '0' },
			{ mw.bcmath.new( '+∞', 3 ), '+∞' },
			{ mw.bcmath.new( '∞', 3 ), '-∞' },
		},
		expect = {
			{ '42.123', 3 },
			{ '+∞', 3 },
			{ '+∞', 3 },
			{ '+∞', 3 },
			{ nil, 3 },
		}
	},
	{ -- 7
		name = 'Subtraction',
		func = callInstance,
		args = { 'sub',
			{ mw.bcmath.new( '0', 3 ), '42.123' },
			{ mw.bcmath.new( '0', 3 ), '+∞' },
			{ mw.bcmath.new( '+∞', 3 ), '0' },
			{ mw.bcmath.new( '+∞', 3 ), '+∞' },
			{ mw.bcmath.new( '+∞', 3 ), '-∞' },
		},
		expect = {
			{ '-42.123', 3 },
			{ '-∞', 3 },
			{ '+∞', 3 },
			{ nil, 3 },
			{ '+∞', 3 },
		}
	},

	{ -- 8
		name = 'Multiply',
		func = callInstance,
		args = { 'mul',
			{ mw.bcmath.new( '21.0', 3 ), '2' },
			{ mw.bcmath.new( '42.0', 3 ), '0' },
			{ mw.bcmath.new( '0', 3 ), '42.0' },
			{ mw.bcmath.new( '∞', 3 ), '0' },
			{ mw.bcmath.new( '0', 3 ), '∞' },
			{ mw.bcmath.new( '42', 3 ), '∞' },
			{ mw.bcmath.new( '+∞', 3 ), '-∞' },
			{ mw.bcmath.new( '+∞', 3 ), '+∞' },
		},
		expect = {
			{ '42.0', 3 },
			{ '0.0', 3 },
			{ '0.0', 3 },
			{ nil, 3 },
			{ nil, 3 },
			{ '-42', 3 }, --@todo bug – this should be '∞'
			{ '-∞', 3 },
			{ '+∞', 3 },
		}
	},
	{ -- 9
		name = 'Divide',
		func = callInstance,
		args = { 'div',
			{ mw.bcmath.new( '42.0', 3 ), '2' },
			{ mw.bcmath.new( '42.0', 3 ), '0' },
			{ mw.bcmath.new( '0', 3 ), '42' },
			{ mw.bcmath.new( '42.0', 3 ), '+∞' },
			{ mw.bcmath.new( '+∞', 3 ), '42' },
			{ mw.bcmath.new( '+∞', 3 ), '+∞' },
		},
		expect = {
			{ '21.000', 3 },
			{ nil, 3 },
			{ '0.000', 3 },
			{ '0', 3 },
			{ '+∞', 3 },
			{ nil, 3 },
		}
	},
	{ -- 10
		name = 'Modulus',
		func = callInstance,
		args = { 'mod',
			{ mw.bcmath.new( '42.0', 3 ), '6' },
			{ mw.bcmath.new( '42.0', 3 ), '0' },
			{ mw.bcmath.new( '0', 3 ), '42' },
			{ mw.bcmath.new( '42.0', 3 ), '+∞' },
			{ mw.bcmath.new( '+∞', 3 ), '42' },
			{ mw.bcmath.new( '+∞', 3 ), '+∞' },
		},
		expect = {
			{ '0.000', 3 },
			{ nil, 3 },
			{ '0.000', 3 },
			{ '0', 3 },
			{ '+∞', 3 },
			{ nil, 3 },
		}
	},
	{ -- 11
		name = 'Power',
		func = callInstance,
		args = { 'pow',
			{ mw.bcmath.new( '42', 0 ), '2' },
			{ mw.bcmath.new( '42', 0 ), '0' },
			{ mw.bcmath.new( '1', 0 ), '0' },
			{ mw.bcmath.new( '1', 0 ), '2' },
		},
		expect = {
			{ '1764', 0 },
			{ '1', 0 },
			{ '1', 0 },
			{ '1', 0 },
		}
	},
	{ -- 12
		name = 'Power-modulus',
		func = callInstance,
		args = { 'powmod',
			{ mw.bcmath.new( '42', 0 ), '2', '6' },
			{ mw.bcmath.new( '42', 0 ), '-2', '6' },
			{ mw.bcmath.new( '42', 0 ), '2', '0' },
		},
		expect = {
			{ '0', 0 },
			{ nil, 0 },
			{ nil, 0 },
		}
	},
	{ -- 13
		name = 'Sqare root',
		func = callInstance,
		args = { 'sqrt',
			{ mw.bcmath.new( '1764', 0 ) },
			{ mw.bcmath.new( '0', 0 ) },
			{ mw.bcmath.new( '-1764', 0 ) },
		},
		expect = {
			{ '42', 0 },
			{ '0', 0 },
			{ nil, 0 },
		}
	},
	{ -- 14
		name = 'Compare',
		func = compInstance,
		args = { 'comp',
			{ mw.bcmath.new( '41', 0 ), '42' },
			{ mw.bcmath.new( '42', 0 ), '42' },
			{ mw.bcmath.new( '43', 0 ), '42' },
			{ mw.bcmath.new( '-∞', 0 ), '42' },
			{ mw.bcmath.new( '+∞', 0 ), '42' },
			{ mw.bcmath.new( '-∞', 0 ), '+∞' },
			{ mw.bcmath.new( '+∞', 0 ), '-∞' },
			{ mw.bcmath.new( '+∞', 0 ), '+∞' },
		},
		expect = {
			{ -1 },
			{ 0 },
			{ 1 },
			{ -1 },
			{ 1 },
			{ -1 },
			{ 1 },
			{ nil },
		}
	},
	{ -- 15
		name = 'Round',
		func = callInstance,
		args = { 'round',
			{ mw.bcmath.new( '-123.456' ), 7 },
			{ mw.bcmath.new( '-123.456' ), 6 },
			{ mw.bcmath.new( '-123.456' ), 5 },
			{ mw.bcmath.new( '-123.456' ), 4 },
			{ mw.bcmath.new( '-123.456' ), 3 },
			{ mw.bcmath.new( '-123.456' ), 2 },
			{ mw.bcmath.new( '-123.456' ), 1 },
			{ mw.bcmath.new( '-456.789' ), 4 },
			{ mw.bcmath.new( '-456.789' ), 3 },
			{ mw.bcmath.new( '-456.789' ), 2 },
			{ mw.bcmath.new( '-456.789' ), 1 },
		},
		expect = {
			{ '-123.456', 3 },
			{ '-123.456', 3 },
			{ '-123.46', 3 },
			{ '-123.5', 3 },
			{ '-123', 3 },
			{ '-120', 3 },
			{ '-100', 3 },
			{ '-456.8', 3 },
			{ '-457', 3 },
			{ '-460', 3 },
			{ '-500', 3 },
		}
	},
	{ -- 16
		name = 'Get sign',
		func = compFunc,
		args = { 'getSign',
			{ nil },
			{ '' },
			{ '0' },
			{ '+0' },
			{ '-0' },
			{ '42' },
			{ '+42' },
			{ '-42' },
			{ '∞' },
			{ '+∞' },
			{ '-∞' },
		},
		expect = {
			{ nil },
			{ 1 },
			{ 1 },
			{ 1 },
			{ -1 },
			{ 1 },
			{ 1 },
			{ -1 },
			{ 1 },
			{ 1 },
			{ -1 },
		}
	},
	{ -- 17
		name = 'Get accumulated sign',
		func = compFunc,
		args = { 'getAccumulatedSign',
			{ nil },
			{ '' },
			{ '1' },
			{ '+1' },
			{ '-1' },
			{ '1', '-1', '1' },
			{ '1', '-1', '-1', '1' },
			{ '1', '-1', '1', '-1', '1' },
			{ '1', '-1', '-1', '-1', '1' },
			{ '1', '-1', '1', '-1', '-1', '1' },
			{ '1', '-1', '-1', '-1', '-1', '1' },
		},
		expect = {
			{ nil },
			{ 1 },
			{ 1 },
			{ 1 },
			{ -1 },
			{ -1 },
			{ 1 },
			{ 1 },
			{ -1 },
			{ -1 },
			{ 1 },
		}
	},
	{ -- 18
		name = 'Get signed zero',
		func = compFunc,
		args = { 'getSignedZero',
			{ nil },
			{ '' },
			{ '0' },
			{ '+0' },
			{ '-0' },
			{ '42' },
			{ '+42' },
			{ '-42' },
			{ '∞' },
			{ '+∞' },
			{ '-∞' },
		},
		expect = {
			{ nil },
			{ nil },
			{ '+0' },
			{ '+0' },
			{ '-0' },
			{ nil },
			{ nil },
			{ nil },
			{ nil },
			{ nil },
			{ nil },
		}
	},
	{ -- 19
		name = 'Get infinite',
		func = compFunc,
		args = { 'getInfinite',
			{ nil },
			{ '' },
			{ '0' },
			{ '+0' },
			{ '-0' },
			{ '42' },
			{ '+42' },
			{ '-42' },
			{ '∞' },
			{ '+∞' },
			{ '-∞' },
		},
		expect = {
			{ nil },
			{ nil },
			{ nil },
			{ nil },
			{ nil },
			{ nil },
			{ nil },
			{ nil },
			{ '+∞' },
			{ '+∞' },
			{ '-∞' },
		}
	},
	{ -- 20
		name = 'Is zero',
		func = compFunc,
		args = { 'isZero',
			{ nil },
			{ '' },
			{ '0' },
			{ '+0' },
			{ '-0' },
			{ '42' },
			{ '+42' },
			{ '-42' },
			{ '∞' },
			{ '+∞' },
			{ '-∞' },
		},
		expect = {
			{ nil },
			{ false },
			{ true },
			{ true },
			{ true },
			{ false },
			{ false },
			{ false },
			{ false },
			{ false },
			{ false },
		}
	},
	{ -- 21
		name = 'Is finite',
		func = compFunc,
		args = { 'isFinite',
			{ nil },
			{ '' },
			{ '0' },
			{ '+0' },
			{ '-0' },
			{ '42' },
			{ '+42' },
			{ '-42' },
			{ '∞' },
			{ '+∞' },
			{ '-∞' },
		},
		expect = {
			{ nil },
			{ false },
			{ true },
			{ true },
			{ true },
			{ true },
			{ true },
			{ true },
			{ false },
			{ false },
			{ false },
		}
	},
	{ -- 22
		name = 'Is infinite',
		func = compFunc,
		args = { 'isInfinite',
			{ nil },
			{ '' },
			{ '0' },
			{ '+0' },
			{ '-0' },
			{ '42' },
			{ '+42' },
			{ '-42' },
			{ '∞' },
			{ '+∞' },
			{ '-∞' },
		},
		expect = {
			{ nil },
			{ false },
			{ false },
			{ false },
			{ false },
			{ false },
			{ false },
			{ false },
			{ true },
			{ true },
			{ true },
		}
	},
	{ -- 23
		name = 'Negation',
		func = compFunc,
		args = { 'neg',
			{ '42' },
			{ '+42' },
			{ '-42' },
			{ '∞' },
			{ '+∞' },
			{ '-∞' },
		},
		expect = {
			{ '-42' },
			{ '-42' },
			{ '+42' },
			{ '-∞' },
			{ '-∞' },
			{ '+∞' },
		}
	},
	{ -- 24
		name = 'Addition',
		func = callFunc,
		args = { 'add',
			{ '21', '21' },
			{ '21', '-21' },
			{ '+∞', '42' },
			{ '42', '+∞' },
			{ '+∞', '+∞' },
			{ '-∞', '+∞' },
		},
		expect = {
			{ '42', 0 },
			{ '0', 0 },
			{ '+∞', 0 },
			{ '+∞', 0 },
			{ '+∞', 0 },
			{ nil, 0 },
		}
	},
	{ -- 25
		name = 'Subtraction',
		func = callFunc,
		args = { 'sub',
			{ '21', '21' },
			{ '21', '-21' },
			{ '+∞', '42' },
			{ '42', '+∞' },
			{ '+∞', '+∞' },
			{ '-∞', '+∞' },
		},
		expect = {
			{ '0', 0 },
			{ '42', 0 },
			{ '+∞', 0 },
			{ '-∞', 0 },
			{ nil, 0 },
			{ '-∞', 0 },
		}
	},
	{ -- 26
		name = 'Multiply',
		func = callFunc,
		args = { 'mul',
			{ '4.2', '4.2' },
			{ '4.2', '-4.2' },
			{ '42', '42' },
			{ '42', '-42' },
			{ '42', '0' },
			{ '0', '42' },
			{ '42', '∞' },
		},
		expect = {
			{ '17.6', 1 },
			{ '-17.6', 1},
			{ '1764', 0 },
			{ '-1764', 0 },
			{ '0', 0 },
			{ '0', 0 },
			{ '-42', 0 }, -- @todo bug – this should be '∞'
		}
	},
	{ -- 27
		name = 'Division',
		func = callFunc,
		args = { 'div',
			{ '42', '42' },
			{ '42.0', '0' },
			{ '0', '42.0' },
			{ '42.0', '+∞' },
			{ '+∞', '42' },
			{ '+∞', '+∞' },
		},
		expect = {
			{ '1', 0 },
			{ nil, 1 },
			{ '0.0', 1 },
			{ '0', 1 },
			{ '+∞', 0 },
			{ nil, 0 },
		}
	},
	{ -- 28
		name = 'Modulus',
		func = callFunc,
		args = { 'mod',
			{ '42', '6' },
			{ '42.0', '0' },
			{ '0', '42' },
			{ '42.0', '+∞' },
			{ '+∞', '42' },
			{ '+∞', '+∞' },
		},
		expect = {
			{ '0', 0 },
			{ nil, 1 },
			{ '0', 0 },
			{ '0', 1 },
			{ '+∞', 0 },
			{ nil, 0 },
		}
	},
	{ -- 29
		name = 'Power',
		func = callFunc,
		args = { 'pow',
			{ '3', '2' },
			{ '3', '0' },
			{ '1', '0' },
			{ '1', '2' },
		},
		expect = {
			{ '9', 0 },
			{ '1', 0 },
			{ '1', 0 },
			{ '1', 0 },
		}
	},
	{ -- 30
		name = 'Power-modulus',
		func = callFunc,
		args = { 'powmod',
			{ '3', '2', '7' },
			{ '3', '2', '0' },
		},
		expect = {
			{ '2', 0 },
			{ nil, 0 },
		}
	},
	{ -- 31
		name = 'Sqrt 9',
		func = callFunc,
		args = { 'sqrt',
			{ '9' },
			{ '0' },
			{ '-1764' },
		},
		expect = {
			{ '3', 0 },
			{ '0', 0 },
			{ nil, 0 },
		}
	},
	{ -- 32
		name = 'Compare',
		func = compFunc,
		args = { 'comp',
			{ '41', '42' },
			{ '42', '42' },
			{ '43', '42' },
			{ '-∞', '42' },
			{ '+∞', '42' },
			{ '-∞', '+∞' },
			{ '-∞', '-∞' },
		},
		expect = {
			{ -1 },
			{ 0 },
			{ 1 },
			{ -1 },
			{ 1 },
			{ -1 },
			{ nil },
		}
	},
	{ -- 33
		name = 'Equality',
		func = compFunc,
		args = { 'eq',
			{ '42', '42' },
			{ '41', '42' },
		},
		expect = {
			{ true },
			{ false },
		}
	},
	{ -- 34
		name = 'Less than',
		func = compFunc,
		args = { 'lt',
			{ '41', '42' },
			{ '42', '42' },
			{ '43', '42' },
		},
		expect = {
			{ true },
			{ false },
			{ false },
		}
	},
	{ -- 35
		name = 'Less or equal',
		func = compFunc,
		args = { 'le',
			{ '41', '42' },
			{ '42', '42' },
			{ '43', '42' },
		},
		expect = {
			{ true },
			{ true },
			{ false },
		}
	},
	{ -- 36
		name = 'Greater than',
		func = compFunc,
		args = { 'gt',
			{ '41', '42' },
			{ '42', '42' },
			{ '43', '42' },
		},
		expect = {
			{ false },
			{ false },
			{ true },
		}
	},
	{ -- 37
		name = 'Greater or equal',
		func = compFunc,
		args = { 'ge',
			{ '41', '42' },
			{ '42', '42' },
			{ '43', '42' },
		},
		expect = {
			{ false },
			{ true },
			{ true },
		}
	},
	{ -- 38
		name = 'call fix',
		func = makeCall,
		args = {
			{ mw.bcmath.new('.123456'), 'fix' },
			{ mw.bcmath.new('-.123456'), 'fix' },
			{ mw.bcmath.new('1.23456'), 'fix' },
			{ mw.bcmath.new('-1.23456'), 'fix' },
			{ mw.bcmath.new('12.3456'), 'fix', 3 },
			{ mw.bcmath.new('-12.3456'), 'fix', 3 },
			{ mw.bcmath.new('123.456'), 'fix', 3 },
			{ mw.bcmath.new('-123.456'), 'fix', 3 },
		},
		expect = {
			{ '0.123456' },
			{ '-0.123456' },
			{ '1.23456' },
			{ '-1.23456' },
			{ '12.3' },
			{ '-12.3' },
			{ '123' },
			{ '-123' },
		}
	},

	{ -- 39
		name = 'call eng',
		func = makeCall,
		args = {
			{ mw.bcmath.new('.123456'), 'eng' },
			{ mw.bcmath.new('-.123456'), 'eng' },
			{ mw.bcmath.new('1.23456'), 'eng' },
			{ mw.bcmath.new('-1.23456'), 'eng' },
			{ mw.bcmath.new('12.3456'), 'eng', 3 },
			{ mw.bcmath.new('-12.3456'), 'eng', 3 },
			{ mw.bcmath.new('123.456'), 'eng', 3 },
			{ mw.bcmath.new('-123.456'), 'eng', 3 },
			{ mw.bcmath.new('1234.56'), 'eng', 3 },
			{ mw.bcmath.new('-1234.56'), 'eng', 3 },
		},
		expect = {
			{ '123.456e-3' },
			{ '-123.456e-3' },
			{ '1.23456' },
			{ '-1.23456' },
			{ '12.3' },
			{ '-12.3' },
			{ '123' },
			{ '-123' },
			{ '1.23e3' },
			{ '-1.23e3' },
		}
	},
	{ -- 40
		name = 'call sci',
		func = makeCall,
		args = {
			{ mw.bcmath.new('.123456'), 'sci' },
			{ mw.bcmath.new('-.123456'), 'sci' },
			{ mw.bcmath.new('1.23456'), 'sci' },
			{ mw.bcmath.new('-1.23456'), 'sci' },
			{ mw.bcmath.new('12.3456'), 'sci', 3 },
			{ mw.bcmath.new('-12.3456'), 'sci', 3 },
			{ mw.bcmath.new('123.456'), 'sci', 3 },
			{ mw.bcmath.new('-123.456'), 'sci', 3 },
		},
		expect = {
			{ '1.23456e-1' },
			{ '-1.23456e-1' },
			{ '1.23456' },
			{ '-1.23456' },
			{ '1.23e1' },
			{ '-1.23e1' },
			{ '1.23e2' },
			{ '-1.23e2' },
		}
	},
	{ -- 41
		name = 'round -123.456',
		func = callFunc,
		args = { 'round',
			{ '-123.456', 7 },
			{ '-123.456', 6 },
			{ '-123.456', 5 },
			{ '-123.456', 4 },
			{ '-123.456', 3 },
			{ '-123.456', 2 },
			{ '-123.456', 1 },
			{ '-456.789', 4 },
			{ '-456.789', 3 },
			{ '-456.789', 2 },
			{ '-456.789', 1 },
			{ '∞', 1 },
			{ '+∞', 1 },
			{ '-∞', 1 },
		},
		expect = {
			{ '-123.456', 3 },
			{ '-123.456', 3 },
			{ '-123.46', 2 },
			{ '-123.5', 1 },
			{ '-123', 0 },
			{ '-120', 0 },
			{ '-100', 0 },
			{ '-456.8', 1 },
			{ '-457', 0 },
			{ '-460', 0 },
			{ '-500', 0 },
			{ '+∞', 0 },
			{ '+∞', 0 },
			{ '-∞', 0 },
		}
	},
}

return testframework.getTestProvider( tests )
