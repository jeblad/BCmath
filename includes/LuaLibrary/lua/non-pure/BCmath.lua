--- Register functions for the bcmath api.
-- @module BCmath

-- accesspoints for the boilerplate
local php      -- luacheck: ignore

-- import pure libs
local libUtil = require 'libraryUtil'

-- lookup
local checkType = libUtil.checkType
local checkTypeMulti = libUtil.checkTypeMulti
local makeCheckSelfFunction = libUtil.makeCheckSelfFunction

--- Check whether operator is defined.
-- This is a simple assertion-like function with a localizable message.
-- @local
-- @raise if value argument is nil
-- @tparam any value to assert
-- @tparam string name to blame
local function checkOperator( value, name )
	if not value then
		error( mw.message.new( 'bcmath-check-operand-nan', name ):plain() )
	end
end

-- this is how the number is parsed
local numberLength = 15
local numberFormat = "%+." .. string.format( "%d", numberLength ) .. "e"

-- @var structure for storage of the lib
local bcmath = {}

--- Install the module in the global space.
-- This function is removed as soon as it is called,
-- so will not be accessible. As a kind of protected api,
-- it is thus tagged as local.
-- @local
-- @tparam table options
function bcmath.setupInterface( options )
	-- Boilerplate
	bcmath.setupInterface = nil
	php = mw_interface
	mw_interface = nil
	php.options = options

	-- Register this library in the "mw" global
	mw = mw or {}
	mw.bcmath = bcmath

	package.loaded['mw.bcmath'] = bcmath
end

-- @var structure for caching zero strings
local zeroCache = {
	[0] = '',
	'0',                 '00',                 '000',                 '0000',
	'00000',             '000000',             '0000000',             '00000000',
	'000000000',         '0000000000',         '00000000000',         '000000000000',
	'0000000000000',     '00000000000000',     '000000000000000',     '0000000000000000',
	'00000000000000000', '000000000000000000', '0000000000000000000', '00000000000000000000'
}
--- Create a string of zeros.
-- This will use the prebuilt cache, or on cache failure
-- it will try to extend the cache.
-- @tparam number length of the string
-- @treturn string
local function zeros( length )
	local str = zeroCache[length]
	if str then
		return str
	end

	local temp = ''
	for _ = 1, length do
		temp = temp .. '0'
	end

	zeroCache[length] = temp

	return temp
end

--- Parse a string representing a float number.
-- This should only be called by @{parseNumScale}, and in particular not
-- from @{argConvs.table} to avoid repeated parsing.
-- @tparam string num to be parsed
-- @treturn string
-- @treturn scale
local function parseFloat( num )
	local scale
	local sign,integral = string.match( num, '^([-+]?)([%d]*)' )
	local fraction = string.match( num, '%.([%d]*)' )
	local exponent = tonumber( string.match( num, '[eE]([-+]?[%d]*)$' ) )
	local integralLen = string.len( integral or '' )
	local fractionLen = string.len( fraction or '' )
	if not exponent then
		return 0, 0
	end

	if exponent < 0 then
		local adjust = math.max( -( integralLen + exponent ), 0 )
		local mantissa = zeros( adjust ) .. integral .. (fraction or '' )
		num = sign
			.. string.sub( mantissa, 1, -( fractionLen - exponent +1 ) )
			.. '.'
			.. string.sub( mantissa, -( fractionLen - exponent ), -1 )
		scale = math.max( fractionLen - exponent, 0 )
	elseif exponent > 0 then
		local adjust = math.max( -( fractionLen - exponent ), 0 )
		local mantissa = integral .. ( fraction or '' ) .. zeros( adjust )
		num = sign
			.. string.sub( mantissa, 1, ( integralLen + exponent ) )
			.. '.'
			.. string.sub( mantissa, ( integralLen + exponent + 1 ), -1 )
		scale = math.max( fractionLen - exponent, 0 )
	else
		num = sign
			.. integral
			.. '.'
			.. ( fraction or '' )
		scale = fractionLen
	end

	return num, scale
end

-- @var structure holding chars to be downcasted.
local downChars = {
	['⁺'] = '+',
	['⁻'] = '-',
	['⁰'] = '0',
	['¹'] = '1',
	['²'] = '2',
	['³'] = '3',
	['⁴'] = '4',
	['⁵'] = '5',
	['⁶'] = '6',
	['⁷'] = '7',
	['⁸'] = '8',
	['⁹'] = '9',
}

--- Downcast characters that has valid replacements.
-- @tparam string character to be translated
-- @treturn string
local function downCast( character )
	local replacement = downChars[character]
	if not replacement then
		return character
	end

	return replacement
end

--- Truncate fraction part of number.
-- Fraction is truncated by removing trailing digits.
-- @tparam string fraction without decimal point or sign
-- @tparam number remove amount of digits
-- @treturn nil|string
local function truncFraction( fraction, remove )
	if not fraction then
		return nil
	end

	local length = string.len( fraction )

	if remove >= length then
		return nil
	end

	if remove > 0 then
		return string.sub( fraction, 1, -remove - 1 )
	end

	return fraction
end

--- Truncate integral part of number.
-- Integral is truncated by replacing trailing digits with zeros.
-- @tparam string integral without decimal point or sign
-- @tparam number remove amount of digits
-- @treturn nil|string
local function truncIntegral( integral, remove )
	if not integral then
		return nil
	end

	local length = string.len( integral )

	if remove >= length then
		return '0'
	end

	if remove > 0 then
		return string.sub( integral, 1, -remove - 1 ) .. zeros( remove )
	end

	return integral
end

-- @var structure for lookup of type converters for arguments
local argConvs = {}

--- Convert nil into bc num-scale pair.
-- This is called from @{parseNumScale}.
-- Returns nil unconditionally.
-- @local
-- @function argConvs.nil
-- @treturn nil
-- @treturn number zero (0) unconditionally
argConvs['nil'] = function()
	return nil, 0
end

--- Convert number into bc num-scale pair.
-- This is called from @{parseNumScale}.
-- Returns nil on failed parsing.
-- @local
-- @function argConvs.number
-- @tparam number value to be parsed
-- @treturn nil|string holding bcnumber
-- @treturn nil|number holding an estimate
argConvs['number'] = function( value )
	local num, scale = parseFloat( string.format( numberFormat, value ) )

	if not string.find( num, '^[-+]?%d*%.?%d*$' ) then
		return nil
	end

	return num, scale
end

--- Convert string into bc num-scale pair.
-- This is called from @{parseNumScale}.
-- The method makes an assumption that this is already a bc number,
-- that is it will not try to parse big reals.
-- Returns nil on failed parsing.
-- @local
-- @function argConvs.string
-- @tparam string value to be parsed
-- @treturn nil|string holding bcnumber
-- @treturn nil|number holding an estimate
argConvs['string'] = function( value )
	local scale
	local num = value

	-- the following is only to normalize to the most obvious forms
	num = mw.ustring.gsub( num, '−', '-' )                   -- minus to hyphen-minus
	num = mw.ustring.gsub( num, '×%s?10%s?', 'e' )           -- scientific notation
	num = mw.ustring.gsub( num, '[ED⏨&𝗘^]', 'e' )            -- engineering notations
	num = mw.ustring.gsub( num, '[⁺⁻⁰¹²³⁴⁵⁶⁷⁸⁹]', downCast ) -- translate superscript
	num = mw.ustring.gsub( num, '%s', '' )                   -- collapse spaces

	if string.find( num, 'e' ) then
		num, scale = parseFloat( num )

		if not string.find( num, '^[-+]?%d*%.?%d*$' ) then
			return nil
		end

		return num, scale
	end

	if not string.find( num, '^[-+]?%d*%.?%d*$' ) then
		return nil
	end

	local p1, p2 = string.find( num, '%.(%d*)' )
	scale = ( p1 and p2 and ( p2-p1 ) ) or 0

	return num, scale
end

--- Convert table into bc num-scale pair.
-- This is called from @{parseNumScale}.
-- The method makes an assumption that this is an BCmath instance,
-- that is it will not try to verify content.
-- @local
-- @function argConvs.table
-- @tparam table value to be parsed
-- @treturn string holding bcnumber
-- @treturn number holding an estimate
argConvs['table'] = function( value )
	return value:value(), value:scale()
end

--- Convert provided value into bc num-scale pair.
-- Dispatches value to type-specific converters.
-- This is a real bottleneck due to the dispatched function calls.
-- @local
-- @function parseNumScale
-- @tparam string|number|table value to be parsed
-- @treturn string holding bcnumber
-- @treturn number holding an estimate
local function parseNumScale( value )
	local conv = argConvs[type( value )]
	if not conv then
		return nil
	end
	local _value, _scale = conv( value )
	return _value, _scale
end

-- @var structure for lookup of type converters for self
local selfConvs = {}

--- Convert a bc number into scientific notation.
-- This is called from @{bcmath:__call}.
-- @local
-- @function selfConvs.sci
-- @tparam table num to be parsed
-- @tparam number precision
-- @treturn string
selfConvs['sci'] = function( num, precision )
	local sign,integral = string.match( num, '^([-+]?)([%d]*)' )
	local fraction = string.match( num, '%.([%d]*)' )
	local integralLen = string.len( integral or '' )
	local lead,mantissa = string.match( integral .. ( fraction or '' ), '^(0*)([%d]*)' )
	local mantissaLen = string.len( mantissa or '' )
	local leadLen = string.len( lead or '' )
	local exponent = integralLen - leadLen - 1
	integral = ( not mantissa or mantissa == '' ) and nil or string.sub( mantissa, 1, 1 )
	fraction = ( not mantissa or mantissaLen < 2 ) and nil or string.sub( mantissa, 2, -1 )
	integralLen = 1
	local fractionLen = mantissaLen - 1

	if not precision then
		return sign == '+' and '' or sign
			.. integral
			.. ( fraction and ( '.' .. fraction ) or '' )
			.. ( exponent == 0 and '' or ( 'e' .. tostring( exponent ) ) )
	end

	fraction = truncFraction( fraction, math.max( integralLen + fractionLen - precision, 0 ) )
	integral = truncIntegral( integral, math.max( integralLen - precision, 0 ) )

	return sign == '+' and '' or sign
		.. integral
		.. ( fraction and ( '.' .. fraction ) or '' )
		.. ( exponent == 0 and '' or ( 'e' .. tostring( exponent ) ) )
end

--- Convert a bc number into engineering notation.
-- This is called from @{bcmath:__call}.
-- @local
-- @function selfConvs.eng
-- @tparam table num to be parsed
-- @tparam number precision
-- @treturn string
selfConvs['eng'] = function( num, precision )
	local sign,integral = string.match( num, '^([-+]?)([%d]*)' )
	local fraction = string.match( num, '%.([%d]*)' )
	local integralLen = string.len( integral or '' )
	local lead,mantissa = string.match( integral .. ( fraction or '' ), '^(0*)([%d]*)' )
	local leadLen = string.len( lead or '' )
	local mantissaLen = string.len( mantissa or '' )
	local exponent = integralLen - leadLen - 1
	local modulus = math.mod( exponent, 3 )

	if math.abs( exponent ) >= 3 then
		exponent = exponent - modulus
	end

	integral = ( not mantissa or mantissa == '' ) and nil or string.sub( mantissa, 1, modulus+1 )
	fraction = ( not mantissa or mantissaLen < modulus+1 ) and nil or string.sub( mantissa, modulus+2, -1 )
	integralLen = 1
	local fractionLen = mantissaLen - modulus - 1

	if not precision then
		return sign == '+' and '' or sign
			.. integral
			.. ( fraction and ( '.' .. fraction ) or '' )
			.. ( exponent == 0 and '' or ( 'e' .. tostring( exponent ) ) )
	end

	fraction = truncFraction( fraction, math.max( integralLen + fractionLen - precision, 0 ) )
	integral = truncIntegral( integral, math.max( integralLen - precision, 0 ) )

	return sign == '+' and '' or sign
		.. integral
		.. ( fraction and ( '.' .. fraction ) or '' )
		.. ( exponent == 0 and '' or ( 'e' .. tostring( exponent ) ) )
end

--- Convert a bc numumber into fixed notation.
-- This is called from @{bcmath:__call}.
-- @local
-- @function selfConvs.fix
-- @tparam table num to be parsed
-- @tparam number precision
-- @treturn string
selfConvs['fix'] = function( num, precision )
	local sign,integral = string.match( num, '^([-+]?)0*([%d]*)' )
	local fraction = string.match( num, '%.([%d]*)' )
	local integralLen = string.len( integral or '' )
	local fractionLen = string.len( fraction or '' )

	if not precision then
		return sign == '+' and '' or sign
			.. integral
			.. ( fraction and ( '.' .. fraction ) or '' )
	end

	fraction = truncFraction( fraction, math.max( integralLen + fractionLen - precision, 0 ) )
	integral = truncIntegral( integral, math.max( integralLen - precision, 0 ) )

	return sign == '+' and '' or sign
		.. integral
		.. ( fraction and ( '.' .. fraction ) or '' )
end

-- @var structure used as metatable for bsmath
local bcmeta = {}

--- Instance is callable.
-- This will format according to given style and precision.
-- Unless overridden `style` will be set to `'fix'`.
-- Available notations are at least `'fix'`, `'eng'`, and `'sci'`.
-- Unless overridden `precision` will not be set, and it will use the full precission.
-- @function bcmath:__call
-- @tparam vararg ... dispatch on type or table field name
-- @treturn string
function bcmeta:__call( ... )
	local style = nil
	local precision = nil

	for _,v in ipairs( { ... } ) do
		local tpe = type( v )
		if tpe == 'string' then
			style = v
		elseif tpe == 'number' then
			precision = v
		elseif tpe == 'table' then
			if v.style then
				style = v.style
			end
			if v.precision then
				precision = v.precision
			end
		end
	end

	local conv = selfConvs[style or 'fix']
	if not conv then
		error( mw.message.new( 'bcmath-check-self-style' ):plain() )
	end

	local num = string.gsub( self:value() or '', '^([-+]?)(0*)', '%1', 1 )
	num = string.gsub( num, '%.$', '', 1 )

	return conv( num, precision )
end

--- Instance is stringable.
-- This will only create a minimal representation, suitable for further formatting.
-- @function bcmath:__tostring
-- @treturn string
function bcmeta:__tostring()
	local num = string.gsub( self:value() or '', '^([-+]?)(0*)', '%1', 1 )
	num = string.gsub( num, '%.$', '', 1 )
	return num
end

--- Internal creator function.
-- @tparam string|number|table value
-- @tparam number scale
-- @treturn self
local function makeBCmath( value, scale )
	checkTypeMulti( 'bcmath object', 1, value, { 'string', 'table', 'number', 'nil' } )
	checkType( 'bcmath object', 2, scale, 'number', true )

	local obj = setmetatable( {}, bcmeta )

	--- Check whether method is part of self.
	-- @local
	-- @function checkSelf
	-- @raise if called from a method not part of self
	local checkSelf = makeCheckSelfFunction( 'mw.bcmath', 'msg', obj, 'bcmath object' )

	-- keep in closure
	local _value, _scale = parseNumScale( value )
	if scale then
		_scale = scale
	end

	--- Check whether self has a defined value.
	-- This is a simple assertion-like function with a localizable message.
	-- @local
	-- @raise if self is missing _value
	local checkSelfValue = function()
		if not _value then
			error( mw.message.new( 'bcmath-check-self-nan' ):plain() )
		end
	end

	--- Get scale from self.
	-- The scale is stored in the closure.
	-- @function bcmath:scale
	-- @treturn number
	function obj:scale()
		checkSelf( self, 'scale' )
		return _scale
	end

	--- Get value from self.
	-- The value is stored in the closure.
	-- @function bcmath:value
	-- @treturn string
	function obj:value()
		checkSelf( self, 'value' )
		return _value
	end

	--- Add self with addend.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcadd](https://www.php.net/manual/en/function.bcadd.php) for further documentation.
	-- @function bcmath:add
	-- @tparam string|number|table addend
	-- @tparam number scale
	-- @treturn self
	function obj:add( addend, scale )
		checkSelf( self, 'add' )
		checkTypeMulti( 'bcmath:add', 1, addend, { 'string', 'number', 'table', 'nil' } )
		checkType( 'bcmath:add', 2, scale, 'number', true )
		checkSelfValue()
		local bval, bscl = parseNumScale( addend )
		checkOperator( bval, 'addend' )
		_value = php.bcadd( _value, bval, scale or math.max( _scale, bscl ) )
		return self
	end

	--- Subtract self with subtrahend.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcsub](https://www.php.net/manual/en/function.bcsub.php) for further documentation.
	-- @function bcmath:sub
	-- @tparam string|number|table subtrahend
	-- @tparam number scale
	-- @treturn self
	function obj:sub( subtrahend, scale )
		checkSelf( self, 'sub' )
		checkTypeMulti( 'bcmath:sub', 1, subtrahend, { 'string', 'number', 'table', 'nil' } )
		checkType( 'bcmath:sub', 2, scale, 'number', true )
		checkSelfValue()
		local bval, bscl = parseNumScale( subtrahend )
		checkOperator( bval, 'subtrahend' )
		_value = php.bcsub( _value, bval, scale or math.max( _scale, bscl ) )
		return self
	end

	--- Multiply self with multiplicator.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcmul](https://www.php.net/manual/en/function.bcmul.php) for further documentation.
	-- @function bcmath:mul
	-- @tparam string|number|table multiplicator
	-- @tparam number scale
	-- @treturn self
	function obj:mul( multiplicator, scale )
		checkSelf( self, 'mul' )
		checkTypeMulti( 'bcmath:mul', 1, multiplicator, { 'string', 'number', 'table', 'nil' } )
		checkType( 'bcmath:mul', 2, scale, 'number', true )
		checkSelfValue()
		local bval, bscl = parseNumScale( multiplicator )
		checkOperator( bval, 'multiplicator' )
		_value = php.bcmul( _value, bval, scale or math.max( _scale, bscl ) )
		return self
	end

	--- Divide self with divisor.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcdiv](https://www.php.net/manual/en/function.bcdiv.php) for further documentation.
	-- @function bcmath:div
	-- @tparam string|number|table divisor
	-- @tparam number scale
	-- @treturn self
	function obj:div( divisor, scale )
		checkSelf( self, 'div' )
		checkTypeMulti( 'bcmath:div', 1, divisor, { 'string', 'number', 'table', 'nil' } )
		checkType( 'bcmath:div', 2, scale, 'number', true )
		checkSelfValue()
		local bval, bscl = parseNumScale( divisor )
		checkOperator( bval, 'divisor' )
		_value = php.bcdiv( _value, bval, scale or math.max( _scale, bscl ) )
		return self
	end

	--- Modulus self with divisor.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcmod](https://www.php.net/manual/en/function.bcmod.php) for further documentation.
	-- @function bcmath:mod
	-- @tparam string|number|table divisor
	-- @tparam number scale
	-- @treturn self
	function obj:mod( divisor, scale )
		checkSelf( self, 'mod' )
		checkTypeMulti( 'bcmath:mod', 1, divisor, { 'string', 'number', 'table', 'nil' } )
		checkType( 'bcmath:mod', 2, scale, 'number', true )
		checkSelfValue()
		local bval, bscl = parseNumScale( divisor )
		checkOperator( bval, 'divisor' )
		_value = php.bcmod( _value, bval, scale or math.max( _scale, bscl ) )
		return self
	end

	--- Power self with exponent.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcpow](https://www.php.net/manual/en/function.bcpow.php) for further documentation.
	-- @function bcmath:pow
	-- @tparam string|number|table exponent
	-- @tparam number scale
	-- @treturn self
	function obj:pow( exponent, scale )
		checkSelf( self, 'pow' )
		checkTypeMulti( 'bcmath:pow', 1, exponent, { 'string', 'number', 'table', 'nil' } )
		checkType( 'bcmath:pow', 2, scale, 'number', true )
		checkSelfValue()
		local bval, bscl = parseNumScale( exponent )
		checkOperator( bval, 'exponent' )
		_value = php.bcpow( _value, bval, scale or math.max( _scale, bscl ) )
		return self
	end

	--- Power-modulus self with exponent and divisor.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcpowmod](https://www.php.net/manual/en/function.bcpowmod.php) for further documentation.
	-- @function bcmath:powmod
	-- @tparam string|number|table exponent
	-- @tparam string|number|table modulus
	-- @tparam number scale
	-- @treturn self
	function obj:powmod( exponent, divisor, scale )
		checkSelf( self, 'powmod' )
		checkTypeMulti( 'bcmath:powmod', 1, exponent, { 'string', 'number', 'table', 'nil' } )
		checkTypeMulti( 'bcmath:powmod', 2, divisor, { 'string', 'number', 'table', 'nil' } )
		checkType( 'bcmath:powmod', 3, scale, 'number', true )
		checkSelfValue()
		local bval1, bscl1 = parseNumScale( exponent )
		checkOperator( bval1, 'exponent' )
		local bval2, bscl2 = parseNumScale( divisor )
		checkOperator( bval2, 'divisor' )
		_value = php.bcpowmod( _value, bval1, bval2, scale or math.max( _scale, bscl1, bscl2 ) )
		return self
	end

	--- Square root self.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcsqrt](https://www.php.net/manual/en/function.bcsqrt.php) for further documentation.
	-- @function bcmath:sqrt
	-- @tparam number scale
	-- @treturn self
	function obj:sqrt( scale )
		checkSelf( self, 'sqrt' )
		checkType( 'bcmath:add', 1, scale, 'number', true )
		checkSelfValue()
		_value = php.bcsqrt( _value, scale or _scale )
		return self
	end

	return obj
end

--- Create new instance.
-- @function mw.bcmath.new
-- @tparam string|number|table scale
-- @tparam number scale
-- @treturn bcmath
function bcmath.new( value, scl )
	return makeBCmath( value, scl )
end

--- Add the addend to augend.
-- This function is available as a metamethod.
-- See [PHP: bcadd](https://www.php.net/manual/en/function.bcadd.php) for further documentation.
-- @function mw.bcmath.add
-- @tparam string|number|table augend
-- @tparam string|number|table addend
-- @tparam number scale
-- @treturn bcmath
function bcmath.add( augend, addend, scl )
	checkTypeMulti( 'bcmath.add', 1, augend, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( 'bcmath.add', 2, addend, { 'string', 'number', 'table', 'nil' } )
	checkType( 'bcmath.add', 3, scl, 'number', true )
	local bval1, bscl1 = parseNumScale( augend )
	checkOperator( bval1, 'augend' )
	local bval2, bscl2 = parseNumScale( addend )
	checkOperator( bval2, 'addend' )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcadd( bval1, bval2, bscl ), bscl )
end
bcmeta.__add = bcmath.add

--- Subtract the subtrahend from minuend.
-- This function is available as a metamethod.
-- See [PHP: bcsub](https://www.php.net/manual/en/function.bcsub.php) for further documentation.
-- @function mw.bcmath.sub
-- @tparam string|number|table minuend
-- @tparam string|number|table subtrahend
-- @tparam number scale
-- @treturn bcmath
function bcmath.sub( minuend, subtrahend, scl )
	checkTypeMulti( 'bcmath.sub', 1, minuend, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( 'bcmath.sub', 2, subtrahend, { 'string', 'number', 'table', 'nil' } )
	checkType( 'bcmath.sub', 3, scl, 'number', true )
	local bval1, bscl1 = parseNumScale( minuend )
	checkOperator( bval1, 'minuend' )
	local bval2, bscl2 = parseNumScale( subtrahend )
	checkOperator( bval2, 'subtrahend' )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcsub( bval1, bval2, bscl ), bscl )
end
bcmeta.__sub = bcmath.sub

--- Multiply the multiplicator with multiplier.
-- This function is available as a metamethod.
-- See [PHP: bcmul](https://www.php.net/manual/en/function.bcmul.php) for further documentation.
-- @function mw.bcmath.mul
-- @tparam string|number|table multiplier
-- @tparam string|number|table multiplicator
-- @tparam number scale
-- @treturn bcmath
function bcmath.mul( multiplier, multiplicator, scl )
	checkTypeMulti( 'bcmath.mul', 1, multiplier, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( 'bcmath.mul', 2, multiplicator, { 'string', 'number', 'table', 'nil' } )
	checkType( 'bcmath.mul', 3, scl, 'number', true )
	local bval1, bscl1 = parseNumScale( multiplier )
	checkOperator( bval1, 'multiplier' )
	local bval2, bscl2 = parseNumScale( multiplicator )
	checkOperator( bval2, 'multiplicator' )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcmul( bval1, bval2, bscl ), bscl )
end
bcmeta.__mul = bcmath.mul

--- Divide the divisor from dividend.
-- This function is available as a metamethod.
-- See [PHP: bcdiv](https://www.php.net/manual/en/function.bcdiv.php) for further documentation.
-- @function mw.bcmath.div
-- @tparam string|number|table dividend
-- @tparam string|number|table divisor
-- @tparam number scale
-- @treturn bcmath
function bcmath.div( dividend, divisor, scl )
	checkTypeMulti( 'bcmath.div', 1, dividend, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( 'bcmath.div', 2, divisor, { 'string', 'number', 'table', 'nil' } )
	checkType( 'bcmath.div', 3, scl, 'number', true )
	local bval1, bscl1 = parseNumScale( dividend )
	checkOperator( bval1, 'dividend' )
	local bval2, bscl2 = parseNumScale( divisor )
	checkOperator( bval2, 'divisor' )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcdiv( bval1, bval2, bscl ), bscl )
end
bcmeta.__div = bcmath.div

--- Modulus the divisor from dividend.
-- This function is available as a metamethod.
-- See [PHP: bcmod](https://www.php.net/manual/en/function.bcmod.php) for further documentation.
-- @function mw.bcmath.mod
-- @tparam string|number|table dividend
-- @tparam string|number|table divisor
-- @tparam number scale
-- @treturn bcmath
function bcmath.mod( dividend, divisor, scl )
	checkTypeMulti( 'bcmath.mod', 1, dividend, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( 'bcmath.mod', 2, divisor, { 'string', 'number', 'table', 'nil' } )
	checkType( 'bcmath.div', 3, scl, 'number', true )
	local bval1, bscl1 = parseNumScale( dividend )
	checkOperator( bval1, 'dividend' )
	local bval2, bscl2 = parseNumScale( divisor )
	checkOperator( bval2, 'divisor' )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcmod( bval1, bval2, bscl ), bscl )
end
bcmeta.__mod = bcmath.mod

--- Power the base to exponent.
-- This function is available as a metamethod.
-- See [PHP: bcpow](https://www.php.net/manual/en/function.bcpow.php) for further documentation.
-- @function mw.bcmath.pow
-- @tparam string|number|table base
-- @tparam string|number|table exponent
-- @tparam number scale
-- @treturn bcmath
function bcmath.pow( base, exponent, scl )
	checkTypeMulti( 'bcmath.pow', 1, base, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( 'bcmath.pow', 2, exponent, { 'string', 'number', 'table', 'nil' } )
	checkType( 'bcmath.pow', 3, scl, 'number', true )
	local bval1, bscl1 = parseNumScale( base )
	checkOperator( bval1, 'base' )
	local bval2, bscl2 = parseNumScale( exponent )
	checkOperator( bval2, 'exponent' )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcpow( bval1, bval2, bscl ), bscl )
end
bcmeta.__pow = bcmath.pow

--- Power-modulus the base to exponent.
-- This function is not available as a metamethod.
-- See [PHP: bcpowmod](https://www.php.net/manual/en/function.bcpowmod.php) for further documentation.
-- @function mw.bcmath.powmod
-- @tparam string|number|table base
-- @tparam string|number|table exponent
-- @tparam string|number|table divisor
-- @tparam number scale
-- @treturn bcmath
function bcmath.powmod( base, exponent, divisor, scl )
	checkTypeMulti( 'bcmath.powmod', 1, base, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( 'bcmath.powmod', 2, exponent, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( 'bcmath.powmod', 3, divisor, { 'string', 'number', 'table', 'nil' } )
	checkType( 'bcmath.powmod', 4, scl, 'number', true )
	checkType( 'bcmath.pow', 3, scl, 'number', true )
	local bval1, bscl1 = parseNumScale( base )
	checkOperator( bval1, 'base' )
	local bval2, bscl2 = parseNumScale( exponent )
	checkOperator( bval2, 'exponent' )
	local bval3, bscl3 = parseNumScale( divisor )
	checkOperator( bval3, 'divisor' )
	local bscl = scl or math.max( bscl1, bscl2, bscl3 )
	return makeBCmath( php.bcpowmod( bval1, bval2, bval3, bscl ), bscl )
end

--- Square root of the operand.
-- This function is not available as a metamethod.
-- See [PHP: bcsqrt](https://www.php.net/manual/en/function.bcsqrt.php) for further documentation.
-- @function mw.bcmath.sqrt
-- @tparam string|number|table operand
-- @tparam number scale
-- @treturn bcmath
function bcmath.sqrt( operand, scl )
	checkTypeMulti( 'bcmath.sqrt', 1, operand, { 'string', 'number', 'table', 'nil' } )
	checkType( 'bcmath.sqrt', 2, scl, 'number', true )
	local bval1, bscl1 = parseNumScale( operand )
	checkOperator( bval1, 'operand' )
	local bscl = scl or bscl1
	return makeBCmath( php.bcsqrt( bval1, bscl ), bscl )
end

--- Compare the left operand with the right operand.
-- This function is not available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.eq
-- @tparam string|number|table lhs
-- @tparam string|number|table rhs
-- @tparam number scale
-- @treturn bcmath
function bcmath.comp( lhs, rhs, scl )
	checkTypeMulti( 'bcmath.comp', 1, lhs, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( 'bcmath.comp', 2, rhs, { 'string', 'number', 'table', 'nil' } )
	checkType( 'bcmath.comp', 3, scl, 'number', true )
	local bval1, bscl1 = parseNumScale( lhs )
	checkOperator( bval1, 'lhs' )
	local bval2, bscl2 = parseNumScale( rhs )
	checkOperator( bval2, 'lhs' )
	local bscl = scl or math.max( bscl1, bscl2 )
	return php.bccomp( bval1, bval2, bscl )
end

--- Check if left operand is equal to right operand.
-- This function is available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.eq
-- @tparam string|number|table lhs
-- @tparam string|number|table rhs
-- @tparam number scale
-- @treturn bcmath
function bcmath.eq( lhs, rhs, scl )
	return bcmath.comp( lhs, rhs, scl ) == 0
end
bcmeta.__eq = bcmath.eq

--- Check if left operand is less than right operand.
-- This function is available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.lt
-- @tparam string|number|table lhs
-- @tparam string|number|table rhs
-- @tparam number scale
-- @treturn bcmath
function bcmath.lt( lhs, rhs, scl )
	return bcmath.comp( lhs, rhs, scl ) < 0
end
bcmeta.__lt = bcmath.lt

--- Check if left operand is greater or equal to right operand.
-- This function is not available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.ge
-- @tparam string|number|table lhs
-- @tparam string|number|table rhs
-- @tparam number scale
-- @treturn bcmath
function bcmath.ge( lhs, rhs, scl )
	return bcmath.comp( lhs, rhs, scl ) >= 0
end

--- Check if left operand is less than or equal to right operand.
-- This function is available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.le
-- @tparam string|number|table lhs
-- @tparam string|number|table rhs
-- @tparam number scale
-- @treturn bcmath
function bcmath.le( lhs, rhs, scl )
	return bcmath.comp( lhs, rhs, scl ) <= 0
end
bcmeta.__le = bcmath.le

--- Check if left operand is equal to right operand.
-- This function is not available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.gt
-- @tparam string|number|table lhs
-- @tparam string|number|table rhs
-- @tparam number scale
-- @treturn bcmath
function bcmath.gt( lhs, rhs, scl )
	return bcmath.comp( lhs, rhs, scl ) > 0
end

return bcmath
