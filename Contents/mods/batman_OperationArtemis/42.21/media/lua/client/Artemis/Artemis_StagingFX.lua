-- Opération Artemis : effets de mise en scène côté client (joueur local).
-- Chaque type de repère a un seul gestionnaire ; les scènes sont dans Artemis_Scenes.

local Config = require "Artemis/Artemis_Config"
local Timeline = require "Artemis/Artemis_Timeline"

local StagingFX = {}

local THOUGHT_COLOR = { r = 0.85, g = 0.85, b = 0.75 }
-- UIManager.FadeOut/FadeIn convertissent la durée en secondes entières ; 0 donnerait un noir instantané.
local MIN_FADE_SECONDS = 1

-- Position d'un son : sur le joueur, ou au loin dans une direction au hasard.
local function soundPosition(cue, player)
    if cue.where ~= "far" then
        return player:getX(), player:getY(), player:getZ()
    end
    local angle = ZombRandFloat(0, 2 * math.pi)
    local distance = cue.distance or 50
    return player:getX() + math.cos(angle) * distance, player:getY() + math.sin(angle) * distance, 0
end

local function fadeSeconds(cue)
    return math.max(MIN_FADE_SECONDS, math.floor(cue.seconds or MIN_FADE_SECONDS))
end

-- Vrai entre un fondu au noir joué par le mod et le retour à l'image. UIManager.FadeIn part d'un
-- écran noir : lancé sans fondu préalable, il produirait lui-même un effet (option désactivée).
local isFadedOut = false

local HANDLERS = {
    -- Son 3D (FMOD) joué localement ; l'émetteur libre est rendu au moteur une fois le son fini.
    -- N'utiliser que des sons ponctuels (pas de son en boucle, comme RadioStatic).
    sound = function(cue, player)
        local x, y, z = soundPosition(cue, player)
        getWorld():getFreeEmitter(x, y, z):playSound(cue.name)
    end,

    -- Pensée affichée au-dessus du personnage, visible du seul joueur local. Une pensée d'aide
    -- (always = true) reste affichée même si l'option « Effets à l'écran » est désactivée.
    thought = function(cue, player)
        if not cue.always and not Config.screenEffectsEnabled() then return end
        player:addLineChatElement(getText(cue.key), THOUGHT_COLOR.r, THOUGHT_COLOR.g, THOUGHT_COLOR.b)
    end,

    -- Réveil (un cri dans l'enclos) : forceAwake ne fait que poser un drapeau lu par le client du
    -- joueur (IsoGameCharacter.java:2807-2811) ; on le pose donc ici, sur le personnage local.
    wake = function(_cue, player)
        if player:isAsleep() then
            player:forceAwake()
        end
    end,

    -- Fondu au noir : même méthode que le vanilla pour le sommeil (ISSleepDialog.lua:78-79).
    fadeOut = function(cue, player)
        if not Config.screenEffectsEnabled() then return end
        UIManager.setFadeBeforeUI(player:getPlayerNum(), true)
        UIManager.FadeOut(player:getPlayerNum(), fadeSeconds(cue))
        isFadedOut = true
    end,

    -- Retour à l'image, seulement si le mod a assombri l'écran ; exécuté même si l'option a été
    -- désactivée entre-temps, pour ne jamais laisser l'écran noir.
    -- Comme au réveil vanilla (SleepingEvent.java:416-417), setFadeBeforeUI reste à vrai.
    fadeIn = function(cue, player)
        if not isFadedOut then return end
        UIManager.FadeIn(player:getPlayerNum(), fadeSeconds(cue))
        isFadedOut = false
    end,
}

local timeline = Timeline.new(HANDLERS)

-- Joue la partie client d'une scène pour le joueur local.
function StagingFX.play(cues, player)
    if cues and player then
        timeline:play(cues, player)
    end
end

function StagingFX.update()
    timeline:update()
end

return StagingFX
