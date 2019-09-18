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

-- @var structure for lookup of type converters
local argConvs = {}
--bcmath.converters = argConvs

--- Convert number into bc num-scale pair.
-- This is called from @{parseNum}.
-- Returns nil on failed parsing.
-- @local
-- @tparam number value to be parsed
-- @treturn nil|string holding bcnumber
-- @treturn nil|number holding an estimate
function argConvs.number( value )
	local num = string.format( numberFormat, value )
	local sign,integral = string.match( num, '^([-+]?)([%d]*)' )
	local fraction = string.match( num, '%.([%d]*)' )
	local exponent = tonumber( string.match( num, '[eE]([-+][%d]*)$' ) )
	local integralLen = string.len( integral )
	local fractionLen = string.len( fraction )
	local scale

	if exponent < 0 then
		local temp = ''
		local adjust = math.max( -( integralLen + exponent ), 0 )
		for _ = 1, adjust do
			temp = temp .. '0'
		end
		local mantissa = temp..integral..fraction
		num = sign
			.. string.sub( mantissa, 1, -( fractionLen - exponent +1 ) )
			.. '.'
			.. string.sub( mantissa, -( fractionLen - exponent ), -1 )
		scale = fractionLen - exponent
	elseif exponent > 0 then
		local temp = ''
		local adjust = math.max( -( fractionLen - exponent ), 0 )
		for _ = 1, adjust do
			temp = temp .. '0'
		end
		local mantissa = integral..fraction..temp
		num = sign
			.. string.sub( mantissa, 1, (integralLen + exponent ) )
			.. '.'
			.. string.sub( mantissa, (integralLen + exponent +1), -1 )
		scale = fractionLen - exponent
	else
		num = sign
			.. integral
			.. '.'
			.. fraction
		scale = fractionLen
	end

	if not string.find( num, '^[-+]?%d*%.?%d*$' ) then
		return nil
	end

	return num, scale
end

--- Convert string into bc num-scale pair.
-- This is called from @{parseNum}.
-- Makes an assumption that this is already a bcnumber,
-- that is it will not try to parse big reals.
-- Returns nil on failed parsing.
-- @local
-- @tparam string value to be parsed
-- @treturn nil|string holding bcnumber
-- @treturn nil|number holding an estimate
function argConvs.string( value )
	local num = string.gsub( value, '%s', '' )

	if not string.find( num, '^[-+]?%d*%.?%d*$' ) then
		return nil
	end

	local p1, p2 = string.find( num, '%.(%d*)' )
	local scale = ( p1 and p2 and ( p2-p1 ) ) or 0
	return num, scale
end

--- Convert table into bc num-scale pair.
-- This is called from `parseNum()`.
-- Makes an assumption that this is an BCmath instance,
-- that is it will not try to verify content.
-- @local
-- @tparam table value to be parsed
-- @treturn string holding bcnumber
-- @treturn number holding an estimate
function argConvs.table( value )
	return value:value(), value:scale()
end

--- Convert provided value into bc num-scale pair.
-- Dispatches value to type-specific converters.
-- @local
-- @function parseNum
-- @tparam string|number|table value to be parsed
-- @treturn string holding bcnumber
-- @treturn number holding an estimate
local function parseNum( value )
	local conv = argConvs[type( value )]
	if not conv then
		return nil
	end
	local _value, _scale = conv( value )
	if not _value then
		error('havoc!')
	end
	return _value, _scale
end

local bcmeta = {}

--- Callable instance.
-- @local
-- @treturn string
function bcmeta:__call()
	return self:value(), self:scale()
end

--- Stringable instance.
-- @local
-- @treturn string
function bcmeta:__tostring()
	return self:value()
end

--- Internal creator function.
-- @tparam string|number|table value
-- @tparam number scale
-- @treturn self
local function makeBCmath( value, scale )
	local obj = setmetatable( {}, bcmeta )

	local checkSelf = makeCheckSelfFunction( 'mw.bcmath', 'msg', obj, 'bcmath object' )

	local _value, _scale = parseNum( value )
	if scale then
		_scale = scale
	end

	--- Get scale.
	-- @function bcmath:scale
	-- @treturn number
	function obj:scale()
		checkSelf( self, 'scale' )
		return _scale
	end

	--- Get value.
	-- @function bcmath:value
	-- @treturn string
	function obj:value()
		checkSelf( self, 'value' )
		return _value
	end

	--- Add the addend to self.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcadd](https://www.php.net/manual/en/function.bcadd.php) for further documentation.
	-- @function bcmath:add
	-- @tparam string|number|table addend
	-- @tparam number scale
	-- @treturn self
	function obj:add( addend, scale )
		checkSelf( self, 'add' )
		checkTypeMulti( 'bcmath:add', 1, addend, { 'string', 'number', 'table' } )
		checkType( 'bcmath:add', 2, scale, 'number', true )
		local bval, bscl = parseNum( addend )
		_value = php.bcadd( _value, bval, scale or math.max( _scale, bscl ) )
		return self
	end

	--- Subtract the subtrahend from self.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcsub](https://www.php.net/manual/en/function.bcsub.php) for further documentation.
	-- @function bcmath:sub
	-- @tparam string|number|table subtrahend
	-- @tparam number scale
	-- @treturn self
	function obj:sub( subtrahend, scale )
		checkSelf( self, 'sub' )
		checkTypeMulti( 'bcmath:sub', 1, subtrahend, { 'string', 'number', 'table' } )
		checkType( 'bcmath:sub', 2, scale, 'number', true )
		local bval, bscl = parseNum( subtrahend )
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
		checkTypeMulti( 'bcmath:mul', 1, multiplicator, { 'string', 'number', 'table' } )
		checkType( 'bcmath:mul', 2, scale, 'number', true )
		local bval, bscl = parseNum( multiplicator )
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
		checkTypeMulti( 'bcmath:div', 1, divisor, { 'string', 'number', 'table' } )
		checkType( 'bcmath:div', 2, scale, 'number', true )
		local bval, bscl = parseNum( divisor )
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
		checkTypeMulti( 'bcmath:mod', 1, divisor, { 'string', 'number', 'table' } )
		checkType( 'bcmath:mod', 2, scale, 'number', true )
		local bval, bscl = parseNum( divisor )
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
		checkTypeMulti( 'bcmath:pow', 1, exponent, { 'string', 'number', 'table' } )
		checkType( 'bcmath:pow', 2, scale, 'number', true )
		local bval, bscl = parseNum( exponent )
		_value = php.bcpow( _value, bval, scale or math.max( _scale, bscl ) )
		return self
	end

	--- Power modulus self with exponent and divisor.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcpowmod](https://www.php.net/manual/en/function.bcpowmod.php) for further documentation.
	-- @function bcmath:powmod
	-- @tparam string|number|table exponent
	-- @tparam string|number|table modulus
	-- @tparam number scale
	-- @treturn self
	function obj:powmod( exponent, divisor, scale )
		checkSelf( self, 'powmod' )
		checkTypeMulti( 'bcmath:powmod', 1, exponent, { 'string', 'number', 'table' } )
		checkTypeMulti( 'bcmath:powmod', 2, divisor, { 'string', 'number', 'table' } )
		checkType( 'bcmath:powmod', 3, scale, 'number', true )
		local bval1, bscl1 = parseNum( exponent )
		local bval2, bscl2 = parseNum( divisor )
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
	checkTypeMulti( 'bcmath.new', 1, value, { 'string', 'table', 'number' } )
	checkType( 'bcmath.new', 2, scl, 'number', true )
	return makeBCmath( value, scl )
end

--- Add the addend to augend.
-- This function is available as a metamethod.
-- @function mw.bcmath.add
-- @tparam string|number|table augend
-- @tparam string|number|table addend
-- @tparam number scale
-- @treturn bcmath
function bcmath.add( augend, addend, scl )
	checkTypeMulti( 'bcmath.add', 1, augend, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.add', 2, addend, { 'string', 'number', 'table' } )
	checkType( 'bcmath.add', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( augend )
	local bval2, bscl2 = parseNum( addend )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcadd( bval1, bval2, bscl ), bscl )
end
bcmeta.__add = bcmath.add

--- Subtract the subtrahend from minuend.
-- This function is available as a metamethod.
-- @function mw.bcmath.sub
-- @tparam string|number|table minuend
-- @tparam string|number|table subtrahend
-- @tparam number scale
-- @treturn bcmath
function bcmath.sub( minuend, subtrahend, scl )
	checkTypeMulti( 'bcmath.sub', 1, minuend, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.sub', 2, subtrahend, { 'string', 'number', 'table' } )
	checkType( 'bcmath.sub', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( minuend )
	local bval2, bscl2 = parseNum( subtrahend )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcsub( bval1, bval2, bscl ), bscl )
end
bcmeta.__sub = bcmath.sub

--- Multiply the multiplicator with multiplier.
-- This function is available as a metamethod.
-- @function mw.bcmath.mul
-- @tparam string|number|table multiplier
-- @tparam string|number|table multiplicator
-- @tparam number scale
-- @treturn bcmath
function bcmath.mul( multiplier, multiplicator, scl )
	checkTypeMulti( 'bcmath.mul', 1, multiplier, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.mul', 2, multiplicator, { 'string', 'number', 'table' } )
	checkType( 'bcmath.mul', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( multiplier )
	local bval2, bscl2 = parseNum( multiplicator )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcmul( bval1, bval2, bscl ), bscl )
end
bcmeta.__mul = bcmath.mul

--- Divide the divisor from dividend.
-- This function is available as a metamethod.
-- @function mw.bcmath.div
-- @tparam string|number|table dividend
-- @tparam string|number|table divisor
-- @tparam number scale
-- @treturn bcmath
function bcmath.div( dividend, divisor, scl )
	checkTypeMulti( 'bcmath.div', 1, dividend, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.div', 2, divisor, { 'string', 'number', 'table' } )
	checkType( 'bcmath.div', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( dividend )
	local bval2, bscl2 = parseNum( divisor )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcdiv( bval1, bval2, bscl ), bscl )
end
bcmeta.__div = bcmath.div

--- Modulus the divisor from dividend.
-- This function is available as a metamethod.
-- @function mw.bcmath.mod
-- @tparam string|number|table dividend
-- @tparam string|number|table divisor
-- @tparam number scale
-- @treturn bcmath
function bcmath.mod( dividend, divisor, scl )
	checkTypeMulti( 'bcmath.mod', 1, dividend, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.mod', 2, divisor, { 'string', 'number', 'table' } )
	checkType( 'bcmath.div', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( dividend )
	local bval2, bscl2 = parseNum( divisor )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcmod( bval1, bval2, bscl ), bscl )
end
bcmeta.__mod = bcmath.mod

--- Power the base to exponent.
-- This function is available as a metamethod.
-- @function mw.bcmath.pow
-- @tparam string|number|table base
-- @tparam string|number|table exponent
-- @tparam number scale
-- @treturn bcmath
function bcmath.pow( base, exponent, scl )
	checkTypeMulti( 'bcmath.pow', 1, base, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.pow', 2, exponent, { 'string', 'number', 'table' } )
	checkType( 'bcmath.pow', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( base )
	local bval2, bscl2 = parseNum( exponent )
	local bscl = scl or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcpow( bval1, bval2, bscl ), bscl )
end
bcmeta.__pow = bcmath.pow

--- Power the base to exponent.
-- This function is not available as a metamethod.
-- @function mw.bcmath.powmod
-- @tparam string|number|table base
-- @tparam string|number|table exponent
-- @tparam number scale
-- @treturn bcmath
function bcmath.powmod( base, exponent, modulus, scl )
	checkTypeMulti( 'bcmath.powmod', 1, base, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.powmod', 2, exponent, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.powmod', 3, modulus, { 'string', 'number', 'table' } )
	checkType( 'bcmath.powmod', 4, scl, 'number', true )
	checkType( 'bcmath.pow', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( base )
	local bval2, bscl2 = parseNum( exponent )
	local bval3, bscl3 = parseNum( modulus )
	local bscl = scl or math.max( bscl1, bscl2, bscl3 )
	return makeBCmath( php.bcpowmod( bval1, bval2, bval3, bscl ), bscl )
end

--- Power the base to exponent.
-- This function is not available as a metamethod.
-- @function mw.bcmath.sqrt
-- @tparam string|number|table operand
-- @tparam number scale
-- @treturn bcmath
function bcmath.sqrt( operand, scl )
	checkTypeMulti( 'bcmath.sqrt', 1, operand, { 'string', 'number', 'table' } )
	checkType( 'bcmath.sqrt', 2, scl, 'number', true )
	local bval1, bscl1 = parseNum( operand )
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
	checkTypeMulti( 'bcmath.comp', 1, lhs, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.comp', 2, rhs, { 'string', 'number', 'table' } )
	checkType( 'bcmath.comp', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( lhs )
	local bval2, bscl2 = parseNum( rhs )
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