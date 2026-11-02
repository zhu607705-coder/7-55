"""Call configured Hi3D through Codex's native MCP/OAuth client.

No model turn, separate agent, credential export or persistent chat is created.
An ephemeral protocol context is used only to bind the native MCP connection.
Example: python3 pipeline/hi3d/client.py get_capabilities --output /private/tmp/caps.json
JSON inputs and outputs containing upload tokens stay outside the repository.
Paid create_generation requires a separately confirmed current quote.
"""
import argparse, json, os, re, select, subprocess, sys, time
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('tool')
parser.add_argument('--input')
parser.add_argument('--output', required=True)
parser.add_argument('--confirmed-current-quote', action='store_true')
args = parser.parse_args()
arguments = json.loads(Path(args.input).read_text()) if args.input else {}
if args.tool == 'create_generation' and not args.confirmed_current_quote:
    raise SystemExit('First obtain explicit user confirmation for this exact quote; no paid task submitted.')
if args.tool == 'create_generation' and arguments.get('confirmed') is not True:
    raise SystemExit('create_generation requires confirmed=true after user confirmation.')

# Disable unrelated MCP servers only inside this temporary protocol context.
config_path = Path(os.environ.get('CODEX_HOME', str(Path.home()/'.codex')))/'config.toml'
configured_names = re.findall(r'^\[mcp_servers\.([A-Za-z0-9_-]+)\]\s*$', config_path.read_text(), re.M)
overrides = {f'mcp_servers.{name}.enabled': False for name in configured_names if name != 'hi3d'}
overrides.update({'mcp_optional_startup_grace_ms':0,'mcp_servers.hi3d.startup_timeout_sec':30})
p = subprocess.Popen(['codex', 'app-server', '--stdio'], stdin=subprocess.PIPE,
    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
def send(message):
    p.stdin.write((json.dumps(message)+'\n').encode());p.stdin.flush()
def fail(message):
    raise RuntimeError(message)
try:
    send({'id':1,'method':'initialize','params':{'clientInfo':{
        'name':'flc-hi3d-native-mcp-client','version':'1.0'},'capabilities':{'experimentalApi':True}}})
    deadline=time.monotonic()+120;buffer=b'';done=False;failed=False;thread_id=None
    while time.monotonic()<deadline and not done:
        if p.poll() is not None:fail('Native MCP client exited before returning a result')
        if not select.select([p.stdout],[],[],.25)[0]:continue
        chunk=os.read(p.stdout.fileno(),65536)
        if not chunk:fail('Native MCP client closed its output')
        buffer+=chunk
        while b'\n' in buffer:
            line,buffer=buffer.split(b'\n',1)
            try:message=json.loads(line)
            except (ValueError,UnicodeDecodeError):continue
            if message.get('error'):fail(json.dumps(message['error']))
            response_id=message.get('id')
            if response_id==1:
                send({'method':'initialized'})
                send({'id':2,'method':'thread/start','params':{
                    'cwd':str(Path(args.output).resolve().parent),'ephemeral':True,'config':overrides}})
            elif response_id==2:
                thread_id=message['result']['thread']['id']
                send({'id':3,'method':'mcpServerStatus/list','params':{
                    'threadId':thread_id,'serverName':'hi3d','detail':'toolsAndAuthOnly'}})
            elif response_id==3:
                servers=message['result'].get('data',[])
                server=next((s for s in servers if s['name']=='hi3d'),None)
                if not server or args.tool not in server.get('tools',{}):fail('Tool catalog unavailable: '+json.dumps({k:server.get(k) for k in ['name','runtimeStatus','authStatus','toolsError']} if server else {'serverMissing':True}))
                send({'id':4,'method':'mcpServer/tool/call','params':{
                    'threadId':thread_id,'server':'hi3d','tool':args.tool,'arguments':arguments}})
            elif response_id==4:
                result=message['result'];failed=bool(result.get('isError',False));out=Path(args.output);out.parent.mkdir(parents=True,exist_ok=True)
                out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');os.chmod(out,0o600)
                print(json.dumps({'tool':args.tool,'isError':result.get('isError',False),'output':str(out)},ensure_ascii=False))
                done=True;break
    if not done:fail('MCP operation timed out. Do not automatically resubmit a generation; reconcile its task ID first.')
    if failed:raise SystemExit(2)
finally:
    p.terminate()
    try:p.wait(timeout=3)
    except subprocess.TimeoutExpired:p.kill()
