
project = 'BCmath'
title = 'BCmath documentation'
description = 'Assertion framework for Lua embedded within Mediawiki.'
full_description = [[The [BCmath extension](https://mediawiki.org/wiki/Extension:BCmath) is a
project to make [arbitrary-precision arithmetic](https://en.wikipedia.org/wiki/Arbitrary-precision_arithmetic)
avaiable to [Lua-scripts](https://en.wikipedia.org/wiki/Lua_programming_language) for the
[Scribunto extension](https://mediawiki.org/wiki/Extension:Scribunto), which is used by
[Wikipedia](https://en.wikipedia.org/wiki/Wikipedia) and other sites. Within Wikipedia Lua is used
to implement advanced templates with [Lua modules](https://en.wikipedia.org/wiki/Help:Lua), and the
same solution is used on a lot of other websites and projects.]]
use_markdown_titles = true
format = 'markdown'
dir = 'docs'
--output = 'mw.bcmath'
--all = true

readme = {
	-- 'topics/introduction.md',
	-- 'topics/vagrant.md',
	-- 'topics/databases.md',
	-- 'topics/hello-world.md',
	-- 'topics/translatewiki.md',
	-- 'topics/vscode.md'
}

examples = {
	'examples'
}

custom_display_name_handler = function(item, default_handler)
	-- show a label beside functions tagged with @delayed.
	if item.type == 'lfunction' or item.type == 'function' then
		return item.name .. ' ()'
	end
	return default_handler(item)
end