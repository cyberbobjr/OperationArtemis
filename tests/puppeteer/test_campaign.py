"""Lua plan contracts and collector file integration. No game execution/progress simulation."""
from pathlib import Path
import contextlib
import io
import json
import tempfile
import sys
from lupa import lua51
import collect_results as collector

ROOT=Path(__file__).resolve().parent
vm=lua51.LuaRuntime(unpack_returned_tuples=True)
factory=vm.execute((ROOT/'campagne_route.lua').read_text(encoding='utf-8'))
chapter=['ch5_base']
vm.globals().ModData=vm.table(get=lambda _key:vm.table(chapter=chapter[0]))
for route,finish in [('passeur','12_fin_passeur'),('helicoptere','10_fin_helicoptere'),('checkpoint','14_fin_checkpoint')]:
    entries=factory(vm.table(route=route,testSave='exact-test-name'))
    names=[]
    for i in range(1,len(entries)+1):
        entry=entries[i]
        file=ROOT/entry.path.split('/')[-1]
        assert file.exists(),file
        names.append(file.stem)
        assert entry.params.testSave=='exact-test-name'
    assert names[:5]==['01_chargement_carnet','02_signal_radio','03_bunker','04_clinique','05_relais']
    assert names[-2:]==[finish,'31_reference_rechargement']
    lab=entries[6]
    assert lab.when(vm.table()) is False and lab.skipReason
    chapter[0]='ch4_lab'; assert lab.when(vm.table()) is True; chapter[0]='ch5_base'
    assert '17_refus_radio_serveur' in names and '27_appel_sans_dossier' in names
    assert ('26_checkpoint_positif' in names)==(route=='checkpoint')
    assert '18_rendez_vous_manque' not in names
    assert entries[len(entries)-1].options.manualStop is False
    second=factory(vm.table(route=route))
    entries[1].params.testSave='modified-first'
    assert second[1].params.testSave is None
extra=factory(vm.table(route='helicoptere',missedRendezvous=True,negatives=False))
assert any(extra[i].path.endswith('18_rendez_vous_manque.lua') for i in range(1,len(extra)+1))
assert not any(extra[i].path.endswith('17_refus_radio_serveur.lua') for i in range(1,len(extra)+1))
reload_plan=vm.execute((ROOT/'campagne_rechargement.lua').read_text(encoding='utf-8'))(vm.table(testSave='reload-test'))
assert len(reload_plan)==1 and reload_plan[1].path.endswith('25_sauvegarde_rechargee.lua')

# Build the actual wrapper and suite through the engine; execute no scenario callback.
# Pure plan tests alone missed the nested loader guard encountered in the game.
engine_root=ROOT.parents[2]/'PZPuppeteer'
import importlib.util
spec=importlib.util.spec_from_file_location('engine_contracts',engine_root/'tests/run_tests.py')
engine_contracts=importlib.util.module_from_spec(spec); spec.loader.exec_module(engine_contracts)
for case in ('01_chargement_carnet','25_sauvegarde_rechargee'):
    engine_vm=engine_contracts.runtime()
    tests=engine_vm.execute((engine_root/'tests/test_batch.lua').read_text(encoding='utf-8'))
    tests.setup()
    engine_vm.globals().FILES['PZPuppet/scenarios/OperationArtemis/'+case+'.lua']=(ROOT/(case+'.lua')).read_text(encoding='utf-8')
    engine_vm.globals().FILES['PZPuppet/scenarios/OperationArtemis/suite.lua']=(ROOT/'suite.lua').read_text(encoding='utf-8')
    engine_vm.execute('PZPuppet.Debug={}')
    status=engine_vm.globals().PZPuppet.runFiles(engine_vm.table_from([engine_vm.table(path='OperationArtemis/'+case+'.lua')]))
    assert status.status=='running' and status.index==1
    assert engine_vm.globals().PZPuppet.lastReport.name=='OperationArtemis/'+case
    assert engine_vm.globals().PZPuppet.lastReport.steps[1].status=='pending'
    assert engine_vm.globals().EXECUTED==0

def file_integration(status='passed',namespace='OperationArtemis',outside_error=False,partial=False):
    with tempfile.TemporaryDirectory() as directory:
        root=Path(directory)/'project'; user=Path(directory)/'user'
        root.mkdir(); (user/'Lua/PZPuppet/reports').mkdir(parents=True)
        case='01_chargement_carnet' if namespace=='OperationArtemis' else 'porte_base'
        name=namespace+'/'+case
        row=dict(scenario=case,command=f'PZPuppet.runFile("OperationArtemis/{case}.lua",{{playerIndex=0}})',
                 preconditions='dedicated game',expected='actual action',observed='not executed',proof='none',status='non executed')
        (root/'manifest.json').write_text(json.dumps([row]),encoding='utf-8')
        raw=(f'PZPuppet 0.1.0\n{name} : {status}\nRun token: 100-2\nBatch token: 100-1\n'
             f'Batch index: 1\nPersistent report: PZPuppet/reports/100-2.txt\nPlayer index: 0\nManual stop: false\n').encode()
        (user/'Lua/PZPuppet/last-report.txt').write_bytes(raw)
        (user/'Lua/PZPuppet/reports/100-2.txt').write_bytes(raw[:-1] if partial else raw)
        console=(f'ERROR: Lua preexisting\n[PZPuppet] Batch 100-1 starting | count: 1\n'
                 f'[PZPuppet] Run token: 100-2 | batch: 100-1 | index: 1 | path: {name}.lua\n'
                 f'[PZPuppet] {name} [1/2] PRE\n[ArtemisPuppet] {case} save=dedicated-test build=42.21 act=0\n'
                 f'[PZPuppet] {name} : {status}\n')
        if outside_error: console+='ERROR: General KahluaThread.flushErrorMessage new exception\n'
        if status=='passed': console+='[PZPuppet] Batch archive requested: 100-2 | report: PZPuppet/reports/100-2.txt\n'
        (user/'console.txt').write_text(console,encoding='utf-8')
        old=(collector.ROOT,collector.USER,sys.argv)
        try:
            collector.ROOT=root; collector.USER=user
            sys.argv=['collect_results.py','--include-current']
            with contextlib.redirect_stdout(io.StringIO()): collector.main()
        finally: collector.ROOT,collector.USER,sys.argv=old
        ack=user/'Lua/PZPuppet/batch-ack.txt'
        if partial:
            assert not ack.exists() and not (root/'reports/runs').exists(); return
        runs=list((root/'reports/runs').iterdir()); assert len(runs)==1
        result=json.loads((runs[0]/'result.json').read_text(encoding='utf-8'))
        assert result['engine_status']==status and result['engine_metadata']['Batch index']=='1'
        assert 'manualStop=false' in result['command'] and 'testSave="dedicated-test"' in result['command']
        assert not result['new_errors']  # Preexisting and post-child errors aren't attributed to its actions.
        assert ack.exists()==(status=='passed')
        if status=='passed':
            assert ('rejected' in ack.read_text())==outside_error
            assert result['batch_archive_accepted']==(not outside_error)
            if namespace=='OperationArtemis':
                row=json.loads((root/'manifest.json').read_text(encoding='utf-8'))[0]
                assert row['status']==('\u00e9chou\u00e9' if outside_error else 'r\u00e9ussi')
                assert (root/'RESULTATS.md').exists()

file_integration()
file_integration(status='failed')
file_integration(outside_error=True)
file_integration(namespace='ArtemisDiagnostic')
file_integration(partial=True)
print('OFFLINE ONLY: route plans, two actual wrapper/suite batch constructions (no callbacks), five collector file integrations passed.')
