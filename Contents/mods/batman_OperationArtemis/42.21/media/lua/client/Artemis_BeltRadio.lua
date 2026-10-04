-- Artemis inscrit uniquement sa chaîne dans le gestionnaire commun de ceinture.
-- Le même gestionnaire fonctionne avec ou sans MilitaryDrop et laisse BWT
-- gérer la batterie et la VOIP quand il est actif.
local Const = require "Artemis/Artemis_Const"
local Support = require "BatmanRadio/BatmanRadio_Core"
BatmanArtemisBeltRadio = Support

local function channels()
    local radio = getZomboidRadio()
    local manager = radio and radio:getScriptManager()
    local channel = manager and manager:getRadioChannel(Const.RADIO.UUID)
    return channel and { channel } or {}
end

Support.register("OperationArtemis", { channels = channels })

return Support
