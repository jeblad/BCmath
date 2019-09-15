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
	/**
	 * Register the library
	 *
	 * @return array
	 */
	public function register() {
		global $wgBCmathSetup;
		return $this->getEngine()->registerInterface(
			__DIR__ . '/lua/non-pure/BCmath.lua',
			[ 'addResourceLoaderModules' => [ $this, 'addResourceLoaderModules' ] ],
			[
				'setup' => $wgBCmathSetup ]
		);
	}
}