"""Operator-assisted, local-only pilot session tracking. Photos stay on the phone."""
import argparse
import json
from pathlib import Path
import re
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[2] / 'release-assets' / 'pilot'
PACKAGE = 'com.sih188.borderdoc'
CACHE = f'/data/user/0/{PACKAGE}/cache'


def select_pair(new_names, document=None, live=None):
    def select(prefix, explicit):
        candidates = sorted(n for n in new_names if n.startswith(prefix) and re.fullmatch(r'[A-Za-z0-9_.-]+\.jpg', n))
        if explicit is not None:
            if explicit not in candidates:
                raise ValueError('Explicit capture must belong to this new session')
            return explicit
        if len(candidates) != 1:
            raise ValueError('Capture selection is ambiguous; explicitly select the document/live filename after reviewing retakes')
        return candidates[0]
    return select('scaled_', document), select('CAP', live)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['begin', 'finish', 'cleanup'])
    parser.add_argument('--device', required=True)
    parser.add_argument('--participant', required=True)
    parser.add_argument('--session', required=True)
    parser.add_argument('--consent', action='store_true', help='Operator confirms voluntary local development-pair evaluation consent')
    parser.add_argument('--document', help='Explicit new cache basename when retakes are ambiguous')
    parser.add_argument('--live', help='Explicit new cache basename when retakes are ambiguous')
    args = parser.parse_args()
    for value in (args.participant, args.session):
        if not re.fullmatch(r'[A-Z][A-Z0-9_-]{1,31}', value):
            parser.error('Use anonymous IDs, for example P01 and P01-S01')
    folder = ROOT / args.session
    def adb(*parts):
        return subprocess.check_output(['adb', '-s', args.device, *parts], text=True, encoding='utf-8', errors='replace')
    def shell(*parts):
        return adb('shell', ' '.join(shlex.quote(p) for p in parts))
    def names():
        return set(shell('run-as', PACKAGE, 'ls', '-1', 'cache').splitlines())
    if args.action == 'begin':
        if not args.consent:
            parser.error('Confirm volunteer consent before starting this development session')
        if ROOT.exists():
            for existing in ROOT.glob('*/session.json'):
                other = json.loads(existing.read_text())
                if other['device'] == args.device and not (existing.parent / 'report.json').exists():
                    parser.error('Finish the active session on this device before starting another')
        before = sorted(names())
        folder.mkdir(parents=True, exist_ok=False)
        state = {'participant': args.participant, 'session': args.session, 'device': args.device,
                 'split': 'development', 'consent': 'confirmed', 'before': before}
        (folder / 'session.json').write_text(json.dumps(state, indent=2)+'\n')
        print(f'{args.session} started. Capture one document and one live photo, then finish this session before starting another.')
        return
    state_path = folder / 'session.json'
    state = json.loads(state_path.read_text())
    if state['participant'] != args.participant or state['device'] != args.device:
        parser.error('Participant or device differs from the recorded session')
    if args.action == 'cleanup':
        if 'captures' not in state or not (folder / 'report.json').is_file():
            parser.error('An evaluated capture pair is required before cleanup')
        # Exactly two registered basenames; no recursive deletion or globbing.
        for name in state['captures']:
            if not re.fullmatch(r'(scaled_|CAP)[A-Za-z0-9_.-]+\.jpg', name):
                raise ValueError('Unsafe capture name')
            shell('run-as', PACKAGE, 'rm', '-f', f'{CACHE}/{name}')
        state['registeredCapturesDeleted'] = True
        state_path.write_text(json.dumps(state, indent=2)+'\n')
        print('Deleted the two registered phone-cache captures. Aggregate pilot report retained; unrelated files and retakes untouched.')
        return
    if (folder / 'report.json').exists():
        parser.error('Session already has a report; use a fresh session for retakes')
    document, live = select_pair(names()-set(state['before']), args.document, args.live)
    state['captures'] = [document, live]
    state_path.write_text(json.dumps(state, indent=2)+'\n')
    command = ['am', 'instrument', '-w', '-r', '-e', 'class', 'com.sih188.borderdoc.face.PilotPairEvaluationTest']
    for key, value in {'pairId':args.session, 'documentSubject':args.participant, 'liveSubject':args.participant,
                       'consent':'confirmed', 'document':f'{CACHE}/{document}', 'selfie':f'{CACHE}/{live}'}.items():
        command.extend(['-e', key, value])
    output = shell(*command, f'{PACKAGE}.test/androidx.test.runner.AndroidJUnitRunner')
    prefix = 'INSTRUMENTATION_RESULT: edgeface_pilot_pair='
    reports = [json.loads(line[len(prefix):]) for line in output.splitlines() if line.startswith(prefix)]
    if len(reports) != 1:
        raise RuntimeError('No unique pilot report returned; session mapping retained, no photos deleted')
    report = reports[0]
    report['instrumentationPassed'] = 'OK (1 test)' in output and 'FAILURES!!!' not in output
    (folder / 'report.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))
    if not report['instrumentationPassed']:
        raise RuntimeError('Pilot execution failed; recorded as failure, not a valid comparison')


if __name__ == '__main__':
    main()
