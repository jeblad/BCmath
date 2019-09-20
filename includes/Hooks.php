<?php

declare( strict_types = 1 );

namespace BCmath;

/**
 * Hook handlers for the BCmath extension
 *
 * @ingroup Extensions
 */
class Hooks {
	/**
	 * Setup for the extension
	 */
	public static function onExtensionSetup() {
		global $wgDebugComments;
		// turn on comments while in development
		$wgDebugComments = true;
	}
	/**
	 * External Lua library paths for Scribunto
	 *
	 * @param any $engine to be used for the call
	 * @param array &$extraLibraryPaths additional libs
	 * @return bool
	 */
	public static function onRegisterScribuntoExternalLibraryPaths(
		string $engine,
		array &$extraLibraryPaths
	): bool {
		if ( $engine !== 'lua' ) {
			return true;
		}
		// Path containing pure Lua libraries that don't need to interact with PHP
		// TODO: Probably not used for this extension
		$extraLibraryPaths[] = __DIR__ . '/LuaLibrary/lua/pure';
		return true;
	}

	/**
	 * Extra Lua libraries for Scribunto
	 *
	 * @param any $engine to be used for the call
	 * @param array &$extraLibraries additional libs
	 * @return bool
	 */
	public static function onRegisterScribuntoLibraries(
		string $engine,
		array &$extraLibraries
	): bool {
		if ( $engine !== 'lua' ) {
			return true;
		}
		$extraLibraries['bcmath'] = [
			'class' => '\BCmath\LuaLibBCmath',
			'deferLoad' => false
		];
		return true;
	}
}