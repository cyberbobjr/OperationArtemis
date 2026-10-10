-- Artemis inscrit uniquement sa chaîne dans le gestionnaire commun de ceinture : Belt Walkie-Talkie
-- (batman_BeltRadio) s'il est activé, sinon la copie de secours embarquée (Artemis_RadioLib) ; même
-- globale BatmanRadioSupport dans les deux cas. Le même gestionnaire fonctionne avec ou sans
-- Military Drop et laisse BWT gérer la batterie et la VOIP quand il est actif.
local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local RadioLib = require "Artemis/Artemis_RadioLib"
-- Charge le récepteur (mod commun ou copie de secours) avant l'inscription.
local Support = RadioLib.receiver()
BatmanArtemisBeltRadio = Support

local function channels()
    local radio = getZomboidRadio()
    local manager = radio and radio:getScriptManager()
    local channel = manager and manager:getRadioChannel(Const.RADIO.UUID)
    return channel and { channel } or {}
end

-- Fréquence de la chaîne connue de tout client (option sandbox), pour la bulle MP
-- d'un talkie à la ceinture : sur un client MP, channels() est vide (gestionnaire nil).
local function frequencies()
    local color = Const.RADIO.LINE_COLOR
    return { { frequency = Config.radioFrequency(), r = color.r, g = color.g, b = color.b } }
end

local PROVIDER = { channels = channels, frequencies = frequencies }

-- Inscription auprès du gestionnaire ; false s'il n'est pas (encore) chargé.
local function register()
    local support = BatmanRadioSupport
    if not (support and support.register) then
        return false
    end
    support.register("OperationArtemis", PROVIDER)
    BatmanArtemisBeltRadio = support
    return true
end

if not register() then
    -- Gestionnaire absent au chargement (ordre inattendu) : nouvel essai au début de la partie.
    Events.OnGameStart.Add(function()
        if not register() then
            Const.log("WARN: shared walkie-talkie receiver (BatmanRadioSupport) not loaded;"
                .. " belt walkie-talkie features are unavailable.")
        end
    end)
end

return Support
