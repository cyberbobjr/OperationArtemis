"""Tests Lua d'Opération Artemis, sans lancer le jeu.

    python tests/run_lua_tests.py

1. syntaxe Lua 5.1 de tous les fichiers Lua du mod (Kahlua suit Lua 5.1) ;
2. copie de secours de Belt Walkie-Talkie (Artemis/BeltRadioFallback) identique à ce qu'en
   génère ../BeltRadio/tools/sync_fallback.py (ignoré sans le dépôt BeltRadio) ;
3. cas de test tests/lua/test_*.lua sous lupa : chaque cas tourne dans un runtime
   neuf, l'API du jeu est simulée par le fichier de test, les fichiers du mod sont
   chargés avec loadMod() ou require "Artemis/...", les fichiers vanilla avec
   loadVanilla() (cas ignorés si le jeu est absent ; variable PZ_MEDIA).

Dépendance : pip install lupa.
"""

import os
import sys
from pathlib import Path

try:
    from lupa import lua51 as lupa_module
except ImportError:  # lupa sans Lua 5.1 : version par défaut
    import lupa as lupa_module

LuaError = lupa_module.LuaError

REPO = Path(__file__).resolve().parent.parent
MOD_LUA = REPO / "Contents" / "mods" / "batman_OperationArtemis" / "42.21" / "media" / "lua"
PZ_MEDIA = Path(os.environ.get("PZ_MEDIA", r"D:\SteamLibrary\steamapps\common\ProjectZomboid\media"))
VANILLA_LUA = PZ_MEDIA / "lua"
TESTS = Path(__file__).resolve().parent / "lua"
WORKSPACE = REPO.parent
BELT_RADIO_TOOL = WORKSPACE / "BeltRadio" / "tools" / "sync_fallback.py"

PRELUDE = r"""
-- Kahlua n'a pas next() (pairs fonctionne sans elle).
next = nil
print = function() end
local compile = loadstring or load

local function run(source, name)
    local chunk, err = compile(source, "@" .. name)
    if not chunk then error(err, 3) end
    return chunk()
end

function loadMod(rel)
    local source = readModFile(rel)
    if not source then error("fichier du mod introuvable : " .. rel, 2) end
    return run(source, rel)
end

--- Fichier vanilla (lua/...) ; false si le jeu n'est pas installé.
function loadVanilla(rel)
    local source = readVanillaFile(rel)
    if not source then return false end
    run(source, "vanilla/" .. rel)
    return true
end

-- require du jeu : module du mod (shared, server puis client), sinon fichier vanilla
-- (shared, client, server), chargé une fois.
local loaded = {}
require = function(name)
    if loaded[name] ~= nil then return loaded[name] end
    for _, scope in ipairs({ "shared/", "server/", "client/" }) do
        if readModFile(scope .. name .. ".lua") then
            loaded[name] = loadMod(scope .. name .. ".lua") or true
            return loaded[name]
        end
    end
    for _, scope in ipairs({ "shared/", "client/", "server/" }) do
        if loadVanilla(scope .. name .. ".lua") then
            loaded[name] = true
            return true
        end
    end
    loaded[name] = true
    return true
end

--- Module déjà fourni par le test (simulation) : require ne charge plus le fichier.
function preloadModule(name, value)
    loaded[name] = value
end

function assertEq(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s : attendu %s, obtenu %s", message or "assertEq",
            tostring(expected), tostring(actual)), 2)
    end
end

function assertTrue(value, message)
    if not value then error(message or "assertTrue", 2) end
end
"""


def _read(base, rel):
    path = base / rel
    return path.read_text(encoding="utf-8", errors="replace") if path.is_file() else None


def new_runtime():
    lua = lupa_module.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.readModFile = lambda rel: _read(MOD_LUA, rel)
    # Fichier d'un autre projet du même dossier (Military Drop...) ; nil s'il est absent.
    g.readSiblingFile = lambda project, rel: _read(WORKSPACE / str(project), rel)
    g.readVanillaFile = lambda rel: _read(VANILLA_LUA, rel)
    g.hasVanilla = VANILLA_LUA.is_dir()
    lua.execute(PRELUDE)
    return lua


def syntax_errors():
    lua = lupa_module.LuaRuntime()
    compile_ = lua.eval("loadstring or load")
    errors = []
    for path in sorted(MOD_LUA.rglob("*.lua")):
        result = compile_(path.read_text(encoding="utf-8", errors="replace"), "@" + path.name)
        if isinstance(result, tuple) and result[0] is None:
            errors.append(f"{path.relative_to(REPO)} : {result[1]}")
    return errors


def fallback_errors():
    """Écarts de la copie de secours de Belt Walkie-Talkie ; None si le dépôt BeltRadio est absent."""
    errors = [f"{scope}/BatmanRadio : chemin du mod commun, masquerait Belt Walkie-Talkie"
              for scope in ("client", "shared", "server") if (MOD_LUA / scope / "BatmanRadio").exists()]
    if not BELT_RADIO_TOOL.is_file():
        return errors or None
    sys.path.insert(0, str(BELT_RADIO_TOOL.parent))
    try:
        import sync_fallback  # noqa: E402
    finally:
        sys.path.pop(0)
    return errors + [e + " (python ../BeltRadio/tools/sync_fallback.py OperationArtemis)"
                     for e in sync_fallback.check("OperationArtemis")]


def run_file(path):
    source = path.read_text(encoding="utf-8")
    cases = new_runtime().execute(source)
    skip = cases["skip"]
    names = sorted(str(k) for k in cases.keys() if k not in ("setup", "skip"))
    results = []
    for name in names:
        if skip:
            results.append((name, str(skip), True))
            continue
        lua = new_runtime()
        try:
            test_cases = lua.execute(source)
            if test_cases["setup"]:
                test_cases["setup"]()
            test_cases[name]()
            results.append((name, None, False))
        except LuaError as error:
            results.append((name, str(error), False))
    return results


def main():
    failures = 0
    errors = syntax_errors()
    for error in errors:
        print("SYNTAXE", error)
    failures += len(errors)
    fallback = fallback_errors()
    if fallback is None:
        print("IGNORÉ copie de secours Belt Walkie-Talkie (dépôt BeltRadio absent)")
    for error in fallback or []:
        print("ÉCHEC  copie de secours :", error)
    failures += len(fallback or [])
    passed = skipped = 0
    for path in sorted(TESTS.glob("test_*.lua")):
        for name, error, was_skipped in run_file(path):
            if was_skipped:
                skipped += 1
                print(f"IGNORÉ {path.name}:{name} ({error})")
            elif error:
                failures += 1
                print(f"ÉCHEC  {path.name}:{name}\n       {error}")
            else:
                passed += 1
    print(f"{passed} cas réussis, {skipped} ignorés, {failures} échecs")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
