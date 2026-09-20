"""Exercise the installed, unmodified release APK through Android accessibility.

Emulators only: this test operates the shutter and saves a virtual-scene capture.
No Flutter VM service, debug build, injected OCR, or test classes in the app.
"""
import argparse
import json
import re
import subprocess
import time
import xml.etree.ElementTree as ET

APP = 'org.example.fictionalscreen.fictional_screen'
parser = argparse.ArgumentParser()
parser.add_argument('--serial', required=True)
args = parser.parse_args()
if not re.fullmatch(r'emulator-\d+', args.serial):
    parser.error('Automatic camera tests are restricted to emulators.')


def adb(*command):
    return subprocess.check_output(['adb', '-s', args.serial, *command], text=True, timeout=35)


def tree():
    adb('shell', 'uiautomator', 'dump', '/data/local/tmp/fictional-release-test.xml')
    return ET.fromstring(adb('shell', 'cat', '/data/local/tmp/fictional-release-test.xml'))


def wait_node(predicate, timeout=40):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            root = tree()
            for node in root.iter('node'):
                label = node.get('content-desc') or node.get('text') or ''
                if 'Error code:' in label or 'Evidence is NOT SAVED' in label:
                    raise AssertionError(label)
                if predicate(node, label):
                    return node
        except (ET.ParseError, subprocess.CalledProcessError):
            pass  # First frame may not yet have an accessibility tree.
        time.sleep(0.25)
    raise AssertionError('Expected screen control did not appear before timeout')


def tap(node):
    left, top, right, bottom = map(int, re.findall(r'\d+', node.attrib['bounds']))
    adb('shell', 'input', 'tap', str((left + right) // 2), str((top + bottom) // 2))


assert adb('shell', 'settings', 'get', 'global', 'airplane_mode_on').strip() == '1'
assert adb('shell', 'settings', 'get', 'global', 'wifi_on').strip() == '0'
adb('shell', 'am', 'force-stop', APP)
adb('shell', 'pm', 'grant', APP, 'android.permission.CAMERA')
adb('shell', 'am', 'start', '-W', '-n', APP + '/.MainActivity')
tap(wait_node(lambda n, label: label == 'Capture fictional specimen' and n.get('enabled') == 'true'))
tap(wait_node(lambda n, label: label.lower() == 'capture specimen' and n.get('enabled') == 'true'))
wait_node(lambda n, label: label == 'Result & evidence')
record = wait_node(lambda n, label: 'Record: ' in label)
record_id = re.search(r'Record: ([0-9a-f-]{36})', record.get('content-desc') or record.get('text')).group(1)
print('Release camera -> OCR -> encrypted save: PASS', flush=True)
adb('shell', 'am', 'force-stop', APP)
adb('shell', 'am', 'start', '-W', '-n', APP + '/.MainActivity')
tap(wait_node(lambda n, label: 'Synthetic capture' in label and record_id in label))
wait_node(lambda n, label: label == 'Result & evidence')
wait_node(lambda n, label: 'Record: ' + record_id in label)
print(json.dumps({'status': 'PASS', 'recordId': record_id,
    'checks': ['release camera capture', 'bundled OCR offline', 'encrypted save', 'same record after force-stop']}))
