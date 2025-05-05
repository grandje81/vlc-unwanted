--[[
MIT License

Copyright (c) 2025 Devilops Software

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

function descriptor()
	return {
		title = "Unwanted",
		version = "1.0",
		license = "MIT",
		shortdesc = "Unwanted",
		description = "Removes unwanted files",
		author = "devilops",
		capabilities = {"playing-listener", "input-listener"}
	}
end


-- holds vlc-rating extension configuration variables
-- set default configuration
local config = {
	max_rating = 5,
	default_rating = 0,
	write_metadata = true,
	write_datafile = true,
	show_locked = false,
	show_reset_ratings = false,
	show_settings_default_rating = false
}

local playlist = {}          -- holds all music items form the current playlist
local store = {}             -- holds all music items from the database
local dialog                 -- main GUI interface
local prefix = "[unwanted] "  -- prefix to log messages
local data_file = "C://VideoTittaren"         -- path to data file

function activate()
	vlc.msg.info(prefix .. "Hello!")

	math.randomseed(os.time())

	data_file = vlc.config.userdatadir() .. "/unwanted.csv"
	config_file = vlc.config.configdir() .. "/unwanted.cfg"
	vlc.msg.info(prefix .. "using data file " .. data_file)
	vlc.msg.info(prefix .. "using config file " .. config_file)

	load_config_file()
	load_data_file()
	scan_playlist()
	update_playlist()
	show_gui()
end

function deactivate()
	vlc.msg.info(prefix ..  "Bye!")
	if dialog ~= nil then
		dialog:delete()
	end
end

function show_gui()
	dialog = vlc.dialog("Unwanted")

	if config.show_locked then
		label_path = dialog:add_label("Press 'Play'!", 1, 1, 9)
		checkbox_locked = dialog:add_check_box("Rating Locked", false, 10, 1)
	else
		label_path = dialog:add_label("Press 'Play'!", 1, 1, 11)
	end

	local onclick_rateN = function(rating)
		return function()
			if config.show_locked then
				checkbox_locked:set_checked(true)
			end
			rate_current_item(rating)
		end
	end

	local indicator = 0
	local row = 3
	local col = 1
	label_indicator = {}

	for i=1,5 do
		label_indicator[indicator] = dialog:add_label("<b>&nbsp;&nbsp;</b>", col, row)
		indicator = indicator + 1
		col = col + 1
		dialog:add_button(i, onclick_rateN(i), col, row)
		col = col + 1
	end

	label_indicator[indicator] = dialog:add_label("<b>&nbsp;&nbsp;</b>", col, row)
	indicator = indicator + 1
	row = row + 1
	col = 1

	vlc.msg.info("added " .. indicator .. " indicators")
	dialog:add_label("<hr>", 1, row, 11, 1)
	row = row + 1

	dialog:add_button("Refresh Playlist", onclick_refresh_playlist, 2, row)

	-- if config.show_reset_ratings then
	-- 	dialog:add_button("Reset Unlocked Ratings", onclick_reset_unlocked_ratings, 4, row)
	-- end

	-- dialog:add_button("Settings", onclick_settings, 8, row)
	--  update_min_max_dropdowns()
	update_gui()
	dialog:show()
end

function update_min_max_dropdowns()
	local rating_values = {[0] = "Unrated"}
	for i=1,config.max_rating do
		rating_values[i] = i
	end

	if config.shuffle_max_rating > config.max_rating then
		config.shuffle_max_rating = config.max_rating
	end

	dropdown_min_rating:clear()
	-- add selected item as first item in dropdown
	dropdown_min_rating:add_value(rating_values[config.shuffle_min_rating], config.shuffle_min_rating)
	-- add rest of items
	for i=0,#rating_values do
		if i ~= config.shuffle_min_rating then
			dropdown_min_rating:add_value(rating_values[i], i)
		end
	end

	dropdown_max_rating:clear()
	-- add selected item as first item in dropdown
	dropdown_max_rating:add_value(rating_values[config.shuffle_max_rating], config.shuffle_max_rating)
	-- add rest of items
	for i=#rating_values,0,-1 do
		if i ~= config.shuffle_max_rating then
			dropdown_max_rating:add_value(rating_values[i], i)
		end
	end
end

function reset_rating_indicators()
	if config.max_rating <= 10 then
		for i = 0,5 do
			label_indicator[i]:set_text("<b>&nbsp;&nbsp;</b>")
		end
	end

	if config.max_rating == 10 then
		for i = 6,11 do
			label_indicator[i]:set_text("<b>&nbsp;&nbsp;</b>")
		end
	end
end

function update_rating_indicators(rating)
	if rating <= 5 then
		label_indicator[rating - 1]:set_text("<b><font color='green'>&lt;&lt;</font></b>")
		label_indicator[rating]:set_text("<b><font color='green'>&gt;&gt;</font></b>")
	else
		label_indicator[rating]:set_text("<b><font color='green'>&lt;&lt;</font></b>")
		label_indicator[rating + 1]:set_text("<b><font color='green'>&gt;&gt;</font></b>")
	end
end

function update_gui()
	local item = vlc.input.item()
	if item == nil then
		label_path:set_text("Press 'Play'!")
		return
	end

	local path = basename(vlc.strings.decode_uri(item:uri()))
	label_path:set_text(path)

	local rating = store[path].rating
	local meta_rating = read_meta()

	if meta_rating > 0 then
		vlc.msg.info(prefix .. path .. ": overriding cached rating " .. rating .. " with metadata rating " .. meta_rating)
		rating = meta_rating
		store[path].rating = meta_rating
		save_data_file()
	else
		vlc.msg.info(prefix .. path .. ": using cached rating " .. rating)
	end

	reset_rating_indicators()
	if rating > 0 then
		update_rating_indicators(rating)
	end

	if config.show_locked then
		checkbox_locked:set_checked(store[path].locked)
	end
end

function onclick_settings()
	dialog:delete()
	dialog = vlc.dialog("Ratings Settings")
	local row = 1
	dialog:add_label("Maximum rating", 3, row)
	settings_dropdown_maxrating = dialog:add_dropdown(4, row)
	row = row + 1

	if config.show_settings_default_rating then
		dialog:add_label("Default rating", 3, row)
		settings_dropdown_defrating = dialog:add_dropdown(4, row)
		row = row + 1
	end

	settings_checkbox_write_meta = dialog:add_check_box("Use metadata", false, 3, row)
	settings_checkbox_write_data = dialog:add_check_box("Use data file", false, 4, row)
	row = row + 1
	dialog:add_label(string.rep("&nbsp;", 80), 1, row, 6)
	row = row + 1
	dialog:add_button("Cancel", onclick_settings_cancel, 3, row)
	dialog:add_button("Save", onclick_settings_save, 4, row)
	update_settings_dialog()
	dialog:show()
end

function update_settings_dialog()
	settings_dropdown_maxrating:clear()
	if config.max_rating == 5 then
		settings_dropdown_maxrating:add_value(5, 5)
		settings_dropdown_maxrating:add_value(10, 10)
	else
		settings_dropdown_maxrating:add_value(10, 10)
		settings_dropdown_maxrating:add_value(5, 5)
	end

	local rating_values = {[0] = "Unrated"}
	for i=1,config.max_rating do
		rating_values[i] = i
	end

	if config.show_settings_default_rating then
		settings_dropdown_defrating:clear()
		settings_dropdown_defrating:add_value(rating_values[config.default_rating], config.default_rating)
		for i=0,#rating_values do
			if i ~= config.default_rating then
				settings_dropdown_defrating:add_value(rating_values[i], i)
			end
		end
	end

	settings_checkbox_write_meta:set_checked(config.write_metadata)
	settings_checkbox_write_data:set_checked(config.write_datafile)
end

function onclick_settings_save()
	config.max_rating = settings_dropdown_maxrating:get_value()

	if config.show_settings_default_rating then
		config.default_rating = settings_dropdown_defrating:get_value()
	end

	config.write_metadata = settings_checkbox_write_meta:get_checked()
	config.write_datafile = settings_checkbox_write_data:get_checked()
	save_config_file()
	dialog:delete()
	dialog = nil
	show_gui()
end

function onclick_settings_cancel()
	dialog:delete()
	dialog = nil
	show_gui()
end

function onclick_refresh_playlist()
	scan_playlist()
	update_playlist()
end

function onclick_reset_unlocked_ratings()
	for fullpath,item in pairs(playlist) do
		local path = basename(fullpath)
		if store[path].locked == false then
			store[path].rating = config.default_rating
		end
	end
	save_data_file()
	update_playlist()
end

function close()
	vlc.deactivate()
end

function rate_current_item(rating)
	local path = label_path:get_text()
	local locked
	if config.show_locked then
		locked = checkbox_locked:get_checked()
	else
		locked = true
	end

	reset_rating_indicators()
	if store[path].rating == rating then
		vlc.msg.info(prefix .. "canceling rating")
		-- clicked same rating button, set to unrated
		store[path].rating = 0
	else
		vlc.msg.info(prefix .. "clicked rating " .. rating)
		-- set new rating
		update_rating_indicators(rating)
		store[path].rating = rating
		store[path].locked = locked
	end

	local fullpath = store[path].fullpath
    local myId = vlc.playlist.current();
	playlist[fullpath] = store[path].rating
	save_data_file()
	update_meta(rating)
    vlc.playlist.next()
	sleep(1)
    vlc.playlist.delete(myId)
    if rating == 1 then
		local special = fullpath:gsub("/", "\\")
		-- local trimmed = special:gsub ('^file:\\\\[^\\]+', '')
		local str = special:sub(9)
		-- local myString = basename(fullpath)
		vlc.msg.info(prefix .. "Trimmed path?: " .. str)
		-- vlc.msg.info(prefix .. "Trimmed path_2?: " .. myString)
		retval, err = windows_delete(str, 3, 1)
	end 
	if retval == nil then
		vlc.msg.err(prefix .. "unable to delete file: " .. err)
	else
		vlc.msg.info(prefix .. "deleted file: " .. fullpath)
	end
end

function file_exists(file)
	retval, err = os.execute("if exist \"" .. file .. "\" (exit 0) else (exit 1)")
	return type(retval) == "number" and retval == 0
end

function sleep(seconds)
	local t_0 = os.clock()
	while os.clock() - t_0 <= seconds do end
end

function windows_delete(file, trys, pause)
	if not file_exists(file) then
		return nil, "File does not exist"
	end
	for i = trys, 1, -1
	do
		os.execute("del /q \"" .. file .. "\"")
		if not file_exists(file) then
			return true
		end
		sleep(pause)
	end
	return nil, "Unable to delete file"
end


function remove_from_playlist()
	local id = vlc.playlist.current()
	vlc.playlist.next()
	sleep(1) -- wait for current item change
	vlc.playlist.delete(id)
end



function read_meta()
	if not config.write_metadata then
		return 0
	end

	if not vlc.item then
		vlc.msg.dbg(prefix .. "No item playing; skipping metadata read")
		return 0
	end

	local metas = vlc.item:metas()
	local rating = metas["rating"]
	if not rating then
		rating = 0
	end
	return rating
end

function update_meta(rating)
	if config.write_metadata then
		local item = vlc.input.item()
		if item == nil then
			vlc.msg.info(prefix .. "cannot set rating metadata when nothing is playing")
			return
		end
		vlc.msg.info(prefix .. "setting metadata 'Rating' to " .. rating)
		item:set_meta("rating", rating)
	end
end

function basename(path)
	i = path:find("/[^/]*$")
	if i == nil then
		return path
	else
		return path:sub(i + 1)
	end
end

-- scans current playlist
function scan_playlist()
	vlc.msg.info(prefix .. "scanning playlist")
	playlist = {}
	local current_playlist = vlc.playlist.get("playlist").children
	for i, entry in ipairs(current_playlist) do
		-- decode path and remove escaping
		local path = entry.item:uri()
		path = vlc.strings.decode_uri(path)
		local fullpath = path
		path = basename(path)

		-- check if we have the song in the database
		-- and copy the rating else create a new entry
		if store[path] then
			playlist[fullpath] = store[path].rating
			store[path].fullpath = fullpath
		else
			playlist[fullpath] = config.default_rating
			store[path] = {rating=config.default_rating, locked=false, fullpath=fullpath}
			changed = true
		end
	end

	-- save changes
	if changed then
		save_data_file()
	end
end

-- updates ratings column for all items in playlist
function update_playlist()
	vlc.msg.info(prefix .. "updating playlist")
	local new_playlist = {}
	local current_playlist = vlc.playlist.get("playlist").children
	for i, entry in ipairs(current_playlist) do
		-- decode path and remove escaping
		local path = entry.item:uri()
		path = vlc.strings.decode_uri(path)
		local fullpath = path
		path = basename(path)

		if store[path] then
			local newentry = {["path"] = fullpath, ["rating"] = store[path].rating}
			table.insert(new_playlist, newentry)
		end
	end

	vlc.playlist.clear()
	vlc.playlist.enqueue(new_playlist)
end

-- -- IO operations -- --

function toboolean(value)
	value = tonumber(value)
	if value == nil or value == 0 then
		return false
	else
		return true
	end
end

function load_data_file()
	if not config.write_datafile then
		return
	end
	-- open file
	vlc.msg.info(prefix .. "Loading data from " .. data_file)
	local file,err = io.open(data_file, "r")
	store = {}
	if err then
		vlc.msg.warn(prefix .. "data file does not exist, creating...")
		file,err = io.open(data_file, "w")
		if err then
			vlc.msg.err(prefix .. "unable to open data file: " .. err)
			vlc.deactivate()
			return
		end
	else
		-- file successfully opened
		for line in file:lines() do
			-- csv layout is tab-separated: path, rating, locked
			local fields = {}
			for field in line:gmatch("[^\t]+") do
                table.insert(fields, field)
			end

			local path = fields[1]
			local rating = tonumber(fields[2])
			local locked = toboolean(fields[3])

			store[path] = {rating=rating, locked=locked}
		end
	end
	io.close(file)
end

function save_data_file()
	if not config.write_datafile then
		return
	end
	vlc.msg.info(prefix .. "Saving data to " .. data_file)
	local bool_to_number = { [true] = 1, [false] = 0 }
	local file,err = io.open(data_file, "w")
    if err then
		vlc.msg.err(prefix .. "unable to open data file.. exiting")
		vlc.deactivate()
		return
	else
		for path,item in pairs(store) do
			if item.rating > 0 then
				file:write(path .. "\t")
				file:write(item.rating .. "\t")
				file:write(bool_to_number[item.locked] .. "\n")
			end
		end
	end
	io.close(file)
end

function load_config_file()
	local saved_config
	-- open file
	vlc.msg.info(prefix .. "Loading config from " .. config_file)
	local file,err = io.open(config_file, "r")
	if err then
		vlc.msg.warn(prefix .. "config file does not exist, creating...")
		file,err = io.open(data_file, "w")
		if err then
			vlc.msg.err(prefix .. "unable to open config file: " .. err)
			vlc.deactivate()
			return
		end
	else
		-- file successfully opened
		local contents = file:read("*all")
		saved_config = parse_xml(contents)
	end
	io.close(file)

	-- override default config with saved config values
	if saved_config ~= nil then
		for key,value in pairs(saved_config) do
			if value == "true" then
				config[key] = true
			elseif value == "false" then
				config[key] = false
			elseif value:match("^%d+$") then
				config[key] = tonumber(value)
			else
				config[key] = value
			end
		end
	end
end

function save_config_file()
	vlc.msg.info(prefix .. "Saving config to " .. config_file)
	local file,err = io.open(config_file, "w")
	if err then
		vlc.msg.err(prefix .. "unable to open config file.. exiting")
		vlc.deactivate()
		return
	else
		local xml = dump_xml(config)
		file:write(xml,"\n")
	end
	io.close(file)
end

-- -- Listeners and helpers -- --

function update_current_playing(fullpath)
	local path = basename(fullpath)
	vlc.msg.info(prefix .. "updating playing: " .. path)

	-- decrement rating, if not locked, to prevent viewed items
	-- from repeating until all higher rated items have been viewed
	if store[path].locked == false then
		if store[path].rating > 1 then
			store[path].rating = store[path].rating - 1
			playlist[fullpath] = store[path].rating
			save_data_file()
		end
	end

	update_gui()
end

function input_changed()
	vlc.msg.info(prefix .. "input_changed!")
	local item = vlc.input.item()
	if item == nil then
		-- user clicked 'Stop'
		return
	end
	local fullpath = vlc.strings.decode_uri(item:uri())
	update_current_playing(fullpath)
end

function playing_changed()
	vlc.msg.info(prefix .. "playing_changed! status: " .. vlc.playlist.status())
end

function meta_changed() end

-- -- XML utilities -- --

function parse_xml(data)
    local tree = {}
    local stack = {}
    local tmp = {}
    local level = 0
    local op, tag, p, empty, val
    table.insert(stack, tree)
    local resolve_xml =  vlc.strings.resolve_xml_special_chars

    for op, tag, p, empty, val in string.gmatch(
            data,
            "[%s\r\n\t]*<(%/?)([%w:_]+)(.-)(%/?)>"..
            "[%s\r\n\t]*([^<]*)[%s\r\n\t]*"
    ) do
        if op=="/" then
            if level>0 then
                level = level - 1
                table.remove(stack)
            end
        else
            level = level + 1
            if val == "" then
                if type(stack[level][tag]) == "nil" then
                    stack[level][tag] = {}
                    table.insert(stack, stack[level][tag])
                else
                    if type(stack[level][tag][1]) == "nil" then
                        tmp = nil
                        tmp = stack[level][tag]
                        stack[level][tag] = nil
                        stack[level][tag] = {}
                        table.insert(stack[level][tag], tmp)
                    end
                    tmp = nil
                    tmp = {}
                    table.insert(stack[level][tag], tmp)
                    table.insert(stack, tmp)
                end
            else
                if type(stack[level][tag]) == "nil" then
                    stack[level][tag] = {}
                end
                stack[level][tag] = resolve_xml(val)
                table.insert(stack,  {})
            end
            if empty ~= "" then
                stack[level][tag] = ""
                level = level - 1
                table.remove(stack)
            end
        end
    end
    return tree
end

function dump_xml(data)
    local level = 0
    local stack = {}
    local dump = ""
    local convert_xml = vlc.strings.convert_xml_special_chars

    local function parse(data, stack)
	local data_index = {}
	local k
	local v
	local i
	local tb

	for k,v in pairs(data) do
        table.insert(data_index, {k, v})
        table.sort(data_index, function(a, b)
		return a[1] < b[1]
        end)
	end

	for i,tb in pairs(data_index) do
        k = tb[1]
        v = tb[2]
        if type(k)=="string" then
            dump = dump.."\n"..string.rep(" ", level).."<"..k..">"
            table.insert(stack, k)
            level = level + 1
        elseif type(k)=="number" and k ~= 1 then
            dump = dump.."\n"..string.rep(" ", level-1).."<"..stack[level]..">"
        end

        if type(v)=="table" then
            parse(v, stack)
        elseif type(v)=="string" then
            dump = dump..(convert_xml(v) or v)
        elseif type(v)=="number" then
            dump = dump..v
        else
            dump = dump..tostring(v)
        end

        if type(k)=="string" then
            if type(v)=="table" then
            dump = dump.."\n"..string.rep(" ",level-1).."</"..k..">"
            else
            dump = dump.."</"..k..">"
            end
            table.remove(stack)
            level = level - 1

        elseif type(k)=="number" and k ~= #data then
            if type(v)=="table" then
            dump = dump.."\n"..string.rep(" ",level-1).."</"..stack[level]..">"
            else
            dump = dump.."</"..stack[level]..">"
            end
        end
        end
    end
    parse(data, stack)
    return dump
end

-- -- Queue implementation -- --
-- Idea from https://www.lua.org/pil/11.4.html

Queue = {}
function Queue.new ()
	return {first = 0, last = -1}
end

function Queue.enqueue (q, value)
	q.last = q.last + 1
	q[q.last] = value
end

function Queue.dequeue (q)
	if q.first > q.last then return nil end
	local value = q[q.first]
	q[q.first] = nil
	q.first = q.first + 1
	return value
end

function Queue.size(q)
	return q.last - q.first + 1
end

-- implements the fisher yates shuffle on the queue
-- based on the wikipedia page
function Queue.shuffle(q)
	local first = q.first
	local last = q.last
	if first > last then return end
	if first == last then return end
	for i=first,last-1 do
		local r = math.random(i,last-1)
		local temporary = q[i]
		q[i] = q[r]
		q[r] = temporary
	end
end
