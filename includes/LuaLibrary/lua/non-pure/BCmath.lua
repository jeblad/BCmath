--- Register functions for the bcmath api.
-- @module BCmath

-- accesspoints for the boilerplate
local php      -- luacheck: ignore

-- @var structure for storage of the lib
local bcmath = {}

--- Install the module in the global space.
-- This function is removed as soon as it is called, so will
-- not be accessible, and it is thus tagged as local.
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

-- import pure libs
local libUtil = require 'libraryUtil'

-- this is how the Lua number is parsed
local numberLength = 15
local numberFormat = "%+." .. string.format( "%d", numberLength ) .. "e"

-- lookup checks
local checkType = libUtil.checkType
local checkTypeMulti = libUtil.checkTypeMulti
local makeCheckSelfFunction = libUtil.makeCheckSelfFunction

--- Check one operand and the scale for valid types.
-- @raise On wrong types
-- @tparam string name
-- @tparam nil|string|number|table operand1
-- @tparam nil|number scale
local function checkUnaryOperand( name, operand1, scale )
	assert( name ) -- simple check
	checkTypeMulti( name, 1, operand1, { 'string', 'number', 'table' } )
	checkType( name, 2, scale, 'number', true )
end

--- Check two operands and the scale for valid types.
-- @raise On wrong types
-- @tparam string name
-- @tparam nil|string|number|table operand1
-- @tparam nil|string|number|table operand2
-- @tparam nil|number scale
local function checkBinaryOperands( name, operand1, operand2, scale )
	assert( name ) -- simple check
	checkTypeMulti( name, 1, operand1, { 'string', 'number', 'table' } )
	checkTypeMulti( name, 2, operand2, { 'string', 'number', 'table' } )
	checkType( name, 2, scale, 'number', true )
end

--- Check three operands and the scale for valid types.
-- @raise On wrong types
-- @tparam string name
-- @tparam nil|string|number|table operand1
-- @tparam nil|string|number|table operand2
-- @tparam nil|string|number|table operand3
-- @tparam nil|number scale
local function checkTernaryOperands( name, operand1, operand2, operand3, scale )
	assert( name ) -- simple check
	checkTypeMulti( name, 1, operand1, { 'string', 'number', 'table' } )
	checkTypeMulti( name, 2, operand2, { 'string', 'number', 'table' } )
	checkTypeMulti( name, 3, operand3, { 'string', 'number', 'table' } )
	checkType( name, 2, scale, 'number', true )
end

-- @var structure for caching zero strings
local zeroCache = {
	'0',
	'00',
	'000', -- kilo
	'0000',
	'00000',
	'000000', -- mega
	'0000000',
	'00000000',
	'000000000', -- giga
	'0000000000',
	'00000000000',
	'000000000000', -- tera
	'0000000000000',
	'00000000000000',
	'000000000000000', -- peta
	'0000000000000000',
	'00000000000000000',
	'000000000000000000', -- exa
	'0000000000000000000',
	'00000000000000000000',
	'000000000000000000000', -- zetta
	'0000000000000000000000',
	'00000000000000000000000',
	'000000000000000000000000', -- yotta
	'0000000000000000000000000',
	'00000000000000000000000000',
	'000000000000000000000000000'
}
--- Create a string of zeros.
-- This will use the prebuilt cache, or on cache failure
-- it will try to extend the cache.
-- @tparam number length of the string
-- @treturn string
local function zeros( length )
	assert( length )
	if length <= 0 then
		return ''
	end
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
-- This should only be called by @{convert}, and in particular not
-- from @{argConvs.table} to avoid repeated parsing.
-- @local
-- @tparam string num to be parsed
-- @treturn string
-- @treturn scale
local function parseFloat( num )
	assert( num )
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

--- Round half away from zero.
-- This implements rounding with string operations, as described by
-- [round half away from zero](https://en.wikipedia.org/wiki/Rounding#Round_half_away_from_zero).
-- @local
-- @tparam string representing a bcmath number
-- @tparam number amount of significant digits
-- @treturn string
local function round( value, precision )
	local first,mantissa,rest = string.match( value, '^([-+]?)([0-9%.]+)(.*)$' )
	local rPos = string.find( mantissa, '%.' )
	mantissa = rPos
		and ( string.sub(mantissa, 1, rPos-1 ) .. string.sub(mantissa, rPos+1) )
		or mantissa
	if string.find( mantissa, '^9*[56789]$' ) then
		mantissa = '0'..mantissa
		if rPos then
			rPos = rPos+1
		end
	end
	local mLen = string.len( mantissa )
	if not precision then
		precision = rPos and rPos-1 or mLen
	end
	precision = math.min( precision, mLen )
	mantissa = (mLen <= precision+1)
		and (mantissa .. zeros( precision-mLen+1 ) )
		or string.sub( mantissa, 1, precision+1)
	local pos, len = string.find( mantissa, '[0-8]9*[56789]$' )
	mantissa = pos
		and ( string.sub( mantissa, 1, pos-1 )
			.. tostring( tonumber( string.sub( mantissa, pos, pos ) ) + 1 )
			.. zeros( (len-pos-1) ) )
		or ( string.sub( mantissa, 1, -2 ) )
	if rPos and rPos > precision then
		mantissa = mantissa .. zeros( rPos-precision-1)
	end
	if rPos and rPos ~= string.len(mantissa)+1 then
		mantissa = string.sub( mantissa, 1, rPos-1 )
			.. '.'
			.. string.sub(mantissa, rPos, -1 )
	end
	return first
		.. mantissa
		.. rest
end

-- @var structure for lookup of type converters for arguments
local argConvs = {}

--- Convert nil into bc num-scale pair.
-- This is called from @{convert}.
-- Returns nil unconditionally.
-- @local
-- @function argConvs.nil
-- @treturn nil
-- @treturn number zero (0) unconditionally
argConvs['nil'] = function()
	return nil, 0
end

--- Convert number into bc num-scale pair.
-- This is called from @{convert}.
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
-- This is called from @{convert}.
-- The method makes an assumption that this is already a bc number,
-- that is it will not try to parse big reals.
-- Returns nil on failed parsing.
-- @local
-- @function argConvs.string
-- @tparam string value to be parsed
-- @treturn nil|string holding bcnumber
-- @treturn nil|number holding an estimate
argConvs['string'] = function( value )
--	local infinity = bcmath.getInfinite( value )
--	if infinity then
--		return infinity, 0
--	end

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

	if string.find( num, '∞' ) then
		if not string.find( num, '^[-+]?∞$' ) then
			return nil
		end

		return num, 0
	end

	if not string.find( num, '^[-+]?%d*%.?%d*$' ) then
		return nil
	end

	local p1, p2 = string.find( num, '%.(%d*)' )
	scale = ( p1 and p2 and ( p2-p1 ) ) or 0

	return num, scale
end

--- Convert table into bc num-scale pair.
-- This is called from @{convert}.
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
-- @function convert
-- @tparam string|number|table value to be parsed
-- @treturn string holding bcnumber
-- @treturn number holding an estimate
local function convert( value )
	local func = argConvs[type( value )]
	if not func then
		return nil
	end
	local _value, _scale = func( value )
	return _value, _scale
end

--- Convert provided value into bc num-scale pair with blame.
-- Dispatches value to type-specific converters through call to convert.
-- If operator is given, then a failure will rise an exception.
-- @local
-- @function convertWithBlame
-- @tparam string|number|table value to be parsed
-- @tparam nil|string operator to be reported
-- @tparam nil|string operand to be reported
-- @treturn string holding bcnumber
-- @treturn number holding an estimate
local function convertWithBlame( value, operator, operand )
	if not value then
		error( mw.message.new( 'bcmath-check-operand-nan', operator or 'unknown', operand or 'unknown'):plain(), 3 )
	end
	return convert( value )
end

--- Extract sign and length from a bignum string.
-- The value should be a string, not a unicode string.
-- @tparam string value to be processed
-- @treturn string
-- @treturn number
local function extractSign( value )
	local str = string.match( value or '', '^([-+]?)' ) or ''
	return str, string.len( str )
end

--- Extract integral and length from a bignum string.
-- The value should be a string, not a unicode string.
-- @tparam string value to be processed
-- @treturn string
-- @treturn number
local function extractIntegral( value )
	local str = string.match( value or '', '^[-+]?0*(%d*)' ) or ''
	return str, string.len( str )
end

--- Extract fraction and length from a bignum string.
-- The value should be a string, not a unicode string.
-- @tparam string value to be processed
-- @treturn string
-- @treturn number
local function extractFraction( value )
	local str = string.match( value or '', '%.(%d*)' ) or ''
	return str, string.len( str )
end

--- Extract lead and length from a bignum string.
-- The value should be a string, not a unicode string.
-- @tparam string value to be processed
-- @treturn string
-- @treturn number
local function extractLead( value )
	local str = string.match( value or '', '^(0*)' ) or ''
	return str, string.len( str )
end

--- Extract mantissa and length from a bignum string.
-- The value should be a string, not a unicode string.
-- @tparam string value to be processed
-- @treturn string
-- @treturn number
local function extractMantissa( value )
	local str = string.match( value or '', '^0*(%d*)' ) or ''
	return str, string.len( str )
end

--- Format the sign for output.
-- @tparam string sign
-- @treturn string
local function formatSign( sign )
	if not sign then
		return ''
	end

	if sign == '-' then
		return '-'
	end

	return ''
end

--- Format the integral for output.
-- @tparam string integral
-- @treturn string
local function formatIntegral( integral )
	if not integral then
		return '0'
	end

	if integral == '' then
		return '0'
	end

	return integral
end

--- Format the fraction for output.
-- @tparam string fraction
-- @treturn string
local function formatFraction( fraction )
	if not fraction then
		return ''
	end

	if fraction == '' then
		return ''
	end

	return string.format( '.%s', fraction )
end

--- Format the exponent for output.
-- @tparam string exponent
-- @treturn string
local function formatExponent( exponent )
	if not exponent then
		return ''
	end

	if type( exponent ) == 'number' then
		exponent = tostring( exponent )
	end


	if exponent == '0' or exponent == '' then
		return ''
	end

	return string.format( 'e%s', exponent )
end

-- @var structure for lookup of type converters for self
local selfConvs = {}

--- Convert a bc number into scientific notation.
-- The function is called from @{bcmath:__call}.
-- It only format the number, it does not do localization.
-- @local
-- @function selfConvs.sci
-- @tparam table num to be parsed
-- @tparam number precision
-- @treturn string
selfConvs['sci'] = function( num, precision )
	local sign, _ = extractSign( num )
	local integral, integralLen = extractIntegral( num )
	local fraction, _ = extractFraction( num )
	local digits = integral..fraction
	local _, leadLen = extractLead( digits )
	local mantissa, mantissaLen = extractMantissa( digits )
	local exponent = integralLen - leadLen -1

	integral = nil
	integralLen = 0
	fraction = nil
	local fractionLen = 0

	if mantissaLen == 0 then
		integral = '0'
		exponent = 0
	end

	if mantissaLen > 0 then
		integral = string.sub( mantissa, 1, 1 )
		integralLen = 1
	end

	if mantissaLen > 1 then
		fraction = string.sub( mantissa, 2, -1 )
		fractionLen = mantissaLen - 1
	end

	if not precision then
		return formatSign( sign )
			.. formatIntegral( integral )
			.. formatFraction( fraction )
			.. formatExponent( exponent )
	end

	fraction = truncFraction( fraction, math.max( integralLen + fractionLen - precision, 0 ) )
	integral = truncIntegral( integral, math.max( integralLen - precision, 0 ) )

	return formatSign( sign )
		.. formatIntegral( integral )
		.. formatFraction( fraction )
		.. formatExponent( exponent )
end

--- Convert a bc number into engineering notation.
-- The function is called from @{bcmath:__call}.
-- It only format the number, it does not do localization.
-- @local
-- @function selfConvs.eng
-- @tparam table num to be parsed
-- @tparam number precision
-- @treturn string
selfConvs['eng'] = function( num, precision )
	local sign, _ = extractSign( num )
	local integral, integralLen = extractIntegral( num )
	local fraction, fractionLen = extractFraction( num )
	local digits = integral..fraction
	local _, leadLen = extractLead( digits )
	local mantissa, mantissaLen = extractMantissa( digits )
	local exponent = integralLen - leadLen - 1
	local modulus = exponent % 3 --math.fmod( exponent, 3 )

	integral = nil
	integralLen = 0
	fraction = nil

	if mantissaLen == 0 then
		integral = '0'
		exponent = 0
	elseif mantissaLen <= modulus then
		mantissaLen = mantissaLen + modulus
		mantissa = mantissa .. zeros( modulus )
		exponent = exponent - modulus
	else
		exponent = exponent - modulus
	end

	if mantissaLen > modulus then
		integral = string.sub( mantissa, 1, modulus+1 )
		integralLen = modulus + 1
	end

	if mantissaLen > modulus+1 then
		fraction = string.sub( mantissa, modulus+2, -1 )
		fractionLen = mantissaLen - modulus - 1
	end

	if not precision then
		return formatSign( sign )
			.. formatIntegral( integral )
			.. formatFraction( fraction )
			.. formatExponent( exponent )
	end

	fraction = truncFraction( fraction, math.max( integralLen + fractionLen - precision, 0 ) )
	integral = truncIntegral( integral, math.max( integralLen - precision, 0 ) )

	return formatSign( sign )
		.. formatIntegral( integral )
		.. formatFraction( fraction )
		.. formatExponent( exponent )
end

--- Convert a bc number into fixed notation.
-- The function is called from @{bcmath:__call}.
-- It only format the number, it does not do localization.
-- @local
-- @function selfConvs.fix
-- @tparam table num to be parsed
-- @tparam number precision
-- @treturn string
selfConvs['fix'] = function( num, precision )
	local sign, _ = extractSign( num )
	local integral, integralLen = extractIntegral( num )
	local fraction, fractionLen = extractFraction( num )

	if not precision then
		return formatSign( sign )
			.. formatIntegral( integral )
			.. formatFraction( fraction )
	end

	fraction = truncFraction( fraction, math.max( integralLen + fractionLen - precision, 0 ) )
	integral = truncIntegral( integral, math.max( integralLen - precision, 0 ) )

	return formatSign( sign )
		.. formatIntegral( integral )
		.. formatFraction( fraction )
end

--- Convert a bc number according to a CLDR pattern.
-- This is called from @{bcmath:__call}.
-- @local
-- @tparam table num to be parsed
-- @tparam number precision
-- @tparam string style
-- @treturn string
local function convertPattern( num, precision, style ) -- luacheck: no unused args
	error( mw.message.new( 'bcmath-check-not-implemented', 'CLDR Pattern' ):plain() )
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

	local func = selfConvs[style or 'fix']
	if not func then
		func = convertPattern
	end

	if self:isNaN() then
		-- make log of all payloads
		mw.log( mw.message.new( 'bcmath-check-self-nan' ):plain() )
		local cnt = mw.message.new( 'bcmath-payload-counter' )
		for i,v in ipairs( { self:payload() } ) do
			if v then
				local msg = mw.message.new( v )
				mw.log( cnt:params( i, msg ):plain() )
			end
		end

		return 'nan'
	end

	local num = self:value()
	num = string.gsub( num, '^([-+]?)(0*)', '%1', 1 )
	num = string.gsub( num, '%.(0*)$', '', 1 )

	-- if empty, then put bak a single zero
	if num == '' then
		num = '0'
	end

	-- return a formatted text representation
	return func( num, precision, style )
end

--- Instance is stringable.
-- This will only create a minimal representation, suitable for further formatting.
-- @function bcmath:__tostring
-- @treturn string
function bcmeta:__tostring()
	if self:isNaN() then
		-- make log of all payloads
		mw.log( mw.message.new( 'bcmath-check-self-nan' ):plain() )
		local cnt = mw.message.new( 'bcmath-payload-counter' )
		for i,v in ipairs( { self:payload() } ) do
			if v then
				local msg = mw.message.new( v )
				mw.log( cnt:params( i, msg ):plain() )
			end
		end

		return 'nan'
	end

	local num = self:value()
	num = string.gsub( num, '^([-+]?)0*', '%1', 1 )
	num = string.gsub( num, '%.(0*)$', '', 1 )

	-- if empty, then put bak a single zero
	if num == '' then
		num = '0'
	end

	-- return a plain text representation
	return num
end

--- Internal creator function.
-- @tparam string|number|table value
-- @tparam nil|number scale of decimal digits
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
	local _payload = nil
	local _value, _scale = convert( value )
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
	-- @nick bcmath:getScale
	-- @function bcmath:scale
	-- @treturn number
	function obj:scale()
		checkSelf( self, 'scale' )
		return _scale
	end
	obj.getScale = obj.scale

	--- Get value from self.
	-- The value is stored in the closure.
	-- @nick bcmath:number
	-- @nick bcmath:getNumber
	-- @nick bcmath:getValue
	-- @function bcmath:value
	-- @treturn string
	function obj:value()
		checkSelf( self, 'value' )
		return _value
	end
	obj.number = obj.value
	obj.getNumber = obj.value
	obj.getValue = obj.value

	--- Add payload to self.
	-- The payload is stored in the closure.
	-- Method is semiprivate as payload should not be changed.
	-- @local
	-- @function bcmath:addPayload
	-- @tparam nil|string key
	-- @tparam nil|message msg
	-- @return self
	function obj:addPayload( key, msg )
		checkSelf( self, 'addPayload' )
		checkType( 'bcmath:addPayload', 1, key, 'string', true )
		checkType( 'bcmath:addPayload', 2, msg, 'table', true )

		if not _payload then
			_payload = {}
		end

		if key and not msg then
			msg = mw.message.new( key )
		end

		local t = { key and string.sub( key, 8 ) or nil, msg }
		table.insert( _payload, t )

		return self
	end

	--- Get payload from self.
	-- The payload is stored in the closure.
	-- @nick bcmath:payloads
	-- @nick bcmath:hasPayload
	-- @nick bcmath:hasPayloads
	-- @function bcmath:payload
	-- @return none, one or several keys
	function obj:payload()
		checkSelf( self, 'payload' )
		return unpack( _payload or {} )
	end
	obj.payloads = obj.payload
	obj.hasPayload = obj.payload
	obj.hasPayloads = obj.payload

	--- Get infinite.
	-- The value is stored in the closure.
	-- @nick bcmath:getInf
	-- @function bcmath:getInfinite
	-- @treturn nil|string
	function obj:getInfinite()
		checkSelf( self, 'value' )
		return bcmath.getInfinite( _value )
	end
	obj.getInf = obj.getInfinite

	--- Is infinite.
	-- The value is stored in the closure.
	-- @nick bcmath:isInf
	-- @function bcmath:isInfinite
	-- @treturn boolean
	function obj:isInfinite()
		checkSelf( self, 'value' )
		return not bcmath.isFinite( _value )
	end
	obj.isInf = obj.isInfinite

	--- Is finite.
	-- The value is stored in the closure.
	-- @nick bcmath:isFin
	-- @function bcmath:isFinite
	-- @treturn boolean
	function obj:isFinite()
		checkSelf( self, 'value' )
		return bcmath.isFinite( _value )
	end
	obj.isFin = obj.isFinite

	--- Get zero.
	-- The value is stored in the closure.
	-- @nick bcmath:getNull
	-- @function bcmath:getSignedZero
	-- @treturn nil|string
	function obj:getSignedZero()
		checkSelf( self, 'value' )
		return bcmath.getSignedZero( _value )
	end
	obj.getSignedNull = obj.getSignedZero

	--- Is zero.
	-- The value is stored in the closure.
	-- @nick bcmath:isNull
	-- @function bcmath:isZero
	-- @treturn boolean
	function obj:isZero()
		checkSelf( self, 'value' )
		return bcmath.isZero( _value )
	end
	obj.isNull = obj.isZero

	--- Is a NaN.
	-- The value is stored in the closure.
	-- @nick bcmath:isNan
	-- @function bcmath:isNaN
	-- @treturn boolean
	function obj:isNaN()
		checkSelf( self, 'value' )
		return not _value
	end
	obj.isNan = obj.isNaN

	--- Has a value.
	-- The value is stored in the closure.
	-- @nick bcmath:exist
	-- @nick bcmath:hasNumber
	-- @function bcmath:exists
	-- @treturn boolean
	function obj:exists()
		checkSelf( self, 'value' )
		return not not _value
	end
	obj.exist = obj.exists
	obj.hasNumber = obj.exists

	--- Negates self.
	-- @function bcmath:neg
	-- @return self
	function obj:neg()
		checkSelf( self, 'neg' )
		checkSelfValue()
		local sign, _ = extractSign( _value )
		if sign == '+' then
			_value = string.gsub( _value, '^%+', '-', 1 )
		elseif sign == '-' then
			_value = string.gsub( _value, '^%-', '+', 1 )
		else
			_value = '-' .. _value
		end

		return self
	end

	--- Add self with addend.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcadd](https://www.php.net/manual/en/function.bcadd.php) for further documentation.
	-- @function bcmath:add
	-- @tparam string|number|table addend an operand
	-- @tparam nil|number scale of decimal digits
	-- @treturn self
	function obj:add( addend, scale )
		checkSelf( self, 'add' )
		checkSelfValue()
		checkUnaryOperand( 'bcmath:add', addend, scale )
		local bval, bscl = convertWithBlame( addend, 'bcmath:add', 'addend' )
		_scale = scale or math.max( _scale, bscl )

		-- short circuit tests
		if self:isInfinite() or bcmath.isInfinite( bval ) then
			-- special case: minuend infinite, subtrahend finite
			if self:isInfinite() and bcmath.isFinite( bval ) then
				return self:addPayload( 'bcmath-add-singlesided-infinite' )
			-- special case: minuend finite, subtrahend infinite
			elseif self:isFinite() and bcmath.isInfinite( bval ) then
				_value = bval
				return self:addPayload( 'bcmath-add-singlesided-infinite' )
			end

			-- special case: infiniteness are dissimilar – NaN
			if self:getInfinite() ~= bcmath.getInfinite( bval ) then
				_value = nil
				return self:addPayload( 'bcmath-add-opposite-infinites' )
			-- special case: infiniteness are similar
			elseif self:getInfinite() == bcmath.getInfinite( bval ) then
				return self:addPayload( 'bcmath-add-similar-infinites' )
			end
		end

		_value = php.bcadd( _value, bval, _scale )

		return self
	end

	--- Subtract self with subtrahend.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcsub](https://www.php.net/manual/en/function.bcsub.php) for further documentation.
	-- @function bcmath:sub
	-- @tparam string|number|table subtrahend an operand
	-- @tparam nil|number scale of decimal digits
	-- @treturn self
	function obj:sub( subtrahend, scale )
		checkSelf( self, 'sub' )
		checkSelfValue()
		checkUnaryOperand( 'bcmath:sub', subtrahend, scale )
		local bval, bscl = convertWithBlame( subtrahend, 'bcmath:sub', 'subtrahend' )
		_scale = scale or math.max( _scale, bscl )

		-- short circuit tests
		if self:isInfinite() or bcmath.isInfinite( bval ) then
			-- special case: minuend infinite, subtrahend finite
			if self:isInfinite() and bcmath.isFinite( bval ) then
				return self:addPayload( 'bcmath-sub-singlesided-infinite' )
			-- special case: minuend finite, subtrahend infinite
			elseif self:isFinite() and bcmath.isInfinite( bval ) then
				_value = bcmath.neg( bval )
				return self:addPayload( 'bcmath-sub-singlesided-infinite' )
			end

			-- special case: infiniteness are dissimilar
			if self:getInfinite() ~= bcmath.getInfinite( bval ) then
				return self:addPayload( 'bcmath-sub-opposite-infinites' )
			-- special case: infiniteness are similar – NaN
			elseif self:getInfinite() == bcmath.getInfinite( bval ) then
				_value = nil
				return self:addPayload( 'bcmath-sub-similar-infinites' )
			end
		end

		_value = php.bcsub( _value, bval, _scale )

		return self
	end

	--- Multiply self with multiplicator.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcmul](https://www.php.net/manual/en/function.bcmul.php) for further documentation.
	-- @function bcmath:mul
	-- @tparam string|number|table multiplicator an operand
	-- @tparam nil|number scale of decimal digits
	-- @treturn self
	function obj:mul( multiplicator, scale )
		checkSelf( self, 'mul' )
		checkSelfValue()
		checkUnaryOperand( 'bcmath:mul', multiplicator, scale )
		local bval, bscl = convertWithBlame( multiplicator, 'bcmath:mul', 'multiplicator' )
		_scale = scale or math.max( _scale, bscl )

		-- short circuit tests
		if self:isInfinite() or bcmath.isInfinite( bval ) then
			-- special case: multiplier infinite, multiplicator zero – NaN
			if self:isInfinite() and bcmath.isZero( bval ) then
				_value = nil
				return self:addPayload( 'bcmath-mul-infinite-and-zero' )
			-- special case: multiplier zero, multiplicator infinite – NaN
			elseif self:isZero() and bcmath.isInfinite( bval ) then
				_value = nil
				return self:addPayload( 'bcmath-mul-infinite-and-zero' )
			end

			-- special case: infiniteness are dissimilar
			if self:getInfinite() ~= bcmath.getInfinite( bval ) then
				_value = bcmath.neg( _value )
				return self:addPayload( 'bcmath-mul-opposite-infinites' )
			-- special case: infiniteness are similar
			elseif self:getInfinite() == bcmath.getInfinite( bval ) then
				-- keep value
				return self:addPayload( 'bcmath-mul-similar-infinites' )
			end
		end

		_value = php.bcmul( _value, bval, _scale )

		return self
	end

	--- Divide self with divisor.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcdiv](https://www.php.net/manual/en/function.bcdiv.php) for further documentation.
	-- @function bcmath:div
	-- @tparam string|number|table divisor an operand
	-- @tparam nil|number scale of decimal digits
	-- @treturn self
	function obj:div( divisor, scale )
		checkSelf( self, 'div' )
		checkSelfValue()
		checkUnaryOperand( 'bcmath:div', divisor, scale )
		local bval, bscl = convertWithBlame( divisor, 'bcmath:div', 'divisor' )
		_scale = scale or math.max( _scale, bscl )

		-- special case: divisor zero – NaN
		if bcmath.isZero( bval ) then
			_value = nil
			return self:addPayload( 'bcmath-div-divisor-zero' )
		end

		-- special case: dividend infinite
		if self:isInfinite() then
			-- special case: divisor infinite – NaN
			if bcmath.isInfinite( bval ) then
				_value = nil
				return self:addPayload( 'bcmath-div-dividend-divisor-infinite' )
			end
			-- special case: divisor finite – NaN
			_value = bcmath.lt( bval, 0 ) and bcmath.neg( _value ) or _value
			return self:addPayload( 'bcmath-div-dividend-infinite' )
		end

		-- self infinite, operand infinite (note double infinite catched above)
		if self:isFinite() and bcmath.isInfinite( bval ) then
			-- sign on zero is not suppoted
			_value = '0'
			return self:addPayload( 'bcmath-div-divisor-infinite' )
		end

		_value = php.bcdiv( _value, bval, _scale )

		return self
	end

	--- Modulus self with divisor.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcmod](https://www.php.net/manual/en/function.bcmod.php) for further documentation.
	-- @function bcmath:mod
	-- @tparam string|number|table divisor an operand
	-- @tparam nil|number scale of decimal digits
	-- @treturn self
	function obj:mod( divisor, scale )
		checkSelf( self, 'mod' )
		checkSelfValue()
		checkUnaryOperand( 'bcmath:mod', divisor, scale )
		local bval, bscl = convertWithBlame( divisor, 'bcmath:mod', 'divisor' )
		_scale = scale or math.max( _scale, bscl )

		-- special case: divisor zero – NaN
		if bcmath.isZero( bval ) then
			_value = nil
			return self:addPayload( 'bcmath-mod-divisor-zero' )
		end

		-- special case: dividend infinite
		if self:isInfinite() then
			-- special case: divisor infinite – NaN
			if bcmath.isInfinite( bval ) then
				_value = nil
				return self:addPayload( 'bcmath-mod-dividend-divisor-infinite' )
			end
			-- special case: divisor finite – NaN
			_value = bcmath.lt( bval, 0 ) and bcmath.neg( _value ) or _value
			return self:addPayload( 'bcmath-mod-dividend-infinite' )
		end

		-- special case: divisor infinite (note double infinite catched above)
		if bcmath.isInfinite( bval ) then
			-- sign on zero is not suppoted
			_value = '0'
			return self:addPayload( 'bcmath-mod-divisor-infinite' )
		end

		_value = php.bcmod( _value, bval, _scale )

		return self
	end

	--- Power self with exponent.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcpow](https://www.php.net/manual/en/function.bcpow.php) for further documentation.
	-- @function bcmath:pow
	-- @tparam string|number|table exponent an operand
	-- @tparam nil|number scale of decimal digits
	-- @treturn self
	function obj:pow( exponent, scale )
		checkSelf( self, 'pow' )
		checkSelfValue()
		checkUnaryOperand( 'bcmath:pow', exponent, scale )
		local bval, bscl = convertWithBlame( exponent, 'bcmath:pow', 'exponent' )
		_scale = scale or math.max( _scale, bscl )

		-- special case: exponent zero – always 1
		if bcmath.eq( bval, '0' ) then
			_value = '1'
			return self:addPayload( 'bcmath-pow-exponent-zero' )
		end

		-- special case: base 1 – always 1
		if bcmath.eq( _value, '1' ) then
			return self:addPayload( 'bcmath-pow-base-one' )
		end

		_value = php.bcpow( _value, bval, _scale )

		return self
	end

	--- Power-modulus self with exponent and divisor.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcpowmod](https://www.php.net/manual/en/function.bcpowmod.php) for further documentation.
	-- @function bcmath:powmod
	-- @tparam string|number|table exponent an operand
	-- @tparam string|number|table divisor an operand
	-- @tparam nil|number scale of decimal digits
	-- @treturn self
	function obj:powmod( exponent, divisor, scale )
		checkSelf( self, 'powmod' )
		checkSelfValue()
		checkBinaryOperands( 'bcmath:powmod', exponent, divisor, scale )
		local bval1, bscl1 = convertWithBlame( exponent, 'bcmath:powmod', 'exponent' )
		local bval2, bscl2 = convertWithBlame( divisor, 'bcmath:powmod', 'divisor' )
		_scale = scale or math.max( _scale, bscl1, bscl2 )

		-- special case: divisor zero – NaN
		if bcmath.eq( bval2, '0' ) then
			_value = nil
			return self:addPayload( 'bcmath-powmod-divisor-zero' )
		end

		-- special case: exponent negative – NaN
		if bcmath.lt( bval1, '0' ) then
			_value = nil
			return self:addPayload( 'bcmath-powmod-exponent-negative' )
		end

		_value = php.bcpowmod( _value, bval1, bval2, _scale )

		return self
	end

	--- Square root self.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcsqrt](https://www.php.net/manual/en/function.bcsqrt.php) for further documentation.
	-- @function bcmath:sqrt
	-- @tparam nil|number scale of decimal digits
	-- @treturn self
	function obj:sqrt( scale )
		checkSelf( self, 'sqrt' )
		checkSelfValue()
		checkType( 'bcmath:sqrt', 1, scale, 'number', true )
		local scl = scale or _scale

		-- special case: operand less than zero – NaN
		if bcmath.lt( _value, 0 ) then
			_value = nil
			return self:addPayload( 'bcmath-sqrt-operand-negative' )
		end

		_value = php.bcsqrt( _value, scl )

		return self
	end

	--- Compare self with operand.
	-- All [comparisons involving a NaN](https://en.wikipedia.org/wiki/NaN#Comparison_with_NaN) will
	-- fail silently and return false.
	-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
	-- @function bcmath:comp
	-- @tparam string|number|table operand
	-- @tparam nil|number scale of decimal digits
	-- @treturn nil|number
	function obj:comp( operand, scale )
		checkSelf( self, 'comp' )
		checkSelfValue()
		checkUnaryOperand( 'bcmath:comp', operand, scale )
		local bval, bscl = convertWithBlame( operand, 'bcmath:comp', 'operand' )
		local scl = scale or math.max( _scale, bscl ) -- don't change the instance

		-- short circuit the tests
		if self:isInfinite() or bcmath.isInfinite( bval ) then
			local inf1 = tonumber( self:isInfinite()
				and mw.ustring.gsub( self:getInfinite(), '∞', '1', 1 )
				or 0 )
			local inf2 = tonumber( bcmath.isInfinite( bval )
				and mw.ustring.gsub( bcmath.getInfinite( bval ), '∞', '1', 1 )
				or 0 )

			-- special case: left infinite, right finite – NaN
			if self:isInfinite() and bcmath.isFinite( bval ) then
				return inf1
			elseif self:isFinite() and bcmath.isInfinite( bval ) then
				return -inf2
			end

			-- special case: infiniteness are dissimilar
			if self:getInfinite() ~= bcmath.getInfinite( bval ) then
				return inf1 < inf2 and -1 or 1
			-- special case: infiniteness are similar
			elseif self:getInfinite() == bcmath.getInfinite( bval ) then
				return nil
			end
		end

		return php.bccomp( _value, bval, scl )
	end

	--- Round self to given precision.
	-- This returns the rounded value as a new bcmath object, it does not change self.
	-- @function bcmath:round
	-- @tparam nil|number precision of decimal digits
	-- @tparam nil|number scale of decimal digits (forwarded to bcmath object)
	-- @treturn self
	function obj:round( precision, scale )
		checkSelf( self, 'round' )
		checkSelfValue()
		checkType( 'bcmath.round', 1, precision, 'number', true )
		checkType( 'bcmath.round', 2, scale, 'number', true )
		_scale = scale or _scale

		-- can not round an infinite value, but can normalize
		if bcmath.isInfinite( _value ) then
			_value = bcmath.getInfinite( _value )
		else
			_value = round( _value, precision )
		end

		return self
	end

	return obj
end

--- Create new instance.
-- @function mw.bcmath.new
-- @tparam string|number|table scale
-- @tparam nil|number scale of decimal digits
-- @treturn bcmath
function bcmath.new( value, scale )
	return makeBCmath( value, scale )
end

--- Get the sign.
-- Returned number is normalized, but nil if no string is found.
-- No explicit sign is interpreted as a positive sign.
-- @function mw.bcmath.getSign
-- @tparam nil|string value to be parsed
-- @treturn nil|number
function bcmath.getSign( value )
	checkTypeMulti( 'bcmath.getSign', 1, value, { 'string', 'number', 'table', 'nil' } )

	local val,_ = convert( value )
	if not val then
		return nil
	end

	local sign = string.match( val, '^([-+]?)' )
	if sign == '+' then
		return 1
	elseif sign == '-' then
		return -1
	end

	return 1
end

--- Get accumulated sign.
-- Returned number is normalized, but nil if no string is found.
-- No explicit sign is interpreted as a positive sign.
-- @function mw.bcmath.getAccumulatedSign
-- @tparam vararg ... to be parsed
-- @treturn nil|number
function bcmath.getAccumulatedSign( ... )
	local acc = nil
	for i,v in ipairs( { ... } ) do
		checkTypeMulti( 'bcmath.getAccumulatedSign', i, v, { 'string', 'number', 'table', 'nil' } )

		local val,_ = convert( v )
		if not val then
			return nil
		end

		local sign = bcmath.getSign( val )
		if not sign then
			return nil
		end

		acc = acc or 1
		if bcmath.getSign( val ) < 0 then
			acc = acc < 0 and 1 or -1
		end
	end
	return acc
end

--- Get the signed zero string.
-- Returned string is normalized, but nil if no zero string is found.
-- No explicit sign is interpreted as a positive sign.
-- @function mw.bcmath.getSignedZero
-- @tparam nil|string value to be parsed
-- @treturn nil|string
function bcmath.getSignedZero( value )
	checkTypeMulti( 'bcmath.getSignedZero', 1, value, { 'string', 'number', 'table', 'nil' } )

	local val,_ = convert( value )
	if not val then
		return nil
	end

	local pos = string.find( val, '^[-+]?[0][0.]*$')
	if not pos then
		return nil
	end

	local sign = string.match( val, '^([-+]?)' )
	if sign == '+' then
		return '+0'
	elseif sign == '-' then
		return '-0'
	end

	return '+0'
end

--- Is the string zero.
-- Returns true if zero is found.
-- @function mw.bcmath.isZero
-- @tparam nil|string value to be parsed
-- @treturn nil|boolean
function bcmath.isZero( value )
	checkTypeMulti( 'bcmath.isZero', 1, value, { 'string', 'number', 'table', 'nil' } )

	local val,_ = convert( value )
	if not val then
		return nil
	end

	local pos = string.find( val, '^[-+]?([0][0.]*)$')
	return not not pos
end

--- Get the strings infinite part.
-- Returned string is normalized,
-- and nil if no infinity is found.
-- @function mw.bcmath.getInfinite
-- @tparam nil|string value to be parsed
-- @treturn nil|string
function bcmath.getInfinite( value )
	checkTypeMulti( 'bcmath.getInfinite', 1, value, { 'string', 'number', 'table', 'nil' } )

	local val,_ = convert( value )
	if not val then
		return nil
	end

	local pos = string.find( val, '^[-+]?∞$')
	if not pos then
		return nil
	end

	local sign = string.match( val, '^([-+]?)' )
	if sign == '+' then
		return '+∞'
	elseif sign == '-' then
		return '-∞'
	end

	return '+∞'
end

--- Is the string infinite.
-- Returned string is normalized.
-- @function mw.bcmath.isInfinite
-- @tparam nil|string value to be parsed
-- @treturn nil|boolean
function bcmath.isInfinite( value )
	checkTypeMulti( 'bcmath.isInfinite', 1, value, { 'string', 'number', 'table', 'nil' } )

	local val,_ = convert( value )
	if not val then
		return nil
	end

	local pos = string.find( val, '[∞]')

	return not not pos
end

--- Is the string finite.
-- Returned string is normalized.
-- @function mw.bcmath.isFinite
-- @tparam nil|string value to be parsed
-- @treturn boolean
function bcmath.isFinite( value )
	checkTypeMulti( 'bcmath.isFinite', 1, value, { 'string', 'number', 'table', 'nil' } )

	local val,_ = convert( value )
	if not val then
		return nil
	end

	local pos = string.find( val, '[0-9]')

	return not not pos
end

--- Negates the string representation of the number
-- @function mw.bcmath.neg
-- @tparam string operand
-- @treturn string
function bcmath.neg( operand )
	checkUnaryOperand( 'bcmath.neg', operand )
	local sign, _ = extractSign( operand )
	if sign == '+' then
		local str = string.gsub( operand, '^%+', '-', 1 )
		return str
	elseif sign == '-' then
		local str = string.gsub( operand, '^%-', '+', 1 )
		return str
	end

	return '-' .. operand
end
bcmeta.__unm = bcmath.neg

--- Add the addend to augend.
-- This function is available as a metamethod.
-- See [PHP: bcadd](https://www.php.net/manual/en/function.bcadd.php) for further documentation.
-- @function mw.bcmath.add
-- @tparam string|number|table augend an operand
-- @tparam string|number|table addend an operand
-- @tparam nil|number scale of decimal digits
-- @treturn bcmath
function bcmath.add( augend, addend, scale )
	checkBinaryOperands( 'bcmath.add', augend, addend, scale )
	local bval1, bscl1 = convertWithBlame( augend, 'bcmath.add', 'augend' )
	local bval2, bscl2 = convertWithBlame( addend, 'bcmath.add', 'addend' )
	local scl = scale or math.max( bscl1, bscl2 )

	-- short circuit the tests
	if bcmath.isInfinite( bval1 ) or bcmath.getInfinite( bval2 ) then
		-- special case: minuend infinite, subtrahend finite
		if bcmath.isInfinite( bval1 ) and bcmath.isFinite( bval2 ) then
			return makeBCmath( bval1, scl ):addPayload( 'bcmath-add-singlesided-infinite' )
		-- special case: minuend finite, subtrahend infinite
		elseif bcmath.isFinite( bval1 ) and bcmath.isInfinite( bval2 ) then
			return makeBCmath( bval2, scl ):addPayload( 'bcmath-add-singlesided-infinite' )
		end

		-- special case: infiniteness are dissimilar – NaN
		if bcmath.getInfinite( bval1 ) ~= bcmath.getInfinite( bval2 ) then
			return makeBCmath( nil, scl ):addPayload( 'bcmath-add-opposite-infinites' )
		-- special case: infiniteness are similar
		elseif bcmath.getInfinite( bval1 ) == bcmath.getInfinite( bval2 ) then
			return makeBCmath( bval1, scl ):addPayload( 'bcmath-add-similar-infinites' )
		end
	end

	return makeBCmath( php.bcadd( bval1, bval2, scl ) or nil, scl )
end
bcmeta.__add = bcmath.add

--- Subtract the subtrahend from minuend.
-- This function is available as a metamethod.
-- See [PHP: bcsub](https://www.php.net/manual/en/function.bcsub.php) for further documentation.
-- @function mw.bcmath.sub
-- @tparam string|number|table minuend an operand
-- @tparam string|number|table subtrahend an operand
-- @tparam nil|number scale of decimal digits
-- @treturn bcmath
function bcmath.sub( minuend, subtrahend, scale )
	checkBinaryOperands( 'bcmath:sub', minuend, subtrahend, scale )
	local bval1, bscl1 = convertWithBlame( minuend, 'bcmath.sub', 'minuend' )
	local bval2, bscl2 = convertWithBlame( subtrahend, 'bcmath.sub', 'subtrahend' )
	local scl = scale or math.max( bscl1, bscl2 )

	-- short circuit the tests
	if bcmath.isInfinite( bval1 ) or bcmath.getInfinite( bval2 ) then
		-- special case: minuend infinite, subtrahend finite
		if bcmath.isInfinite( bval1 ) and bcmath.isFinite( bval2 ) then
			return makeBCmath( bval1, scl ):addPayload( 'bcmath-sub-singlesided-infinite' )
		-- special case: minuend finite, subtrahend infinite
		elseif bcmath.isFinite( bval1 ) and bcmath.isInfinite( bval2 ) then
			return makeBCmath( bcmath.neg( bval2 ), scl ):addPayload( 'bcmath-sub-singlesided-infinite' )
		end

		-- special case: infiniteness are dissimilar
		if bcmath.getInfinite( bval1 ) ~= bcmath.getInfinite( bval2 ) then
			return makeBCmath( bval1, scl ):addPayload( 'bcmath-sub-opposite-infinites' )
		-- special case: infiniteness are similar – NaN
		elseif bcmath.getInfinite( bval1 ) == bcmath.getInfinite( bval2 ) then
			return makeBCmath( nil, scl ):addPayload( 'bcmath-sub-similar-infinites' )
		end
	end

	return makeBCmath( php.bcsub( bval1, bval2, scl ) or nil, scl )
end
bcmeta.__sub = bcmath.sub

--- Multiply the multiplicator with multiplier.
-- This function is available as a metamethod.
-- See [PHP: bcmul](https://www.php.net/manual/en/function.bcmul.php) for further documentation.
-- @function mw.bcmath.mul
-- @tparam string|number|table multiplier an operand
-- @tparam string|number|table multiplicator an operand
-- @tparam nil|number scale of decimal digits
-- @treturn bcmath
function bcmath.mul( multiplier, multiplicator, scale )
	checkBinaryOperands( 'bcmath:mul', multiplier, multiplicator, scale )
	local bval1, bscl1 = convertWithBlame( multiplier, 'bcmath.mul', 'multiplier' )
	local bval2, bscl2 = convertWithBlame( multiplicator, 'bcmath.mul', 'multiplicator' )
	local scl = scale or math.max( bscl1, bscl2 )

	-- short circuit the tests
	if bcmath.isInfinite( bval1 ) or bcmath.isInfinite( bval2 ) then
		-- For the following, see https://en.wikipedia.org/wiki/Indeterminate_form
		-- special case: multiplier infinite, multiplicator zero – NaN
		if bcmath.isInfinite( bval1 ) and bcmath.isZero( bval2 ) then
			return makeBCmath( nil, scl ):addPayload( 'bcmath-mul-infinite-and-zero' )
		-- special case: multiplier zero, multiplicator infinite – NaN
		elseif bcmath.isZero( bval1 ) and bcmath.isInfinite( bval2 ) then
			return makeBCmath( nil, scl ):addPayload( 'bcmath-mul-infinite-and-zero' )
		end
--[[
		-- special case: multiplier infinite, multiplicator finite – infinite
		if bcmath.isInfinite( bval1 ) and bcmath.isZero( bval2 ) then
			return makeBCmath( '', scl ):addPayload( 'bcmath-mul-infinite-and-finite' )
		-- special case: multiplier zero, multiplicator infinite – infinite
		elseif bcmath.isZero( bval1 ) and bcmath.isInfinite( bval2 ) then
			return makeBCmath( nil, scl ):addPayload( 'bcmath-mul-infinite-and-finite' )
		end
]]
		-- special case: infiniteness are dissimilar
		if bcmath.getInfinite( bval1 ) ~= bcmath.getInfinite( bval2 ) then
			return makeBCmath( bcmath.neg( bval1 ), scl ):addPayload( 'bcmath-mul-opposite-infinites' )
		-- special case: infiniteness are similar
		elseif bcmath.getInfinite( bval1 ) == bcmath.getInfinite( bval2 ) then
			-- keep value
			return makeBCmath( bval1, scl ):addPayload( 'bcmath-mul-similar-infinites' )
		end
	end

	return makeBCmath( php.bcmul( bval1, bval2, scl ) or nil, scl )
end
bcmeta.__mul = bcmath.mul

--- Divide the divisor from dividend.
-- This function is available as a metamethod.
-- See [PHP: bcdiv](https://www.php.net/manual/en/function.bcdiv.php) for further documentation.
-- @function mw.bcmath.div
-- @tparam string|number|table dividend an operand
-- @tparam string|number|table divisor an operand
-- @tparam nil|number scale of decimal digits
-- @treturn bcmath
function bcmath.div( dividend, divisor, scale )
	checkBinaryOperands( 'bcmath:div', dividend, divisor, scale )
	local bval1, bscl1 = convertWithBlame( dividend, 'bcmath.div', 'dividend' )
	local bval2, bscl2 = convertWithBlame( divisor, 'bcmath.div', 'divisor' )
	local scl = scale or math.max( bscl1, bscl2 )

	-- special case: divisor zero – NaN
	if bcmath.isZero( bval2 ) then
		return makeBCmath( nil, scl ):addPayload( 'bcmath-div-divisor-zero' )
	end

	-- special case: dividend infinite
	if bcmath.isInfinite( bval1 ) then
		-- special case: divisor infinite – NaN
		if bcmath.isInfinite( bval2 ) then
			return makeBCmath( nil, scl):addPayload( 'bcmath-div-dividend-divisor-infinite' )
		end
		-- special case: divisor finite – possible sign shift
		local val = bcmath.lt( bval2, 0 ) and bcmath.neg( bval1 ) or bval1
		return makeBCmath( val, scl):addPayload( 'bcmath-div-dividend-infinite' )
	end

	-- special case: divisor infinite (note double infinite catched above)
	if bcmath.isInfinite( bval2 ) then
		-- sign on zero is not suppoted
		return makeBCmath( '0', scl ):addPayload( 'bcmath-div-divisor-infinite' )
	end

	return makeBCmath( php.bcdiv( bval1, bval2, scl ) or nil, scl )
end
bcmeta.__div = bcmath.div

--- Modulus the divisor from dividend.
-- This function is available as a metamethod.
-- See [PHP: bcmod](https://www.php.net/manual/en/function.bcmod.php) for further documentation.
-- @function mw.bcmath.mod
-- @tparam string|number|table dividend an operand
-- @tparam string|number|table divisor an operand
-- @tparam nil|number scale of decimal digits
-- @treturn bcmath
function bcmath.mod( dividend, divisor, scale )
	checkBinaryOperands( 'bcmath:mod', dividend, divisor, scale )
	local bval1, bscl1 = convertWithBlame( dividend, 'bcmath.mod', 'dividend' )
	local bval2, bscl2 = convertWithBlame( divisor, 'bcmath.mod', 'divisor' )
	local scl = scale or math.max( bscl1, bscl2 )

	-- special case: divisor zero – NaN
	if bcmath.isZero( bval2 ) then
		return makeBCmath( nil, scl ):addPayload( 'bcmath-mod-divisor-zero' )
	end

	-- special case: dividend infinite
	if bcmath.isInfinite( bval1 ) then
		-- special case: divisor infinite – NaN
		if bcmath.isInfinite( bval2 ) then
			return makeBCmath( nil, scl):addPayload( 'bcmath-mod-dividend-divisor-infinite' )
		end
		-- special case: divisor finite – possible sign shift
		local val = bcmath.lt( bval2, 0 ) and bcmath.neg( bval1 ) or bval1
		return makeBCmath( val, scl):addPayload( 'bcmath-mod-dividend-infinite' )
	end

	-- special case: divisor infinite (note double infinite catched above)
	if bcmath.isInfinite( bval2 ) then
		-- sign on zero is not supported
		return makeBCmath( '0', scl ):addPayload( 'bcmath-mod-divisor-infinite' )
	end

	return makeBCmath( php.bcmod( bval1, bval2, scl ) or nil, scl )
end
bcmeta.__mod = bcmath.mod

--- Power the base to exponent.
-- This function is available as a metamethod.
-- See [PHP: bcpow](https://www.php.net/manual/en/function.bcpow.php) for further documentation.
-- @function mw.bcmath.pow
-- @tparam string|number|table base an operand
-- @tparam string|number|table exponent an operand
-- @tparam nil|number scale of decimal digits
-- @treturn bcmath
function bcmath.pow( base, exponent, scale )
	checkBinaryOperands( 'bcmath:pow', base, exponent, scale )
	local bval1, bscl1 = convertWithBlame( base, 'bcmath.pow', 'base' )
	local bval2, bscl2 = convertWithBlame( exponent, 'bcmath.pow', 'exponent' )
	local scl = scale or math.max( bscl1, bscl2 )

	-- exponent zero – always 1
	if bcmath.eq( bval2, '0' ) then
		return makeBCmath( '1', scl ):addPayload( 'bcmath-pow-exponent-zero' )
	end

	-- base 1 – always 1
	if bcmath.eq( bval1, '1' ) then
		return makeBCmath( '1', scl ):addPayload( 'bcmath-pow-base-one' )
	end

	return makeBCmath( php.bcpow( bval1, bval2, scl ) or nil, scl )
end
bcmeta.__pow = bcmath.pow

--- Power-modulus the base to exponent.
-- This function is not available as a metamethod.
-- See [PHP: bcpowmod](https://www.php.net/manual/en/function.bcpowmod.php) for further documentation.
-- @function mw.bcmath.powmod
-- @tparam string|number|table base an operand
-- @tparam string|number|table exponent an operand
-- @tparam string|number|table divisor an operand
-- @tparam nil|number scale of decimal digits
-- @treturn bcmath
function bcmath.powmod( base, exponent, divisor, scale )
	checkTernaryOperands( 'bcmath:powmod', base, exponent, divisor, scale )
	local bval1, bscl1 = convertWithBlame( base, 'bcmath.powmod', 'base' )
	local bval2, bscl2 = convertWithBlame( exponent, 'bcmath.powmod', 'exponent' )
	local bval3, bscl3 = convertWithBlame( divisor, 'bcmath.powmod', 'divisor' )
	local scl = scale or math.max( bscl1, bscl2, bscl3 )

	-- divisor zero – NaN
	if bcmath.eq( bval3, '0' ) then
		return makeBCmath( nil, scl ):addPayload( 'bcmath-pow-divisor-zero' )
	end

	-- exponent negative – NaN
	if bcmath.lt( bval2, '0' ) then
		return makeBCmath( nil, scl ):addPayload( 'bcmath-pow-exponent-negative' )
	end

	return makeBCmath( php.bcpowmod( bval1, bval2, bval3, scl ) or nil, scl )
end

--- Square root of the operand.
-- This function is not available as a metamethod.
-- See [PHP: bcsqrt](https://www.php.net/manual/en/function.bcsqrt.php) for further documentation.
-- @function mw.bcmath.sqrt
-- @tparam string|number|table an operand
-- @tparam nil|number scale of decimal digits
-- @treturn bcmath
function bcmath.sqrt( operand, scale )
	checkUnaryOperand( 'bcmath:sqrt', operand, scale )
	local bval1, bscl1 = convertWithBlame( operand, 'bcmath.sqrt', 'operand' )
	local scl = scale or bscl1

	-- operand less than zero – NaN
	if bcmath.lt( bval1, 0 ) then
		return makeBCmath( nil, scl ):addPayload( 'bcmath-sqrt-operand-negative' )
	end

	return makeBCmath( php.bcsqrt( bval1, scl ), scl )
end

--- Compare the left operand with the right operand.
-- This function is not available as a metamethod.
-- All [comparisons involving a NaN](https://en.wikipedia.org/wiki/NaN#Comparison_with_NaN) will
-- fail silently and return false.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.comp
-- @tparam string|number|table left an operand
-- @tparam string|number|table right an operand
-- @tparam nil|number scale of decimal digits
-- @treturn nil|number
function bcmath.comp( left, right, scale )
	checkBinaryOperands( 'bcmath:comp', left, right, scale )
	local bval1, bscl1 = convertWithBlame( left, 'bcmath.comp', 'left' )
	local bval2, bscl2 = convertWithBlame( right, 'bcmath.comp', 'right' )
	if not( bval1 ) or not( bval2 ) then
		return false
	end

	-- short circuit the tests
	if bcmath.isInfinite( bval1 ) or bcmath.isInfinite( bval2 ) then
		--local inf = { mw.ustring.gsub( bcmath.getInfinite( bval1 ), '∞', '1', 1 ) }
		--do return inf end
		local inf1 = tonumber( bcmath.isInfinite(bval1 )
			and mw.ustring.gsub( bcmath.getInfinite( bval1 ), '∞', '1', 1 )
			or 0 )
		local inf2 = tonumber( bcmath.isInfinite(bval2 )
			and mw.ustring.gsub( bcmath.getInfinite( bval2 ), '∞', '1', 1 )
			or 0 )

		-- special case: left infinite, right finite – NaN
		if bcmath.isInfinite( bval1 ) and bcmath.isFinite( bval2 ) then
			return inf1
		elseif bcmath.isFinite( bval1 ) and bcmath.isInfinite( bval2 ) then
			return -inf2
		end

		-- special case: infiniteness are dissimilar
		if bcmath.getInfinite( bval1 ) ~= bcmath.getInfinite( bval2 ) then
			return inf1 < inf2 and -1 or 1
		-- special case: infiniteness are similar
		elseif bcmath.getInfinite( bval1 ) == bcmath.getInfinite( bval2 ) then
			return nil
		end
	end

	local bscl = scale or math.max( bscl1, bscl2 )
	return php.bccomp( bval1, bval2, bscl )
end

--- Check if left operand is equal to right operand.
-- This function is available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.eq
-- @tparam string|number|table left an operand
-- @tparam string|number|table right an operand
-- @tparam nil|number scale of decimal digits
-- @treturn boolean
function bcmath.eq( left, right, scale )
	return bcmath.comp( left, right, scale ) == 0
end
bcmeta.__eq = bcmath.eq

--- Check if left operand is less than right operand.
-- This function is available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.lt
-- @tparam string|number|table left an operand
-- @tparam string|number|table right an operand
-- @tparam nil|number scale of decimal digits
-- @treturn boolean
function bcmath.lt( left, right, scale )
	return bcmath.comp( left, right, scale ) < 0
end
bcmeta.__lt = bcmath.lt

--- Check if left operand is greater or equal to right operand.
-- This function is not available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.ge
-- @tparam string|number|table left an operand
-- @tparam string|number|table right an operand
-- @tparam nil|number scale of decimal digits
-- @treturn boolean
function bcmath.ge( left, right, scale )
	return bcmath.comp( left, right, scale ) >= 0
end

--- Check if left operand is less than or equal to right operand.
-- This function is available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.le
-- @tparam string|number|table left an operand
-- @tparam string|number|table right an operand
-- @tparam nil|number scale of decimal digits
-- @treturn boolean
function bcmath.le( left, right, scale )
	return bcmath.comp( left, right, scale ) <= 0
end
bcmeta.__le = bcmath.le

--- Check if left operand is equal to right operand.
-- This function is not available as a metamethod.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.gt
-- @tparam string|number|table left an operand
-- @tparam string|number|table right an operand
-- @tparam nil|number scale of decimal digits
-- @treturn boolean
function bcmath.gt( left, right, scale )
	return bcmath.comp( left, right, scale ) > 0
end

--- Round the value to given precision.
-- @function mw.bcmath.round
-- @tparam string|number|table value
-- @tparam nil|number precision of decimal digits
-- @tparam nil|number scale of decimal digits (forwarded to bcmath object)
-- @treturn bcmath
function bcmath.round( value, precision, scale )
	checkTypeMulti( 'bcmath.round', 1, value, { 'string', 'table', 'number' } )
	checkType( 'bcmath.round', 2, precision, 'number', true )
	checkType( 'bcmath.round', 3, scale, 'number', true )
	local bval, bscl = convertWithBlame( value, 'bcmath.round', 'value' )

	-- can not round an infinite value
	if bcmath.isInfinite( bval ) then
		return makeBCmath( bcmath.getInfinite( bval ), bscl )
	end

	return makeBCmath( round( bval, precision ), scale )
end

return bcmath
