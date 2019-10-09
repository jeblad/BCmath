
project = 'BCmath'
title = 'BCmath documentation'
description = 'Access to bignum calculus for Lua embedded within Mediawiki.'
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

kind_names={topic='Manual'}

readme = {
	'topics/introduction.md',
	-- 'topics/pitfalls.md',
	'topics/wikibase.md',
	'topics/databases.md',
	'topics/non-pure.md',
	'topics/vagrant.md',
	-- 'topics/hello-world.md',
	'topics/vscode.md',
	'topics/sources.md',
	'CONTRIBUTING.md',
	'CODE_OF_CONDUCT.md',
	'SECURITY.md',
	'TRANSLATING.md'
}

examples = {
	'examples'
}

custom_tags = {
	{ 'nick', title='Nicknames', hidden = false, format=nil },
}

custom_display_name_handler = function(item, default_handler)
	-- Strip arguments to functions
	if item.type == 'lfunction' or item.type == 'function' then
		return item.name .. ' ()'
	end
	return default_handler(item)
end