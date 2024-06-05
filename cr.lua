local se = require "samp.events"

local analyzing = false
local prev_page_text = ""
local fined_count = 0
local data = {
	list = {},
	last_update = -1
}

local path = getWorkingDirectory() .. "\\config\\prices.json"
if not doesFileExist(path) then
	createDirectory(getWorkingDirectory() .. "\\config\\")
	local file = io.open(path, "wb")
	file:write(encodeJson(data))
	file:close()
else
	local file = io.open(path, "rb")
	data = decodeJson(file:read("*a"))
	file:close()
end

function main()
	assert(isSampLoaded(), "SA:MP is required!")
	repeat wait(0) until isSampAvailable()
	sampRegisterChatCommand("price", get_price)
	wait(-1)
end

function get_price(item)
	item = tostring(item)

	if data.last_update == -1 then
		sampAddChatMessage("[Ðûíîê] {FFFFFF}Ñðåäíèå öåíû íå çàãðóæåíû!", 0xFF6060)
		sampAddChatMessage("[Ðûíîê] {FFFFFF}Çàãðóçèòü èõ ìîæíî íà ïèêàïå ñðåäíèõ öåí {FF6060}(òîëüêî ñ PREMIUM VIP)",  0xFF6060)
		return
	end

	item = string_to_lower(item)
	if item ~= nil and not string.find(item, "^%s*$") then
		local temp, actual = {}, true
		for name, info in pairs(data.list) do
			if string.find(string_to_lower(name), item, 1, true) then
				local sa, vc = "Íåèçâåñòíî", "Íåèçâåñòíî"

				if type(info.sa.price) == "table" then
					local min = sumFormat(info.sa.price[1])
					local max = sumFormat(info.sa.price[2])
					sa = string.format("$%s - %s", min, max)
				elseif tonumber(info.sa.price) then
					sa = "$" .. sumFormat(info.sa.price)
				end

				if type(info.vc.price) == "table" then
					local min = sumFormat(info.vc.price[1])
					local max = sumFormat(info.vc.price[2])
					vc = string.format("%s - %s", min, max)
				elseif tonumber(info.vc.price) then
					vc = sumFormat(info.vc.price)
				end

				if info.sa.updated and os.time() - info.sa.updated > (86400 * 7) then
					sa = "{FFAA60}" .. sa
					actual = false
				else
					sa = "{FF6060}" .. sa
				end

				if info.vc.updated and os.time() - info.vc.updated > (86400 * 7) then
					vc = string.format("{FFAA60}(VC$: %s)", vc)
					actual = false
				else
					vc = string.format("{EEEEEE}(VC$: %s)", vc)
				end

				temp[#temp + 1] = ("%s) {FFFFFF}%s: %s %s"):format(#temp + 1, name, sa, vc)
			end
		end

		if #temp >= 1 then
			local msg = string.format("[Ðûíîê] {FFFFFF}%s {FF6060}%s{FFFFFF} %s:",
				plural(#temp, {"Íàéäåí", "Íàéäåíî", "Íàéäåíî"}),
				#temp,
				plural(#temp, {"òîâàð", "òîâàðà", "òîâàðîâ"})
			)
			sampAddChatMessage(msg, 0xFF6060)
			for _, msg in ipairs(temp) do
				sampAddChatMessage(msg, 0xFF6060)
			end
			if not actual then
				sampAddChatMessage("[Ïîäñêàçêà] {FFFFFF}Óñòàðåâøèå öåíû ïîìå÷åíû {FFAA60}îðàíæâåâûì{FFFFFF} öâåòîì (Íåîáõîäèìî îáíîâèòü)", 0xFF6060)
			end
			return
		end
		sampAddChatMessage("[Ðûíîê] {FFFFFF}Íå óäàëîñü íàéòè òîâàð ñ ïîõîæèì íàçâàíèåì", 0xFF6060)
		return
	end
	sampAddChatMessage("[Ðûíîê] {FFFFFF}Ââåäèòå /price [Íàçâàíèå òîâàðà èëè åãî ÷àñòü]", 0xFF6060)
end

function se.onShowDialog(id, style, title, but_1, but_2, text)
	if id == 15073 and string.find(title, "Ñðåäíÿÿ öåíà òîâàðîâ ïðè ïðîäàæå") then
		if not analyzing then
			prev_page_text = text
			text = string.gsub(text, "(Ïîèñê ïî íàçâàíèþ\t%s)\n", "%1\n{00FF00}Ïðîàíàëèçèðîâàòü âñå öåíû\t \n", 1)
			go_analyzing_list_id = findListInDialog(text, style, "Ïðîàíàëèçèðîâàòü âñå öåíû")
		elseif prev_page_text == text then
			sampAddChatMessage("[Ðûíîê] {FFFFFF}Àíàëèç çàâåðø¸í! Ñðåäíèå öåíû íà òîâàðû îáíîâëåíû!", 0xFF6060)
			printStyledString("~w~~g~Prices found: " .. pCount, 2000, 6)
			prev_page_text = nil
			analyzing = false

			local file = io.open(path, "wb")
			if file ~= nil then
				file:write(encodeJson(data))
				file:close()
			else
				sampAddChatMessage("[Ðûíîê] {FFFFFF}Îøèáêà ñîõðàíåíèÿ ôàéëà ñ öåíàìè!", 0xFF6060)
			end

			lua_thread.create(sendResponse, id, 0, nil, nil)
			return false
		else
			parser(text)
			printStyledString("~w~Prices found: ~r~" .. pCount, 2000, 6)
			prev_page_text = text

			local list = findListInDialog(text, style, "Ñëåäóþùàÿ ñòðàíèöà")
			if list == nil then
				analyzing = false
				sampAddChatMessage("[Ðûíîê] {FFFFFF}Îøèáêà ïðîâåðêè öåí! Íå óäàëîñü ïåðåéòè íà ñëåäóþùóþ ñòðàíèöó!", 0xFF6060)
				lua_thread.create(sendResponse, id, 0, nil, nil)
				return false
			else
				lua_thread.create(sendResponse, id, 1, list, nil)
			end
			return false
		end
		return { id, style, title, but_1, but_2, text }
	elseif analyzing then
		sampAddChatMessage("[Ðûíîê] {FFFFFF}Îøèáêà ïðîâåðêè öåí! Àíàëèç áûë ñáèò äðóãèì äèàëîãîì!", 0xFF6060)
		lua_thread.create(sendResponse, id, 0, nil, nil)
		return false
	end

	if id == 3082 then
		if data.last_update == -1 then
			text = text:gsub("Ñòîèìîñòü:[^\n]+", "%1\n{FFAA60}Ñðåäíèå öåíû íå çàãðóæåíû!")
			return { id, style, title, but_1, but_2, text }
		end

		for line in string.gmatch(text, "[^\n]+") do
			local item = string.match(line, ".*{%x+}(.+){%x+}.*$")
			local temp = {}

			if item == nil then
				text = string.gsub(text, "Ñòîèìîñòü:[^\n]+", "%1 {FFAA60}(Òîâàð íå îïðåäåë¸í)")
				print("{FFAA60}Íå óäàëîñü îïðåäåëèòü òîâàð: «" .. line .. "»")
				return { id, style, title, but_1, but_2, text }
			end

			for name, info in pairs(data.list) do
				if string.find(item, name, 1, true) then
					local state = string.find(text, "Ñòîèìîñòü: VC$", 1, true) and "vc" or "sa"
					local price = (state == "vc") and "VC$" or "$"
					local outdated = info[state].updated and (os.time() - info[state].updated) > (86400 * 7)

					if type(info[state].price) == "table" then
						local min = price .. sumFormat(info[state].price[1])
						local max = price .. sumFormat(info[state].price[2])
						price = string.format("Îò %s äî %s", min, max)
						temp[#temp + 1] = { name, price, outdated }
					elseif tonumber(info[state].price) then
						price = string.format("~%s%s", price, sumFormat(info[state].price))
						temp[#temp + 1] = { name, price, outdated }
					end
				end
			end

			if #temp > 1 then
				local result = ""
				for i = 1, #temp do
					result = result .. string.format("{67BE55}%s - {FFAA60}%s", temp[i][1], temp[i][2])
					if i ~= #temp then
						result = result .. "\n"
					end
				end
				text = text:gsub("Ñòîèìîñòü:[^\n]+", "%1\n\n{67BE55}Ñðåäíÿÿ ñòîèìîñòü òîâàðîâ ñ ïîõîæèì íàçâàíèåì:\n" .. result)
			elseif #temp == 1 then
				text = text:gsub("Ñòîèìîñòü:[^\n]+", "%1 {FFAA60}(" .. temp[1][2] .. ")")
			else
				text = text:gsub("Ñòîèìîñòü:[^\n]+", "%1 {FFAA60}(Ñð. öåíà íå íàéäåíà)")
			end
			break
		end
		return { id, style, title, but_1, but_2, text }
	end

	if id == 3060 then
		local item = string.match(text, "%( {57FF6B}(.+){FFFFFF} %)")
		if item ~= nil then
			local temp = {}
			for name, info in pairs(data.list) do
				if string.find(string_to_lower(name), string_to_lower(item), 1, true) then
					local sa, vc = "Íåèçâåñòíî", "Íåèçâåñòíî"

					if type(info.sa.price) == "table" then
						local min = "$" .. sumFormat(info.sa.price[1])
						local max = "$" .. sumFormat(info.sa.price[2])
						sa = string.format("%s - %s", min, max)
					elseif tonumber(info.sa.price) then
						sa = "$" .. sumFormat(info.sa.price)
					end

					if type(info.vc.price) == "table" then
						local min = sumFormat(info.vc.price[1])
						local max = sumFormat(info.vc.price[2])
						vc = string.format("%s - %s", min, max)
					elseif tonumber(info.vc.price) then
						vc = sumFormat(info.vc.price)
					end

					temp[#temp + 1] = { name, sa, vc }
				end
			end

			local result
			if #temp > 1 then
				result = "Ïîõîæèå òîâàðû:\n"
				for i, info in ipairs(temp) do
					result = result .. string.format("{67BE55}%s) %s: {FFAA60}%s {BBBBBB}(VC$: %s)", i, info[1], info[2], info[3])
					if i ~= #temp then result = result .. "\n" end
				end
			elseif #temp == 1 then
				result = string.format("Ñðåäíÿÿ öåíà: {FFAA60}%s {BBBBBB}(VC$: %s)", temp[1][2], temp[1][3])
			else
				result = "Ñðåäíÿÿ öåíà íà ýòîò òîâàð íåèçâåñòíà"
			end

			text = string.gsub(text, "$", "\n\n{67BE55}" .. result)
			return { id, style, title, but_1, but_2, text }
		end
	end
end

function se.onSendDialogResponse(id, but, list, input)
	if not analyzing and id == 15073 and go_analyzing_list_id ~= nil then
		if list == go_analyzing_list_id and but == 1 then
			local text = sampGetDialogText()
			local style = sampGetCurrentDialogType()
			list = findListInDialog(text, style, "Ñëåäóþùàÿ ñòðàíèöà")
			if list == nil then
				sampAddChatMessage("[Ðûíîê] {FFFFFF}Îøèáêà ïðîâåðêè öåí! Íå óäàëîñü ïåðåéòè íà ñëåäóþùóþ ñòðàíèöó!", 0xFF6060)
				return { id, 0, list, input }
			else
				analyzing = true
				data.last_update = os.time()
				sampAddChatMessage("[Ðûíîê] {FFFFFF}Çàïóùåí àíàëèç öåí. Íå îòêðûâàéòå äî çàâåðøåíèÿ äðóãèå äèàëîãè!", 0xFF6060)

				pCount = 0
				parser(text)
				printStyledString("~w~Prices found: ~r~" .. pCount, 2000, 6)
			end
		end

		if list >= go_analyzing_list_id then
			list = list - 1
		end

		go_analyzing_list_id = nil
		return { id, but, list, input }
	end
end

function parser(text)
	local i = 0
	for line in string.gmatch(text, "[^\n]+") do
		i = i + 1
		if i > 3 then
			local item, price = string.match(line, "^(.+)\t%$(.+)$")
			if item and price then
				if data.list[item] == nil then
					data.list[item] = {
						sa = { price = nil, updated = nil },
						vc = { price = nil, updated = nil },
					}
				end
				local t = data.list[item][string.find(price, "VC") and "vc" or "sa"]
				price = string.gsub(price, "%p+", "")
				local int_price = tonumber(string.match(price, "%d+"))
				if int_price == nil then
					print(("Íåóäàëîñü îáíàðóæèòü öåíó íà òîâàð: %s || Out: «%s»"):format(item, price))
					goto skip
				end

				int_price = normalise_int(int_price)
				if t.updated and (os.time() - t.updated < 60) then
					if type(t.price) == "table" then
						if t.price[1] > int_price then
							t.price[1] = int_price -- min price
						else
							t.price[2] = int_price -- max price
						end
					else
						local p = tonumber(t.price)
						if p > int_price then
							t.price = { int_price, p }			
						else
							t.price = { p, int_price }
						end
					end
				else
					t.price = int_price
				end
				t.updated = os.time()
				pCount = pCount + 1

				::skip::
			end
		end
	end
end

function findListInDialog(text, style, search)
	local i = 0
	for line in string.gmatch(text, "[^\n]+") do
		if string.find(line, search, 1, true) then
			return i - (style == 5 and 1 or 0)
		end
		i = i + 1
	end
	return nil
end

function string_to_lower(str)
	for i = 192, 223 do
		str = str:gsub(_G.string.char(i), _G.string.char(i + 32))
	end
	str = str:gsub(_G.string.char(168), _G.string.char(184))
	return str:lower()
end

function sumFormat(sum)
	sum = tostring(sum)
	count = sum:match("%d+")
	if count and #count > 3 then
		local b, e = ("%d"):format(count):gsub("^%-", "")
		local c = b:reverse():gsub("%d%d%d", "%1.")
		local d = c:reverse():gsub("^%.", "")
		return sum:gsub(count, (e == 1 and "-" or "") .. d)
	end
	return sum
end

function plural(n, forms) 
	n = math.abs(n) % 100
	if n % 10 == 1 and n ~= 11 then
		return forms[1]
	elseif 2 <= n % 10 and n % 10 <= 4 and (n < 10 or n >= 20) then
		return forms[2]
	end
	return forms[3]
end

function normalise_int(int)
    for i = 4, 10 do
        if int < 10^i and int >= 10^2 then
            int = int / 10^(i-3)
            int = math.floor(int) * 10^(i-3)
            break
        end
    end
    
    return int
end

function sendResponse(id, button, list, input)
	wait(100)
	sampSendDialogResponse(id, button, list, input)
end
