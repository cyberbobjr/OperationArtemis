"""Report command reconstruction only; no game API or progression simulated."""
from pathlib import Path
import json
from lupa import lua51
from collect_results import run_command, completed_segment

root=Path(__file__).resolve().parent
lua=lua51.LuaRuntime()
compile_only=lua.eval('function(s) local f,e=loadstring(s); assert(f,e) end')
old='PZPuppet.runFile("OperationArtemis/03_bunker.lua",{playerIndex=0},{testSave="old",resume=true})'
fresh=run_command(old,'PZPuppet_Artemis_Negatifs',False)
assert 'resume=' not in fresh and 'old' not in fresh and 'PZPuppet_Artemis_Negatifs' in fresh
compile_only(fresh)
resumed=run_command(fresh,'new-save',True)
assert resumed.count('resume=true')==1 and 'Negatifs' not in resumed
compile_only(resumed)
custom='PZPuppet.runFile("OperationArtemis/21_computer_contenus.lua",{playerIndex=0},{laptop=true,testSave="old",resume=true})'
assert 'laptop=true' in run_command(custom,'new',False)
param=run_command('PZPuppet.runFile("OperationArtemis/14_fin_checkpoint.lua",{playerIndex=0},{completedQuarantine=true})','test',False)
assert 'completedQuarantine' not in param
param=run_command(param,'test',False,{'completedQuarantine':True})
assert 'completedQuarantine=true' in param
compile_only(param)
logs='step\nERROR: Lua during run\n[PZPuppet] OperationArtemis/14_fin_checkpoint : passed\nERROR: Lua new startup\n'
segment=completed_segment(logs,'OperationArtemis/14_fin_checkpoint','passed')
assert 'during run' in segment and 'new startup' not in segment
assert completed_segment(logs,'OperationArtemis/13_entree_checkpoint','passed')==logs
for row in json.loads((root/'manifest.json').read_text(encoding='utf-8')):
    for resume in (False,True):
        compile_only(run_command(row['command'],'PZPuppet_Artemis_Negatifs',resume))
print('Report-only checks passed: fresh/resumed save guards and all manifest commands compile.')
