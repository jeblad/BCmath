# BCmath

![stability-experimental](https://img.shields.io/badge/stability-experimental-orange.svg?style=for-the-badge)
![GitHub issues](https://img.shields.io/github/issues-raw/jeblad/BCmath?style=for-the-badge)

This [extension for Mediawiki](https://www.mediawiki.org/wiki/Extension:Expect) adds [arbitrary-precision arithmetic](https://en.wikipedia.org/wiki/Arbitrary-precision_arithmetic) to Lua modules provided by the [Scribunto extension](https://www.mediawiki.org/wiki/Extension:Scribunto). The modules call bcmath library for PHP through a minimal interface layer.

Help is available at [BCmath documentation](https://jeblad.github.io/BCmath/), with an [introduction](https://jeblad.github.io/BCmath/manual/introduction.md.html), references, and examples.

## Usage

BCmath depends on modules from the Scribunto extension.

1. Download from [Github](https://github.com/jeblad/BCmath) [zip](https://github.com/jeblad/BCmath/archive/master.zip) and place the file(s) in a directory called BCmath in your extensions/ folder.
2. Add the following code at the bottom of your LocalSettings.php:

	```lua
	wfLoadExtension( 'BCmath' );
	```

3. Done – Navigate to Special:Version on your wiki to verify that the extension is successfully installed.

## Development

Expect uses [Mediawiki-Vagrant](https://www.mediawiki.org/wiki/MediaWiki-Vagrant), and a complete setup can be made quite easily.

1. Make sure you have Vagrant, etc, prepare a development directory, and move to that directory.
2. Clone Mediawiki

	```bash
	git clone --recursive https://gerrit.wikimedia.org/r/mediawiki/vagrant .
	```

3. Run setup.

	```bash
	./setup.sh
	```

4. Enable the role for Scribunto. This pulls in the role for Scribunto, which then pulls in additional roles.

	```bash
	vagrant roles enable scribunto
	```

5. Start the instance.

	```bash
	vagrant up
	```

6. Download from [Github](https://github.com/jeblad/BCmath) ([zip](https://github.com/jeblad/BCmath/archive/master.zip)) and place the file(s) in a directory called BCmath in your extensions/ folder.

7. Add the following code at the bottom of your LocalSettings.php:

	```lua
	wfLoadExtension( 'BCmath' );
	```

7. Done.
