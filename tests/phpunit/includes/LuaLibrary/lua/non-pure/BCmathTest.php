<?php

declare( strict_types = 1 );

namespace BCmath\Test;

use Scribunto_LuaEngineTestBase;

/**
 * @group BCmath
 *
 * @license GPL-2.0-or-later
 *
 * @author John Erling Blad < jeblad@gmail.com >
 */
class BCmathTest extends Scribunto_LuaEngineTestBase {
	protected static $moduleName = 'BCmathTest';
	/**
	 * @slowThreshold 1000
	 * @see Scribunto_LuaEngineTestBase::getTestModules()
	 */
	protected function getTestModules(): array {
		return parent::getTestModules() + [
			'BCmathTest' => __DIR__ . '/BCmathTest.lua'
		];
	}
}