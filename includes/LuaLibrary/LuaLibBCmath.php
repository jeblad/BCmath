<?php

declare( strict_types = 1 );

namespace BCmath;

use Scribunto_LuaLibraryBase;
use \Exception;

/**
 * Registers our lua modules to Scribunto
 *
 * @ingroup Extensions
 */
class LuaLibBCmath extends Scribunto_LuaLibraryBase {
	public function register(): array {
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
		$langCode = 'en';
		$parser = $this->getParser();
		if ( $parser ) {
			$language = $parser->getTargetLanguage();
			if ( is_a($language, 'Language' ) ) {
				$langCode = $language->getCode();
			}
		}
		return $this->getEngine()->registerInterface( __DIR__ . '/lua/non-pure/BCmath.lua', $lib, [
			'lang' => $langCode,
		] );
	}

	/**
	 * Sanitize strings
	 * This can be turned off by setting $wgBCmathExtFiltering to false.
	 * @internal
	 * @param string $val
	 * @return string
	 */
	private static function sanitize( string $str ): string {
		global $wgBCmathExtFiltering;
		if ( $wgBCmathExtFiltering === false ) {
			return $str;
		}
		if ( preg_match( '/^[-+]?[0-9]*(?:\.[0-9]*)?$/s', $str, $matches) === 1 ) {
			return $matches[0]; // uses the untaint-trick from perl
		}
		throw new Exception('Sanitizion failed.');
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
			return [ \bcadd(
				self::sanitize( $lhs ),
				self::sanitize( $rhs ),
				is_null( $scale ) ? bcscale() : $scale
			) ];
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
			return [ \bcsub(
				self::sanitize( $lhs ),
				self::sanitize( $rhs ),
				is_null( $scale ) ? bcscale() : $scale
			) ];
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
			return [ \bcmul(
				self::sanitize( $lhs ),
				self::sanitize( $rhs ),
				is_null( $scale ) ? bcscale() : $scale
			) ];
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
			return [ \bcdiv(
				self::sanitize( $dividend ),
				self::sanitize( $divisor ),
				is_null( $scale ) ? bcscale() : $scale
			) ];
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
			return [ \bcmod(
				self::sanitize( $dividend ),
				self::sanitize( $divisor ),
				is_null( $scale ) ? bcscale() : $scale
			) ];
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
			return [ \bcpow(
				self::sanitize( $base ),
				self::sanitize( $exponent ),
				is_null( $scale ) ? bcscale() : $scale
			) ];
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
			return [ \bcpowmod(
				self::sanitize( $base ),
				self::sanitize( $exponent ),
				$modulus, is_null( $scale ) ? bcscale() : $scale
			) ];
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
			return [ \bcsqrt(
				self::sanitize( $operand ),
				is_null( $scale ) ? bcscale() : $scale
			) ];
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
			return [ \bccomp(
				self::sanitize( $lhs ),
				self::sanitize( $rhs ),
				is_null( $scale ) ? bcscale() : $scale
			) ];
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( 'bcmath:comp() failed (' . $ex->getMessage() . ')' );
		}
	}
}
