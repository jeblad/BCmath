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
	public function register(): array {
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
	 * @return array
	 */
	public function bcAdd( string $lhs, string $rhs, ?int $scale = null ): array {
		try {
			return [ \bcadd( $lhs, $rhs, is_null( $scale ) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( 'bcmath:add() failed (' . $ex->getMessage() . ')' );
		}
	}

	/**
	 * Handler for bcSub
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @param null|int $scale
	 * @return array
	 */
	public function bcSub( string $lhs, string $rhs, ?int $scale = null ): array {
		try {
			return [ \bcsub( $lhs, $rhs, is_null( $scale ) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( 'bcmath:sub() failed (' . $ex->getMessage() . ')' );
		}
	}

	/**
	 * Handler for bcMul
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @param null|int $scale
	 * @return array
	 */
	public function bcMul( string $lhs, string $rhs, ?int $scale = null ): array {
		try {
			return [ \bcmul( $lhs, $rhs, is_null( $scale ) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( 'bcmath:mul() failed (' . $ex->getMessage() . ')' );
		}
	}

	/**
	 * Handler for bcDiv
	 * @internal
	 * @param string $dividend
	 * @param string $divisor
	 * @param null|int $scale
	 * @return array
	 */
	public function bcDiv( string $dividend, string $divisor, ?int $scale = null ): array {
		try {
			return [ \bcdiv( $dividend, $divisor, is_null( $scale ) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( 'bcmath:div() failed (' . $ex->getMessage() . ')' );
		}
	}

	/**
	 * Handler for bcMod
	 * @internal
	 * @param string $dividend
	 * @param string $divisor
	 * @param null|int $scale
	 * @return array
	 */
	public function bcMod( string $dividend, string $divisor, ?int $scale = null ): array {
		try {
			return [ \bcmod( $dividend, $divisor, is_null( $scale ) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( 'bcmath:mod() failed (' . $ex->getMessage() . ')' );
		}
	}

	/**
	 * Handler for bcPow
	 * @internal
	 * @param string $base
	 * @param string $exponent
	 * @param null|int $scale
	 * @return array
	 */
	public function bcPow( string $base, string $exponent, ?int $scale = null ): array {
		try {
			return [ \bcpow( $base, $exponent, is_null( $scale ) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( 'bcmath:pow() failed (' . $ex->getMessage() . ')' );
		}
	}

	/**
	 * Handler for bcPowMod
	 * @internal
	 * @param string $base
	 * @param string $exponent
	 * @param string $modulus
	 * @param null|int $scale
	 * @return array
	 */
	public function bcPowMod( string $base, string $exponent, string $modulus, ?int $scale = null ): array {
		try {
			return [ \bcpowmod( $base, $exponent, $modulus, is_null( $scale ) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( 'bcmath:powmod() failed (' . $ex->getMessage() . ')' );
		}
	}

	/**
	 * Handler for bcSqrt
	 * @internal
	 * @param string $operand
	 * @param null|int $scale
	 * @return array
	 */
	public function bcSqrt( string $operand, ?int $scale = null ): array {
		try {
			return [ \bcsqrt( $operand, is_null( $scale ) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( 'bcmath:sqrt() failed (' . $ex->getMessage() . ')' );
		}
	}

	/**
	 * Handler for bcComp
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @param null|int $scale
	 * @return array
	 */
	public function bcComp( string $lhs, string $rhs, ?int $scale = null ): array {
		try {
			return [ \bccomp( $lhs, $rhs, is_null( $scale ) ? bcscale() : $scale ) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( 'bcmath:comp() failed (' . $ex->getMessage() . ')' );
		}
	}
}
