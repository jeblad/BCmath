<?php
declare( strict_types = 1 );
namespace BCmath;
use Scribunto_LuaLibraryBase;
/**
 * Registers our lua modules to Scribunto
 *
 * @ingroup Extensions
 */
class LuaLibBCmath extends Scribunto_LuaLibraryBase {
	public function register() {
		$lib = [
			'bcadd' => [ $this, 'bcAdd' ],
			'bcsub' => [ $this, 'bcSub' ],
			'bcmul' => [ $this, 'bcMul' ],
			'bcdiv' => [ $this, 'bcDiv' ],
			'bcmod' => [ $this, 'bcMod' ],
			'bcpow' => [ $this, 'bcPow' ],
			'bcpowmod' => [ $this, 'bcPowMod' ],
			'bcsqrt' => [ $this, 'bcSqrt' ]
		];
		// Get the correct default language from the parser
		if ( $this->getParser() ) {
			$lang = $this->getParser()->getTargetLanguage();
		} else {
			global $wgContLang;
			$lang = $wgContLang;
		}
		return $this->getEngine()->registerInterface( __DIR__ . '/lua/non-pure/BCmath.lua', $lib, [
			'lang' => $lang->getCode(),
		] );
	}

	/**
	 * Handler for bcAdd
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @param null|int $rhs
	 * @return string
	 */
	public function bcAdd( $lhs, $rhs, $scale=null ) {
		try {
			return [ \bcadd( $lhs, $rhs, is_null($scale) ? 0 : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:add() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcSub
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @return string
	 */
	public function bcSub( $lhs, $rhs ) {
		try {
			return [ \bcsub( $lhs, $rhs ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:sub() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcMul
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @return string
	 */
	public function bcMul( $lhs, $rhs ) {
		try {
			return [ \bcmul( $lhs, $rhs ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:mul() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcDiv
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @return string
	 */
	public function bcDiv( $lhs, $rhs ) {
		try {
			return [ \bcdiv( $lhs, $rhs ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:div() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcMod
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @return string
	 */
	public function bcMod( $lhs, $rhs ) {
		try {
			return [ \bcmod( $lhs, $rhs ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:mod() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcPow
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @return string
	 */
	public function bcPow( $lhs, $rhs ) {
		try {
			return [ \bcpow( $lhs, $rhs ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:pow() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcPowMod
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @return string
	 */
	public function bcPowMod( $lhs, $rhs ) {
		try {
			return [ \bcpowmod( $lhs, $rhs ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:powmod() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcSqrt
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @return string
	 */
	public function bcSqrt( $num ) {
		try {
			return [ \bcsqrt( $num ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:sqrt() failed (" . $ex->getMessage() . ")" );
		}
	}
}