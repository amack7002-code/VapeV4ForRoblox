local isfile = isfile or function(file)
	local suc, res = pcall(readfile, file)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local REPO = 'https://raw.githubusercontent.com/amack7002-code/VapeV4ForRoblox/'
local WATERMARK = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.'

local function readSafe(path)
	local suc, res = pcall(readfile, path)
	return suc and res or nil
end

local function getCommit()
	local c = readSafe('newvape/profiles/commit.txt')
	return c and #c > 0 and c or 'main'
end

-- Local file first, GitHub only if the file isn't on disk
local function downloadFile(path, func)
	if not isfile(path) then
		local rel = (path:gsub('^newvape/', ''))
		local res
		for _, ref in {getCommit(), 'main'} do
			local suc, body = pcall(game.HttpGet, game, REPO..ref..'/'..rel, true)
			if suc and body and body ~= '404: Not Found' and body ~= '' then
				res = body
				break
			end
		end
		if not res then
			error('Failed to load '..path..' (not on disk, GitHub fetch failed)')
		end
		if path:find('%.lua$') then
			res = WATERMARK..'\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

-- Only deletes GitHub-cached (watermarked) files; your own local files are never touched
local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find(WATERMARK, 1, true)) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local suc, page = pcall(game.HttpGet, game, 'https://github.com/amack7002-code/VapeV4ForRoblox')
	local commit
	if suc and type(page) == 'string' then
		local s = page:find('currentOid')
		commit = s and page:sub(s + 13, s + 52)
		if commit and #commit ~= 40 then commit = nil end
	end

	-- Offline / GitHub fetch failed: skip the update check, keep whatever is on disk
	if commit then
		if readSafe('newvape/profiles/commit.txt') ~= commit then
			wipeFolder('newvape')
			wipeFolder('newvape/games')
			wipeFolder('newvape/guis')
			wipeFolder('newvape/libraries')
		end
		writefile('newvape/profiles/commit.txt', commit)
	end
end

return assert(loadstring(downloadFile('newvape/main.lua'), 'main'))()