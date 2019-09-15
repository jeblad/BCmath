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

local function makeBCarg( num )
	return ( type( num ) == 'table' and num() )
		or ( type( num ) == 'string' and num )
		or tostring( num )
end

local function makeBCmath( data )
	local obj = {}
	local checkSelf = makeCheckSelfFunction( 'mw.bcmath', 'msg', obj, 'bcmath object' )

	function obj:add( num )
		checkSelf( self, 'add' )
		checkTypeMulti( 'bcmath:add', 1, num, { 'string', 'table' } )
		data = php.bcadd( self(), makeBCarg( num ) )
		return self
	end

	function obj:sub( num )
		checkSelf( self, 'sub' )
		checkTypeMulti( 'bcmath:sub', 1, num, { 'string', 'table' } )
		data = php.bcsub( self(), makeBCarg( num ) )
		return self
	end

	function obj:mul( num )
		checkSelf( self, 'mul' )
		checkTypeMulti( 'bcmath:mul', 1, num, { 'string', 'table' } )
		data = php.bcmul( self(), makeBCarg( num ) )
		return self
	end

	function obj:div( num )
		checkSelf( self, 'div' )
		checkTypeMulti( 'bcmath:div', 1, num, { 'string', 'table' } )
		data = php.bcdiv( self(), makeBCarg( num ) )
		return self
	end

	function obj:mod( num )
		checkSelf( self, 'mod' )
		checkTypeMulti( 'bcmath:mod', 1, num, { 'string', 'table' } )
		data = php.bcmod( self(), makeBCarg( num ) )
		return self
	end

	function obj:pow( num )
		checkSelf( self, 'pow' )
		checkTypeMulti( 'bcmath:pow', 1, num, { 'string', 'table' } )
		data = php.bcpow( self(), makeBCarg( num ) )
		return self
	end

	function obj:powmod( num )
		checkSelf( self, 'powmod' )
		checkTypeMulti( 'bcmath:powmod', 1, num, { 'string', 'table' } )
		data = php.bcpowmod( self(), makeBCarg( num ) )
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
	checkTypeMulti( 'bcmath:__add', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__add', 2, rhs, { 'string', 'table' } )
	return makeBCmath( php.bcadd( makeBCarg( lhs ), makeBCarg( rhs ) ) )
end

function bcsuper.__sub( lhs, rhs )
	checkTypeMulti( 'bcmath:__sub', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__sub', 2, rhs, { 'string', 'table' } )
	return makeBCmath( php.bcsub( makeBCarg( lhs ), makeBCarg( rhs ) ) )
end

function bcsuper.__mul( lhs, rhs )
	checkTypeMulti( 'bcmath:__mul', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__mul', 2, rhs, { 'string', 'table' } )
	return makeBCmath( php.bcmul( makeBCarg( lhs ), makeBCarg( rhs ) ) )
end

function bcsuper.__div( lhs, rhs )
	checkTypeMulti( 'bcmath:__div', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__div', 2, rhs, { 'string', 'table' } )
	return makeBCmath( php.bcdiv( makeBCarg( lhs ), makeBCarg( rhs ) ) )
end

function bcsuper.__mod( lhs, rhs )
	checkTypeMulti( 'bcmath:__mod', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__mod', 2, rhs, { 'string', 'table' } )
	return makeBCmath( php.bcmod( makeBCarg( lhs ), makeBCarg( rhs ) ) )
end

function bcsuper.__pow( lhs, rhs )
	checkTypeMulti( 'bcmath:__pow', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__pow', 2, rhs, { 'string', 'table' } )
	return makeBCmath( php.bcpow( makeBCarg( lhs ), makeBCarg( rhs ) ) )
end

-- Not a metamethod
function bcsuper.__powmod( lhs, rhs )
	checkTypeMulti( 'bcmath:__powmod', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__powmod', 2, rhs, { 'string', 'table' } )
	return makeBCmath( php.bcpowmod( makeBCarg( lhs ), makeBCarg( rhs ) ) )
end

-- Not a metamethod
function bcsuper.__sqrt( lhs, rhs )
	checkTypeMulti( 'bcmath:__sqrt', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__sqrt', 2, rhs, { 'string', 'table' } )
	return makeBCmath( php.bcsqrt( makeBCarg( lhs ), makeBCarg( rhs ) ) )
end

function bcsuper.__eq( lhs, rhs )
	checkTypeMulti( 'bcmath:__eq', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__eq', 2, rhs, { 'string', 'table' } )
	return php.bccomp( makeBCarg( lhs ), makeBCarg( rhs ) ) == 0
end

function bcsuper.__lt( lhs, rhs )
	checkTypeMulti( 'bcmath:__lt', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__lt', 2, rhs, { 'string', 'table' } )
	return php.bccomp( makeBCarg( lhs ), makeBCarg( rhs ) ) < 0
end

function bcsuper.__le( lhs, rhs )
	checkTypeMulti( 'bcmath:__le', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath:__le', 2, rhs, { 'string', 'table' } )
	return php.bccomp( makeBCarg( lhs ), makeBCarg( rhs ) ) <= 0
end

function bcsuper._k_tostring( t )
	return mw.dumpObject( t )
end

function bcmath.new( num )
	checkType( 'bcmath.new', 1, num, 'string' )
	return makeBCmath( num )
end

function bcmath.add( lhs, rhs, scale )
	checkTypeMulti( 'bcmath.add', 1, lhs, { 'string', 'table' } )
	checkTypeMulti( 'bcmath.add', 2, rhs, { 'string', 'table' } )
	checkType( 'bcmath.add', 3, scale, 'number', true )
	return makeBCmath( php.bcadd( makeBCarg( lhs ), makeBCarg( rhs ), scale ) )
end

return bcmath