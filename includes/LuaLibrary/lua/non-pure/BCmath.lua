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

local function checkUnaryOperand( name, operand1, scale )
	checkTypeMulti( name, 1, operand1, { 'string', 'number', 'table', 'nil' } )
	checkType( name, 2, scale, 'number', true )
end

local function checkBinaryOperands( name, operand1, operand2, scale )
	checkTypeMulti( name, 1, operand1, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( name, 2, operand2, { 'string', 'number', 'table', 'nil' } )
	checkType( name, 2, scale, 'number', true )
end

local function checkTernaryOperands( name, operand1, operand2, operand3, scale )
	checkTypeMulti( name, 1, operand1, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( name, 2, operand2, { 'string', 'number', 'table', 'nil' } )
	checkTypeMulti( name, 3, operand3, { 'string', 'number', 'table', 'nil' } )
	checkType( name, 2, scale, 'number', true )
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
-- @local
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

--- Check string for infinity character.
-- Returned number gives the sign of the infinity,
-- and nil if no infinity is found.
-- @tparam string num to be parsed
-- @treturn number
local function checkInfinity( num )
	if not num then
		return nil
	end
	if num == '∞' then
		return 1
	end
	if num == '+∞' then
		return 1
	end
	if num == '-∞' then
		return -1
	end
	return 0
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
	if checkInfinity( value )  ~= 0 then
		return ( checkInfinity( value ) == 1 and '+∞' )
			or ( checkInfinity( value ) == -1 and '-∞' )
			or nil, 0
	end

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
-- If operator is given, then a failure will rise an exception.
-- This is a real bottleneck due to the dispatched function calls.
-- @local
-- @function parseNumScale
-- @tparam string|number|table value to be parsed
-- @tparam nil|string operator to be reported
-- @treturn string holding bcnumber
-- @treturn number holding an estimate
local function parseNumScale( value, operator, operand )
	if operator and not value then
		error( mw.message.new( 'bcmath-check-operand-nan', operator, operand ):plain() )
	end
	local conv = argConvs[type( value )]
	if not conv then
		return nil
	end
	local _value, _scale = conv( value )
	return _value, _scale
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
-- This is called from @{bcmath:__call}.
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
-- This is called from @{bcmath:__call}.
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
	local modulus = math.fmod( exponent, 3 )
	mw.logObject(mantissa)

	integral = nil
	integralLen = 0
	fraction = nil
	if mantissaLen == 0 then
		mw.log('then: mantissaLen == 0')
		integral = '0'
		exponent = 0
	else
		mw.log('else: mantissaLen =/= 0')
		mw.logObject(exponent)
		mw.logObject(modulus)
		exponent = exponent - modulus
	end
	if mantissaLen > modulus then
		mw.log('then: mantissaLen > modulus')
		integral = string.sub( mantissa, 1, modulus )
		integralLen = modulus + 1
	elseif mantissaLen > 0 then
		mw.log('else: mantissaLen /> modulus')
		integral = mantissa
		integralLen = mantissaLen
	end
	if mantissaLen > modulus+1 then
		fraction = string.sub( mantissa, modulus+1, -1 )
		fractionLen = mantissaLen - modulus - 1
	end
	mw.logObject(exponent)

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
-- This is called from @{bcmath:__call}.
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
	error( mw.message.new( 'bcmath-check-self-style', 'CLDR Pattern' ):plain() )
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
		conv = convertPattern
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
	--num = string.gsub( num, '%.$', '', 1 )

	-- if empty, then put bak a single zero
	if num == '' then
		num = '0'
	end

	-- return a formatted text representation
	return conv( num, precision, style )
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
	--num = string.gsub( num, '%.$', '', 1 )

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
	-- @tparam string key
	-- @return self
	function obj:addPayload( key )
		checkSelf( self, 'addPayload' )
		if not _payload then
			_payload = {}
		end
		table.insert( _payload, key )
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

	--- Add self with addend.
	-- This method will store result in self, and then return self to facilitate chaining.
	-- See [PHP: bcadd](https://www.php.net/manual/en/function.bcadd.php) for further documentation.
	-- @function bcmath:add
	-- @tparam string|number|table addend an operand
	-- @tparam nil|number scale of decimal digits
	-- @treturn self
	function obj:add( addend, scale )
		checkSelf( self, 'add' )
		checkUnaryOperand( 'bcmath:add', addend, scale )
		checkSelfValue()
		local bval, bscl = parseNumScale( addend, 'bcmath:add', 'addend' )

		-- normal calculation
		if checkInfinity( _value ) == 0 and checkInfinity( bval ) == 0 then
			_value = php.bcadd( _value, bval, scale or math.max( _scale, bscl ) )
			return self
		end

		if checkInfinity( _value ) == 0 or checkInfinity( bval ) == 0 then
			_value = ( checkInfinity( _value ) == -1 and '-∞' )
				or ( checkInfinity( _value ) == 1 and '+∞' )
				or ( checkInfinity( bval ) == -1 and '-∞' )
				or ( checkInfinity( bval ) == 1 and '+∞' )
				or nil

			if not _value then
				self:addPayload ( 'bcmath-add-singlesided-infinite' )
			end

			return self
		end

		if checkInfinity( _value ) == checkInfinity( bval ) then
			self:addPayload ( 'bcmath-add-similar-infinites' )

			return self
		end

		_value = nil
		self:addPayload ( 'bcmath-add-opposite-infinites' )

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
		checkUnaryOperand( 'bcmath:sub', subtrahend, scale )
		checkSelfValue()
		local bval, bscl = parseNumScale( subtrahend, 'bcmath:sub', 'subtrahend' )

		if checkInfinity( _value ) == 0 and checkInfinity( bval ) == 0 then
			_value = php.bcsub( _value, bval, scale or math.max( _scale, bscl ) )
			return self
		end

		if checkInfinity( _value ) == 0 or checkInfinity( bval ) == 0 then
			_value = ( checkInfinity( _value ) == -1 and '-∞' )
				or ( checkInfinity( _value ) == 1 and '+∞' )
				or ( checkInfinity( bval ) == -1 and '+∞' )
				or ( checkInfinity( bval ) == 1 and '-∞' )
				or nil

			if not _value then
				self:addPayload ( 'bcmath-sub-singlesided-infinite' )
			end

			return self
		end

		if checkInfinity( _value ) == -checkInfinity( bval ) then
			self:addPayload ( 'bcmath-sub-opposite-infinites' )
			return self
		end

		_value = nil
		self:addPayload ( 'bcmath-sub-similar-infinite' )

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
		checkUnaryOperand( 'bcmath:mul', multiplicator, scale )
		checkSelfValue()
		local bval, bscl = parseNumScale( multiplicator, 'bcmath:mul', 'multiplicator' )
		_value = php.bcmul( _value, bval, scale or math.max( _scale, bscl ) )
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
		checkUnaryOperand( 'bcmath:div', divisor, scale )
		checkSelfValue()
		local bval, bscl = parseNumScale( divisor, 'bcmath:div', 'divisor' )
		_value = php.bcdiv( _value, bval, scale or math.max( _scale, bscl ) )
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
		checkUnaryOperand( 'bcmath:mod', divisor, scale )
		checkSelfValue()
		local bval, bscl = parseNumScale( divisor, 'bcmath:mod', 'divisor' )
		_value = php.bcmod( _value, bval, scale or math.max( _scale, bscl ) )
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
		checkUnaryOperand( 'bcmath:pow', exponent, scale )
		checkSelfValue()
		local bval, bscl = parseNumScale( exponent, 'bcmath:pow', 'exponent' )
		_value = php.bcpow( _value, bval, scale or math.max( _scale, bscl ) )
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
		checkBinaryOperands( 'bcmath:powmod', exponent, divisor, scale )
		checkSelfValue()
		local bval1, bscl1 = parseNumScale( exponent, 'bcmath:powmod', 'exponent' )
		local bval2, bscl2 = parseNumScale( divisor, 'bcmath:powmod', 'divisor' )
		_value = php.bcpowmod( _value, bval1, bval2, scale or math.max( _scale, bscl1, bscl2 ) )
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
		checkType( 'bcmath:sqrt', 1, scale, 'number', true )
		checkSelfValue()
		_value = php.bcsqrt( _value, scale or _scale )
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
	local bval1, bscl1 = parseNumScale( augend, 'bcmath.add', 'augend' )
	local bval2, bscl2 = parseNumScale( addend, 'bcmath.add', 'addend' )

	if checkInfinity( bval1 ) == 0 and checkInfinity( bval2 ) == 0 then
		local bscl = scale or math.max( bscl1, bscl2 )
		return makeBCmath( php.bcadd( bval1, bval2, bscl ), bscl )
	end

	if checkInfinity( bval1 ) == 0 or checkInfinity( bval2 ) == 0 then
		local value = ( checkInfinity( bval1 ) ~= 0 and bval1 )
			or ( checkInfinity( bval2 ) ~= 0 and bval2 )
			or nil

		local obj = makeBCmath( value )

		if not value then
			obj:addPayload ( 'bcmath-add-singlesided-infinite' )
		end

		return obj
	end

	if checkInfinity( bval1 ) == checkInfinity( bval2 ) then
		local obj = makeBCmath( bval1 )
		obj:addPayload ( 'bcmath-add-similar-infinites' )

		return obj
	end

	local obj = makeBCmath()
	obj:addPayload ( 'bcmath-add-opposite-infinites' )

	return obj

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
	local bval1, bscl1 = parseNumScale( minuend, 'bcmath.sub', 'minuend' )
	local bval2, bscl2 = parseNumScale( subtrahend, 'bcmath.sub', 'subtrahend' )

	if checkInfinity( bval1 ) == 0 and checkInfinity( bval2 ) == 0 then
		local bscl = scale or math.max( bscl1, bscl2 )
		return makeBCmath( php.bcsub( bval1, bval2, bscl ), bscl )
	end

	if checkInfinity( bval1 ) == 0 or checkInfinity( bval2 ) == 0 then
		local value = ( checkInfinity( bval1 ) == -1 and '-∞' )
			or ( checkInfinity( bval1 ) == 1 and '+∞' )
			or ( checkInfinity( bval2 ) == -1 and '+∞' )
			or ( checkInfinity( bval2 ) == 1 and '-∞' )
			or nil

		local obj = makeBCmath( value )

		if not value then
			obj:addPayload ( 'bcmath-sub-singlesided-infinite' )
		end

		return obj
	end

	if checkInfinity( bval1 ) == -checkInfinity( bval2 ) then
		local obj = makeBCmath( bval1 )
		obj:addPayload ( 'bcmath-sub-opposite-infinites' )

		return obj
	end

	local obj = makeBCmath()
	obj:addPayload ( 'bcmath-add-similar-infinites' )

	return obj

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
	local bval1, bscl1 = parseNumScale( multiplier, 'bcmath.mul', 'multiplier' )
	local bval2, bscl2 = parseNumScale( multiplicator, 'bcmath.mul', 'multiplicator' )
	local bscl = scale or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcmul( bval1, bval2, bscl ), bscl )
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
	local bval1, bscl1 = parseNumScale( dividend, 'bcmath.div', 'dividend' )
	local bval2, bscl2 = parseNumScale( divisor, 'bcmath.div', 'divisor' )
	local bscl = scale or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcdiv( bval1, bval2, bscl ), bscl )
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
	local bval1, bscl1 = parseNumScale( dividend, 'bcmath.mod', 'dividend' )
	local bval2, bscl2 = parseNumScale( divisor, 'bcmath.mod', 'divisor' )
	local bscl = scale or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcmod( bval1, bval2, bscl ), bscl )
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
	local bval1, bscl1 = parseNumScale( base, 'bcmath.pow', 'base' )
	local bval2, bscl2 = parseNumScale( exponent, 'bcmath.pow', 'exponent' )
	local bscl = scale or math.max( bscl1, bscl2 )
	return makeBCmath( php.bcpow( bval1, bval2, bscl ), bscl )
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
	local bval1, bscl1 = parseNumScale( base, 'bcmath.powmod', 'base' )
	local bval2, bscl2 = parseNumScale( exponent, 'bcmath.powmod', 'exponent' )
	local bval3, bscl3 = parseNumScale( divisor, 'bcmath.powmod', 'divisor' )
	local bscl = scale or math.max( bscl1, bscl2, bscl3 )
	return makeBCmath( php.bcpowmod( bval1, bval2, bval3, bscl ), bscl )
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
	local bval1, bscl1 = parseNumScale( operand, 'bcmath.sqrt', 'operand' )
	local bscl = scale or bscl1
	return makeBCmath( php.bcsqrt( bval1, bscl ), bscl )
end

--- Compare the left operand with the right operand.
-- This function is not available as a metamethod.
-- All [comparisons involving a NaN](https://en.wikipedia.org/wiki/NaN#Comparison_with_NaN) will
-- fail silently and return false.
-- See [PHP: bccomp](https://www.php.net/manual/en/function.bccomp.php) for further documentation.
-- @function mw.bcmath.eq
-- @tparam string|number|table left an operand
-- @tparam string|number|table right an operand
-- @tparam nil|number scale of decimal digits
-- @treturn bcmath
function bcmath.comp( left, right, scale )
	checkBinaryOperands( 'bcmath:comp', left, right, scale )
	local bval1, bscl1 = parseNumScale( left, 'bcmath.comp', 'left' )
	local bval2, bscl2 = parseNumScale( right, 'bcmath.comp', 'right' )
	if not( bval1 ) or not( bval2 ) then
		return false
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
-- @treturn bcmath
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
-- @treturn bcmath
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
-- @treturn bcmath
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
-- @treturn bcmath
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
-- @treturn bcmath
function bcmath.gt( left, right, scale )
	return bcmath.comp( left, right, scale ) > 0
end

return bcmath
