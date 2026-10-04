"""Archive real PZPuppeteer reports and per-run console tails. No game control or save writes."""
from pathlib import Path
from datetime import datetime
import argparse
import hashlib
import json
import re
import time
import sys

ROOT=Path(__file__).resolve().parent
USER=Path('C:/Users/cyber/Zomboid')
sys.path.insert(0,str(ROOT.parents[2]/'PZPuppeteer/tools'))
from collect_reports import report_metadata, acknowledge, lua_errors

def run_command(command, save, resumed, parameters=None, options=None):
    """Rebuild only per-run guards; never carry an old save or resume into a new run."""
    match=re.fullmatch(r'(PZPuppet\.runFile\("[^"]+",\{[^{}]*\})(?:,\{([^{}]*)\})?\)',command)
    if not match:
        raise ValueError('Unexpected command shape: '+command)
    fields=[f.strip() for f in (match.group(2) or '').split(',') if f.strip()
            and not re.match(r'^(?:testSave|resume|deferDossierRead|infectionFixture|depositDossier|prepareSterilization|completedQuarantine)\s*=',f.strip())]
    if save:
        fields.append('testSave='+json.dumps(save,ensure_ascii=False))
    if resumed:
        fields.append('resume=true')
    for key,value in (parameters or {}).items():
        fields.append(key+'='+('true' if value else 'false'))
    prefix=match.group(1)
    if options:
        player_index=options.get('Player index')
        manual_stop=options.get('Manual stop')
        values=[]
        if player_index is not None:
            assert re.fullmatch(r'[0-3]',player_index)
            values.append('playerIndex='+player_index)
        if manual_stop is not None:
            assert manual_stop in ('true','false')
            values.append('manualStop='+manual_stop)
        if values:
            prefix=re.sub(r'\{[^{}]*\}$','{'+','.join(values)+'}',prefix)
    return prefix+(',{'+','.join(fields)+'}' if fields else '')+')'

def completed_segment(segment, name, status):
    # A return to the menu may log another f:0 initialization before collection.
    # Keep it in the session context, not in the completed scenario's error count.
    end=re.search(r'\[PZPuppet\] '+re.escape(name)+r' : '+re.escape(status)+r'[^\r\n]*',segment)
    return segment[:end.end()]+'\n' if end else segment

def write_results(manifest):
    (ROOT/'manifest.json').write_text(json.dumps(list(manifest.values()),ensure_ascii=False,indent=2),encoding='utf-8')
    table=['# Campagne PZPuppeteer — Operation Artemis','',
           'Statuts fondés sur les rapports de cette campagne; les erreurs restent à attribuer.','',
           '| Scénario | Préconditions | Commande | Résultat attendu | Résultat observé | Preuve | Statut |',
           '|---|---|---|---|---|---|---|']
    for r in manifest.values():
        table.append(f'| {r["scenario"]} | {r["preconditions"]} | `{r["command"]}` | {r["expected"]} | {r["observed"]} | [{r["proof"]}]({r["proof"]}) | {r["status"]} |')
    (ROOT/'RESULTATS.md').write_text('\n'.join(table)+'\n',encoding='utf-8')

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--watch',action='store_true')
    parser.add_argument('--include-current',action='store_true',help='Also archive the current real report if its scenario start is present in console.txt')
    parser.add_argument('--seconds',type=float,default=0)
    args=parser.parse_args()
    console=USER/'console.txt'; report=USER/'Lua/PZPuppet/last-report.txt'
    offset=console.stat().st_size if console.exists() and not args.include_current else 0
    fingerprint=(report.stat().st_mtime_ns,hashlib.sha256(report.read_bytes()).hexdigest()) if report.exists() and not args.include_current else None
    runlog=bytearray(); active=None; signature=None
    runstart=0; processed=0; pending_ack=None
    started=time.monotonic()
    manifest={r['scenario']:r for r in json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))}
    print('Watching executions; include current report='+str(args.include_current)+'. Never launch the next case until its archive appears.',flush=True)
    while True:
        if console.exists():
            size=console.stat().st_size
            with console.open('rb') as handle:
                head=handle.read(256)
                if size<offset or (signature is not None and head!=signature):
                    offset=0; runlog=bytearray(); active=None; runstart=0; processed=0; pending_ack=None
                signature=head
                handle.seek(offset); data=handle.read()
            offset+=len(data); runlog.extend(data)
            decoded=runlog.decode('utf-8',errors='replace').replace('\x00','')
            # Scan a line only once; avoid a stale start superseding the next running case.
            for m in re.finditer(r'\[PZPuppet\] ((?:OperationArtemis|ArtemisDiagnostic)/[a-z0-9_]+) \[1/\d+\]',decoded):
                if m.start()>=processed:
                    active=m.group(1); runstart=m.start()
            last_newline=decoded.rfind('\n')
            if last_newline>=0: processed=last_newline+1
        if report.exists():
            raw=report.read_bytes(); digest=(report.stat().st_mtime_ns,hashlib.sha256(raw).hexdigest())
            text=raw.decode('utf-8',errors='replace')
            metadata=report_metadata(raw)
            # New engine batches wait for this exact completed report to be archived.
            # Never read an early partial PrintWriter output as a terminal report.
            if metadata and metadata['fields'].get('Run token'):
                token=metadata['fields'].get('Run token')
                relative=metadata['fields'].get('Persistent report')
                if not re.fullmatch(r'\d+-\d+',token) or relative!=f'PZPuppet/reports/{token}.txt':
                    raise ValueError('Invalid persistent report metadata')
                decoded=runlog.decode('utf-8',errors='replace').replace('\x00','')
                persistent=USER/'Lua'/str(relative)
                requested=f'[PZPuppet] Batch archive requested: {token} | report: {relative}' in decoded
                batch=metadata['fields'].get('Batch token')
                finished=f'[PZPuppet] {metadata["name"]} : {metadata["status"]}' in decoded
                if (batch and metadata['status']=='passed' and not requested) or not finished or not persistent.is_file() or persistent.read_bytes()!=raw:
                    if not args.watch or (args.seconds and time.monotonic()-started>=args.seconds): break
                    time.sleep(0.25)
                    continue
            match=re.search(r'^(OperationArtemis|ArtemisDiagnostic)/([a-z0-9_]+) : (passed|failed|cancelled)$',text,re.M)
            if digest!=fingerprint and match and '/'.join(match.groups()[:2])==active:
                namespace,case,status=match.groups()
                stamp=datetime.now().strftime('%Y%m%d_%H%M%S_%f')
                document_case=('diagnostic_'+case) if namespace=='ArtemisDiagnostic' else case
                out=ROOT/'reports/runs'/f'{stamp}_{document_case}'; out.mkdir(parents=True)
                evidence_path=out.relative_to(ROOT/'reports').as_posix()
                segment=runlog.decode('utf-8',errors='replace').replace('\x00','')[runstart:]
                segment=completed_segment(segment,active,status)
                # Preserve report metadata edited while a long game test is running.
                manifest={r['scenario']:r for r in json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))}
                row=manifest[case] if namespace=='OperationArtemis' else dict(
                    command=f'PZPuppet.runFile("OperationArtemis/diagnostic_{case}.lua",{{playerIndex=0}})',
                    preconditions='Solo debug 42.21; dedicated test save; see diagnostic source guards',
                    expected='Diagnostic observations only; a pass does not validate a nominal route')
                environment=re.search(r'\[ArtemisPuppet\] \S+ save=(.*?) build=(\S+) act=',segment)
                resumed='PRE: resume real' in segment
                parameters={}
                if case=='07_archives_portique' and 'Read through vanilla inventory callback: batman_Artemis.ArtemisDossier' not in text:
                    parameters['deferDossierRead']=True
                if case=='26_checkpoint_positif' and 'SETUP: temporary real body infection only' in text:
                    parameters['infectionFixture']=True
                if case=='27_appel_sans_dossier' and 'Drop actual dossier through vanilla inventory callback' in text:
                    parameters['depositDossier']=True
                if case=='19_sterilisation' and 'SETUP: one-day sterilization option before real dossier reading' in text:
                    parameters['prepareSterilization']=True
                if 'PRE: quarantine already naturally passed before scenario, still inside pen' in text:
                    parameters['completedQuarantine']=True
                effective_command=run_command(row['command'],environment.group(1) if environment else None,resumed,parameters,
                                              metadata['fields'] if metadata else None)
                errors=lua_errors(segment)
                native_messages=[line for line in segment.splitlines() if re.search(r'ERROR\s*:\s*General|SEVERE:',line)
                                 and line not in errors]
                (out/'puppeteer.txt').write_bytes(raw)
                (out/'console.txt').write_text(segment,encoding='utf-8')
                (out/'errors.txt').write_text('\n'.join(errors),encoding='utf-8')
                (out/'native-messages.txt').write_text('\n'.join(native_messages),encoding='utf-8')
                startup=runlog.decode('utf-8',errors='replace').replace('\x00','')[:runstart]
                (out/'before-scenario.txt').write_text(startup,encoding='utf-8')
                versions=re.findall(r'version=(42\.[^\s]+)',runlog.decode('utf-8',errors='replace'))
                observation=dict(scenario=case,namespace=namespace,engine_status=status,new_errors=errors,command=effective_command,resumed=resumed,
                                 version=versions[-1] if versions else (environment.group(2) if environment else 'See environment/session header'),
                                 status='réussi' if status=='passed' and not errors else 'échoué',native_messages=native_messages,
                                 engine_metadata=metadata['fields'] if metadata else {},
                                 note='Any new Lua error blocks a clean pass; attribution requires reading console context.')
                (out/'result.json').write_text(json.dumps(observation,ensure_ascii=False,indent=2),encoding='utf-8')
                (ROOT/'reports'/f'{document_case}.md').write_text(f'# {namespace}/{case}\n\nStatut observé : **{observation["status"]}**. Moteur : `{status}`.\n\n'
                    f'Préconditions : {row["preconditions"]}.\n\nCommande : `{effective_command}`\n\n'
                    f'Attendu : {row["expected"]}.\n\nPreuves : [{evidence_path}/puppeteer.txt]({evidence_path}/puppeteer.txt), '
                    f'[{evidence_path}/console.txt]({evidence_path}/console.txt), [{evidence_path}/errors.txt]({evidence_path}/errors.txt).\n\n'
                    f'Messages natifs distincts : {len(native_messages)} ; [détail]({evidence_path}/native-messages.txt).\n\n'
                    'Résultat à interpréter avec les préconditions, la version et les erreurs de chargement de la session.\n'
                    + ('\nReprise explicite : les acquisitions antérieures ne sont pas rejouées; consulter les archives des tentatives précédentes.\n' if resumed else ''),encoding='utf-8')
                if namespace=='ArtemisDiagnostic':
                    if status=='passed' and metadata and metadata['fields'].get('Batch token'):
                        pending_ack=(metadata,raw,out)
                    print(f'{namespace}/{case}: {status}, new errors={len(errors)} -> {out}',flush=True)
                    fingerprint=digest; active=None
                else:
                    row.update(executed=True,command=effective_command,
                           observed=f'Moteur {status}; {len(errors)} nouvelles erreurs à examiner.'+(' Reprise avec acquisitions réelles conservées.' if resumed else ''),
                           proof=f'reports/{case}.md',status=observation['status'])
                    if row.get('scope'):
                        row['observed']+=' '+row['scope']
                    write_results(manifest)
                    print(f'{case}: {status}, new errors={len(errors)} -> {out}',flush=True)
                    if status=='passed' and metadata and metadata['fields'].get('Batch token'):
                        pending_ack=(metadata,raw,out)
                    fingerprint=digest; active=None
        if pending_ack:
            decoded=runlog.decode('utf-8',errors='replace').replace('\x00','')
            if acknowledge(pending_ack[0],pending_ack[1],decoded,pending_ack[2],USER):
                receipt=json.loads((pending_ack[2]/'batch-ack.json').read_text(encoding='utf-8'))
                if not receipt['accepted']:
                    name=pending_ack[0]['name']; document_case=name.split('/',1)[1]
                    if name.startswith('ArtemisDiagnostic/'):
                        document_case='diagnostic_'+document_case
                    document=ROOT/'reports'/f'{document_case}.md'
                    with document.open('a',encoding='utf-8') as handle:
                        evidence=pending_ack[2].relative_to(ROOT/'reports').as_posix()
                        handle.write(f'\nCampagne arrêtée : {len(receipt["errors"])} marqueurs d’erreur Lua depuis son départ, y compris entre scénarios. '
                                     f'[Preuve]({evidence}/batch-ack.json). Le résultat moteur du scénario reste conservé.\n')
                    if name.startswith('OperationArtemis/'):
                        row=manifest[document_case]
                        row['status']='échoué'
                        row['observed']+=' Campagne arrêtée après détection d’erreurs Lua; voir batch-ack.json.'
                        write_results(manifest)
                print('Batch archive ACK: '+pending_ack[0]['fields']['Run token'],flush=True)
                pending_ack=None
        if not args.watch or (args.seconds and time.monotonic()-started>=args.seconds): break
        time.sleep(0.5)

if __name__=='__main__': main()
