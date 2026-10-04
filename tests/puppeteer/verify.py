"""Static contract checks only. Does not execute game actions or simulate progression."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import re
import subprocess
from lupa import lua51

ROOT=Path(__file__).resolve().parent
ENGINE=ROOT.parents[2]/'PZPuppeteer/Contents/mods/batman_PZPuppeteer/42.21/media/lua/client/PZPuppet/PZPuppet_Core.lua'

def main():
    vm=lua51.LuaRuntime(unpack_returned_tuples=True)
    vm.execute(ENGINE.read_text(encoding='utf-8'))
    vm.execute('require=function() end; Events={OnDisconnect={Add=function() end}}')
    for file in ('PZPuppet_Game.lua','PZPuppet_Debug.lua'):
        vm.execute((ENGINE.parent/file).read_text(encoding='utf-8'))
    cases=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
    suite=vm.execute((ROOT/'suite.lua').read_text(encoding='utf-8'))
    forbidden=['debugCompleteChapter','DEBUG_ADVANCE','DEBUG_START','DEBUG_RESET','Progress.','Plot.','Store.save','ModData.add','ModData.getOrCreate']
    text=(ROOT/'suite.lua').read_text(encoding='utf-8')
    for token in forbidden: assert token not in text,token
    compile_only=vm.eval('function(source) local f,e=loadstring(source); assert(f,e); return true end')
    for path in ROOT.glob('*.lua'): compile_only(path.read_text(encoding='utf-8'))
    for row in cases:
        name=row['scenario']; wrapper=(ROOT/f'{name}.lua').read_text(encoding='utf-8')
        params=vm.table(case='14_fin_checkpoint' if name.startswith(('29_','30_')) else name,reportCase=name)
        a,b=suite(params),suite(params)
        assert a.name==f'OperationArtemis/{name}' and b.name==a.name
        assert a.steps!=b.steps and len(a.cleanups)>0 and len(a.steps)>0
        for i in range(1,len(a.steps)+1):
            step=a.steps[i]
            assert isinstance(step.label,str) and step.timeout>0 and step.timeout<40000
        assert 'return function(params)' in wrapper and ':run(' not in wrapper
    globals_=['PZPuppet','ModData','isClient','isServer','isDebugEnabled','getCore','getWorld','print',
              'getActivatedMods','getGameTime','getCell','instanceof','ISInventoryPaneContextMenu',
              'CharacterTrait','ISRadioAction','ISContextMenu','triggerEvent','getText','getTimestampMs',
              'Events','sendClientCommand','ISActivateGenerator','ISOpenCloseDoor','getZomboidRadio',
              'getScriptManager','SandboxVars','getFileReader','getFileWriter','instanceItem',
              'AdjacentFreeTileFinder','ISPathFindAction','ISTimedActionQueue','getGameSpeed','getSandboxOptions','CharacterStat','ISWorldObjectContextMenu']
    subprocess.run(['luacheck',str(ROOT/'suite.lua'),'--no-max-line-length','--no-unused','--no-unused-args',
                    '--globals',*globals_],check=True)
    # Require spelling must correspond to an observed local source, with exact path case.
    bases=[ROOT.parents[1]/'Contents/mods/batman_OperationArtemis/42.21/media/lua',
           Path('D:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua')]
    for ref in re.findall(r'require\s+"([^"]+)"',text):
        matches=[base/area/f'{ref}.lua' for base in bases for area in ('client','shared','server') if (base/area/f'{ref}.lua').exists()]
        assert matches,ref
        def exact(path):
            cursor=path.anchor
            for part in path.parts[1:]:
                directory=Path(cursor)
                if part not in {p.name for p in directory.iterdir()}: return False
                cursor=str(directory/part)
            return True
        assert any(exact(m) for m in matches),ref
    installed=Path('C:/Users/cyber/Zomboid/Lua/PZPuppet/scenarios/OperationArtemis')
    hashes={}
    for file in ROOT.glob('*.lua'):
        assert file.read_bytes()==(installed/file.name).read_bytes(),f'Loading copy differs: {file.name}'
        hashes[file.name]=hashlib.sha256(file.read_bytes()).hexdigest()
    validation=dict(checked_utc=datetime.now(timezone.utc).isoformat(),scenario_count=len(cases),
                    lua_files=len(hashes),syntax='Lua 5.1 compilation passed',
                    contracts='fresh factories, named steps, finite timeouts, finally',
                    lint='0 warnings / 0 errors',installed_copies_match=True,
                    in_game_execution=False,hashes=hashes)
    inspection=ROOT/'reports/inspection'
    inspection.mkdir(parents=True,exist_ok=True)
    (inspection/'validation-static.json').write_text(json.dumps(validation,indent=2),encoding='utf-8')
    print(f'STATIC ONLY: Lua 5.1 syntax, {len(cases)} fresh factories, named steps, bounded timeouts, finally and no progression shortcuts verified.')

if __name__=='__main__': main()
