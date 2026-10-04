-- Opération Artemis : motifs de clignotement des lampes (fonctions pures).
-- Un motif est périodique : pendant periodMs, la lampe est éteinte dans les fenêtres « off »
-- ({ début, fin } en millisecondes) et allumée le reste du temps. Un décalage propre à chaque lampe
-- (tiré de ses coordonnées) évite que toutes les lampes clignotent ensemble.

local Blink = {}

-- L'éclairage n'est recalculé qu'environ 15 fois par seconde, avec un fondu (.claude/pz-knowledge/
-- power-and-lights.md) : une coupure de moins de 0,2 s passe inaperçue (constaté en jeu). Les
-- coupures durent donc au moins 0,25 s.
Blink.PATTERNS = {
    -- Batteries qui faiblissent : de longues périodes allumées, puis deux ou trois ratés.
    failing = { periodMs = 6100, off = { { 1200, 1500 }, { 1700, 1950 }, { 4200, 4800 } } },
    -- Lampe de secours presque vide : un bref raté, puis une coupure plus longue.
    lowBattery = { periodMs = 5000, off = { { 3700, 3950 }, { 4100, 4350 }, { 4400, 4900 } } },
    -- Gyrophares d'alarme : 0,6 s allumé, 0,6 s éteint, toutes les lampes ensemble (sync).
    alarm = { periodMs = 1200, off = { { 600, 1200 } }, sync = true },
}

-- Nombres premiers : les coordonnées voisines donnent des décalages éloignés.
local OFFSET_FACTORS = { x = 7919, y = 104729, z = 1299709 }
-- Les étages vont jusqu'à -17 (base secrète) : on les ramène au positif avant le modulo, car dans
-- Kahlua « % » garde le signe du dividende (.claude/pz-knowledge/kahlua-lua.md).
local Z_SHIFT = 64

-- Décalage (0 à periodMs - 1) de la lampe placée en x, y, z ; 0 pour un motif synchronisé.
function Blink.offset(pattern, x, y, z)
    if pattern.sync then
        return 0
    end
    local value = x * OFFSET_FACTORS.x + y * OFFSET_FACTORS.y + (z + Z_SHIFT) * OFFSET_FACTORS.z
    return value % pattern.periodMs
end

-- La lampe est-elle allumée à l'instant nowMs (horloge positive), avec ce décalage ?
function Blink.isLit(pattern, nowMs, offset)
    local phase = (nowMs + offset) % pattern.periodMs
    for _, window in ipairs(pattern.off) do
        if phase >= window[1] and phase < window[2] then
            return false
        end
    end
    return true
end

-- Motif de ce nom, ou nil (lampe fixe).
function Blink.get(name)
    return name and Blink.PATTERNS[name] or nil
end

return Blink
