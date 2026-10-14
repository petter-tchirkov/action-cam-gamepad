local addonName = ...

local CENTER_CHARACTER_CVAR = "CameraKeepCharacterCentered"
local SHOULDER_OFFSET_CVAR = "test_cameraOverShoulder"
local DYNAMIC_PITCH_CVAR = "test_cameraDynamicPitch"
local PITCH_PAD_CVARS = {
    "test_cameraDynamicPitchBaseFovPad",
    "test_cameraDynamicPitchBaseFovPadFlying",
}

local HORIZONTAL_MIN, HORIZONTAL_MAX, HORIZONTAL_STEP = -5, 5, 0.1
local VERTICAL_MIN, VERTICAL_MAX, VERTICAL_STEP = 0, 1, 0.05

local defaults = {
    enabled = true,
    horizontalOffset = 1,
    verticalOffset = 0,
}

local settingsCategory
local centeringOverridden = false
local applyQueued = false

local function Print(message)
    print("|cff33ff99" .. addonName .. "|r: " .. message)
end

local function IsGamepadUIActive()
    return InputUtil and InputUtil.IsGamepadUIEnabled and InputUtil.IsGamepadUIEnabled()
end

local function SetCameraCVar(name, value)
    local current = tonumber(C_CVar.GetCVar(name))
    if current and math.abs(current - value) < 1e-4 then
        return
    end
    if not C_CVar.SetCVar(name, tostring(value)) then
        Print(string.format("could not set %s.", name))
    end
end

local function RemoveGamepadOverride()
    if centeringOverridden then
        C_CVar.RemoveTempCVar(CENTER_CHARACTER_CVAR)
        centeringOverridden = false
    end
end

local function Apply()
    if not ActionCamGamepadDB.enabled then
        RemoveGamepadOverride()
        return
    end

    if not IsGamepadUIActive() then
        return
    end

    if not centeringOverridden then
        C_CVar.SetTempCVar(CENTER_CHARACTER_CVAR, "0")
        centeringOverridden = true
    end
    SetCameraCVar(SHOULDER_OFFSET_CVAR, ActionCamGamepadDB.horizontalOffset)

    local verticalOffset = ActionCamGamepadDB.verticalOffset
    SetCameraCVar(DYNAMIC_PITCH_CVAR, verticalOffset > 0 and 1 or 0)
    if verticalOffset > 0 then
        for _, cvar in ipairs(PITCH_PAD_CVARS) do
            SetCameraCVar(cvar, verticalOffset)
        end
    end
end

local function IsMenuOpen()
    return (SettingsPanel and SettingsPanel:IsShown())
        or (GameMenuFrame and GameMenuFrame:IsShown())
end

local function FlushApply()
    if not applyQueued or IsMenuOpen() then
        return
    end
    applyQueued = false
    Apply()
end

local function QueueFlush()
    C_Timer.After(0, FlushApply)
end

local function QueueApply()
    applyQueued = true
    if not IsMenuOpen() then
        QueueFlush()
    end
end

local function HookMenuClose()
    for _, menu in ipairs({ SettingsPanel, GameMenuFrame }) do
        menu:HookScript("OnHide", QueueFlush)
    end
end

local function SetEnabled(enabled)
    ActionCamGamepadDB.enabled = enabled
    QueueApply()
end

local function SetOffset(key, value, minValue, maxValue)
    local offset = tonumber(value)
    if not offset or offset < minValue or offset > maxValue then
        return nil
    end

    ActionCamGamepadDB[key] = offset
    QueueApply()
    return offset
end

local function SetHorizontalOffset(value)
    return SetOffset("horizontalOffset", value, HORIZONTAL_MIN, HORIZONTAL_MAX)
end

local function SetVerticalOffset(value)
    return SetOffset("verticalOffset", value, VERTICAL_MIN, VERTICAL_MAX)
end

local function FormatOffset(value)
    return string.format("%.2f", value)
end

local function RegisterSettings()
    local category = Settings.RegisterVerticalLayoutCategory(addonName)

    local enabledSetting = Settings.RegisterProxySetting(category, "ACTIONCAMGAMEPAD_ENABLED",
        Settings.VarType.Boolean, "Enable camera offset", defaults.enabled,
        function() return ActionCamGamepadDB.enabled end, SetEnabled)
    Settings.CreateCheckbox(category, enabledSetting,
        "Apply the camera offsets while the Gamepad UI is active.")

    local horizontalSetting = Settings.RegisterProxySetting(category, "ACTIONCAMGAMEPAD_HORIZONTAL",
        Settings.VarType.Number, "Horizontal offset", defaults.horizontalOffset,
        function() return ActionCamGamepadDB.horizontalOffset end, SetHorizontalOffset)
    local horizontalOptions = Settings.CreateSliderOptions(HORIZONTAL_MIN, HORIZONTAL_MAX, HORIZONTAL_STEP)
    horizontalOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, FormatOffset)
    Settings.CreateSlider(category, horizontalSetting, horizontalOptions,
        "Moves the camera sideways. Negative values sit over the left shoulder; positive values over the right.")

    local verticalSetting = Settings.RegisterProxySetting(category, "ACTIONCAMGAMEPAD_VERTICAL",
        Settings.VarType.Number, "Vertical offset", defaults.verticalOffset,
        function() return ActionCamGamepadDB.verticalOffset end, SetVerticalOffset)
    local verticalOptions = Settings.CreateSliderOptions(VERTICAL_MIN, VERTICAL_MAX, VERTICAL_STEP)
    verticalOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, FormatOffset)
    Settings.CreateSlider(category, verticalSetting, verticalOptions,
        "Moves the character lower on the screen so you see more ahead. 0 keeps the character centered vertically.")

    Settings.RegisterAddOnCategory(category)
    return category
end

local transitionSubscriber = { addonName }

local function RegisterForGamepadTransitions()
    InputUtil.RegisterForInterfaceTransitions(transitionSubscriber)
    InputUtil.RegisterGamepadInit(transitionSubscriber, function()
        centeringOverridden = false
        QueueApply()
    end)
    InputUtil.RegisterGamepadUninit(transitionSubscriber, RemoveGamepadOverride)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" then
        if loadedAddon ~= addonName then
            return
        end

        ActionCamGamepadDB = ActionCamGamepadDB or {}
        for key, value in pairs(defaults) do
            if ActionCamGamepadDB[key] == nil then
                ActionCamGamepadDB[key] = value
            end
        end
        settingsCategory = RegisterSettings()
        HookMenuClose()
        RegisterForGamepadTransitions()
        frame:UnregisterEvent("ADDON_LOADED")
        return
    end

    QueueApply()
end)

local function HandleOffsetCommand(label, value, current, setter, minValue, maxValue)
    if not value then
        Print(string.format("%s offset is %.2f.", label, current))
        return
    end

    local offset = setter(value)
    if offset then
        Print(string.format("%s offset set to %.2f.", label, offset))
    else
        Print(string.format("%s offset must be a number from %g to %g.", label, minValue, maxValue))
    end
end

SLASH_ACTIONCAMGAMEPAD1 = "/acg"
SlashCmdList.ACTIONCAMGAMEPAD = function(message)
    local command = message:match("^%s*(%S*)"):lower()
    local value = message:match("^%s*%S+%s+(.-)%s*$")

    if command == "on" then
        SetEnabled(true)
        Print("enabled.")
    elseif command == "off" then
        SetEnabled(false)
        Print("disabled.")
    elseif command == "offset" or command == "horizontal" then
        HandleOffsetCommand("horizontal", value, ActionCamGamepadDB.horizontalOffset,
            SetHorizontalOffset, HORIZONTAL_MIN, HORIZONTAL_MAX)
    elseif command == "vertical" then
        HandleOffsetCommand("vertical", value, ActionCamGamepadDB.verticalOffset,
            SetVerticalOffset, VERTICAL_MIN, VERTICAL_MAX)
    elseif command == "apply" then
        Apply()
        Print(ActionCamGamepadDB.enabled and "settings applied." or "disabled; use /acg on to enable.")
    elseif command == "config" or command == "options" then
        Settings.OpenToCategory(settingsCategory:GetID())
    else
        local state = ActionCamGamepadDB.enabled and "enabled" or "disabled"
        Print(string.format("is %s; horizontal %.2f, vertical %.2f. Commands: /acg config, /acg on, /acg off, /acg horizontal <-5..5>, /acg vertical <0..1>, /acg apply",
            state, ActionCamGamepadDB.horizontalOffset, ActionCamGamepadDB.verticalOffset))
    end
end
