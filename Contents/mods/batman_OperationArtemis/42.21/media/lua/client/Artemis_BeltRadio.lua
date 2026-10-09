-- Artemis inscrit uniquement sa chaîne dans le gestionnaire commun de ceinture.
-- Le même gestionnaire fonctionne avec ou sans MilitaryDrop et laisse BWT
-- gérer la batterie et la VOIP quand il est actif.
local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Support = require "BatmanRadio/BatmanRadio_Core"
BatmanArtemisBeltRadio = Support

local function channels()
    local radio = getZomboidRadio()
    local manager = radio and radio:getScriptManager()
    local channel = manager and manager:getRadioChannel(Const.RADIO.UUID)
    return channel and { channel } or {}
end

-- Fréquence de la chaîne connue de tout client (option sandbox), pour la bulle MP
-- d'une radio non tenue : sur un client MP, channels() est vide (gestionnaire nil).
local function frequencies()
    local color = Const.RADIO.LINE_COLOR
    return { { frequency = Config.radioFrequency(), r = color.r, g = color.g, b = color.b } }
end

Support.register("OperationArtemis", { channels = channels, frequencies = frequencies })

return Support
