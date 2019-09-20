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
		global $wgContLang;
		$lang = $wgContLang;
		$lib = [
			'bcadd'    => [ $this, 'bcAdd' ],
			'bcsub'    => [ $this, 'bcSub' ],
			'bcmul'    => [ $this, 'bcMul' ],
			'bcdiv'    => [ $this, 'bcDiv' ],
			'bcmod'    => [ $this, 'bcMod' ],
			'bcpow'    => [ $this, 'bcPow' ],
			'bcpowmod' => [ $this, 'bcPowMod' ],
			'bcsqrt'   => [ $this, 'bcSqrt' ],
			'bccomp'   => [ $this, 'bcComp' ]
		];
		// Get the correct default language from the parser
		if ( $this->getParser() ) {
			$lang = $this->getParser()->getTargetLanguage();
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
	 * @param null|int $scale
	 * @return string
	 */
	public function bcAdd( $lhs, $rhs, $scale=null ) {
		try {
			return [ \bcadd( $lhs, $rhs, is_null($scale) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:add() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcSub
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @param null|int $scale
	 * @return string
	 */
	public function bcSub( $lhs, $rhs, $scale=null ) {
		try {
			return [ \bcsub( $lhs, $rhs, is_null($scale) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:sub() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcMul
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @param null|int $scale
	 * @return string
	 */
	public function bcMul( $lhs, $rhs, $scale=null ) {
		try {
			return [ \bcmul( $lhs, $rhs, is_null($scale) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:mul() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcDiv
	 * @internal
	 * @param string $dividend
	 * @param string $divisor
	 * @param null|int $scale
	 * @return string
	 */
	public function bcDiv( $dividend, $divisor, $scale=null ) {
		try {
			return [ \bcdiv( $dividend, $divisor, is_null($scale) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:div() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcMod
	 * @internal
	 * @param string $dividend
	 * @param string $divisor
	 * @param null|int $scale
	 * @return string
	 */
	public function bcMod( $dividend, $divisor, $scale=null ) {
		try {
			return [ \bcmod( $dividend, $divisor, is_null($scale) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:mod() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcPow
	 * @internal
	 * @param string $base
	 * @param string $exponent
	 * @param null|int $scale
	 * @return string
	 */
	public function bcPow( $base, $exponent, $scale=null ) {
		try {
			return [ \bcpow( $base, $exponent, is_null($scale) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:pow() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcPowMod
	 * @internal
	 * @param string $base
	 * @param string $exponent
	 * @param string $modulus
	 * @param null|int $scale
	 * @return string
	 */
	public function bcPowMod( $base, $exponent, $modulus, $scale=null ) {
		try {
			return [ \bcpowmod( $base, $exponent, $modulus, is_null($scale) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:powmod() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcSqrt
	 * @internal
	 * @param string $operand
	 * @param null|int $scale
	 * @return string
	 */
	public function bcSqrt( $operand, $scale=null ) {
		try {
			return [ \bcsqrt( $operand, is_null($scale) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:sqrt() failed (" . $ex->getMessage() . ")" );
		}
	}

	/**
	 * Handler for bcComp
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @param null|int $scale
	 * @return string
	 */
	public function bcComp( $lhs, $rhs, $scale=null ) {
		try {
			return [ \bccomp( $lhs, $rhs, is_null($scale) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:comp() failed (" . $ex->getMessage() . ")" );
		}
	}
}