--- Register functions for the bcmath api.
-- @module BCmath

-- accesspoints for the boilerplate
local php      -- luacheck: ignore

-- pure libs
local libUtil = require 'libraryUtil'

-- lookup
local checkType = libUtil.checkType
local checkTypeMulti = libUtil.checkTypeMulti
local makeCheckSelfFunction = libUtil.makeCheckSelfFunction

local numberLength = 15
local numberFormat = "%+." .. string.format( "%d", numberLength ) .. "e"

-- @var structure for storage of the lib
local bcmath = {}

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

local argConvs = {}
bcmath.converters = argConvs

argConvs.number = function( value )
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

	return num, scale
end

argConvs.string = function( value )
	local num = string.gsub( value, '%s', '' )
	local p1, p2 = string.find( num, '%.(%d*)' )
	local scale = ( p1 and p2 and ( p2-p1 ) ) or 0
	return num, scale
end

argConvs.table = function( value )
	local num = value.num()
	local scale = value.scale()
	return num, scale
end

local function parseNum( value )
	local conv = argConvs[type( value )]
	if not conv then
		return nil
	end
	return conv( value )
end

local bcmeta = {}

function bcmeta:__call()
	return self:num()
end

function bcmeta:__tostring()
	return self:num()
end

local function makeBCmath( value, scale )
	local obj = setmetatable( {}, bcmeta )

	local checkSelf = makeCheckSelfFunction( 'mw.bcmath', 'msg', obj, 'bcmath object' )
	checkTypeMulti( 'bcmath object', 1, value, { 'string', 'table', 'number' } )
	checkType( 'bcmath object', 2, scale, 'number', true )

	local bignum, bigscale = parseNum( value )
	if scale then
		bigscale = scale
	end

	function obj:scale()
		return bigscale
	end

	function obj:num()
		return bignum
	end

	function obj:add( addend, scl )
		checkSelf( self, 'add' )
		checkTypeMulti( 'bcmath:add', 1, addend, { 'string', 'number', 'table' } )
		checkType( 'bcmath:add', 2, scl, 'number', true )
		local bval, bscl = parseNum( addend )
		bignum = php.bcadd( self:num(), bval, scl or math.min( self:scale(), bscl ) )
		return self
	end

	function obj:sub( subtrahend, scl )
		checkSelf( self, 'sub' )
		checkTypeMulti( 'bcmath:sub', 1, subtrahend, { 'string', 'number', 'table' } )
		checkType( 'bcmath:sub', 2, scl, 'number', true )
		local bval, bscl = parseNum( subtrahend )
		bignum = php.bcsub( self:num(), bval, scl or math.min( self:scale(), bscl ) )
		return self
	end

	function obj:mul( operand, scl )
		checkSelf( self, 'mul' )
		checkTypeMulti( 'bcmath:mul', 1, operand, { 'string', 'number', 'table' } )
		checkType( 'bcmath:mul', 2, scl, 'number', true )
		local bval, bscl = parseNum( operand )
		bignum = php.bcmul( self:num(), bval, scl or ( self:scale() * bscl ) )
		return self
	end

	function obj:div( divisor, scl )
		checkSelf( self, 'div' )
		checkTypeMulti( 'bcmath:div', 1, divisor, { 'string', 'number', 'table' } )
		checkType( 'bcmath:div', 2, scl, 'number', true )
		local bval, bscl = parseNum( divisor )
		bignum = php.bcdiv( self:num(), bval, scl or ( self:scale() * bscl ) )
		return self
	end

	function obj:mod( divisor, scl )
		checkSelf( self, 'mod' )
		checkTypeMulti( 'bcmath:mod', 1, divisor, { 'string', 'number', 'table' } )
		checkType( 'bcmath:mod', 2, scl, 'number', true )
		local bval, bscl = parseNum( divisor )
		bignum = php.bcmod( self:num(), bval, scl or ( self:scale() * bscl ) )
		return self
	end

	function obj:pow( exponent, scl )
		checkSelf( self, 'pow' )
		checkTypeMulti( 'bcmath:pow', 1, exponent, { 'string', 'number', 'table' } )
		checkType( 'bcmath:pow', 2, scl, 'number', true )
		local bval, bscl = parseNum( exponent )
		bignum = php.bcpow( self:num(), bval, scl or math.pow( self:scale(), bscl ) )
		return self
	end

	function obj:powmod( exponent, modulus, scl )
		checkSelf( self, 'powmod' )
		checkTypeMulti( 'bcmath:powmod', 1, exponent, { 'string', 'number', 'table' } )
		checkTypeMulti( 'bcmath:powmod', 2, modulus, { 'string', 'number', 'table' } )
		checkType( 'bcmath:powmod', 3, scl, 'number', true )
		local bval1, bscl1 = parseNum( exponent )
		local bval2, bscl2 = parseNum( modulus )
		bignum = php.bcpowmod( self:num(), bval1, bval2, scl or math.pow( self:scale(), bscl1 + bscl2 ) )
		return self
	end

	function obj:sqrt( scl )
		checkSelf( self, 'sqrt' )
		checkType( 'bcmath:add', 1, scl, 'number', true )
		bignum = php.bcsqrt( self:num(), scl or math.pow( self:scale(), 2 ) )
		return self
	end

	return obj
end

function bcmath.new( num )
	checkType( 'bcmath.new', 1, num, 'string' )
	return makeBCmath( num )
end

function bcmath.add( augend, addend, scl )
	checkTypeMulti( 'bcmath.add', 1, augend, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.add', 2, addend, { 'string', 'number', 'table' } )
	checkType( 'bcmath.add', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( augend )
	local bval2, bscl2 = parseNum( addend )
	local bscl = scl or math.min( bscl1, bscl2 )
	return makeBCmath( php.bcadd( bval1, bval2, bscl ), bscl )
end

bcmeta.__add = bcmath.add

function bcmath.sub( minuend, subtrahend, scl )
	checkTypeMulti( 'bcmath.sub', 1, minuend, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.sub', 2, subtrahend, { 'string', 'number', 'table' } )
	checkType( 'bcmath.sub', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( minuend )
	local bval2, bscl2 = parseNum( subtrahend )
	local bscl = scl or math.min( bscl1, bscl2 )
	return makeBCmath( php.bcsub( bval1, bval2, bscl ), bscl )
end

bcmeta.__sub = bcmath.sub

function bcmath.mul( multiplier, multiplicator, scl )
	checkTypeMulti( 'bcmath.mul', 1, multiplier, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.mul', 2, multiplicator, { 'string', 'number', 'table' } )
	checkType( 'bcmath.mul', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( multiplier )
	local bval2, bscl2 = parseNum( multiplicator )
	local bscl = scl or ( bscl1 * bscl2 )
	return makeBCmath( php.bcmul( bval1, bval2, bscl ), bscl )
end

bcmeta.__mul = bcmath.mul

function bcmath.div( dividend, divisor, scl )
	checkTypeMulti( 'bcmath.div', 1, dividend, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.div', 2, divisor, { 'string', 'number', 'table' } )
	checkType( 'bcmath.div', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( dividend )
	local bval2, bscl2 = parseNum( divisor )
	local bscl = scl or ( bscl1 * bscl2 )
	return makeBCmath( php.bcdiv( bval1, bval2, bscl ), bscl )
end

bcmeta.__div = bcmath.div

function bcmath.mod( dividend, divisor, scl )
	checkTypeMulti( 'bcmath.mod', 1, dividend, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.mod', 2, divisor, { 'string', 'number', 'table' } )
	checkType( 'bcmath.div', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( dividend )
	local bval2, bscl2 = parseNum( divisor )
	local bscl = scl or ( bscl1 * bscl2 )
	return makeBCmath( php.bcmod( bval1, bval2, bscl ), bscl )
end

bcmeta.__mod = bcmath.mod

function bcmath.pow( base, exponent, scl )
	checkTypeMulti( 'bcmath.pow', 1, base, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.pow', 2, exponent, { 'string', 'number', 'table' } )
	checkType( 'bcmath.pow', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( base )
	local bval2, bscl2 = parseNum( exponent )
	local bscl = scl or math.pow( bscl1, bscl2 )
	return makeBCmath( php.bcpow( bval1, bval2, bscl ), bscl )
end

bcmeta.__pow = bcmath.pow

-- Not a metamethod
function bcmath.powmod( base, exponent, modulus, scl )
	checkTypeMulti( 'bcmath.powmod', 1, base, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.powmod', 2, exponent, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.powmod', 3, modulus, { 'string', 'number', 'table' } )
	checkType( 'bcmath.powmod', 4, scl, 'number', true )
	checkType( 'bcmath.pow', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( base )
	local bval2, bscl2 = parseNum( exponent )
	local bval3, bscl3 = parseNum( modulus )
	local bscl = scl or math.pow( bscl1, bscl2, bscl3 )
	return makeBCmath( php.bcpowmod( bval1, bval2, bval3, bscl ), bscl )
end

-- Not a metamethod
function bcmath.sqrt( operand, scl )
	checkTypeMulti( 'bcmath.sqrt', 1, operand, { 'string', 'number', 'table' } )
	checkType( 'bcmath.sqrt', 2, scl, 'number', true )
	local bval1, bscl1 = parseNum( operand )
	local bscl = scl or bscl1
	return makeBCmath( php.bcsqrt( bval1, bscl ), bscl )
end

function bcmath.eq( lhs, rhs, scl )
	checkTypeMulti( 'bcmath.eq', 1, lhs, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.eq', 2, rhs, { 'string', 'number', 'table' } )
	checkType( 'bcmath.eq', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( lhs )
	local bval2, bscl2 = parseNum( rhs )
	local bscl = scl or math.min( bscl1, bscl2 )
	return php.bccomp( bval1, bval2, bscl ) == 0
end

bcmeta.__eq = bcmath.eq

function bcmath.lt( lhs, rhs, scl )
	checkTypeMulti( 'bcmath.lt', 1, lhs, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.lt', 2, rhs, { 'string', 'number', 'table' } )
	checkType( 'bcmath.lt', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( lhs )
	local bval2, bscl2 = parseNum( rhs )
	local bscl = scl or math.min( bscl1, bscl2 )
	return php.bccomp( bval1, bval2, bscl ) < 0
end

bcmeta.__lt = bcmath.lt

-- Not a metamethod
function bcmath.ge( lhs, rhs, scl )
	return not bcmath.lt( lhs, rhs, scl )
end

function bcmath.le( lhs, rhs, scl )
	checkTypeMulti( 'bcmath.le', 1, lhs, { 'string', 'number', 'table' } )
	checkTypeMulti( 'bcmath.le', 2, rhs, { 'string', 'number', 'table' } )
	checkType( 'bcmath.le', 3, scl, 'number', true )
	local bval1, bscl1 = parseNum( lhs )
	local bval2, bscl2 = parseNum( rhs )
	local bscl = scl or math.min( bscl1, bscl2 )
	return php.bccomp( bval1, bval2, bscl ) <= 0
end

bcmeta.__le = bcmath.le

-- Not a metamethod
function bcmath.gt( lhs, rhs, scl )
	return not bcmath.le( lhs, rhs, scl )
end

return bcmath