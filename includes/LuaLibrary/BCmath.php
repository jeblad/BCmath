<?php
//declare( strict_types = 1 );
class Scribunto_LuaBCmathLibrary extends Scribunto_LuaLibraryBase {
	public function register() {
		$lib = [
			'bcadd' => [ $this, 'bcAdd' ]
		];
		// Get the correct default language from the parser
		if ( $this->getParser() ) {
			$lang = $this->getParser()->getTargetLanguage();
		} else {
			global $wgContLang;
			$lang = $wgContLang;
		}
		return $this->getEngine()->registerInterface( 'mw.bcmath.lua', $lib, [
			'lang' => $lang->getCode(),
		] );
	}

	/**
	 * Handler for bcAdd
	 * @internal
	 * @param string $lhs
	 * @param string $rhs
	 * @return string
	 */
	public function bcAdd( $lhs, $rhs ) {
		try {
			return bcadd( $lhs, $rhs );
		} catch ( MWException $ex ) {
			throw new Scribunto_LuaError( "bcmath:add() failed (" . $ex->getMessage() . ")" );
		}
	}
}