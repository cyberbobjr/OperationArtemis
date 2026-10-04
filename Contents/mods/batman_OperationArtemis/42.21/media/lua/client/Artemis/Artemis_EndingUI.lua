-- Opération Artemis : écran de victoire (fin de l'opération, décisions de la phase 4).
-- Plein écran, par-dessus le jeu : fondu au blanc, image, épilogue lu par V qui défile, puis la
-- chronique de la partie (Artemis_Chronicle) ; « Terminer » (chronique écrite dans un fichier, partie
-- sauvegardée, retour au menu) ou « Continuer » (la partie continue ; écran rouvrable depuis le journal).
-- Détails du moteur : .claude/pz-knowledge/ui-windows.md (« Écran plein écran pendant une pause solo »)
-- et sounds-and-noise.md (« Son pendant la pause solo ») :
-- - en solo, pause par setGameSpeed(0), réappliquée à chaque mise à jour (Échap et la touche Pause la
--   relancent) ; OnTick n'est plus appelé en pause : fondu et défilement vivent dans render ;
-- - voix et musique : un seul fichier par langue, joué par playMusic (non mis en pause) ; la musique
--   vanilla est coupée pendant l'écran (volume de la musique, l'option n'est pas modifiée) ; si l'option
--   « Musique » du joueur est à 0, le jeu ne joue rien (SoundManager.java:449) ;
-- - manette : boutons actifs en pause (activeWhilePaused, comme la carte du monde) ; A = premier bouton,
--   B = second (modèle ISPostDeathUI) ;
-- - Échap : le menu de pause s'afficherait sous cet écran toujours au premier plan ; l'écran se masque
--   tant que le menu est visible (OnPreUIDraw : update n'est pas appelé sur un élément masqué, OnTick
--   non plus en pause), et ses boutons sont sans effet pendant ce temps.

require "ISUI/ISPanelJoypad"
require "ISUI/ISRichTextPanel"
require "ISUI/ISButton"

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local State = require "Artemis/Artemis_State"
local Chronicle = require "Artemis/Artemis_Chronicle"
local Endings = require "Artemis/Artemis_Endings"
local EndingSafety = require "Artemis/Artemis_EndingSafety"

local EndingUI = ISPanelJoypad:derive("ArtemisEndingUI")
EndingUI.instance = nil

-- Image, morceau (voix de V sur « The First Light », un script de son par langue) et paragraphes de
-- l'épilogue dépendent de la fin obtenue (Artemis_Endings).
-- Durée du morceau : le texte défile sur toute sa longueur (même musique pour toutes les fins).
local MUSIC_SECONDS = 219
local FADE_MS = 2500
local TEXT_WIDTH_RATIO = 0.55
local BUTTON_WIDTH = 220
local BUTTON_HEIGHT = 32
local MARGIN = 24

local function isSolo()
    return not isClient()
end

local function endingOf(state)
    return State.flagValue(state, "ending", "result")
end

local function musicName(state)
    local language = Translator.getLanguage()
    local code = language and tostring(language:name()) or ""
    return Endings.soundName(endingOf(state), code)
end

local function pauseGame()
    if isSolo() then
        setShowPausedMessage(false)
        if getGameSpeed() ~= 0 then
            setGameSpeed(0)
        end
    end
end

-- Vitesse d'avant l'ouverture (relecture depuis le journal pendant une pause ou en accéléré).
local function resumeGame(previousSpeed)
    if isSolo() then
        setShowPausedMessage(true)
        setGameSpeed(previousSpeed or 1)
    end
end

local function isPauseMenuOpen()
    return MainScreen.instance ~= nil and MainScreen.instance:isReallyVisible()
end

local function epilogueText(state)
    local parts = { " <CENTRE> <SIZE:large> ", getText("IGUI_Artemis_Ending_Title"), " <LINE> ",
        " <SIZE:medium> ", getText(Endings.subtitleKey(endingOf(state))), " <LINE> <LINE> <LINE> <SIZE:medium> " }
    for _, key in ipairs(Endings.paragraphKeys(endingOf(state))) do
        parts[#parts + 1] = getText(key) .. " <LINE> <LINE> "
    end
    return table.concat(parts)
end

local function chronicleText(state)
    local lines = Chronicle.render(Chronicle.lines(state, Config.radioFrequencyLabel()), getText)
    local parts = { " <LINE> <LINE> <SIZE:medium> " }
    for index, line in ipairs(lines) do
        -- Première ligne : titre de la chronique.
        if index == 1 then
            parts[#parts + 1] = " <SIZE:large> " .. line .. " <SIZE:medium> <LINE> <LINE> "
        else
            parts[#parts + 1] = line .. " <LINE> "
        end
    end
    return table.concat(parts)
end

-- Chronique en texte brut dans Zomboid\Lua\OperationArtemis (encodage UTF-8, accents conservés).
local function writeChronicle(state)
    local ending = endingOf(state)
    if type(ending) ~= "table" then return nil end
    local name = Chronicle.fileName(getWorld():getWorld(), ending.day)
    local writer = getFileWriter(name, true, false)
    if not writer then return nil end
    writer:writeln(getText("IGUI_Artemis_Ending_Title"))
    writer:writeln("")
    for _, key in ipairs(Endings.paragraphKeys(ending)) do
        writer:writeln(getText(key))
        writer:writeln("")
    end
    for _, line in ipairs(Chronicle.render(Chronicle.lines(state, Config.radioFrequencyLabel()), getText)) do
        writer:writeln(line)
    end
    writer:close()
    return name
end

function EndingUI:createChildren()
    local textWidth = math.floor(self.width * TEXT_WIDTH_RATIO)
    local buttonsTop = self.height - BUTTON_HEIGHT - MARGIN
    local panel = ISRichTextPanel:new(math.floor((self.width - textWidth) / 2), MARGIN, textWidth,
        buttonsTop - MARGIN * 2)
    panel:initialise()
    panel.background = false
    panel.clip = true
    panel.autosetheight = false
    -- La molette revient à l'écran (défilement manuel), sinon le panneau la garderait.
    panel.blockMouseWheel = true
    panel.text = epilogueText(self.state) .. chronicleText(self.state)
    self:addChild(panel)
    panel:paginate()
    self.textPanel = panel

    local centerX = math.floor(self.width / 2)
    local buttons = {}
    if self.isReplay then
        buttons[1] = { key = "IGUI_Artemis_Ending_Close", onClick = EndingUI.onClose }
    else
        buttons[1] = { key = "IGUI_Artemis_Ending_Finish", onClick = EndingUI.onFinish }
        buttons[2] = { key = "IGUI_Artemis_Ending_Continue", onClick = EndingUI.onContinue }
    end
    local total = #buttons * BUTTON_WIDTH + (#buttons - 1) * MARGIN
    for index, spec in ipairs(buttons) do
        local x = centerX - math.floor(total / 2) + (index - 1) * (BUTTON_WIDTH + MARGIN)
        local button = ISButton:new(x, buttonsTop, BUTTON_WIDTH, BUTTON_HEIGHT, getText(spec.key), self, spec.onClick)
        button:initialise()
        self:addChild(button)
        spec.button = button
    end
    self.buttons = buttons
end

-- Part du morceau écoulée (0 à 1), d'après l'horloge réelle (le jeu est en pause).
function EndingUI:progress()
    local elapsed = getTimestampMs() - self.openedAtMs - (self.withFade and FADE_MS or 0)
    return math.max(0, math.min(1, elapsed / (MUSIC_SECONDS * 1000)))
end

function EndingUI:prerender()
    self:drawRect(0, 0, self.width, self.height, 1, 0.02, 0.03, 0.05)
    if self.image and self.image:isReady() then
        self:drawTextureScaledAspect(self.image, 0, 0, self.width, self.height, 1, 1, 1, 1)
    end
    -- Voile sombre sous le texte, pour la lisibilité.
    local panel = self.textPanel
    self:drawRect(panel.x - MARGIN, 0, panel.width + MARGIN * 2, self.height, 0.55, 0, 0, 0)
    -- Défilement : le texte monte au rythme du morceau (sauf si le joueur fait défiler lui-même).
    if not self.isManualScroll then
        local range = math.max(0, panel:getScrollHeight() - panel.height)
        panel:setYScroll(-range * self:progress())
    end
end

function EndingUI:render()
    ISPanelJoypad.render(self)
    if self.withFade then
        local elapsed = getTimestampMs() - self.openedAtMs
        if elapsed < FADE_MS then
            -- Fondu au blanc à l'ouverture (le fondu vanilla ne fait que le noir).
            local alpha = 1 - elapsed / FADE_MS
            self:drawRect(0, 0, self.width, self.height, alpha, 1, 1, 1)
        end
    end
end

function EndingUI:update()
    ISPanelJoypad.update(self)
    if not (MainScreen.instance and MainScreen.instance:isVisible()) then
        pauseGame()
    end
end

function EndingUI:onMouseWheel(delta)
    self.isManualScroll = true
    local panel = self.textPanel
    local range = math.max(0, panel:getScrollHeight() - panel.height)
    panel:setYScroll(math.max(-range, math.min(0, panel:getYScroll() - delta * 40)))
    return true
end

function EndingUI:onMouseDown()
    return true
end

function EndingUI:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self:setISButtonForA(self.buttons[1].button)
    if self.buttons[2] then
        self:setISButtonForB(self.buttons[2].button)
    end
end

function EndingUI:onJoypadBeforeDeactivate(joypadData)
    self:setISButtonForA(self.buttons[1].button)
    if self.buttons[2] then
        self:setISButtonForB(self.buttons[2].button)
    end
end

-- Masqué tant que le menu de pause (Échap) est affiché.
local function onPreUIDraw()
    local screen = EndingUI.instance
    if screen then
        screen:setVisible(not isPauseMenuOpen())
    end
end

function EndingUI:close()
    Events.OnPreUIDraw.Remove(onPreUIDraw)
    getSoundManager():stopMusic(self.music)
    getSoundManager():setMusicVolume(getCore():getOptionMusicVolume() / 10)
    self:removeFromUIManager()
    if EndingUI.instance == self then
        EndingUI.instance = nil
    end
    resumeGame(self.previousSpeed)
end

-- Terminer : chronique écrite, puis sauvegarde et retour au menu (exitToMenu sauvegarde, même en pause).
function EndingUI:onFinish()
    if isPauseMenuOpen() then return end
    local name = writeChronicle(self.state)
    Const.log("fin : chronique ecrite dans Zomboid/Lua/" .. tostring(name))
    self:close()
    getCore():exitToMenu()
end

-- Continuer : la partie continue (épilogue) ; le serveur retient ce choix pour ce joueur.
function EndingUI:onContinue()
    if isPauseMenuOpen() then return end
    local player = getPlayer()
    if player then
        sendClientCommand(player, Const.NET_MODULE, Const.COMMAND.CONTINUE_AFTER_ENDING, {})
    end
    self:close()
end

function EndingUI:onClose()
    if isPauseMenuOpen() then return end
    self:close()
end

function EndingUI:new(state, withFade, isReplay)
    local x, y = getPlayerScreenLeft(0), getPlayerScreenTop(0)
    local o = ISPanelJoypad:new(x, y, getPlayerScreenWidth(0), getPlayerScreenHeight(0))
    setmetatable(o, self)
    self.__index = self
    o.state = state
    o.withFade = withFade
    o.isReplay = isReplay
    o.openedAtMs = getTimestampMs()
    o.image = getTexture(Endings.image(endingOf(state)))
    o.music = musicName(state)
    o.moveWithMouse = false
    o.activeWhilePaused = true
    o.previousSpeed = getGameSpeed()
    return o
end

-- Ouvre l'écran (une seule fois à la fois). withFade : fondu au blanc (fin qui vient d'avoir lieu) ;
-- isReplay : ouvert depuis le journal après avoir choisi de continuer (seulement « Fermer »).
function EndingUI.open(state, withFade, isReplay)
    if EndingUI.instance then return end
    local player = getPlayer()
    -- Uniquement la présentation de victoire, jamais la relecture du journal.
    if not isReplay and not isClient() and not isServer() then
        local removed = EndingSafety.clearArrival(player)
        Const.log("fin : zone d'arrivee degagee (" .. removed .. " zombie(s), rayon " .. EndingSafety.RADIUS .. ")")
    end
    local screen = EndingUI:new(state, withFade, isReplay)
    screen:initialise()
    screen:addToUIManager()
    screen:setAlwaysOnTop(true)
    screen.javaObject:setIgnoreLossControl(true)
    EndingUI.instance = screen
    getSoundManager():setMusicVolume(0)
    getSoundManager():playMusic(screen.music)
    pauseGame()
    Events.OnPreUIDraw.Add(onPreUIDraw)
    if player and JoypadState.players[player:getPlayerNum() + 1] then
        setJoypadFocus(player:getPlayerNum(), screen)
    end
end

return EndingUI
