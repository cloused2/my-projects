script_name("{ff7e7e}Deposite Caclulator [V1.1]")
script_author("MTG MODS")
script_version("1.2 Beta")

require "lib.moonloader"
require 'encoding'.default = 'CP1251'
local u8 = require 'encoding'.UTF8
local ffi = require 'ffi'

local inicfg = require 'inicfg'
local my_ini = "DepositeCaclulator.ini"
local settings = inicfg.load({
	general = {
		my_deposite = 0,
		my_rank = 0,
		my_houses = 0,
		my_vip = 0,
		my_insurance = 0,
		my_lavka = 0,
		fix = -1.76
    },
	
}, my_ini)

if MONET_DPI_SCALE == nil then MONET_DPI_SCALE = 1.0 end

local fa = require('fAwesome6_solid')
local imgui = require('mimgui')
local new = imgui.new
local MainWindow  = new.bool()
local my_insurance = new.int(settings.general.my_insurance)
local my_lavka = new.int(settings.general.my_lavka)
local my_houses = new.int(settings.general.my_houses)
local my_vip = new.int(settings.general.my_vip)
local my_rank = new.int(settings.general.my_rank)
local input_fix = new.char[256](u8(settings.general.fix))

local sizeX, sizeY = getScreenResolution()


local check_stats = false

local newdeposite_bool = false
local newdeposite = 0

function main()

	if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(0) end 
	
	sampAddChatMessage('{ff0000}[INFO] {ffffff}Скрипт "Deposite Caclulator" загружен и готов к работе! Автор: MTG MODS | Версия: 1.2 Beta | Используйте {00ccff}/deposite',-1)
	
	sampRegisterChatCommand("deposite", function() 
		check_stats = true 
		sampSendChat('/stats') 
		MainWindow[0] = not MainWindow[0] 
	end)
	
	sampRegisterChatCommand("newdeposite", function(param) 
		if param:find("%d") and not param:find("%D") then 
			newdeposite_bool = true 
			newdeposite = param
		else
			sampAddChatMessage('{ff0000}[INFO] {ffffff}Используйте {00ccff}/deposite [значение]',-1)
		end
	end)
	
	wait(-1)
	
end	

require("samp.events").onShowDialog = function(dialogid, style, title, button1, button2, text)
	
	if dialogid == 235 and check_stats then -- получение статистики
		
		if text:find("{FFFFFF}Деньги на депозите: {B83434}%[(.+)%](.+){FFFFFF}Работа") then
			local deposite = text:match("{FFFFFF}Деньги на депозите: {B83434}%[(.+)%](.+){FFFFFF}Работа")
			settings.general.my_deposite = deposite:gsub("%D", "")
			settings.general.my_deposite = math.floor(settings.general.my_deposite)
			inicfg.save(settings, my_ini)
		end
		
		if text:find("{FFFFFF}Должность: {B83434}(.+)%((%d+)%)") then
			local rank, rank_number = text:match("{FFFFFF}Должность: {B83434}(.+)%((%d+)%)(.+)Уровень розыска")
			my_rank[0] = tonumber(rank_number)
			settings.general.my_rank = tonumber(rank_number)
			inicfg.save(settings, my_ini)
		end
		
		if text:find("{FFFFFF}Статус: {B83434}%[(.+)%](.+){FFFFFF}Супруг") then
			local vip = text:match("{FFFFFF}Статус: {B83434}%[(.+)%](.+){FFFFFF}Супруг")
			
			if vip == 'Premium' then
				my_vip[0] = 6
			elseif vip == 'Titan' then
				my_vip[0] = 5
			elseif vip == 'Daimond' then
				my_vip[0] = 4
			elseif vip == 'Platinum' then
				my_vip[0] = 3
			elseif vip == 'Gold' then
				my_vip[0] = 2
			elseif vip == 'Bronze' then
				my_vip[0] = 1
			elseif vip == 'Не имеется' then
				my_vip[0] = 0
			end
			
			settings.general.my_vip = my_vip[0]
			inicfg.save(settings, my_ini)
			
		end
		
		sampSendDialogResponse(235, 0,0,0)
		check_stats = false
		return false
	
	end
	
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	fa.Init(14 * MONET_DPI_SCALE)
	dark_theme()
end)

local MainWindow = imgui.OnFrame(
    function() return MainWindow[0] end,
    function(opyat_govnokog_exx)
	
		imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(800 * MONET_DPI_SCALE, 530 * MONET_DPI_SCALE), imgui.Cond.FirstUseEver)
		imgui.Begin(fa.LANDMARK.." Deposite Caclulator by MTG MODS [V1.2 Beta]", MainWindow, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
		
		if imgui.BeginChild('##1', imgui.ImVec2(790 * MONET_DPI_SCALE, 65 * MONET_DPI_SCALE), true) then
			
			imgui.CenterText(fa.MONEY_CHECK_DOLLAR..u8' Денег на вашем депозите: $' .. comma_value(getMyDeposite()) .. ' / $' .. comma_value(getMaxDeposite()) )
			
			if getMyDeposite() > getMaxDeposite() then 
				imgui.CenterTextDisabled(u8"У вас на депозите $" .. comma_value( tonumber(getMyDeposite()) - getMaxDeposite() ) .. u8" лишние, с них прибыль не идёт, и их можно снять")
			elseif getMyDeposite() > 0 and getMyDeposite() < getMaxDeposite() then
				imgui.CenterTextDisabled(u8"Чтобы иметь максимальную прибыль с депозита, пополните его ещё на $" .. comma_value( getMaxDeposite() - getMyDeposite() ) .. u8" либо ожидайте " .. gotoFullDeposite() .. " PAYDAY")
			elseif getMyDeposite() == getMaxDeposite() then
				imgui.CenterTextDisabled(u8"Ваш депозит полностю заполнением, и теперь вы каждый PAYDAY будете иметь прибыль, которую можно снимать")
			elseif getMyDeposite() == 0 then
				imgui.CenterTextDisabled(u8"Депозит полностю пустой, и не приносит прибыль!")
			end
			
			imgui.CenterTextDisabled(u8"Чтобы указать другое кол-во денег на депозите вместо использования данных из /stats, введите /newdeposite [значение]")
	
			
		imgui.EndChild() end
		
		if imgui.BeginChild('##2', imgui.ImVec2(790 * MONET_DPI_SCALE, 75 * MONET_DPI_SCALE), true) then
		
			imgui.CenterText(fa.SACK_DOLLAR..u8' Подсчёт прибыли с депозита, учитывая указанные вами условия:' )
			
			imgui.Separator()
			imgui.Columns(3)
			imgui.CenterColumnText(u8'Простой PAYDAY')
			imgui.NextColumn()
			imgui.CenterColumnText(u8'PAYDAY в X2 доме')
			imgui.NextColumn()
			imgui.CenterColumnText('X4 PAYDAY')
			imgui.Columns(1)
			imgui.Separator()
			imgui.Columns(3)
			imgui.CenterColumnText('$' .. tostring( comma_value( getDeposite() ) ) )
			imgui.NextColumn()
			imgui.CenterColumnText('$' .. tostring( comma_value( getDeposite() * 2 ) ) )
			imgui.NextColumn()
			imgui.CenterColumnText('$' .. tostring( comma_value( getDeposite() * 4 ) ) )
			imgui.Columns(1)
			--imgui.Separator()
		
		imgui.EndChild() end
		
		if imgui.BeginChild('##3', imgui.ImVec2(790 * MONET_DPI_SCALE, 345 * MONET_DPI_SCALE), true) then
			
			imgui.CenterText(u8'Укажите условия, которые влияют на прибыль с депозита')
			
			imgui.Separator()
			
			imgui.CenterText(fa.CROWN .. u8' Уровень VIP статуса')
			local numButtons = 7
			local buttonWidth = 100 * MONET_DPI_SCALE
			local totalButtonWidth = buttonWidth * numButtons + imgui.GetStyle().ItemSpacing.x * (numButtons - 1)
			local startPosX = (imgui.GetWindowWidth() - totalButtonWidth) / 2
			imgui.SetCursorPosX(startPosX)
			for i = 0, numButtons - 1 do
				if i > 0 then
					imgui.SameLine()
				end

				local label = ""
				if i == 0 then
					label = u8" Без VIP "
				elseif i == 1 then
					label = u8" Bronze VIP "
				elseif i == 2 then
					label = u8" Gold VIP "
				elseif i == 3 then
					label = u8" Platinum VIP "
				elseif i == 4 then
					label = u8" Diamond VIP "
				elseif i == 5 then
					label = u8" Titan VIP "
				elseif i == 6 then
					label = u8" Premium VIP "
				end

				imgui.SetCursorPosX(startPosX + i * (buttonWidth + imgui.GetStyle().ItemSpacing.x))
				if imgui.RadioButtonIntPtr(label, my_vip, i) then
					my_vip[0] = i
					settings.general.my_vip = my_vip[0]
					inicfg.save(settings, my_ini)
				end
			end
			
			
			imgui.Separator()
			
			
			
			imgui.CenterText(fa.HOUSE .. u8' Количество домов с улучшением депозита')
			imgui.SameLine(0,5)
			imgui.TextDisabled(u8"[?]")
			if imgui.IsItemHovered() then
				imgui.SetTooltip(u8'Для каждого дома есть улучшение "Депозитные условия"\nДанное улучшение стоит $60,000,000\nУлучшенный дом повышает максимальный депозит на $6,000,000\nВы можете подселиться в такой дом, или купить его у игроков\nОбычно такие уже улучшенные дома игроки продают по ± $40,000,000')
			end
			
			for i = 0, 15 do
				if i > 0 then
					imgui.SameLine()
				end
				local label = " " .. tostring(i) .. "##houses"
				if imgui.RadioButtonIntPtr(label, my_houses, i) then
					my_houses[0] = i
					settings.general.my_houses = my_houses[0]
					inicfg.save(settings, my_ini)
				end
			end
			
			imgui.Separator()
			
			imgui.CenterText(fa.USER .. u8' Порядковая должность в организации (номер ранга)')
			local numButtons = 11
			local buttonWidth = 50 * MONET_DPI_SCALE
			local totalButtonWidth = buttonWidth * numButtons + imgui.GetStyle().ItemSpacing.x * (numButtons - 1)
			local startPosX = (imgui.GetWindowWidth() - totalButtonWidth) / 2
			imgui.SetCursorPosX(startPosX)
			for i = 0, numButtons - 1 do
				if i > 0 then
					imgui.SameLine()
				end
				
				local label = u8" " .. tostring(i) .. " "

				imgui.SetCursorPosX(startPosX + i * (buttonWidth + imgui.GetStyle().ItemSpacing.x))
				if imgui.RadioButtonIntPtr(label, my_rank, i) then
					my_rank[0] = i
					settings.general.my_rank = my_rank[0]
					inicfg.save(settings, my_ini)
				end
			end
			
			imgui.Separator()
			
			imgui.CenterText(fa.FILE_INVOICE_DOLLAR .. u8' Наличие пенсионного страхования')
			imgui.SameLine(0,5)
			imgui.TextDisabled(u8"[?]")
			
			if imgui.IsItemHovered() then
				imgui.SetTooltip(u8'Улучшение "Пенсионное Страхование" даёт +15 процентов к депозиту\nОно покупается в Страховой Компании за $200,000,000')
			end
				
			local numButtons = 2
			local buttonWidth = 100 * MONET_DPI_SCALE
			local totalButtonWidth = buttonWidth * numButtons + imgui.GetStyle().ItemSpacing.x * (numButtons - 1)
			local startPosX = (imgui.GetWindowWidth() - totalButtonWidth) / 2
			imgui.SetCursorPosX(startPosX)
			for i = 0, numButtons - 1 do
				if i > 0 then
					imgui.SameLine()
				end
				
				local label
				if i == 0 then
					label = u8' Нету '
				elseif i == 1 then
					label = u8' Есть '
				end

				imgui.SetCursorPosX(startPosX + i * (buttonWidth + imgui.GetStyle().ItemSpacing.x))
				if imgui.RadioButtonIntPtr(label, my_insurance, i) then
					my_insurance[0] = i
					if my_insurance[0] == 0 then
						settings.general.my_insurance = false
						inicfg.save(settings, my_ini)
					else
						settings.general.my_insurance = true
						inicfg.save(settings, my_ini)
					end
				end
			end


			imgui.Separator()
			
			imgui.CenterText(fa.BOX_ARCHIVE .. u8' Наличие Элитной Лавки')
			imgui.SameLine(0,5)
			imgui.TextDisabled(u8"[?]")
			
			if imgui.IsItemHovered() then
				imgui.SetTooltip(u8'Аксесуар "Элитная Лавка" даёт +12 процентов к депозиту')
			end
				
			local numButtons = 2
			local buttonWidth = 100 * MONET_DPI_SCALE
			local totalButtonWidth = buttonWidth * numButtons + imgui.GetStyle().ItemSpacing.x * (numButtons - 1)
			local startPosX = (imgui.GetWindowWidth() - totalButtonWidth) / 2
			imgui.SetCursorPosX(startPosX)
			for i = 0, numButtons - 1 do
				if i > 0 then
					imgui.SameLine()
				end
				
				local label
				if i == 0 then
					label = u8' Нету ##lavka' 
				elseif i == 1 then
					label = u8' Есть ##lavka'
				end

				imgui.SetCursorPosX(startPosX + i * (buttonWidth + imgui.GetStyle().ItemSpacing.x))
				if imgui.RadioButtonIntPtr(label, my_lavka, i) then
					my_lavka[0] = i
					if my_lavka[0] == 0 then
						settings.general.my_lavka = false
						inicfg.save(settings, my_ini)
					else
						settings.general.my_lavka = true
						inicfg.save(settings, my_ini)
					end
				end
			end


			imgui.Separator()
			
			imgui.CenterText(fa.CIRCLE_DOLLAR_TO_SLOT .. u8' Текущий процент фикса экономики')
			imgui.SameLine(0,5)
			imgui.TextDisabled(u8"[?]")
			if imgui.IsItemHovered() then
				imgui.SetTooltip(u8'Узнать текущий процент фикса экономики вы можете из:\n- Discord: https://discord.gg/qBPEYjfNhv\n- BlastHack: https://www.blast.hk/threads/197531/')
			end
			
			imgui.PushItemWidth(50 * MONET_DPI_SCALE)
			imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - 25 * MONET_DPI_SCALE)
			if imgui.InputText(u8'%##fix', input_fix, 256) then
				settings.general.fix = u8:decode(ffi.string(input_fix))
				--inicfg.save(settings, my_ini)
			end
			
			
		imgui.EndChild() end
		
		imgui.End()
		
    end
)

function getMyDeposite()

	local deposit
	
	if newdeposite_bool then
		deposit = newdeposite
	else
		local matchResult = tostring(settings.general.my_deposite):match("(%d+)")
		deposit = matchResult and tonumber(matchResult) or 0
	end

	return tonumber(deposit)
end
function getMaxDeposite()
	local max_deposite = 200000000 + ( 6000000 * settings.general.my_houses )
	return tonumber(max_deposite)
end
function getVipProfit()

	local vip_bonus

    if my_vip[0] == 0 then -- no vip
		vip_bonus = 1500
    elseif my_vip[0] == 1 then -- bronze vip
		vip_bonus = 1400
    elseif my_vip[0] == 2  then -- gold vip
		vip_bonus = 1300
    elseif my_vip[0] == 3 then -- platinum vip
		vip_bonus = 1250
    elseif my_vip[0] == 4 then -- daimond vip
		vip_bonus = 1200
    elseif my_vip[0] == 5 then -- titan vip
		vip_bonus = 1150
    elseif my_vip[0] == 6 then -- premium vip
		vip_bonus = 800
    end

	return tonumber(vip_bonus)

end
function getPercentBonus()

	local percent = 0

	if my_insurance[0] == 1 then
	    percent = percent + 15
	end
	
	if my_rank[0] >= 1 and my_rank[0] <= 3 then
		percent = percent + 15
	elseif my_rank[0] >= 4 and my_rank[0] <= 7 then
		percent = percent + 25
	elseif my_rank[0] >= 8 and my_rank[0] <= 10 then
		percent = percent + 30
	end

	if my_lavka[0] == 1 then
		percent = percent + 12
	end
	
	return tonumber(percent)

end
function getDeposite()

	local deposite = getMyDeposite()

    if tonumber(deposite) > getMaxDeposite() then
		deposite = getMaxDeposite()
    end
	
    local my_deposite = deposite / getVipProfit()

	local my_deposite_bonus = my_deposite + ( my_deposite / 100 ) * getPercentBonus()

	local final_deposite = my_deposite_bonus  - ( my_deposite_bonus / 100 ) * tonumber(settings.general.fix)

	return math.floor(final_deposite)

end
function gotoFullDeposite()

	local currentDeposit = getMyDeposite()

    if currentDeposit >= getMaxDeposite() then
        return
    end

    local iterations = 0

    while currentDeposit < getMaxDeposite() do
	
        local my_deposite = currentDeposit / getVipProfit()
		
        local my_deposite_bonus = my_deposite + (my_deposite / 100) * getPercentBonus()
		
        local final_deposite = my_deposite_bonus - (my_deposite_bonus / 100) * tonumber(settings.general.fix)
		
		currentDeposit = currentDeposit + final_deposite
		
        iterations = iterations + 1
		
    end

    return iterations
end

function comma_value(n) -- эта функция полностю взята со скрипта MoneySeparator by Royan_Millans and YarikVL
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end
function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end
function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end
function imgui.CenterTextDisabled(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.TextDisabled(text)
end
function dark_theme()

	imgui.SwitchContext()
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5 * MONET_DPI_SCALE, 5 * MONET_DPI_SCALE)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5 * MONET_DPI_SCALE, 5 * MONET_DPI_SCALE)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5 * MONET_DPI_SCALE, 5 * MONET_DPI_SCALE)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2 * MONET_DPI_SCALE, 2 * MONET_DPI_SCALE)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
    imgui.GetStyle().IndentSpacing = 0
    imgui.GetStyle().ScrollbarSize = 10 * MONET_DPI_SCALE
    imgui.GetStyle().GrabMinSize = 10 * MONET_DPI_SCALE
    imgui.GetStyle().WindowBorderSize = 1 * MONET_DPI_SCALE
    imgui.GetStyle().ChildBorderSize = 1 * MONET_DPI_SCALE
    imgui.GetStyle().PopupBorderSize = 1 * MONET_DPI_SCALE
    imgui.GetStyle().FrameBorderSize = 1 * MONET_DPI_SCALE
    imgui.GetStyle().TabBorderSize = 1 * MONET_DPI_SCALE
	imgui.GetStyle().WindowRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().ChildRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().FrameRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().PopupRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().ScrollbarRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().GrabRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().TabRounding = 8 * MONET_DPI_SCALE
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
    
    imgui.GetStyle().Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Border]                 = imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
    imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
    imgui.GetStyle().Colors[imgui.Col.CheckMark]              = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Button]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Header]                 = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Separator]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
    imgui.GetStyle().Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(1.00, 0.00, 0.00, 0.35)
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
    imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
    imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
	
end
