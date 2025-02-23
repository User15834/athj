script_name("ATools Crash Monitor")
script_version("1.1")
local imgui = require 'mimgui'
local encoding = require 'encoding'
local u8 = encoding.UTF8
encoding.default = 'CP1251'

imgui.OnInitialize(function()
    local mainFont = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 14, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.GetIO().FontDefault = mainFont
    imgui.DarkTheme() 
end)

local state = {
    window = {
        crashReport = imgui.new.bool(false),
    },
    crashInfo = {
        message = "",
        time = "",
    }
}

function onSystemMessage(msg, type, script)
    if msg:find("ATools") and type == 3 then 
        state.crashInfo.message = msg
        state.crashInfo.time = getCurrentDateTime()
        state.window.crashReport[0] = true 
    end
end

function getCurrentDateTime()
    local localTime = os.time()
    local utcTime = os.time(os.date("!*t", localTime))
    local localOffset = os.difftime(localTime, utcTime)

    local moscowOffset = 3 * 3600
    local moscowTime = localTime + moscowOffset - localOffset

    local currentDateTime = os.date("*t", moscowTime)
    local hours = string.format("%02d", currentDateTime.hour)
    local minutes = string.format("%02d", currentDateTime.min)
    local seconds = string.format("%02d", currentDateTime.sec)
    local day = string.format("%02d", currentDateTime.day)
    local month = string.format("%02d", currentDateTime.month)
    local year = string.format("%04d", currentDateTime.year)

    return hours .. ":" .. minutes .. ":" .. seconds .. " | " .. day .. "." .. month .. "." .. year
end

function reloadMainScript()
    local mainScriptName = "ATools 4.0.0 pb.lua"
    
    if doesFileExist(getGameDirectory() .. "\\moonloader\\" .. mainScriptName) then
        scr = script.find(mainScriptName)
        scr:reload()
    else
        sampAddChatMessage("{FF6A61}[ATools]{FFFFFF} Основной скрипт не найден: " .. mainScriptName, -1)
    end
end

function openMoonloaderFolder()
    local gameDirectory = getGameDirectory()
    local moonloaderPath = gameDirectory .. "\\moonloader"
    
    os.execute('explorer "' .. moonloaderPath .. '"')
end

function sendErrorReport()
    sampAddChatMessage("{4682B4}[ATools]{FFFFFF} Отчёт об ошибке отправлен разработчику.", -1)
end

imgui.OnFrame(function() return state.window.crashReport[0] end, function()
    imgui.SetNextWindowPos(imgui.ImVec2(950, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(600, 400), imgui.Cond.FirstUseEver)
    
    imgui.Begin(u8"ATools - Система Мониторинга Ошибок", state.window.crashReport, 
        imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove)

    imgui.CenterTextColoredRGB("{FFFFFF}Произошла {FF6A61}ошибка{FFFFFF} в процессе работы {4682B4}ATools{FFFFFF}")
    imgui.Spacing()

    imgui.TextColoredRGB("{FFFFFF}Время ошибки: {4682B4}" .. state.crashInfo.time)
    imgui.Spacing()

    imgui.TextColoredRGB("{FFFFFF}Описание ошибки:")
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 0.5, 0.5, 1)) 
    imgui.TextWrapped(state.crashInfo.message)
    imgui.PopStyleColor()

    if imgui.IsItemHovered() then
        imgui.SetTooltip(u8"Нажмите, чтобы скопировать ошибку в буфер обмена")
        if imgui.IsMouseClicked(0) then
            imgui.SetClipboardText(state.crashInfo.message)
        end
    end

    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    if imgui.Button(u8"Закрыть", imgui.ImVec2(-1, 30)) then
        state.window.crashReport[0] = false
    end

    imgui.End()
end)

function imgui.CenterTextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end

            -- Calculate total width of the text
            local total_width = 0
            if text[0] then
                for i = 0, #text do
                    total_width = total_width + imgui.CalcTextSize(u8(text[i])).x
                end
            else
                total_width = imgui.CalcTextSize(u8(w)).x
            end

            -- Set cursor position to center
            local window_width = imgui.GetWindowWidth()
            imgui.SetCursorPosX((window_width - total_width) / 2)

            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else 
                imgui.Text(u8(w)) 
            end
        end
    end
    render_text(text)
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(text)
end

function imgui.DarkTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()

    style.WindowPadding = imgui.ImVec2(6, 6)
    style.FramePadding = imgui.ImVec2(5, 5)
    style.ItemSpacing = imgui.ImVec2(6, 6)
    style.ItemInnerSpacing = imgui.ImVec2(5, 5)
    style.TouchExtraPadding = imgui.ImVec2(0, 0)
    style.IndentSpacing = 10
    style.ScrollbarSize = 12
    style.GrabMinSize = 10

    style.WindowBorderSize = 1
    style.ChildBorderSize = 1
    style.PopupBorderSize = 1
    style.FrameBorderSize = 0
    style.TabBorderSize = 1

    style.WindowRounding = 8
    style.ChildRounding = 6
    style.FrameRounding = 6
    style.PopupRounding = 8
    style.ScrollbarRounding = 6
    style.GrabRounding = 8
    style.TabRounding = 6

    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    style.SelectableTextAlign = imgui.ImVec2(0.0, 0.5)

    local colors = style.Colors
    colors[imgui.Col.Text] = imgui.ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[imgui.Col.PopupBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    colors[imgui.Col.Border] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.24, 0.24, 0.24, 1.00)
    colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    colors[imgui.Col.CheckMark] = imgui.ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    colors[imgui.Col.Button] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.24, 0.24, 0.24, 1.00)
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    colors[imgui.Col.Header] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.24, 0.24, 0.24, 1.00)
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    colors[imgui.Col.Tab] = imgui.ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[imgui.Col.TabHovered] = imgui.ImVec4(0.24, 0.24, 0.24, 1.00)
    colors[imgui.Col.TabActive] = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
end

