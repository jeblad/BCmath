--- Register functions for the bcmath api.
-- @module BCmath

-- accesspoints for the boilerplate
local php      -- luacheck: ignore

-- pure libs
local libUtil = require 'libraryUtil'
local checkType = libUtil.checkType
local checkTypeMulti = libUtil.checkTypeMulti
local makeCheckSelfFunction = libUtil.makeCheckSelfFunction

-- @var structure for storage of the lib
local bcmath = {}

-- @var metatable for the library
local meta = {}

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

local bcsuper = {}

local function makeBCmath( data )
	local obj = {}
	local checkSelf = makeCheckSelfFunction( 'mw.bcmath', 'msg', obj, 'bcmath object' )

	function obj:add( num )
		checkSelf( self, 'add' )
		checkTypeMulti( 'bcmath:add', 1, num, { 'string', 'table' } )
		data = php.bcadd( self(), type( num ) == 'string' and num or num() )
		return self
	end

	function obj:sub( num )
		checkSelf( self, 'sub' )
		checkTypeMulti( 'bcmath:sub', 1, num, { 'string', 'table' } )
		data = php.bcsub( self(), type( num ) == 'string' and num or num() )
		return self
	end

	function obj:mul( num )
		checkSelf( self, 'mul' )
		checkTypeMulti( 'bcmath:mul', 1, num, { 'string', 'table' } )
		data = php.bcmul( self(), type( num ) == 'string' and num or num() )
		return self
	end

	function obj:div( num )
		checkSelf( self, 'div' )
		checkTypeMulti( 'bcmath:div', 1, num, { 'string', 'table' } )
		data = php.bcdiv( self(), type( num ) == 'string' and num or num() )
		return self
	end

	function obj:mod( num )
		checkSelf( self, 'mod' )
		checkTypeMulti( 'bcmath:mod', 1, num, { 'string', 'table' } )
		data = php.bcmod( self(), type( num ) == 'string' and num or num() )
		return self
	end

	function obj:pow( num )
		checkSelf( self, 'pow' )
		checkTypeMulti( 'bcmath:pow', 1, num, { 'string', 'table' } )
		data = php.bcpow( self(), type( num ) == 'string' and num or num() )
		return self
	end

	function obj:powmod( num )
		checkSelf( self, 'powmod' )
		checkTypeMulti( 'bcmath:powmod', 1, num, { 'string', 'table' } )
		data = php.bcpowmod( self(), type( num ) == 'string' and num or num() )
		return self
	end

	function obj:sqrt()
		checkSelf( self, 'sqrt' )
		data = php.bcsqrt( self() )
		return self
	end

 --   bccomp — Compare two arbitrary precision numbers

	local bcmeta = setmetatable( {}, bcsuper )
	function bcmeta.__call()
		return data
	end
	return setmetatable( obj, bcmeta )
end

function bcsuper.__add( lhs, rhs )
	return makeBCmath( php.bcadd( lhs(), rhs() ) )
end

function bcsuper.__sub( lhs, rhs )
	return makeBCmath( php.bcsub( lhs(), rhs() ) )
end

function bcsuper.__mul( lhs, rhs )
	return makeBCmath( php.bcmul( lhs(), rhs() ) )
end

function bcsuper.__div( lhs, rhs )
	return makeBCmath( php.bcdiv( lhs(), rhs() ) )
end

function bcsuper.__mod( lhs, rhs )
	return makeBCmath( php.bcmod( lhs(), rhs() ) )
end

function bcsuper.__pow( lhs, rhs )
	return makeBCmath( php.bcpow( lhs(), rhs() ) )
end

function bcsuper._k_tostring( t )
	return mw.dumpObject( t )
end

function bcmath.new( num )
	checkType( 'bcmath.new', 1, num, 'string' )
	return makeBCmath( num )
end

return bcmath