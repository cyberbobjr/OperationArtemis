-- Opération Artemis : fenêtre du journal (acte en cours et entrées datées, la plus récente en premier).

require "ISUI/ISCollapsableWindow"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"

local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"
local ClientState = require "Artemis/Artemis_ClientState"
local Guide = require "Artemis/Artemis_Guide"
local Trial = require "Artemis/Artemis_Trial"
local Const = require "Artemis/Artemis_Const"
local State = require "Artemis/Artemis_State"
local Extraction = require "Artemis/Artemis_Extraction"
local EndingUI = require "Artemis/Artemis_EndingUI"
local Sterilization = require "Artemis/Artemis_Sterilization"
local Plot = require "Artemis/Artemis_Plot"
local Quarantine = require "Artemis/Artemis_Quarantine"
local River = require "Artemis/Artemis_River"
local Boats = require "Artemis/Artemis_Boats"
local Vaccine = require "Artemis/Artemis_Vaccine"

local JournalUI = ISCollapsableWindow:derive("ArtemisJournalUI")
JournalUI.instance = nil

local WIDTH = 460
local HEIGHT = 520
local PADDING = 8
local BUTTON_HEIGHT = 24

-- Épreuve en cours (évasion du labo) : son objectif, en rouge.
local function appendTrial(parts, state)
    local chapter = Story.get(Story.EXIT_CHAPTER)
    if chapter and chapter.escape and Trial.isRunning(state.flags, Story.EXIT_CHAPTER) then
        parts[#parts + 1] = " <TEXT> <RGB:1,0.35,0.3> " .. getText(chapter.escape.objectiveKey)
            .. " <RGB:1,1,1> <LINE> <LINE> "
    end
end

-- Ligne d'objectif d'une route : nom de la route en ambre, puis le texte.
local function appendRoute(parts, labelKey, text)
    parts[#parts + 1] = " <TEXT> <RGB:0.85,0.7,0.4> " .. getText(labelKey) .. " <RGB:1,1,1> " .. text
        .. " <LINE> <LINE> "
end

-- Route B : appeler l'évacuation, puis le rendez-vous quotidien.
local function helicopterGoal(state)
    local called = Extraction.isCalled(State.flagValue(state, "extraction", Extraction.KEY))
    local key = called and "IGUI_Artemis_Exfil_Goal_Rendezvous" or "IGUI_Artemis_Exfil_Goal_Call"
    return getText(key, Config.radioFrequencyLabel())
end

-- Route A : bateaux de V (mod de bateau actif) ou passeur de Brandenburg.
local function riverGoal(state)
    if Boats.vBoatScript() ~= nil then
        return getText("IGUI_Artemis_Exfil_Goal_RiverBoat")
    end
    if Extraction.isCalled(State.flagValue(state, "extraction", Story.FERRY.key)) then
        return getText("IGUI_Artemis_Exfil_Goal_FerryRendezvous")
    end
    local isCut = River.isCut(State.flagValue(state, River.FLAG, "kinsella"))
    return getText("IGUI_Artemis_Exfil_Goal_Ferry", Config.radioFrequencyLabel())
        .. " " .. getText(isCut and "IGUI_Artemis_Exfil_KinsellaDark" or "IGUI_Artemis_Exfil_KinsellaLit")
end

-- Route C : test d'entrée, quarantaine, barrage ouvert ou refus.
local function checkpointGoal(state)
    local entry = State.flagValue(state, Quarantine.FLAG, getPlayer():getUsername())
    local phase = type(entry) == "table" and entry.phase or nil
    if phase == Quarantine.RUNNING then
        local left = math.max(0, entry.startHours + entry.hours - getGameTime():getWorldAgeHours())
        return getText("IGUI_Artemis_Exfil_Goal_Quarantine", tostring(math.ceil(left)))
    end
    if phase == Quarantine.PASSED then
        return getText("IGUI_Artemis_Exfil_Goal_CheckpointPassed")
    end
    local text = getText(Vaccine.isActive() and "IGUI_Artemis_Exfil_Goal_CheckpointVaccine"
        or "IGUI_Artemis_Exfil_Goal_Checkpoint")
    if phase == Quarantine.REFUSED then
        text = getText(Vaccine.isActive() and "IGUI_Artemis_Exfil_Goal_CheckpointRefusedCure"
            or "IGUI_Artemis_Exfil_Goal_CheckpointRefused") .. " " .. text
    elseif phase == Quarantine.CLEARED then
        text = getText("IGUI_Artemis_Exfil_Goal_CheckpointCleared")
    end
    return text
end

-- Acte III : les trois routes et leur état ; échéance de la stérilisation (option) en rouge.
local function appendExfiltration(parts, state)
    if state.act ~= Const.ACT.EXFILTRATION or Trial.isRunning(state.flags, Story.EXIT_CHAPTER) then return end
    parts[#parts + 1] = " <H2> " .. getText("IGUI_Artemis_Exfil_Title") .. " <LINE> "
    parts[#parts + 1] = " <TEXT> " .. getText("IGUI_Artemis_Exfil_Smoke") .. " <LINE> <LINE> "
    local entry = Sterilization.entry(state.flags)
    local nowHours = getGameTime():getWorldAgeHours()
    local stage = Sterilization.stage(entry, nowHours)
    if stage == Sterilization.STRUCK then
        parts[#parts + 1] = " <TEXT> <RGB:1,0.35,0.3> " .. getText("IGUI_Artemis_Sterilization_Struck")
            .. " <RGB:1,1,1> <LINE> <LINE> "
    elseif stage ~= nil then
        local days = math.max(1, Sterilization.daysLeft(entry, nowHours))
        local countdown = getText("IGUI_Artemis_Sterilization_Countdown", tostring(days))
        parts[#parts + 1] = " <TEXT> <RGB:1,0.35,0.3> " .. countdown .. " <RGB:1,1,1> <LINE> <LINE> "
    end
    if not Sterilization.closesRoute(state.flags, "B") then
        appendRoute(parts, "IGUI_Artemis_Exfil_Route_B", helicopterGoal(state))
    end
    appendRoute(parts, "IGUI_Artemis_Exfil_Route_A", riverGoal(state))
    if not Sterilization.closesRoute(state.flags, "C") then
        appendRoute(parts, "IGUI_Artemis_Exfil_Route_C", checkpointGoal(state))
    end
end

-- Chapitre en cours (acte II) : numéro, titre et objectif. Code d'appel une fois appris.
local function appendObjective(parts, state)
    appendTrial(parts, state)
    appendExfiltration(parts, state)
    local chapter = Story.get(state.chapter)
    if chapter then
        local ordinal = tostring(Plot.chapterOrdinal(state, state.chapter))
        parts[#parts + 1] = " <H2> " .. getText("IGUI_Artemis_ChapterTitle", ordinal,
            getText("IGUI_Artemis_" .. state.chapter .. "_Title")) .. " <LINE> "
        parts[#parts + 1] = " <TEXT> " .. getText("IGUI_Artemis_" .. state.chapter .. "_Goal") .. " <LINE> <LINE> "
    end
    -- Étape du guide selon l'étage du joueur local (grand lieu, comme la base secrète).
    local step = Guide.currentStep(getPlayer())
    if step then
        parts[#parts + 1] = " <TEXT> <RGB:0.85,0.7,0.4> " .. getText("IGUI_Artemis_GuideNow") .. " <RGB:1,1,1> "
            .. getText(step.key) .. " <LINE> <LINE> "
    end
    if state.callCode then
        parts[#parts + 1] = " <TEXT> <RGB:0.85,0.7,0.4> " .. getText("IGUI_Artemis_CallCode", state.callCode)
            .. " <RGB:1,1,1> <LINE> <LINE> "
    end
end

-- Les descriptions d'acte et les entrées du journal peuvent citer la fréquence (%1), réglable.
local function buildText(state)
    local frequency = Config.radioFrequencyLabel()
    local parts = {
        " <H1> ", getText("IGUI_Artemis_Title"), " <LINE> <LINE> ",
        " <H2> ", getText("IGUI_Artemis_Act" .. tostring(state.act)), " <LINE> ",
        " <TEXT> ", getText("IGUI_Artemis_ActDesc" .. tostring(state.act), frequency), " <LINE> <LINE> ",
    }
    appendObjective(parts, state)
    parts[#parts + 1] = " <H2> " .. getText("IGUI_Artemis_JournalHeader") .. " <LINE> "
    if #state.journal == 0 then
        parts[#parts + 1] = " <TEXT> " .. getText("IGUI_Artemis_JournalEmpty") .. " <LINE> "
    end
    for index = #state.journal, 1, -1 do
        local entry = state.journal[index]
        parts[#parts + 1] = " <TEXT> <RGB:0.85,0.7,0.4> " .. getText("IGUI_Artemis_Day", tostring(entry.day))
        parts[#parts + 1] = " <RGB:1,1,1> " .. getText(tostring(entry.key), frequency) .. " <LINE> "
    end
    return table.concat(parts)
end

function JournalUI:createChildren()
    ISCollapsableWindow.createChildren(self)
    local top = self:titleBarHeight() + PADDING
    local panel = ISRichTextPanel:new(PADDING, top, self.width - PADDING * 2,
        self.height - top - PADDING * 2 - BUTTON_HEIGHT)
    panel:initialise()
    panel.background = false
    panel.clip = true
    panel.autosetheight = false
    panel.marginRight = panel.marginLeft
    panel.anchorRight = true
    panel.anchorBottom = true
    self:addChild(panel)
    panel:addScrollBars()
    self.textPanel = panel
    -- Épilogue : relire l'écran de fin.
    local button = ISButton:new(PADDING, self.height - PADDING - BUTTON_HEIGHT, self.width - PADDING * 2, BUTTON_HEIGHT,
        getText("IGUI_Artemis_Ending_Replay"), self, JournalUI.onReplayEnding)
    button:initialise()
    button.anchorTop = false
    button.anchorBottom = true
    button.anchorRight = true
    self:addChild(button)
    self.endingButton = button
    self:refresh()
end

local function stepKey()
    local step = Guide.currentStep(getPlayer())
    return step and step.key or ""
end

function JournalUI:onReplayEnding()
    EndingUI.open(ClientState.get(), false, true)
end

function JournalUI:refresh()
    local state = ClientState.get()
    self.endingButton:setVisible(state.act == Const.ACT.DONE)
    self.shownRevision = state.rev
    self.shownStepKey = stepKey()
    self.textPanel.text = buildText(state)
    self.textPanel:paginate()
end

-- L'étape du guide se relit au plus deux fois par seconde (elle copie l'état du client).
local STEP_CHECK_MS = 500

function JournalUI:update()
    ISCollapsableWindow.update(self)
    local now = getTimestampMs()
    local isStepCheckDue = now - (self.lastStepCheckMs or 0) >= STEP_CHECK_MS
    if isStepCheckDue then
        self.lastStepCheckMs = now
    end
    if ClientState.revision() ~= self.shownRevision or (isStepCheckDue and stepKey() ~= self.shownStepKey) then
        self:refresh()
    end
end

function JournalUI:close()
    self:removeFromUIManager()
    if JournalUI.instance == self then
        JournalUI.instance = nil
    end
end

function JournalUI:new(x, y)
    local o = ISCollapsableWindow:new(x, y, WIDTH, HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.title = getText("IGUI_Artemis_Title")
    o:setResizable(true)
    return o
end

function JournalUI.toggle()
    if JournalUI.instance then
        JournalUI.instance:close()
        return
    end
    local x = math.floor((getCore():getScreenWidth() - WIDTH) / 2)
    local y = math.floor((getCore():getScreenHeight() - HEIGHT) / 2)
    local window = JournalUI:new(x, y)
    window:initialise()
    window:addToUIManager()
    JournalUI.instance = window
end

return JournalUI
