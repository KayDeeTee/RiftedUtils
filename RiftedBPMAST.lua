local riftedBpmAst = {}

local render = require "necro.render.Render"
local chat = require "necro.client.Chat"
local enum = require "system.utils.Enum"
local gfx = require "system.gfx.GFX"
local menu = require "necro.menu.Menu"
local customActions = require "necro.game.data.CustomActions"
local settings = require "necro.config.Settings"
local riftedTool = require "Rifted.RiftedTool"
local riftedCategory = require "Rifted.RiftedCategory"
local riftedSearchFilter = require "Rifted.RiftedSearchFilter"
local riftedBeatmap = require "Rifted.RiftedBeatmap"

local default = 100
local previousBpm = nil

local function solver( ast )

	local order = {"Negative", "Positive", "Exponent", "Multiply", "Add"}
	local order_idx = 1

	while #ast ~= 1 do
		for idx, token in ipairs(ast) do

			if token.type == "Negative" and order_idx <= #order and order[order_idx] == token.type then
				local b = tonumber(ast[idx+1].str) or 0
				ast[ idx ].type = "Number"
				ast[ idx ].str = tostring( b * -1 )
				table.remove( ast, idx+1 )
				goto continue
			end

			if token.type == "Positive" and order_idx <= #order and order[order_idx] == token.type then
				local b = tonumber(ast[idx+1].str) or 0
				ast[ idx ].type = "Number"
				ast[ idx ].str = tostring( b * 1 )
				table.remove( ast, idx+1 )
				goto continue
			end

			if token.type == "Exponent" and order_idx <= #order and order[order_idx] == token.type then
				if idx == 1 or idx == #ast then
					return previousBpm
				end
				local a = tonumber(ast[idx-1].str) or 0
				local b = tonumber(ast[idx+1].str) or 0
				ast[ idx ].type = "Number"
				ast[ idx ].str = tostring( a ^ b )
				table.remove( ast, idx+1 )
				table.remove( ast, idx-1 )
				goto continue
			end

			if token.type == "Multiply" and order_idx <= #order and order[order_idx] == token.type then
				if idx == 1 or idx == #ast then
					return previousBpm
				end
				local a = tonumber(ast[idx-1].str) or 0
				local b = tonumber(ast[idx+1].str) or 0
				ast[ idx ].type = "Number"
				if ast[ idx ].str == "*" then
					ast[ idx ].str = tostring( a * b )
				end
				if ast[ idx ].str == "/" then
					ast[ idx ].str = tostring( a / b )
				end
				if ast[ idx ].str == "%" then
					ast[ idx ].str = tostring( a % b )
				end
				table.remove( ast, idx+1 )
				table.remove( ast, idx-1 )
				goto continue
			end

			if token.type == "Add" and order_idx <= #order and order[order_idx] == token.type then
				if idx == 1 or idx == #ast then
					return previousBpm
				end
				local a = tonumber(ast[idx-1].str) or 0
				local b = tonumber(ast[idx+1].str) or 0
				ast[ idx ].type = "Number"
				if ast[ idx ].str == "+" then
					ast[ idx ].str = tostring( a + b )
				end
				if ast[ idx ].str == "-" then
					ast[ idx ].str = tostring( a - b )
				end
				table.remove( ast, idx+1 )
				table.remove( ast, idx-1 )
				goto continue
			end

		end
		order_idx = order_idx + 1
		::continue::
	end
	return tonumber( ast[1].str ) or 0
end
 

local function ast( str )
	if tonumber( str ) then
		return tonumber(str)
	end

	--TOKENISE

	local token = {}
	local tokens = {}

	token.type = nil
	token.str = ""
	token.decimals = 0

	local idx = 1
	local invalid = false

	for i = 1, #str do
		local c = str:sub(i,i)
		if c == " " then goto continue end --really no continue??

		if token.type == "Number" then
			if not c:find( "[^%d%.]" ) then
				token.str = token.str .. c
				if c == "." then
					token.decimals = token.decimals + 1
					if token.decimals > 1 then
						invalid = true
					end
				end

				goto continue
			end
			tokens[idx] = token
			idx = idx + 1
			token = {}
			token.type = nil
			token.str = ""
		end

		if token.type == "Indentifier" then
			if string.match( c, "%a") then
				token.str = token.str .. c
				goto continue
			end
			tokens[idx] = token
			idx = idx + 1
			token = {}
			token.type = nil
			token.str = ""
		end

		if token.type == nil then
			--check if valid number
			if not c:find( "[^%d%.]" ) then
				token.type = "Number"
				token.str = token.str .. c
				goto continue
			end
			if string.match( c, "%a") then
				token.type = "Indentifier"
				token.str = token.str .. c
				goto continue
			end
			if c == "+" then
				token.type = "AddOrPositive"
				token.str = token.str .. c
				goto insert_token
			end

			if c == "-" then
				token.type = "SubOrNegative"
				token.str = token.str .. c
				goto insert_token
			end

			if c == "*" then
				token.type = "Multiply"
				token.str = "*"
				goto insert_token
			end

			if c == "^" then
				token.type = "Exponent"
				token.str = token.str .. c
				goto insert_token
			end

			if c == "/" then
				token.type = "Multiply"
				token.str = "/"
				goto insert_token
			end

			if c == "%" then
				token.type = "Multiply"
				token.str = "%"
				goto insert_token
			end

			if c == "(" then
				token.type = "BlockBegin"
				token.str = token.str .. c
				goto insert_token
			end

			if c == ")" then
				token.type = "BlockEnd"
				token.str = token.str .. c
				goto insert_token
			end
		end

		invalid = true

		::insert_token:: --if I have terrible code flow I might as well have terrible code flow
		tokens[idx] = token
		idx = idx + 1
		token = {}
		token.type = nil
		token.str = ""
		token.decimals = 0
		::continue::
	end

	if token.type ~= nil then
		tokens[idx] = token
		idx = idx + 1
		token = {}
		token.type = nil
		token.str = ""
	end

	for idx, token in ipairs(tokens) do
		if token.type == "Indentifier" then
			local v = string.lower(token.str)
			if v == "bpm" then
				token.type = "Number"
				token.str = tostring( riftedBeatmap.getBPM() )
			elseif v == "prev" then
				token.type = "Number"
				token.str = tostring( previousBpm )
			else
				invalid = true
			end
		end
	end

	if invalid then
		return previousBpm
	end

	--Disambiguate unary operations
	for idx, token in ipairs(tokens) do
		if token.type == "AddOrPositive" then
			if idx == 1 then
				token.type = "Positive"
			elseif (tokens[idx-1].type == "Number" or tokens[idx-1].type == "Number") then
				token.type = "Add"
			else
				token.type = "Positive"
			end
		end
		if token.type == "SubOrNegative" then
			if idx == 1 then
				token.type = "Negative"
			elseif (tokens[idx-1].type == "Number" or tokens[idx-1].type == "Number") then
				token.type = "Add"
			else
				token.type = "Negative"
			end
		end
	end

	--Solve blocks
	local block_found = true
	while block_found do
		block_found = false
		local idx_start = -1
		local idx_end = -1
		for idx, token in ipairs(tokens) do
			if token.type == "BlockBegin" then
				if idx_end == -1 then
					idx_start = idx
				end
			end
			if token.type == "BlockEnd" then
				if idx_end == -1 then
					idx_end = idx
				end
			end 
		end

		if idx_end ~= -1 then
			local solver_tokens = {}
			for i=idx_start+1,idx_end-1 do
				solver_tokens[ i-idx_start ] = tokens[i]
			end
			local solution = solver( solver_tokens )
			tokens[ idx_start ].type = "Number"
			tokens[ idx_start].str = tostring( solution )
			for i=idx_start+1,idx_end do
				table.remove( tokens, idx_start+1 )
			end
			block_found = true
		end
	end
	return solver(tokens)
end

local function textEntryCallback(value)
	local brush = {}
	for i, category in ipairs(riftedCategory.getFilteredCategories(
		riftedSearchFilter.getFilterText(), riftedSearchFilter.getCategoryFilter()))
	do
		if category.brushes then
			for _, brushdata in ipairs(category.brushes) do
				if brushdata.name == "BPM change" then
					brush = brushdata.brush
				end
			end
		end
	end


	--local brush = riftedTool.getBrush() or {}

	local parameters = brush.attr and brush.attr.Rifted_object and brush.attr.Rifted_object.data
			and brush.attr.Rifted_object.data.parameters


	parameters.Bpm = ast(value) or previousBpm or default
	previousBpm = parameters.Bpm
	brush.hoverText = L.formatKey("%s BPM", "bpmCounter", parameters.Bpm)

	riftedTool.setBrush(brush)
end

customActions.registerHotkey {
    id = "BPM_ADV",
    category = "Rifted Utils",
    name = "BPM advanced",
    keyBinding = "lshift+b",
    callback = function ()
		menu.open("textEntry", {
			label = L"Enter BPM",
			text = tostring(previousBpm),
			autoSelect = true,
			callback = textEntryCallback,
			cancelCallback = nil,
		})
    end,
}

return riftedBpmAst
