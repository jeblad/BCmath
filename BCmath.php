<?php
if ( function_exists( 'wfLoadExtension' ) ) {
	wfLoadExtension( 'BCmath', __DIR__ . '/extension.json' );
	// Keep i18n globals so mergeMessageFileList.php doesn't break
	$wgMessagesDirs['BCmath'] = __DIR__ . '/i18n';
	wfWarn(
		'Deprecated PHP entry point used for BCmath extension. Please use wfLoadExtension ' .
		'instead, see https://www.mediawiki.org/wiki/Extension_registration for more details.'
	);
	return true;
} else {
	die( 'This version of the BCmath extension requires MediaWiki 1.25+' );
}
