require 'moonloader'
imgui = require 'imgui'
function json(filePath)
    local class = {}
        function class.save(tbl)
        if tbl then local F = io.open(filePath, 'w');	F:write(encodeJson(tbl) or {});	F:close();	return true, 'ok' end
        return false, 'table = nil'
    end
    function class.load(defaultTable)
        if not doesFileExist(filePath) then;	class.save(defaultTable or {});	end
        local F = io.open(filePath, 'r+');	local TABLE = decodeJson(F:read() or {}); F:close()
        for def_k, def_v in pairs(defaultTable) do;  if TABLE[def_k] == nil then;   TABLE[def_k] = def_v;   end;    end
        return TABLE
    end; return class
end
jPath = getWorkingDirectory() .. '/config/chromakey.json'
j = json(jPath).load({
	
})

chromakey = {}
for k,v in ipairs(j) do
	table.insert(chromakey,{
        index = 0,
        color = imgui.ImFloat4(unpack(v.color)),
        pos = imgui.ImFloat3(unpack(v.pos)),
        rot = imgui.ImFloat3(unpack(v.rot)),
        scale = imgui.ImFloat(v.scale),
        colision = imgui.ImBool(v.colision),
	})
end
pos = {}
created = false
window = imgui.ImBool(false)
WALL = 19362
font = renderCreateFont('arial',10,0x4)
function main()
	while not isSampAvailable() do wait(0) end

	sampRegisterChatCommand('chromakey',function() window.v = not window.v end)

    wait(-1)
end
function onD3DPresent() imgui.Process = window.v end

function imgui.OnDrawFrame()
	local sw,sh = getScreenResolution()

	if window.v then
		-- imgui.SetNextWindowSize(imgui.ImVec2(500,500),1)
		imgui.SetNextWindowPos(imgui.ImVec2(sw/2,sh/2), imgui.Cond.FirstUseEver)
		imgui.Begin('chromakey//by_vespan',window,32+64)
        imgui.ShowCursor = true
        if isKeyDown(VK_RBUTTON) then
            imgui.ShowCursor = false
        end
        if imgui.Button(created and 'delete chromakey' or 'spawning there chromakey') then
            created = not created
            if created then
                pos = {getCharCoordinates(PLAYER_PED)}
                for k,v in ipairs(chromakey) do
                    v.index = getFreeIndexObject()
                    setChromakey(v)
                end
            else
                for k,v in ipairs(chromakey) do
                    removeObj(v.index)
                end
            end
        end
        if created then
            local _,x,y,z = convert3DCoordsToScreenEx(pos[1],pos[2],pos[3])
            if z > 1 then
                renderDrawPolygon(x,y,10,10,10,0,-1)
            end
            if imgui.Button('save') then
                j = {}
                for k,v in ipairs(chromakey) do
                    table.insert(j,{
                        color = {v.color.v[1],v.color.v[2],v.color.v[3],v.color.v[4]},
                        pos = {v.pos.v[1],v.pos.v[2],v.pos.v[3]},
                        rot = {v.rot.v[1],v.rot.v[2],v.rot.v[3]},
                        scale = v.scale.v,
                        colision = v.colision.v,
                    })
                end
                json(jPath).save(j)
            end
    		if imgui.Button('create new chromakey') then
                createNewChromakey()
    		end
            imgui.Separator()
    		for k,v in ipairs(chromakey) do
                local _,x,y,z = convert3DCoordsToScreenEx(pos[1]+v.pos.v[1],pos[2]+v.pos.v[2],pos[3]+v.pos.v[3]) 
                if z > 1 then
                    renderFontDrawText(font,tostring(k),x-(renderGetFontDrawTextLength(font,tostring(k))/2),y,-1)
                end
    			if imgui.BeginMenu(''..k) then
                    if imgui.DragFloat3('pos x,y,z',v.pos,0.001,-100000,100000) then;  setChromakey(v);    end
                    if imgui.DragFloat3('rot x,y,z',v.rot,0.001,-100000,100000) then;  setChromakey(v);    end
                    if imgui.DragFloat('scale',v.scale,0.05,0.5,5) then;   setChromakey(v);    end
                    if imgui.Checkbox('colision',v.colision) then; setChromakey(v);    end
    				if imgui.ColorEdit4('color',v.color,512) then; setChromakey(v);    end
                    if imgui.Button('remove!') then
                        removeObj(v.index)
                        table.remove(chromakey,k)
                    end
    				imgui.EndMenu()
    			end
    		end
        end
		imgui.End()
	end

end

function getFreeIndexObject()
    local index = 1
    for k,v in ipairs(getAllObjects()) do
        if index == sampGetObjectSampIdByHandle(v) then
            index = index + 1
        else
            index = index + 1 --тю блять
        end
    end
    return index
end

function createNewChromakey()
    table.insert(chromakey,{
        index = getFreeIndexObject(),
        color = imgui.ImFloat4(1,0,1,1),
        pos = imgui.ImFloat3(0,0,0),
        rot = imgui.ImFloat3(0,0,0),
        scale = imgui.ImFloat(1.00),
        colision = imgui.ImBool(true),
    })
    setChromakey(chromakey[#chromakey])
end
function setChromakey(v)
    createObj(v.index,WALL,{pos[1]+v.pos.v[1],pos[2]+v.pos.v[2],pos[3]+v.pos.v[3]},{0,0,0},50,v.scale.v,v.colision.v,0)
    setRotationObject(v.index,{v.rot.v[1],v.rot.v[2],v.rot.v[3]})
    setMaterialObject(v.index,1,0,15040,'cuntcuts','white',float4ToHex(v.color.v))
end

function float4ToHex(v)
    return string.format('0x%02x%02x%02x%02x',
        v[4]*255,v[1]*255,v[2]*255,v[3]*255
    )
end

function setMaterialObject(id,materialType,materialId,model,libraryName,textureName,color)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs,id)
    raknetBitStreamWriteInt8(bs,materialType)
    raknetBitStreamWriteInt8(bs,materialId)
    raknetBitStreamWriteInt16(bs,model)
    raknetBitStreamWriteInt8(bs,#libraryName)
    raknetBitStreamWriteString(bs,libraryName)
    raknetBitStreamWriteInt8(bs,#textureName)
    raknetBitStreamWriteString(bs,textureName)
    raknetBitStreamWriteInt32(bs,color)
    raknetEmulRpcReceiveBitStream(84,bs)
    raknetDeleteBitStream(bs)
end

function removeObj(id)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs,id)
    raknetEmulRpcReceiveBitStream(47,bs)
    raknetDeleteBitStream(bs)
end

function createObj(id,model,pos,rot,draw,scale,colision,heading)

    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs,id)
    raknetBitStreamWriteInt32(bs,model)

    raknetBitStreamWriteFloat(bs,pos[1])
    raknetBitStreamWriteFloat(bs,pos[2])
    raknetBitStreamWriteFloat(bs,pos[3])  

    raknetBitStreamWriteFloat(bs,rot[1])
    raknetBitStreamWriteFloat(bs,rot[2])
    raknetBitStreamWriteFloat(bs,rot[3])
    raknetBitStreamWriteFloat(bs,draw)

    raknetEmulRpcReceiveBitStream(44,bs)
    raknetDeleteBitStream(bs)
    local obj = sampGetObjectHandleBySampId(id)

    setObjectRotation(obj, rot[1],rot[2],rot[3])
    setObjectScale(obj, scale)
    setObjectCollision(obj, colision)
    setObjectHeading(obj,heading)

end

function setRotationObject(id,rot)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs,id)
    raknetBitStreamWriteFloat(bs,rot[1])
    raknetBitStreamWriteFloat(bs,rot[2])
    raknetBitStreamWriteFloat(bs,rot[3])
    raknetEmulRpcReceiveBitStream(46,bs)
    raknetDeleteBitStream(bs)
end

function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 2.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 5.0
    style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0

    colors[clr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
    colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
    colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
    colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = colors[clr.PopupBg]
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end
apply_custom_style()

local origsampAddChatMessage = sampAddChatMessage
function sampAddChatMessage(text,...); origsampAddChatMessage((tostring(text)):format(...),-1); end