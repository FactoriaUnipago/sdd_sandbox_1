#!/usr/bin/env bash
# sdd-sync.sh - Sincroniza estándares SDD al proyecto actual
#
# GitHub (repo privado):
#   curl -H "Authorization: token TU_PAT" https://raw.githubusercontent.com/FactoriaUnipago/unipago-sdd-standard/main/sync/sdd-sync.sh -o sdd-sync.sh
#   bash sdd-sync.sh --token TU_PAT --ide kiro --role developer
#
# Azure DevOps (repo privado):
#   curl -u ":TU_PAT" "https://dev.azure.com/unipagosa/sdd-standards/_apis/git/repositories/unipago-sdd-standard/items?path=/sync/sdd-sync.sh&api-version=7.0" -o sdd-sync.sh
#   bash sdd-sync.sh --token TU_PAT --host azure --ide kiro --role developer

set -e

# Force Python to use UTF-8 on Windows (default cp1252 crashes on emoji/special chars)
export PYTHONUTF8=1

# --- Auto-fix CRLF (Windows curl downloads may add \r) ---
if grep -qP '\r$' "$0" 2>/dev/null; then
  sed -i 's/\r$//' "$0"
  exec bash "$0" "$@"
fi

# --- Prerequisites check ---
echo ""
echo "🔍 Verificando prerequisitos..."

# Python (required)
PYTHON=""
if python3 --version &>/dev/null 2>&1; then
  PYTHON="python3"
elif python --version &>/dev/null 2>&1; then
  PYTHON="python"
else
  echo "   ❌ Python no encontrado."
  echo "      Instala Python 3: https://www.python.org/downloads/"
  exit 1
fi

# Node/npx (required — la mayoría de MCPs usan npx)
if ! command -v npx &>/dev/null; then
  echo "   ❌ npx no encontrado (Node.js no instalado)."
  echo "      Instala Node.js: https://nodejs.org/"
  exit 1
fi

# Git (required — para clonar el standard)
if ! command -v git &>/dev/null; then
  echo "   ❌ git no encontrado."
  echo "      Instala Git: https://git-scm.com/downloads"
  exit 1
fi

echo "   ✅ Python: $($PYTHON --version 2>&1)"
echo "   ✅ Node: $(node --version 2>&1)"
echo "   ✅ Git: $(git --version 2>&1)"

# --- Defaults ---
IDE=""
ROLE=""
HOST=""
PROJECT_HOST=""
TOKEN=""
CHECK=false
REFRESH=false
FORCE=false
BRANCH="main"
USE_MCP_PROXY=false

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --ide)   IDE="$2"; shift 2 ;;
    --role)  ROLE="$2"; shift 2 ;;
    --host)  HOST="$2"; shift 2 ;;
    --project-host) PROJECT_HOST="$2"; shift 2 ;;
    --token) TOKEN="$2"; shift 2 ;;
    --check) CHECK=true; shift ;;
    --force) FORCE=true; shift ;;
    --refresh) REFRESH=true; shift ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --mcp-proxy) USE_MCP_PROXY=true; shift ;;
    *) echo "❌ Argumento desconocido: $1"; exit 1 ;;
  esac
done

# --- Auto-detect config from .sdd-config.json if not provided ---
if [ -f ".sdd-config.json" ]; then
  SAVED=$($PYTHON -c "
import json
with open('.sdd-config.json') as f:
    config = json.load(f)
print(config.get('role', ''))
print(config.get('host', ''))
print(config.get('project_host', ''))
print('|'.join(config.get('ides', [])))
" 2>/dev/null | tr -d '\r' || echo "")
  if [ -n "$SAVED" ]; then
    SAVED_ROLE=$(echo "$SAVED" | sed -n '1p')
    SAVED_HOST=$(echo "$SAVED" | sed -n '2p')
    SAVED_PHOST=$(echo "$SAVED" | sed -n '3p')
    SAVED_IDES=$(echo "$SAVED" | sed -n '4p')
    [ -z "$ROLE" ] && [ -n "$SAVED_ROLE" ] && ROLE="$SAVED_ROLE"
    [ -z "$HOST" ] && [ -n "$SAVED_HOST" ] && HOST="$SAVED_HOST"
    [ -z "$PROJECT_HOST" ] && [ -n "$SAVED_PHOST" ] && PROJECT_HOST="$SAVED_PHOST"
    [ -z "$IDE" ] && [ -n "$SAVED_IDES" ] && IDE=$(echo "$SAVED_IDES" | tr '|' ',' | head -1)
  fi
fi

# Restore proxy preference from cache if not explicitly set
if [ "$FORCE" = true ] && [ "$USE_MCP_PROXY" = false ]; then
  # --force without --mcp-proxy = disable proxy, clean up
  rm -f ".sdd-cache/use-mcp-proxy" 2>/dev/null || true
  rm -f ".lazy-mcp-servers.json" 2>/dev/null || true
  rm -f ".sdd-cache/mcp-proxy.json" 2>/dev/null || true
elif [ "$USE_MCP_PROXY" = false ] && [ -f ".sdd-cache/use-mcp-proxy" ]; then
  CACHED_PROXY=$(cat ".sdd-cache/use-mcp-proxy" 2>/dev/null | tr -d '[:space:]')
  [ "$CACHED_PROXY" = "true" ] && USE_MCP_PROXY=true
fi

# --- Generic IDE adapter: reads adapters/<ide>/adapter.json ---
# Usage: ide_adapter <ide_name> <action> [args...]
# Actions: files, mcp, mcp_path, product_dir, needs_conversion, dir
#
# MUST be defined before --refresh block (bash is sequential).
# ADAPTER_ENGINE is set from cache here; re-set from TEMP_DIR after clone.

ADAPTER_ENGINE=""
if [ -f ".sdd-cache/adapter_engine.py" ]; then
  ADAPTER_ENGINE=".sdd-cache/adapter_engine.py"
fi

TEMP_DIR="${TEMP_DIR:-.sdd-sync-temp}"

ide_adapter() {
  local ide_name="$1"
  local action="$2"
  shift 2

  # Locate adapter.json (from cloned standard repo, cache, or local)
  local adapter_json=""
  if [ -f "$TEMP_DIR/adapters/$ide_name/adapter.json" ]; then
    adapter_json="$TEMP_DIR/adapters/$ide_name/adapter.json"
  elif [ -f ".sdd-cache/adapters/$ide_name/adapter.json" ]; then
    adapter_json=".sdd-cache/adapters/$ide_name/adapter.json"
  elif [ -f "adapters/$ide_name/adapter.json" ]; then
    adapter_json="adapters/$ide_name/adapter.json"
  else
    echo "   ❌ No adapter.json found for IDE '$ide_name'"
    echo "      Expected: adapters/$ide_name/adapter.json"
    return 1
  fi

  if [ -z "$ADAPTER_ENGINE" ]; then
    return 1
  fi

  case "$action" in
    files)
      $PYTHON "$ADAPTER_ENGINE" "$adapter_json" files "$1" "$2" "${3:-$TEMP_DIR}" "$ROLE"
      ;;
    mcp)
      $PYTHON "$ADAPTER_ENGINE" "$adapter_json" mcp "$1" "$2"
      ;;
    mcp_path)
      $PYTHON "$ADAPTER_ENGINE" "$adapter_json" mcp_path "$1"
      ;;
    product_dir)
      $PYTHON "$ADAPTER_ENGINE" "$adapter_json" product_dir
      ;;
    needs_conversion)
      $PYTHON "$ADAPTER_ENGINE" "$adapter_json" needs_conversion
      ;;
    dir)
      $PYTHON "$ADAPTER_ENGINE" "$adapter_json" dir
      ;;
  esac
}

# --- Refresh mode: regenerate mcp.json without downloading ---
if [ "$REFRESH" = true ]; then
  echo ""
  echo "=== SDD Standards Refresh ==="


  declare -A IDE_DIRS=(
    ["kiro"]=".kiro"
    ["cursor"]=".cursor"
    ["claude"]=".claude"
    ["antigravity"]=".agents"
    ["windsurf"]=".windsurf"
    ["copilot"]=".github"
  )
  
  # Determine which IDEs to refresh
  REFRESH_IDES=""
  if [ -n "$IDE" ]; then
    # Explicit --ide given or auto-detected from config (may be comma-separated)
    REFRESH_IDES=$(echo "$IDE" | tr ',' ' ')
  elif [ -f ".sdd-config.json" ]; then
    # Read ides array from config
    REFRESH_IDES=$($PYTHON -c "
import json
with open('.sdd-config.json') as f:
    config = json.load(f)
print(' '.join(config.get('ides', [])))
" 2>/dev/null || echo "")
  fi
  
  if [ -z "$REFRESH_IDES" ]; then
    echo "❌ No se detectaron IDEs. Usa --ide kiro o ejecuta sync completo primero."
    exit 1
  fi
  
  echo "Regenerando MCP para: $REFRESH_IDES"
  echo ""

  for ide_name in $REFRESH_IDES; do
    TARGET_DIR="${IDE_DIRS[$ide_name]}"
    SETTINGS_DIR="$TARGET_DIR/settings"
    
    # Find source mcp.json — varies by IDE
    MCP_SOURCE=""
    if [ -f "$SETTINGS_DIR/mcp.json" ]; then
      MCP_SOURCE="$SETTINGS_DIR/mcp.json"
    elif [ -f ".sdd-cache/mcp-direct.json" ]; then
      # Antigravity: settings/ was cleaned, use cached direct version
      mkdir -p "$SETTINGS_DIR"
      cp ".sdd-cache/mcp-direct.json" "$SETTINGS_DIR/mcp.json"
      MCP_SOURCE="$SETTINGS_DIR/mcp.json"
    elif [ -f "$TARGET_DIR/mcp_config.json" ]; then
      # Fallback: use converted config (antigravity format)
      mkdir -p "$SETTINGS_DIR"
      cp "$TARGET_DIR/mcp_config.json" "$SETTINGS_DIR/mcp.json"
      MCP_SOURCE="$SETTINGS_DIR/mcp.json"
    fi

    if [ -z "$MCP_SOURCE" ]; then
      echo "   ⚠️  $ide_name: sin mcp.json, omitido"
      continue
    fi

    $PYTHON - "$SETTINGS_DIR" "$MCP_SOURCE" "$ROLE" <<'REFRESHEOF'
import json, os, re, sys

settings_dir = sys.argv[1]
mcp_source = sys.argv[2]
role = sys.argv[3]

# Read from template if available (has ALL servers including previously filtered ones)
template_path = '.sdd-cache/mcp-template.json'
if os.path.exists(template_path):
    with open(template_path) as f:
        mcp = json.load(f)
    # Role filter
    matrix_path = '.sdd-cache/role-mcp-matrix.json'
    if role != 'all' and os.path.exists(matrix_path):
        with open(matrix_path) as f:
            matrix = json.load(f)
        roles = [r.strip() for r in role.split(',')]
        allowed = set()
        for r in roles:
            if r in matrix.get('roles', {}):
                allowed.update(matrix['roles'][r].get('required', []))
                allowed.update(matrix['roles'][r].get('optional', []))
            else:
                allowed.update(matrix.get(r, []))
        mcp = {'mcpServers': {k: v for k, v in mcp.get('mcpServers', {}).items() if k in allowed}}
else:
    with open(mcp_source) as f:
        mcp = json.load(f)

def resolve_vars(block, source):
    for k, v in block.items():
        if isinstance(v, str) and '${' in v:
            def replacer(m):
                vn = m.group(1)
                val = source.get(vn, m.group(0))
                return str(val)
            block[k] = re.sub(r'\$\{([^}]+)\}', replacer, v)

# Merge env from .sdd-config.json
if os.path.exists('.sdd-config.json'):
    with open('.sdd-config.json') as cf:
        mcp_env = json.load(cf).get('env', {})
    for sc in mcp.get('mcpServers', {}).values():
        resolve_vars(sc.get('env', {}), mcp_env)
        resolve_vars(sc.get('headers', {}), mcp_env)
        if 'args' in sc:
            for i, arg in enumerate(sc['args']):
                if isinstance(arg, str) and '${' in arg:
                    sc['args'][i] = re.sub(r'\$\{([^}]+)\}', lambda m: str(mcp_env.get(m.group(1), m.group(0))), arg)

# Merge credentials
email = ''
if os.path.exists('.sdd-credentials.json'):
    with open('.sdd-credentials.json') as cf:
        creds = json.load(cf)
    creds = {k: v for k, v in creds.items() if not k.startswith('_') and v}
    # Auto-compute AZURE_DEVOPS_PAT_B64
    email = creds.get('AZURE_DEVOPS_EMAIL', '')
    if not email:
        import subprocess
        try:
            email = subprocess.run(['git', 'config', 'user.email'], capture_output=True, text=True, timeout=5).stdout.strip()
            if not email:
                email = subprocess.run(['git', 'config', '--global', 'user.email'], capture_output=True, text=True, timeout=5).stdout.strip()
        except Exception:
            pass
    if email and creds.get('AZURE_DEVOPS_PAT'):
        import base64
        raw = f"{email}:{creds['AZURE_DEVOPS_PAT']}"
        creds['AZURE_DEVOPS_PAT_B64'] = base64.b64encode(raw.encode()).decode()
        # Persist PAT_B64 so future runs don't need email to resolve
        with open('.sdd-credentials.json') as _f:
            _saved = json.load(_f)
        _saved['AZURE_DEVOPS_PAT_B64'] = creds['AZURE_DEVOPS_PAT_B64']
        with open('.sdd-credentials.json', 'w') as _f:
            json.dump(_saved, _f, indent=2)
    for sc in mcp.get('mcpServers', {}).values():
        resolve_vars(sc.get('env', {}), creds)
        resolve_vars(sc.get('headers', {}), creds)
        if 'args' in sc:
            for i, arg in enumerate(sc['args']):
                if isinstance(arg, str) and '${' in arg:
                    sc['args'][i] = re.sub(r'\$\{([^}]+)\}', lambda m: str(creds.get(m.group(1), m.group(0))), arg)

# Filter unresolved — check env + args + headers (consistent with full sync)
def has_bad_vars(block):
    return any(isinstance(v, str) and ('${' in v or v.strip() == '') for v in block.values())
def args_have_bad_vars(args):
    return any(isinstance(a, str) and '${' in a for a in args)

final_servers = {}
skipped = []
for name, conf in mcp.get('mcpServers', {}).items():
    env = conf.get('env', {})
    headers = conf.get('headers', {})
    args = conf.get('args', [])
    if has_bad_vars(env) or has_bad_vars(headers) or args_have_bad_vars(args):
        skipped.append(name)
    else:
        clean = {k: v for k, v in conf.items() if k not in ('roles', '_note', '_category')}
        # Resolve relative paths in env vars to absolute
        if 'env' in clean:
            for ek, ev in clean['env'].items():
                if isinstance(ev, str) and not os.path.isabs(ev) and ('/' in ev or '\\' in ev):
                    abs_path = os.path.join(os.getcwd(), ev).replace('\\', '/')
                    clean['env'][ek] = abs_path
                    parent = os.path.dirname(abs_path)
                    if parent:
                        os.makedirs(parent, exist_ok=True)
        final_servers[name] = clean

mcp = {'mcpServers': final_servers}
os.makedirs(settings_dir, exist_ok=True)
with open(os.path.join(settings_dir, 'mcp.json'), 'w') as f:
    json.dump(mcp, f, indent=2)

# Also update cached direct version
if os.path.exists('.sdd-cache'):
    with open('.sdd-cache/mcp-direct.json', 'w') as f:
        json.dump(mcp, f, indent=2)

skip_msg = f' ({len(skipped)} omitidos: {", ".join(skipped)})' if skipped else ''
print(f'   ✅ {len(final_servers)} servers{skip_msg}')
if 'azure-devops' in skipped and not email:
    print('      ⚠️ azure-devops requiere git identity → git config --global user.email')
REFRESHEOF
    # Re-apply adapter conversion if needed (e.g., antigravity needs mcp_config.json)
    if ide_adapter "$ide_name" needs_conversion 2>/dev/null; then
      ide_adapter "$ide_name" mcp "$SETTINGS_DIR/mcp.json" "$TARGET_DIR" > /dev/null 2>&1
      # Clean up intermediate settings/ dir (antigravity uses mcp_config.json directly)
      [ -d "$SETTINGS_DIR" ] && rm -rf "$SETTINGS_DIR"
    fi

    # Regenerate lazy-mcp proxy for non-antigravity IDEs if original sync used --mcp-proxy
    CACHED_PROXY=$(cat ".sdd-cache/use-mcp-proxy" 2>/dev/null || echo "false")
    if [ "$CACHED_PROXY" = "true" ] && [ "$ide_name" != "antigravity" ]; then
      echo "   🔄 Regenerando lazy-mcp proxy para $ide_name..."
      $PYTHON - "$SETTINGS_DIR" <<'LAZYREFRESHEOF'
import json, os, sys, platform

settings_dir = sys.argv[1]
mcp_path = os.path.join(settings_dir, 'mcp.json')

with open(mcp_path) as f:
    mcp = json.load(f)

servers = mcp.get('mcpServers', {})
project_root = os.getcwd()
lazy_config_path = os.path.join(project_root, '.lazy-mcp-servers.json')

# Windows: spawn('npx') = ENOENT, spawn('npx.cmd') = EINVAL
# Fix: use 'cmd /c npx' which lets Windows shell resolve .cmd files
is_win = platform.system() == 'Windows'

def wrap_cmd(cmd, args):
    if is_win:
        return 'cmd', ['/c', cmd] + (args or [])
    return cmd, args or []

lazy_servers = []
for name, conf in servers.items():
    entry = {'name': name, 'description': conf.get('_note', f'{name} MCP server')}
    if 'command' in conf:
        cmd, args = wrap_cmd(conf['command'], conf.get('args', []))
        entry['command'] = cmd
        entry['args'] = args
    elif 'url' in conf:
        entry['url'] = conf['url']
    if 'env' in conf:
        entry['env'] = conf['env']
    if 'headers' in conf:
        entry['headers'] = conf['headers']
    lazy_servers.append(entry)

with open(lazy_config_path, 'w') as f:
    json.dump({'servers': lazy_servers}, f, indent=2)
    f.write('\n')

proxy_cmd, proxy_args = wrap_cmd('npx', ['lazy-mcp@latest', '--config', lazy_config_path])
proxy_config = {
    'mcpServers': {
        'lazy-mcp': {
            'command': proxy_cmd,
            'args': proxy_args
        }
    }
}

with open(mcp_path, 'w') as f:
    json.dump(proxy_config, f, indent=2)

print(f'      lazy-mcp: {len(servers)} servers wrapped → 1 proxy')
LAZYREFRESHEOF
    fi
  done
  
  echo ""
  echo "✅ Refresh completado"
  exit 0
fi

# --- Auto-detect token from .sdd-credentials.json if not provided ---
if [ -z "$TOKEN" ] && [ -f ".sdd-credentials.json" ]; then
  TOKEN=$($PYTHON -c "
import json
with open('.sdd-credentials.json') as f:
    creds = json.load(f)
# SDD_SYNC_TOKEN is the dedicated token for the standard repo
token = creds.get('SDD_SYNC_TOKEN', '')
if not token:
    # Fallback: use GITHUB_PAT or AZURE_DEVOPS_PAT
    host = '$HOST' if '$HOST' else 'github'
    if host == 'github':
        token = creds.get('GITHUB_PAT', '')
    else:
        token = creds.get('AZURE_DEVOPS_PAT', '')
print(token)
" 2>/dev/null || echo "")
fi

# --- Interactive prompts (only ask for what's missing) ---
NEEDS_PROMPT=false
if [ -z "$HOST" ] || [ -z "$IDE" ] || [ -z "$ROLE" ] || [ -z "$TOKEN" ]; then
  if [ "$CHECK" = false ]; then NEEDS_PROMPT=true; fi
fi

if [ "$NEEDS_PROMPT" = true ]; then
  echo ""
  echo "========================================"
  echo "  Unipago SDD Standard - Instalación"
  echo "========================================"
  echo ""
fi

# Host (del standard)
if [ -z "$HOST" ]; then
  echo "  ¿Dónde está el repo del STANDARD SDD?"
  echo "    [1] GitHub (default)"
  echo "    [2] Azure DevOps"
  echo ""
  read -p "  Selecciona (1 o 2): " HOST_CHOICE
  case "$HOST_CHOICE" in
    2) HOST="azure" ;;
    *) HOST="github" ;;
  esac
  echo ""
fi

# Project host (del proyecto)
if [ -z "$PROJECT_HOST" ]; then
  echo "  ¿Dónde está (o estará) el repo de tu proyecto?"
  echo "    [1] GitHub (default)"
  echo "    [2] Azure DevOps"
  echo ""
  read -p "  Selecciona (1 o 2): " PROJ_HOST_CHOICE
  case "$PROJ_HOST_CHOICE" in
    2) PROJECT_HOST="azure" ;;
    *) PROJECT_HOST="github" ;;
  esac
  echo ""
fi

# IDE
if [ -z "$IDE" ]; then
  echo "  ¿Qué IDE agéntico usas?"
  echo "    [1] Kiro (default)"
  echo "    [2] Cursor (próximamente)"
  echo "    [3] Claude Code (próximamente)"
  echo "    [4] Antigravity / Gemini"
  echo "    [5] Windsurf (próximamente)"
  echo "    [6] GitHub Copilot (próximamente)"
  echo ""
  read -p "  Selecciona (1-6): " IDE_CHOICE
  case "$IDE_CHOICE" in
    2) IDE="cursor" ;;
    3) IDE="claude" ;;
    4) IDE="antigravity" ;;
    5) IDE="windsurf" ;;
    6) IDE="copilot" ;;
    *) IDE="kiro" ;;
  esac
  echo ""
fi

# Role
if [ -z "$ROLE" ]; then
  echo "  ¿Cuál es tu rol?"
  echo "    [1] Analista"
  echo "    [2] Developer"
  echo "    [3] QA"
  echo "    [4] Todos los roles (default)"
  echo ""
  read -p "  Selecciona (1-4): " ROLE_CHOICE
  case "$ROLE_CHOICE" in
    1) ROLE="analyst" ;;
    2) ROLE="developer" ;;
    3) ROLE="qa" ;;
    *) ROLE="all" ;;
  esac
  echo ""
fi

# Token
# Try reading token from .sdd-credentials.json
if [ -z "$TOKEN" ] && [ -f ".sdd-credentials.json" ]; then
  TOKEN=$($PYTHON -c "
import json
with open('.sdd-credentials.json') as f:
    creds = json.load(f)
token = creds.get('SDD_SYNC_TOKEN', '')
if token:
    print(token)
" 2>/dev/null || echo "")
  if [ -n "$TOKEN" ]; then
    echo "  🔑 Token leído de .sdd-credentials.json"
  fi
fi

if [ -z "$TOKEN" ] && [ "$CHECK" = false ]; then
  echo "  Este token es SOLO para descargar el standard SDD (repo privado)."
  echo "  No es el token de tu proyecto — ese se pide después."
  echo ""
  if [ "$HOST" = "github" ]; then
    echo "  Crea un GitHub PAT con acceso al repo del standard:"
    echo "    https://github.com/settings/tokens?type=beta"
    echo "    → Repository: FactoriaUnipago/unipago-sdd-standard"
    echo "    → Permissions: Contents → Read-only"
  else
    echo "  Crea un Azure DevOps PAT con acceso al repo del standard:"
    echo "    https://dev.azure.com/unipagosa/_usersSettings/tokens"
    echo "    → Scopes: Code → Read"
  fi
  echo ""
  # Windows Git Bash: Ctrl+V inserts literal char instead of paste
  if [[ "$(uname -s)" == *"MINGW"* ]] || [[ "$(uname -s)" == *"MSYS"* ]] || [[ "$OS" == "Windows_NT" ]]; then
    echo "  💡 Windows: usa Shift+Insert o clic derecho para pegar"
  fi
  read -sp "  Pega tu token aquí: " TOKEN
  echo ""
  # Sanitize control characters
  TOKEN=$(echo "$TOKEN" | tr -d '[:cntrl:]')

  if [ -z "$TOKEN" ]; then
    echo ""
    echo "  ❌ Token es obligatorio."
    exit 1
  fi

  # Save token to .sdd-credentials.json for future syncs
  if [ -f ".sdd-credentials.json" ]; then
    $PYTHON -c "
import json
with open('.sdd-credentials.json') as f:
    creds = json.load(f)
creds['SDD_SYNC_TOKEN'] = '$TOKEN'
with open('.sdd-credentials.json', 'w') as f:
    json.dump(creds, f, indent=2)
" 2>/dev/null
  fi
  echo ""
fi

# --- Multi-IDE: if --ide has commas OR ides[] exists in config, sync all ---
MULTI_IDE=false
ALL_IDES=""

# Check if --ide was comma-separated (e.g. --ide kiro,cursor)
if [ -n "$IDE" ] && [[ "$IDE" == *","* ]]; then
  ALL_IDES=$(echo "$IDE" | tr ',' ' ')
  MULTI_IDE=true
  IDE=$(echo "$ALL_IDES" | awk '{print $1}')  # first IDE as primary
elif [ -z "$IDE" ] && [ -f ".sdd-config.json" ] && [ "$NEEDS_PROMPT" = false ]; then
  ALL_IDES=$($PYTHON -c "
import json
with open('.sdd-config.json') as f:
    config = json.load(f)
ides = config.get('ides', [])
if ides:
    print(' '.join(ides))
" 2>/dev/null || echo "")
  if [ -n "$ALL_IDES" ]; then
    MULTI_IDE=true
    IDE=$(echo "$ALL_IDES" | awk '{print $1}')  # use first IDE as primary
  fi
fi

# --- Apply defaults for any fields still empty ---
[ -z "$HOST" ] && HOST="github"
[ -z "$PROJECT_HOST" ] && PROJECT_HOST="github"
[ -z "$IDE" ] && IDE="kiro"
[ -z "$ROLE" ] && ROLE="all"

# Summary
if [ "$NEEDS_PROMPT" = true ]; then
  echo "  Standard: $HOST"
  echo "  Proyecto: $PROJECT_HOST"
  echo "  IDE:      $IDE"
  echo "  Rol:      $ROLE"
  echo "  Token:    ****${TOKEN: -4}"
  echo "========================================"
  echo ""
fi

# --- Host configuration ---
declare -A REPO_URLS=(
  ["github"]="https://github.com/FactoriaUnipago/unipago-sdd-standard.git"
  ["azure"]="https://dev.azure.com/unipagosa/sdd-standards/_git/unipago-sdd-standard"
)

STANDARDS_REPO="${REPO_URLS[$HOST]}"

if [ -z "$STANDARDS_REPO" ]; then
  echo "❌ Host '$HOST' no reconocido. Opciones: github, azure"
  exit 1
fi

TEMP_DIR=".sdd-sync-temp"
VERSION_FILE=".sdd-standards-version"

# IDE-specific output directories
declare -A IDE_DIRS=(
  ["kiro"]=".kiro"
  ["cursor"]=".cursor"
  ["claude"]=".claude"
  ["antigravity"]=".agents"
  ["windsurf"]=".windsurf"
  ["copilot"]=".github"
)

TARGET_DIR="${IDE_DIRS[$IDE]}"

if [ -z "$TARGET_DIR" ]; then
  echo "❌ IDE '$IDE' no reconocido. Opciones: kiro, antigravity"
  exit 1
fi

# ide_adapter() defined earlier (before --refresh block)



echo ""
echo "=== SDD Standards Sync ==="
echo "Host: $HOST"
echo "IDE:  $IDE ($TARGET_DIR)"
echo "Role: $ROLE"
echo ""

# --- Validate IDE adapter (checked after clone, when adapter dir is available) ---

# --- 1. Clone standards repo (shallow) ---
echo "⤵️  Descargando estándares..."
rm -rf "$TEMP_DIR"

# Build authenticated clone URL (--token flag or env var)
PAT="${TOKEN:-${GITHUB_PAT:-${AZURE_PAT:-}}}"

if [ -n "$PAT" ] && [ "$HOST" = "github" ]; then
  CLONE_URL="https://${PAT}@github.com/FactoriaUnipago/unipago-sdd-standard.git"
elif [ -n "$PAT" ] && [ "$HOST" = "azure" ]; then
  CLONE_URL="https://${PAT}@dev.azure.com/unipagosa/sdd-standards/_git/unipago-sdd-standard"
else
  CLONE_URL="$STANDARDS_REPO"
fi
GIT_TERMINAL_PROMPT=0 git clone --depth 1 --branch "$BRANCH" --config core.autocrlf=false "$CLONE_URL" "$TEMP_DIR"

if [ ! -f "$TEMP_DIR/VERSION" ]; then
  echo "❌ No se pudo descargar el repositorio de estándares."
  echo "   Verifica acceso: git clone $STANDARDS_REPO"
  exit 1
fi

# Validate adapter exists
if [ ! -d "$TEMP_DIR/adapters/$IDE" ]; then
  echo "⚠️  Adapter '$IDE' no encontrado — steering se copiará sin frontmatter IDE-specific"
fi

# Resolve adapter engine path (now that TEMP_DIR exists)
ADAPTER_ENGINE=""
if [ -f "$TEMP_DIR/adapters/adapter_engine.py" ]; then
  ADAPTER_ENGINE="$TEMP_DIR/adapters/adapter_engine.py"
elif [ -f ".sdd-cache/adapter_engine.py" ]; then
  ADAPTER_ENGINE=".sdd-cache/adapter_engine.py"
elif [ -f "adapters/adapter_engine.py" ]; then
  ADAPTER_ENGINE="adapters/adapter_engine.py"
else
  echo "❌ adapter_engine.py no encontrado"
  exit 1
fi

REMOTE_VERSION=$(cat "$TEMP_DIR/VERSION" | tr -d '[:space:]')
LOCAL_VERSION="0.0.0"
if [ -f "$VERSION_FILE" ]; then
  LOCAL_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
fi

echo "   Remote: v$REMOTE_VERSION | Local: v$LOCAL_VERSION"

# --- Check mode (CI) ---
if [ "$CHECK" = true ]; then
  if [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
    echo "❌ Standards desincronizados. Remote: v$REMOTE_VERSION, Local: v$LOCAL_VERSION"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  echo "✅ Standards sincronizados (v$REMOTE_VERSION)"
  rm -rf "$TEMP_DIR"
  exit 0
fi

# --- Skip if already up to date ---
if [ "$REMOTE_VERSION" = "$LOCAL_VERSION" ] && [ "$FORCE" = false ]; then
  echo ""
  echo "✅ Ya estás al día (v$LOCAL_VERSION)"
  echo "   Si deseas forzar re-sync: bash sdd-sync.sh --force"
  rm -rf "$TEMP_DIR"
  exit 0
fi

# --- 2. Initialize git if needed ---
if [ ! -d ".git" ]; then
  echo "📦 Inicializando repositorio git..."
  git init -q
  echo "   ✅ git init completado"
fi

# --- 2a. Check git identity (needed for initial commit) ---
GIT_USER=$(git config user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config user.email 2>/dev/null || git config --global user.email 2>/dev/null || echo "")
HAS_GIT_IDENTITY=true
if [ -z "$GIT_USER" ] || [ -z "$GIT_EMAIL" ]; then
  HAS_GIT_IDENTITY=false
fi

# --- 3. Create target directory ---
mkdir -p "$TARGET_DIR"

echo "📦 Copiando archivos..."

# --- Helper: copy steering file with IDE-appropriate frontmatter ---
copy_steering_file() {
  local file="$1"
  local filename=$(basename "$file")
  local target_dir="${2:-$STEERING_DIR}"
  local target_ide="${3:-$IDE}"
  local content=$(cat "$file")

  # Check if adapter has per-file frontmatter overrides
  frontmatter=$($PYTHON -c "
import json, os
transform_path = '$TEMP_DIR/adapters/$target_ide/adapter.json'
if not os.path.exists(transform_path):
    exit(0)
with open(transform_path) as f:
    t = json.load(f)
fm = t.get('steering',{}).get('frontmatter',{}).get('$filename',{})
if fm:
    lines = ['---']
    lines.append(f\"inclusion: {fm['inclusion']}\")
    if 'fileMatchPattern' in fm:
        lines.append(f'fileMatchPattern: \"{fm[\"fileMatchPattern\"]}\"')
    lines.append('---')
    print('\n'.join(lines))
" 2>/dev/null || echo "")

  if [ -n "$frontmatter" ]; then
    echo -e "${frontmatter}\n${content}" > "$target_dir/$filename"
  elif [ "$target_ide" = "kiro" ]; then
    # Auto-convert alwaysApply/globs to Kiro's inclusion/fileMatchPattern format
    converted=$($PYTHON -c "
import re
content = open('$file').read()

# Extract frontmatter
fm_match = re.search(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
if not fm_match:
    print(content)
    exit(0)

fm_text = fm_match.group(1)
body = content[fm_match.end():]

# Parse alwaysApply
always = re.search(r'alwaysApply:\s*(true|false)', fm_text)
inclusion = 'always' if (always and always.group(1) == 'true') else 'manual'

# Parse globs → fileMatchPattern
globs = re.search(r'globs:\s*\[([^\]]*)\]', fm_text)
file_match = ''
if globs and inclusion == 'manual':
    # Convert glob array to comma-separated pattern
    patterns = [g.strip().strip('\"').strip(\"'\") for g in globs.group(1).split(',')]
    file_match = ', '.join(patterns)

# Parse description
desc = re.search(r'description:\s*[\"\\']?([^\"\\'\n]*)', fm_text)
desc_text = desc.group(1) if desc else ''

# Build Kiro frontmatter
lines = ['---']
lines.append(f'inclusion: {inclusion}')
if file_match:
    lines.append(f'fileMatchPattern: \"{file_match}\"')
if desc_text:
    lines.append(f'description: \"{desc_text}\"')
lines.append('---')
print('\n'.join(lines) + body)
" 2>/dev/null || echo "")
    if [ -n "$converted" ]; then
      echo "$converted" > "$target_dir/$filename"
    else
      echo "$content" > "$target_dir/$filename"
    fi
  else
    echo "$content" > "$target_dir/$filename"
  fi
}

# --- 3a. Universal steering (filtered by role) ---
STEERING_DIR="$TARGET_DIR/steering"
mkdir -p "$STEERING_DIR"
# Clean old steerings (role may have changed, or files removed from standard)
rm -f "$STEERING_DIR/"*.md 2>/dev/null || true

# Also prepare secondary IDE steering dirs
if [ "$MULTI_IDE" = true ]; then
  for extra_ide in $ALL_IDES; do
    [ "$extra_ide" = "$IDE" ] && continue
    EXTRA_DIR="${IDE_DIRS[$extra_ide]}"
    if [ -n "$EXTRA_DIR" ]; then
      mkdir -p "$EXTRA_DIR/steering"
      rm -f "$EXTRA_DIR/steering/"*.md 2>/dev/null || true
    fi
  done
fi

UNIVERSAL_COUNT=0
STEERING_SKIPPED=0
if [ -d "$TEMP_DIR/core/steering/universal" ]; then
  for file in "$TEMP_DIR/core/steering/universal/"*.md; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")

    # Role filter: read roles: from frontmatter
    if [ "$ROLE" = "all" ]; then
      copy_steering_file "$file" && UNIVERSAL_COUNT=$((UNIVERSAL_COUNT + 1))
      continue
    fi

    # Extract roles array from YAML frontmatter (e.g., roles: [analyst, developer])
    steering_roles=$($PYTHON - "$file" <<'ROLEEOF'
import re, sys
filepath = sys.argv[1]
with open(filepath) as f:
    content = f.read()
m = re.search(r'^roles:\s*\[([^\]]*)\]', content, re.MULTILINE)
if m:
    print(m.group(1).replace(' ', ''))
else:
    print('all')
ROLEEOF
)
    # Fallback if Python fails
    [ -z "$steering_roles" ] && steering_roles="all"

    # Check if user's role matches any steering role
    role_match=false
    if [ "$steering_roles" = "all" ]; then
      role_match=true
    else
      IFS=',' read -ra USER_ROLES <<< "$ROLE"
      IFS=',' read -ra STEER_ROLES <<< "$steering_roles"
      for ur in "${USER_ROLES[@]}"; do
        for sr in "${STEER_ROLES[@]}"; do
          if [ "$(echo "$ur" | tr -d ' ')" = "$(echo "$sr" | tr -d ' ')" ]; then
            role_match=true
            break 2
          fi
        done
      done
    fi

    if [ "$role_match" = true ]; then
      copy_steering_file "$file" && UNIVERSAL_COUNT=$((UNIVERSAL_COUNT + 1))
      # Also copy to secondary IDEs
      if [ "$MULTI_IDE" = true ]; then
        for extra_ide in $ALL_IDES; do
          [ "$extra_ide" = "$IDE" ] && continue
          EXTRA_DIR="${IDE_DIRS[$extra_ide]}"
          if [ -n "$EXTRA_DIR" ]; then
            # Copy raw content (secondary IDEs may use different frontmatter)
            sec_steering="$EXTRA_DIR/steering"
            cp "$STEERING_DIR/$filename" "$sec_steering/$filename" 2>/dev/null || true
          fi
        done
      fi
    else
      STEERING_SKIPPED=$((STEERING_SKIPPED + 1))
    fi
  done
fi
if [ "$STEERING_SKIPPED" -gt 0 ]; then
  echo "   ✅ Steering universal: $UNIVERSAL_COUNT archivos (role: $ROLE, $STEERING_SKIPPED omitidos)"
else
  echo "   ✅ Steering universal: $UNIVERSAL_COUNT archivos"
fi

# --- 3a-cache. Cache ALL stacks for scanner/initializer ---
CACHE_DIR=".sdd-cache/stacks"
rm -rf "$CACHE_DIR"
mkdir -p "$CACHE_DIR"
if [ -d "$TEMP_DIR/core/steering/stacks" ]; then
  cp -r "$TEMP_DIR/core/steering/stacks/"* "$CACHE_DIR/" 2>/dev/null || true
  CACHE_COUNT=$(find "$CACHE_DIR" -name '*.md' -type f 2>/dev/null | wc -l)
  echo "   ✅ Stack cache: $CACHE_COUNT archivos (para activación por scanner)"
fi

# --- 3b. Stack-specific steering (based on .sdd-config.json) ---
STACK_COUNT=0
STACKS_LOADED=""

# Read stacks from .sdd-config.json if exists
if [ -f ".sdd-config.json" ]; then
  STACKS=$($PYTHON -c "
import json
with open('.sdd-config.json') as f:
    config = json.load(f)
stacks = config.get('stacks', [])
print(' '.join(stacks))
" 2>/dev/null || echo "")
else
  STACKS=""
fi

if [ -n "$STACKS" ]; then
  for stack in $STACKS; do
    STACK_DIR="$TEMP_DIR/core/steering/stacks/$stack"
    if [ -d "$STACK_DIR" ]; then
      for file in "$STACK_DIR/"*.md; do
        [ -f "$file" ] && copy_steering_file "$file" && STACK_COUNT=$((STACK_COUNT + 1))
      done
      STACKS_LOADED="$STACKS_LOADED $stack"
    fi
  done
  echo "   ✅ Steering stacks: $STACK_COUNT archivos ($STACKS_LOADED)"
else
  echo "   ℹ️  Sin stacks configurados — usa project-scanner o project-initializer"
  echo "      para detectar y activar tu tech stack (sin re-sync)"
fi

# --- 3c. Powers (filtered by role) ---
POWERS_DIR="$TARGET_DIR/powers"
rm -rf "$POWERS_DIR"
mkdir -p "$POWERS_DIR"
POWERS_COUNT=0
POWERS_SKIPPED=0

for power_dir in "$TEMP_DIR/core/powers/"*/; do
  [ -d "$power_dir" ] || continue
  power_name=$(basename "$power_dir")
  power_file="$power_dir/POWER.md"

  if [ "$ROLE" = "all" ]; then
    cp -r "$power_dir" "$POWERS_DIR/$power_name"
    POWERS_COUNT=$((POWERS_COUNT + 1))
    continue
  fi

  # Extract role from POWER.md (## Role: <role>)
  if [ -f "$power_file" ]; then
    power_role=$(grep -i "^## Role:" "$power_file" 2>/dev/null | head -1 | sed 's/## Role:[[:space:]]*//' | tr '[:upper:]' '[:lower:]' | tr -d '\r')
  else
    power_role=""
  fi

  # Map role names
  case "$power_role" in
    analyst) allowed_role="analyst" ;;
    developer) allowed_role="developer" ;;
    qa) allowed_role="qa" ;;
    *) allowed_role="all" ;;  # No role = available to all
  esac

  # Check if power role matches any of the user's roles (comma-separated)
  role_match=false
  if [ "$allowed_role" = "all" ]; then
    role_match=true
  else
    IFS=',' read -ra USER_ROLES <<< "$ROLE"
    for ur in "${USER_ROLES[@]}"; do
      if [ "$(echo "$ur" | tr -d ' ')" = "$allowed_role" ]; then
        role_match=true
        break
      fi
    done
  fi

  if [ "$role_match" = true ]; then
    cp -r "$power_dir" "$POWERS_DIR/$power_name"
    POWERS_COUNT=$((POWERS_COUNT + 1))
  else
    POWERS_SKIPPED=$((POWERS_SKIPPED + 1))
  fi
done

if [ "$POWERS_SKIPPED" -gt 0 ]; then
  echo "   ✅ Powers: $POWERS_COUNT powers (role: $ROLE, $POWERS_SKIPPED omitidos)"
else
  echo "   ✅ Powers: $POWERS_COUNT powers"
fi

# --- 3d. Hooks ---
HOOKS_DIR="$TARGET_DIR/hooks"
mkdir -p "$HOOKS_DIR"
cp -f "$TEMP_DIR/core/hooks/"* "$HOOKS_DIR/"
HOOKS_COUNT=$(ls -1 "$HOOKS_DIR/"* 2>/dev/null | wc -l)
echo "   ✅ Hooks: $HOOKS_COUNT hooks"

# --- 3e. Templates ---
TEMPLATES_DIR="specs/_templates"
mkdir -p "$TEMPLATES_DIR"
cp -f "$TEMP_DIR/core/templates/"*.md "$TEMPLATES_DIR/" 2>/dev/null
TEMPLATES_COUNT=$(ls -1 "$TEMPLATES_DIR/"* 2>/dev/null | wc -l)
echo "   ✅ Templates: $TEMPLATES_COUNT templates"

# --- 3e2. Architecture doc templates (first sync only) ---
ARCH_TEMPLATES_DIR="docs/architecture/_templates"
if [ ! -d "$ARCH_TEMPLATES_DIR" ] && [ -d "$TEMP_DIR/core/templates/architecture" ]; then
  mkdir -p "$ARCH_TEMPLATES_DIR"
  for tmpl in "$TEMP_DIR/core/templates/architecture/"*-template.md; do
    cp -f "$tmpl" "$ARCH_TEMPLATES_DIR/"
  done
  ARCH_COUNT=$(ls -1 "$ARCH_TEMPLATES_DIR/"*.md 2>/dev/null | wc -l)
  echo "   ✅ Architecture templates: $ARCH_COUNT templates → docs/architecture/_templates/"
else
  echo "   ℹ️  Architecture templates: already exists, skipped"
fi

# --- 3f. Themes ---
THEMES_DIR="$TARGET_DIR/themes"
mkdir -p "$THEMES_DIR"
cp -f "$TEMP_DIR/core/themes/"* "$THEMES_DIR/"
THEMES_COUNT=$(ls -1 "$THEMES_DIR/"* 2>/dev/null | wc -l)
echo "   ✅ Themes: $THEMES_COUNT themes"

# --- 3f-extra. Selected theme (LOCAL - never overwrite) ---
if [ ! -f "design-system-theme.md" ]; then
  SELECTED_THEME=""
  if [ -f ".sdd-config.json" ]; then
    SELECTED_THEME=$($PYTHON -c "
import json
with open('.sdd-config.json') as f:
    config = json.load(f)
print(config.get('theme', ''))
" 2>/dev/null || echo "")
  fi
  
  if [ -n "$SELECTED_THEME" ] && [ -f "$TEMP_DIR/core/themes/THEME_${SELECTED_THEME^^}.md" ]; then
    cp "$TEMP_DIR/core/themes/THEME_${SELECTED_THEME^^}.md" "design-system-theme.md"
    echo "   ✅ Theme: $SELECTED_THEME → design-system-theme.md"
  else
    echo "   ℹ️  Sin theme seleccionado — se configura en Step 1.5 o project-initializer"
  fi
fi

# --- 3g. Multi-IDE: copy files to secondary IDEs BEFORE config/MCP ---
if [ "$MULTI_IDE" = true ]; then
  for extra_ide in $ALL_IDES; do
    [ "$extra_ide" = "$IDE" ] && continue
    EXTRA_DIR="${IDE_DIRS[$extra_ide]}"
    if [ -n "$EXTRA_DIR" ]; then
      echo "   🔄 Copiando archivos a $extra_ide ($EXTRA_DIR)..."
      ide_adapter "$extra_ide" files "$TARGET_DIR" "$EXTRA_DIR" "$TEMP_DIR"
      echo "   ✅ $extra_ide: archivos copiados"
    fi
  done
fi

# --- 3h. MCP (filtered by role) ---
SETTINGS_DIR="$TARGET_DIR/settings"
mkdir -p "$SETTINGS_DIR"

# Check if uvx is available (only developer/all need it: aws, aws-iac, python-analyzer)
HAS_UVX=false
if [ "$ROLE" = "developer" ] || [ "$ROLE" = "all" ]; then
  if command -v uvx &>/dev/null; then
    HAS_UVX=true
  else
    echo "   ⚠️  uvx no encontrado — instalando uv..."
    $PYTHON -m pip install uv -q 2>/dev/null
    if command -v uvx &>/dev/null; then
      HAS_UVX=true
      echo "   ✅ uv instalado"
    else
      echo "   ⚠️  No se pudo instalar uv — MCPs que usan uvx serán omitidos"
      echo "      Para instalar manualmente: pip install uv"
    fi
  fi
fi

$PYTHON - "$SETTINGS_DIR" "$HAS_UVX" "$TEMP_DIR" "$ROLE" <<'PYEOF'
import json, os, sys, re

settings_dir = sys.argv[1]
mcp_out = os.path.join(settings_dir, 'mcp.json')
has_uvx = sys.argv[2] == 'true'
temp_dir = sys.argv[3]
role = sys.argv[4]

try:
    with open(f'{temp_dir}/core/mcp/mcp.json') as f:
        mcp = json.load(f)
    with open(f'{temp_dir}/core/mcp/role-mcp-matrix.json') as f:
        matrix = json.load(f)

    if role == 'all':
        filtered = mcp
    else:
        # Support comma-separated multi-role (e.g. developer,analyst)
        roles = [r.strip() for r in role.split(',')]
        allowed = set()
        for r in roles:
            if r in matrix['roles']:
                allowed.update(matrix['roles'][r].get('required', []))
                allowed.update(matrix['roles'][r].get('optional', []))
        filtered = {'mcpServers': {k: v for k, v in mcp['mcpServers'].items() if k in allowed}}

    # Helper: resolve ${VAR} in a dict block (supports embedded vars like "Bearer ${TOKEN}")
    def resolve_vars(block, source):
        for k, v in block.items():
            if isinstance(v, str) and '${' in v:
                def replacer(m):
                    vn = m.group(1)
                    val = source.get(vn, m.group(0))
                    return str(val)
                block[k] = re.sub(r'\$\{([^}]+)\}', replacer, v)

    # Merge env/headers/args from .sdd-config.json
    config_path = '.sdd-config.json'
    if os.path.exists(config_path):
        with open(config_path) as cf:
            sdd_config = json.load(cf)
        mcp_env = sdd_config.get('env', {})
        if mcp_env:
            for sn, sc in filtered.get('mcpServers', {}).items():
                resolve_vars(sc.get('env', {}), mcp_env)
                resolve_vars(sc.get('headers', {}), mcp_env)
                # Also resolve ${VAR} in args[]
                if 'args' in sc:
                    for i, arg in enumerate(sc['args']):
                        if isinstance(arg, str) and '${' in arg:
                            sc['args'][i] = re.sub(r'\$\{([^}]+)\}', lambda m: str(mcp_env.get(m.group(1), m.group(0))), arg)

    # Merge credentials from .sdd-credentials.json
    email = ''  # Track for azure-devops warning
    creds_path = '.sdd-credentials.json'
    if os.path.exists(creds_path):
        with open(creds_path) as cf:
            creds = json.load(cf)
        creds = {k: v for k, v in creds.items() if not k.startswith('_') and v}
        # Auto-compute AZURE_DEVOPS_PAT_B64 from email:pat (base64 encoded)
        # Fallback: use git config user.email if AZURE_DEVOPS_EMAIL not set
        email = creds.get('AZURE_DEVOPS_EMAIL', '')
        if not email:
            import subprocess
            try:
                email = subprocess.run(['git', 'config', 'user.email'], capture_output=True, text=True, timeout=5).stdout.strip()
                if not email:
                    email = subprocess.run(['git', 'config', '--global', 'user.email'], capture_output=True, text=True, timeout=5).stdout.strip()
            except Exception:
                pass
        if email and creds.get('AZURE_DEVOPS_PAT'):
            import base64
            raw = f"{email}:{creds['AZURE_DEVOPS_PAT']}"
            creds['AZURE_DEVOPS_PAT_B64'] = base64.b64encode(raw.encode()).decode()
            # Persist PAT_B64 so future runs don't need email to resolve
            with open(creds_path) as _f:
                _saved = json.load(_f)
            _saved['AZURE_DEVOPS_PAT_B64'] = creds['AZURE_DEVOPS_PAT_B64']
            with open(creds_path, 'w') as _f:
                json.dump(_saved, _f, indent=2)
        if creds:
            for sn, sc in filtered.get('mcpServers', {}).items():
                resolve_vars(sc.get('env', {}), creds)
                resolve_vars(sc.get('headers', {}), creds)
                # Also resolve ${VAR} in args[]
                if 'args' in sc:
                    for i, arg in enumerate(sc['args']):
                        if isinstance(arg, str) and '${' in arg:
                            sc['args'][i] = re.sub(r'\$\{([^}]+)\}', lambda m: str(creds.get(m.group(1), m.group(0))), arg)

    # Helper: check if block has unresolved or empty vars
    def has_bad_vars(block):
        return any(
            isinstance(v, str) and ('${' in v or v.strip() == '')
            for v in block.values()
        )

    # Helper: check if args have unresolved vars
    def args_have_bad_vars(args):
        return any(isinstance(a, str) and '${' in a for a in args)

    # Filter out servers with unresolved/empty env/headers/args or missing commands
    final_servers = {}
    skipped_names = []
    for name, conf in filtered.get('mcpServers', {}).items():
        # Skip uvx-based MCPs if uvx not available
        if not has_uvx and conf.get('command') == 'uvx':
            skipped_names.append(name + ' (uvx)')
            continue
        env = conf.get('env', {})
        headers = conf.get('headers', {})
        args = conf.get('args', [])
        if has_bad_vars(env) or has_bad_vars(headers) or args_have_bad_vars(args):
            skipped_names.append(name)
        else:
            clean = {k: v for k, v in conf.items() if k not in ('roles', '_note', '_category')}
            # Resolve relative paths in env vars to absolute (e.g., MEMORY_FILE_PATH)
            if 'env' in clean:
                for ek, ev in clean['env'].items():
                    if isinstance(ev, str) and not os.path.isabs(ev) and ('/' in ev or '\\' in ev):
                        abs_path = os.path.join(os.getcwd(), ev).replace('\\', '/')
                        clean['env'][ek] = abs_path
                        # Create parent directory if it doesn't exist
                        parent = os.path.dirname(abs_path)
                        if parent:
                            os.makedirs(parent, exist_ok=True)
            final_servers[name] = clean

    result = {'mcpServers': final_servers}
    with open(mcp_out, 'w') as f:
        json.dump(result, f, indent=2)

    print(f'   MCP: {len(final_servers)} servers activos (role: {role})')
    if skipped_names:
        skip_list = ', '.join(skipped_names)
        print(f'   Omitidos ({len(skipped_names)}): {skip_list}')
        # Specific hint for azure-devops (most common issue)
        if 'azure-devops' in skipped_names and not email:
            print('      ⚠️ azure-devops requiere git identity para autenticación')
            print('         → Configura: git config --global user.email tu@empresa.com')
            print('         → Luego corre: bash sdd-sync.sh --refresh')
        else:
            print('      Configura variables faltantes y corre: bash sdd-sync.sh --refresh')

except Exception as e:
    # Always write a valid mcp.json even on error
    with open(mcp_out, 'w') as f:
        json.dump({'mcpServers': {}}, f, indent=2)
    print(f'   ERROR generando MCP config: {e}')
    print('   Se creo mcp.json vacio. Corre: bash sdd-sync.sh --refresh')
PYEOF

# --- 3h-lazy. Generate lazy-mcp config (wraps all MCPs for lazy loading) ---
# Opt-in via --mcp-proxy flag. Without it, each MCP connects directly (more reliable).
# NOT compatible with Antigravity (stdio handling + native lazy loading + 100-tool limit).
# When primary=antigravity + multi-IDE: generate proxy, then restore direct for antigravity.

# Save direct MCP config before lazy-mcp rewrites it (in .sdd-cache/ — survives adapter cleanup)
mkdir -p .sdd-cache
# Always cache the role-filtered template (with ${VAR} resolved) for --refresh
cp "$SETTINGS_DIR/mcp.json" ".sdd-cache/mcp-direct.json"
# Cache raw template (unresolved) so --refresh can re-resolve with new credentials
cp "$TEMP_DIR/core/mcp/mcp.json" ".sdd-cache/mcp-template.json"
cp "$TEMP_DIR/core/mcp/role-mcp-matrix.json" ".sdd-cache/role-mcp-matrix.json" 2>/dev/null || true
# Save sync flags for --refresh
echo "$USE_MCP_PROXY" > ".sdd-cache/use-mcp-proxy"
# Cache adapter engine + configs so --refresh can re-apply conversions
cp "$TEMP_DIR/adapters/adapter_engine.py" ".sdd-cache/adapter_engine.py" 2>/dev/null || true
for adapter_dir in "$TEMP_DIR"/adapters/*/; do
  adapter_name=$(basename "$adapter_dir")
  mkdir -p ".sdd-cache/adapters/$adapter_name"
  cp "$adapter_dir/adapter.json" ".sdd-cache/adapters/$adapter_name/adapter.json" 2>/dev/null || true
done


if [ "$USE_MCP_PROXY" = true ]; then
  echo "   🔄 Generando lazy-mcp config..."
  $PYTHON - "$SETTINGS_DIR" <<'LAZYEOF'
import json, os, sys, platform

settings_dir = sys.argv[1]
mcp_path = os.path.join(settings_dir, 'mcp.json')

try:
    with open(mcp_path) as f:
        mcp = json.load(f)

    servers = mcp.get('mcpServers', {})
    if not servers:
        print('   lazy-mcp: no servers to wrap')
        sys.exit(0)

    # Write servers config for lazy-mcp (requires "servers" array format)
    project_root = os.getcwd()
    lazy_config_path = os.path.join(project_root, '.lazy-mcp-servers.json')

    # Windows: spawn('npx') = ENOENT, spawn('npx.cmd') = EINVAL
    # Fix: use 'cmd /c npx' which lets Windows shell resolve .cmd files
    is_win = platform.system() == 'Windows'

    def wrap_cmd(cmd, args):
        if is_win:
            return 'cmd', ['/c', cmd] + (args or [])
        return cmd, args or []

    lazy_servers = []
    for name, conf in servers.items():
        entry = {
            'name': name,
            'description': conf.get('_note', f'{name} MCP server')
        }
        if 'command' in conf:
            cmd, args = wrap_cmd(conf['command'], conf.get('args', []))
            entry['command'] = cmd
            entry['args'] = args
        elif 'url' in conf:
            entry['url'] = conf['url']
        if 'env' in conf:
            entry['env'] = conf['env']
        if 'headers' in conf:
            entry['headers'] = conf['headers']
        lazy_servers.append(entry)

    lazy_config = {'servers': lazy_servers}
    with open(lazy_config_path, 'w') as f:
        json.dump(lazy_config, f, indent=2)
        f.write('\n')

    proxy_cmd, proxy_args = wrap_cmd('npx', ['lazy-mcp@latest', '--config', lazy_config_path])
    proxy_config = {
        'mcpServers': {
            'lazy-mcp': {
                'command': proxy_cmd,
                'args': proxy_args
            }
        }
    }
    with open(mcp_path, 'w') as f:
        json.dump(proxy_config, f, indent=2)

    print(f'   lazy-mcp: {len(servers)} servers wrapped → 1 proxy (on-demand loading)')

except Exception as e:
    print(f'   ⚠️ lazy-mcp config failed: {e}')
    print('   Keeping direct MCP config (no proxy)')
LAZYEOF

  server_count=$($PYTHON -c "import json; print(len(json.load(open('$SETTINGS_DIR/mcp.json')).get('mcpServers',{})))" 2>/dev/null || echo '?')

  # If primary is antigravity, save proxy version then restore direct
  if [ "$IDE" = "antigravity" ] && [ -f ".sdd-cache/mcp-direct.json" ]; then
    cp "$SETTINGS_DIR/mcp.json" ".sdd-cache/mcp-proxy.json"
    cp ".sdd-cache/mcp-direct.json" "$SETTINGS_DIR/mcp.json"
    echo "   ⚠️ Antigravity usa modo directo (lazy-mcp no compatible)"
    echo "      lazy-mcp generado para IDEs secundarios (kiro, cursor, etc.)"
  fi
else
  server_count=$($PYTHON -c "import json; print(len(json.load(open('$SETTINGS_DIR/mcp.json')).get('mcpServers',{})))" 2>/dev/null || echo '?')
  echo "   ✅ MCP config directo (${server_count} servers — cada uno conecta independiente)"
fi

# --- 3i. If primary IDE needs conversion, apply adapter ---
if ide_adapter "$IDE" needs_conversion; then
  echo "   🔄 Convirtiendo a formato $IDE..."
  # Copy MCP to IDE-specific location
  if [ -f "$TARGET_DIR/settings/mcp.json" ]; then
    ide_adapter "$IDE" mcp "$TARGET_DIR/settings/mcp.json" "$TARGET_DIR" > /dev/null
  fi
  # Run adapter conversion
  ide_adapter "$IDE" files "$TARGET_DIR" "$TARGET_DIR" "$TEMP_DIR"
  echo "   ✅ Formato $IDE aplicado"
fi

# --- 4. product.md (PROJECT ROOT - shared across all IDEs, never overwrite) ---
PRODUCT_DIR=$(ide_adapter "$IDE" product_dir "$TARGET_DIR")
if [ ! -f "$PRODUCT_DIR/product.md" ]; then
  mkdir -p "$PRODUCT_DIR"
  cp "$TEMP_DIR/core/env/product.md.template" "$PRODUCT_DIR/product.md"
  echo "   📝 product.md creado en raíz — edítalo con la info de tu proyecto"
fi

# --- 5. .sdd-config.json (PROJECT-level config - never overwrite) ---
if [ ! -f ".sdd-config.json" ]; then
  $PYTHON -c "
import json
with open('$TEMP_DIR/core/env/.sdd-config.template.json') as f:
    config = json.load(f)
config['host'] = '$HOST'
config['project_host'] = '$PROJECT_HOST'
config['detected_by'] = 'dev-sync'
with open('.sdd-config.json', 'w') as f:
    json.dump(config, f, indent=2)
"
  echo "   📝 .sdd-config.json creado — usa project-scanner para llenar stacks y repo_type"

  # --- Ask spec prefix (only on first setup) ---
  echo ""
  echo "  ¿Qué prefijo usan tus work items?"
  echo "    [1] AB#  (Azure DevOps: AB#123) — default"
  echo "    [2] GH#  (GitHub Issues: GH#123)"
  echo "    [3] JIRA- (Jira: JIRA-123)"
  echo "    [4] Ninguno (sin prefijo)"
  echo ""
  printf "  Selecciona (1-4): "
  read -r PREFIX_CHOICE
  case "$PREFIX_CHOICE" in
    2) SPEC_PREFIX="GH#" ;;
    3) SPEC_PREFIX="JIRA-" ;;
    4) SPEC_PREFIX="" ;;
    *) SPEC_PREFIX="AB#" ;;
  esac
  $PYTHON -c "
import json
with open('.sdd-config.json') as f:
    config = json.load(f)
config['spec_prefix'] = '$SPEC_PREFIX'
with open('.sdd-config.json', 'w') as f:
    json.dump(config, f, indent=2)
pfx = '$SPEC_PREFIX' if '$SPEC_PREFIX' else '(sin prefijo)'
print('   📝 Prefijo de specs: ' + pfx)
"
fi

# --- 5a. Ensure .sdd-credentials.json exists before saving token ---
if [ ! -f ".sdd-credentials.template.json" ]; then
  cp "$TEMP_DIR/core/env/.sdd-credentials.template.json" ".sdd-credentials.template.json"
fi
if [ ! -f ".sdd-credentials.json" ]; then
  cp ".sdd-credentials.template.json" ".sdd-credentials.json"
fi

# --- 5b. Save token to .sdd-credentials.json ---
$PYTHON -c "
import json
with open('.sdd-credentials.json') as f:
    creds = json.load(f)
if creds.get('SDD_SYNC_TOKEN', '') != '$TOKEN':
    creds['SDD_SYNC_TOKEN'] = '$TOKEN'
    with open('.sdd-credentials.json', 'w') as f:
        json.dump(creds, f, indent=2)
" 2>/dev/null || true

# --- 5b. Register IDE(s) in .sdd-config.json ---
if [ "$MULTI_IDE" = true ]; then
  IDES_TO_REGISTER="$ALL_IDES"
else
  IDES_TO_REGISTER="$IDE"
fi
$PYTHON -c "
import json
with open('.sdd-config.json') as f:
    config = json.load(f)
ides = config.get('ides', [])
for ide in '$IDES_TO_REGISTER'.split():
    if ide not in ides:
        ides.append(ide)
config['ides'] = ides
with open('.sdd-config.json', 'w') as f:
    json.dump(config, f, indent=2)
print('   📝 IDEs registrados: ' + ', '.join(ides))
"

# --- 5c. Register role + last_sync in .sdd-config.json ---
$PYTHON -c "
import json
from datetime import datetime, timezone
with open('.sdd-config.json') as f:
    config = json.load(f)
changed = False
if config.get('role') != '$ROLE':
    config['role'] = '$ROLE'
    changed = True
    print('   📝 Role $ROLE registrado en .sdd-config.json')
config['last_sync'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
changed = True
if changed:
    with open('.sdd-config.json', 'w') as f:
        json.dump(config, f, indent=2)
"

# --- 5d. Add missing fields with defaults (never overwrite existing) ---
$PYTHON -c "
import json
with open('.sdd-config.json') as f:
    config = json.load(f)
defaults = {
    'docs_language': 'es',
    'verbosity': 'detailed',
    'repo_type': '',
    'spec_prefix': '',
    'project_name': '',
    'project_type': '',
    'theme': '',
    'host': '',
    'project_host': '',
    'detected_by': ''
}
added = []
for key, value in defaults.items():
    if key not in config:
        config[key] = value
        added.append(key)
if added:
    with open('.sdd-config.json', 'w') as f:
        json.dump(config, f, indent=2)
    print('   📝 Campos agregados a .sdd-config.json: ' + ', '.join(added))
"

# --- 6. specs/ directory ---
mkdir -p "specs"


# --- 7. Credentials (inline, per role) ---
echo ""
echo "🔑 Configuración rápida (ENTER para omitir):"

# Define all credential prompts (short, clear)
declare -A CRED_PROMPTS=(
  ["AZURE_DEVOPS_PAT"]="PAT de Azure DevOps (dev.azure.com → Settings → Tokens)"
  ["AZURE_DEVOPS_EMAIL"]="Email de Azure DevOps (para autenticación MCP)"
  ["AZURE_DEVOPS_PROJECT"]="Proyecto en Azure DevOps (ej: MiProyecto)"
  ["GITHUB_PAT"]="GitHub PAT (github.com/settings/tokens)"
  ["DB_USER"]="Usuario de base de datos (local)"
  ["DB_PASS"]="Contraseña de base de datos (local)"
  ["DB_HOST"]="Host de base de datos (ej: localhost)"
  ["DB_PORT"]="Puerto de base de datos (ej: 5432)"
  ["DB_NAME"]="Nombre de base de datos"
  ["POSTMAN_API_KEY"]="Postman API Key (Settings → API Keys)"
  ["VERCEL_TOKEN"]="Vercel Token (Settings → Tokens)"
  ["STITCH_API_KEY"]="Stitch API Key (stitch.withgoogle.com/settings)"
)

# Define which credentials to ASK per role (inline prompts)
# AZURE_DEVOPS_EMAIL is NOT prompted — auto-detected from git config user.email
# AZURE_DEVOPS_PAT + PROJECT always asked (everyone uses Azure DevOps)
ROLE_ASK=""
case "$ROLE" in
  analyst)   ROLE_ASK="AZURE_DEVOPS_PAT AZURE_DEVOPS_PROJECT" ;;
  qa)        ROLE_ASK="AZURE_DEVOPS_PAT AZURE_DEVOPS_PROJECT POSTMAN_API_KEY" ;;
  developer) ROLE_ASK="AZURE_DEVOPS_PAT AZURE_DEVOPS_PROJECT" ;;
  all)       ROLE_ASK="AZURE_DEVOPS_PAT AZURE_DEVOPS_PROJECT POSTMAN_API_KEY" ;;
esac

# Add GITHUB_PAT only if project is on GitHub
if [ "$PROJECT_HOST" = "github" ]; then
  ROLE_ASK="$ROLE_ASK GITHUB_PAT"
fi

CREDS_UPDATED=false
for cred_key in $ROLE_ASK; do
  # Check if credential already has a value
  CRED_VAL=$($PYTHON -c "
import json
with open('.sdd-credentials.json') as f:
    creds = json.load(f)
val = creds.get('$cred_key', '')
if val and not val.startswith('_'):
    print(val)
" 2>/dev/null || echo "")

  # Also check .sdd-config.json for env values like AZURE_DEVOPS_PROJECT
  if [ -z "$CRED_VAL" ]; then
    CRED_VAL=$($PYTHON -c "
import json
with open('.sdd-config.json') as f:
    config = json.load(f)
val = config.get('env', {}).get('$cred_key', '')
if val:
    print(val)
" 2>/dev/null || echo "")
  fi

  if [ -z "$CRED_VAL" ]; then
    PROMPT_TEXT="${CRED_PROMPTS[$cred_key]}"

    # For AZURE_DEVOPS_EMAIL, suggest git email as default
    DEFAULT_HINT=""
    if [ "$cred_key" = "AZURE_DEVOPS_EMAIL" ]; then
      GIT_EMAIL=$(git config user.email 2>/dev/null || git config --global user.email 2>/dev/null || echo "")
      if [ -n "$GIT_EMAIL" ]; then
        DEFAULT_HINT=" [$GIT_EMAIL]"
      fi
    fi

    # Mask sensitive inputs (PAT, KEY, TOKEN, PASS)
    if [[ "$cred_key" == *"PASS"* ]] || [[ "$cred_key" == *"PAT"* ]] || [[ "$cred_key" == *"KEY"* ]] || [[ "$cred_key" == *"TOKEN"* ]]; then
      # Windows Git Bash: Ctrl+V inserts literal char (0x16) instead of paste
      if [[ "$(uname -s)" == *"MINGW"* ]] || [[ "$(uname -s)" == *"MSYS"* ]] || [[ "$OS" == "Windows_NT" ]]; then
        echo "      💡 Windows: usa Shift+Insert o clic derecho para pegar (Ctrl+V no funciona aquí)"
      fi
      read -sp "   $cred_key → $PROMPT_TEXT: " CRED_INPUT
      echo ""
      # Sanitize: remove control characters (Ctrl+V = 0x16, etc.)
      CRED_INPUT=$(echo "$CRED_INPUT" | tr -d '[:cntrl:]')
    else
      read -p "   $cred_key → $PROMPT_TEXT${DEFAULT_HINT}: " CRED_INPUT
    fi

    # If ENTER on AZURE_DEVOPS_EMAIL and we have git email, use it
    if [ -z "$CRED_INPUT" ] && [ "$cred_key" = "AZURE_DEVOPS_EMAIL" ] && [ -n "$GIT_EMAIL" ]; then
      CRED_INPUT="$GIT_EMAIL"
      echo "   → usando $GIT_EMAIL (de git config)"
    fi
    if [ -n "$CRED_INPUT" ]; then
      # Save to appropriate file
      if [[ "$cred_key" == "AZURE_DEVOPS_PROJECT" ]] || [[ "$cred_key" == "DB_HOST" ]] || [[ "$cred_key" == "DB_PORT" ]] || [[ "$cred_key" == "DB_NAME" ]]; then
        # Shared config → .sdd-config.json
        $PYTHON -c "
import json
with open('.sdd-config.json') as f:
    config = json.load(f)
if 'env' not in config:
    config['env'] = {}
config['env']['$cred_key'] = '$CRED_INPUT'
with open('.sdd-config.json', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null
      else
        # Secrets → .sdd-credentials.json
        $PYTHON -c "
import json
with open('.sdd-credentials.json') as f:
    creds = json.load(f)
creds['$cred_key'] = '$CRED_INPUT'
with open('.sdd-credentials.json', 'w') as f:
    json.dump(creds, f, indent=2)
" 2>/dev/null
      fi
      echo "   ✅ $cred_key configurado"
      CREDS_UPDATED=true
    else
      echo "   ⏳ $cred_key omitido"
    fi
  else
    echo "   ✅ $cred_key ya configurado"
  fi
done

# Developer: show pending credentials summary (no prompts)
if [ "$ROLE" = "developer" ] || [ "$ROLE" = "all" ]; then
  PENDING_CREDS=""
  for dev_key in DB_USER DB_PASS DB_HOST DB_PORT DB_NAME VERCEL_TOKEN STITCH_API_KEY POSTMAN_API_KEY GITHUB_PAT; do
    DEV_VAL=$($PYTHON -c "
import json, os
creds = {}
config_env = {}
if os.path.exists('.sdd-credentials.json'):
    with open('.sdd-credentials.json') as f:
        creds = json.load(f)
if os.path.exists('.sdd-config.json'):
    with open('.sdd-config.json') as f:
        config_env = json.load(f).get('env', {})
val = creds.get('$dev_key', '') or config_env.get('$dev_key', '')
if val and not str(val).startswith('_'):
    print('ok')
" 2>/dev/null || echo "")
    if [ -z "$DEV_VAL" ]; then
      PENDING_CREDS="$PENDING_CREDS $dev_key"
    fi
  done
  PENDING_CREDS=$(echo "$PENDING_CREDS" | xargs)
  if [ -n "$PENDING_CREDS" ]; then
    echo ""
    echo "   📝 Credenciales pendientes (llenar cuando las necesites):"
    for pk in $PENDING_CREDS; do
      echo "      - $pk"
    done
    echo "      → Edita .sdd-credentials.json → bash sdd-sync.sh --force"
  fi
fi

# --- 7b. Re-resolve MCP with new credentials ---
# MCP was generated in step 3h BEFORE credentials existed.
# Now that .sdd-credentials.json has values, re-resolve to include
# servers that were filtered (e.g. azure-devops needs PAT_B64).
if [ -f ".sdd-credentials.json" ] && [ -f ".sdd-cache/mcp-template.json" ]; then
  echo ""
  echo "🔄 Re-resolviendo MCP con credenciales nuevas..."
  $PYTHON - "$SETTINGS_DIR" "$ROLE" <<'RERESOLVEOF'
import json, os, re, sys, subprocess, base64

settings_dir = sys.argv[1]
role = sys.argv[2]

with open('.sdd-cache/mcp-template.json') as f:
    mcp = json.load(f)

# Role filter
matrix_path = '.sdd-cache/role-mcp-matrix.json'
if role != 'all' and os.path.exists(matrix_path):
    with open(matrix_path) as f:
        matrix = json.load(f)
    roles = [r.strip() for r in role.split(',')]
    allowed = set()
    for r in roles:
        if r in matrix.get('roles', {}):
            allowed.update(matrix['roles'][r].get('required', []))
            allowed.update(matrix['roles'][r].get('optional', []))
    mcp = {'mcpServers': {k: v for k, v in mcp.get('mcpServers', {}).items() if k in allowed}}

def resolve_vars(block, source):
    for k, v in block.items():
        if isinstance(v, str) and '${' in v:
            block[k] = re.sub(r'\$\{([^}]+)\}', lambda m: str(source.get(m.group(1), m.group(0))), v)

def resolve_args(args, source):
    for i, arg in enumerate(args):
        if isinstance(arg, str) and '${' in arg:
            args[i] = re.sub(r'\$\{([^}]+)\}', lambda m: str(source.get(m.group(1), m.group(0))), arg)

# Merge env from .sdd-config.json
if os.path.exists('.sdd-config.json'):
    with open('.sdd-config.json') as cf:
        mcp_env = json.load(cf).get('env', {})
    for sc in mcp.get('mcpServers', {}).values():
        resolve_vars(sc.get('env', {}), mcp_env)
        resolve_vars(sc.get('headers', {}), mcp_env)
        if 'args' in sc:
            resolve_args(sc['args'], mcp_env)

# Merge credentials
with open('.sdd-credentials.json') as cf:
    creds = json.load(cf)
creds = {k: v for k, v in creds.items() if not k.startswith('_') and v}

# Auto-compute AZURE_DEVOPS_PAT_B64
email = creds.get('AZURE_DEVOPS_EMAIL', '')
if not email:
    try:
        email = subprocess.run(['git', 'config', 'user.email'], capture_output=True, text=True, timeout=5).stdout.strip()
        if not email:
            email = subprocess.run(['git', 'config', '--global', 'user.email'], capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception:
        pass
if email and creds.get('AZURE_DEVOPS_PAT'):
    creds['AZURE_DEVOPS_PAT_B64'] = base64.b64encode(f"{email}:{creds['AZURE_DEVOPS_PAT']}".encode()).decode()
    # Persist PAT_B64 so future runs don't need email to resolve
    with open('.sdd-credentials.json') as _f:
        _saved = json.load(_f)
    _saved['AZURE_DEVOPS_PAT_B64'] = creds['AZURE_DEVOPS_PAT_B64']
    with open('.sdd-credentials.json', 'w') as _f:
        json.dump(_saved, _f, indent=2)

for sc in mcp.get('mcpServers', {}).values():
    resolve_vars(sc.get('env', {}), creds)
    resolve_vars(sc.get('headers', {}), creds)
    if 'args' in sc:
        resolve_args(sc['args'], creds)

# Filter unresolved
def has_bad_vars(block):
    return any(isinstance(v, str) and ('${' in v or v.strip() == '') for v in block.values())
def args_have_bad_vars(args):
    return any(isinstance(a, str) and '${' in a for a in args)

final_servers = {}
skipped = []
for name, conf in mcp.get('mcpServers', {}).items():
    env = conf.get('env', {})
    headers = conf.get('headers', {})
    args = conf.get('args', [])
    if has_bad_vars(env) or has_bad_vars(headers) or args_have_bad_vars(args):
        skipped.append(name)
    else:
        clean = {k: v for k, v in conf.items() if k not in ('roles', '_note', '_category')}
        # Resolve relative paths in env vars to absolute
        if 'env' in clean:
            for ek, ev in clean['env'].items():
                if isinstance(ev, str) and not os.path.isabs(ev) and ('/' in ev or '\\' in ev):
                    abs_path = os.path.join(os.getcwd(), ev).replace('\\', '/')
                    clean['env'][ek] = abs_path
                    parent = os.path.dirname(abs_path)
                    if parent:
                        os.makedirs(parent, exist_ok=True)
        final_servers[name] = clean

old_path = os.path.join(settings_dir, 'mcp.json')
cache_path = '.sdd-cache/mcp-direct.json'
# Read old count from cache (settings/mcp.json may have been moved by adapter)
if os.path.exists(cache_path):
    old_count = len(json.load(open(cache_path)).get('mcpServers', {}))
elif os.path.exists(old_path):
    old_count = len(json.load(open(old_path)).get('mcpServers', {}))
else:
    old_count = 0
new_count = len(final_servers)

mcp = {'mcpServers': final_servers}
os.makedirs(settings_dir, exist_ok=True)
with open(old_path, 'w') as f:
    json.dump(mcp, f, indent=2)
with open('.sdd-cache/mcp-direct.json', 'w') as f:
    json.dump(mcp, f, indent=2)

if new_count > old_count:
    gained = new_count - old_count
    print(f'   ✅ MCP actualizado: {old_count} → {new_count} servers (+{gained} con credenciales)')
else:
    print(f'   ✅ MCP: {new_count} servers (sin cambios)')
if skipped:
    print(f'   Omitidos ({len(skipped)}): {", ".join(skipped)}')
RERESOLVEOF
  # Re-apply adapter conversion (antigravity needs mcp_config.json)
  if ide_adapter "$IDE" needs_conversion 2>/dev/null; then
    ide_adapter "$IDE" mcp "$SETTINGS_DIR/mcp.json" "$TARGET_DIR" > /dev/null 2>&1
    # Clean up intermediate settings/ dir (antigravity uses mcp_config.json directly)
    [ -d "$SETTINGS_DIR" ] && rm -rf "$SETTINGS_DIR"
  fi

  # Regenerate proxy cache if --mcp-proxy was used (step 10a reads from .sdd-cache/mcp-proxy.json)
  if [ "$USE_MCP_PROXY" = true ]; then
    echo "   🔄 Regenerando lazy-mcp proxy con credenciales nuevas..."
    $PYTHON - <<'REPROXYEOF'
import json, os, sys, platform

with open('.sdd-cache/mcp-direct.json') as f:
    mcp = json.load(f)

servers = mcp.get('mcpServers', {})
project_root = os.getcwd()
lazy_config_path = os.path.join(project_root, '.lazy-mcp-servers.json')

# Windows: spawn('npx') = ENOENT, spawn('npx.cmd') = EINVAL
# Fix: use 'cmd /c npx' which lets Windows shell resolve .cmd files
is_win = platform.system() == 'Windows'

def wrap_cmd(cmd, args):
    if is_win:
        return 'cmd', ['/c', cmd] + (args or [])
    return cmd, args or []

lazy_servers = []
for name, conf in servers.items():
    entry = {'name': name, 'description': conf.get('_note', f'{name} MCP server')}
    if 'command' in conf:
        cmd, args = wrap_cmd(conf['command'], conf.get('args', []))
        entry['command'] = cmd
        entry['args'] = args
    elif 'url' in conf:
        entry['url'] = conf['url']
    if 'env' in conf:
        entry['env'] = conf['env']
    if 'headers' in conf:
        entry['headers'] = conf['headers']
    lazy_servers.append(entry)

with open(lazy_config_path, 'w') as f:
    json.dump({'servers': lazy_servers}, f, indent=2)
    f.write('\n')

proxy_cmd, proxy_args = wrap_cmd('npx', ['lazy-mcp@latest', '--config', lazy_config_path])
proxy_config = {
    'mcpServers': {
        'lazy-mcp': {
            'command': proxy_cmd,
            'args': proxy_args
        }
    }
}

with open('.sdd-cache/mcp-proxy.json', 'w') as f:
    json.dump(proxy_config, f, indent=2)
print('   Proxy actualizado: ' + str(len(servers)) + ' servers wrapped')
REPROXYEOF
    # Apply proxy to IDE's mcp.json (the re-resolve overwrote it with direct servers)
    if [ -f "$SETTINGS_DIR/mcp.json" ]; then
      cp ".sdd-cache/mcp-proxy.json" "$SETTINGS_DIR/mcp.json"
      echo "   ✅ $SETTINGS_DIR/mcp.json → lazy-mcp proxy"
    fi
  fi
fi

# --- 8. Copy sdd-sync.sh to project root (so new members don't need curl) ---
cp "$TEMP_DIR/sync/sdd-sync.sh" "./sdd-sync.sh" 2>/dev/null || true

# --- 8a. Register version ---
echo "$REMOTE_VERSION" > "$VERSION_FILE"

# --- 9a. Ensure SDD files are gitignored ---
# Get the correct MCP path for the primary IDE (no copy)
# Normalize backslashes to forward slashes (Windows adapter returns backslash, git needs forward)
PRIMARY_MCP_IGNORE=$(ide_adapter "$IDE" mcp_path "$TARGET_DIR" | tr '\\' '/')
SDD_GITIGNORE_ENTRIES=(
  ".sdd-cache/"
  ".sdd-credentials.json"
  "$PRIMARY_MCP_IGNORE"
  ".sdd-memory/"
  ".sdd-sync-temp/"
  ".lazy-mcp-servers.json"
  ".codebase-memory/"
  # MCP-generated temp files (not project code)
  ".playwright-mcp/"
  ".eslintcache"
  ".ruff_cache/"
  # Kiro native spec artifacts (SDD uses its own powers, not Kiro's spec mode)
  ".config.kiro"
  ".kiro/specs/"
)
# Add secondary IDE MCP entries
if [ "$MULTI_IDE" = true ]; then
  for extra_ide in $ALL_IDES; do
    [ "$extra_ide" = "$IDE" ] && continue
    EXTRA_DIR="${IDE_DIRS[$extra_ide]}"
    [ -n "$EXTRA_DIR" ] && SDD_GITIGNORE_ENTRIES+=("$(ide_adapter "$extra_ide" mcp_path "$EXTRA_DIR" | tr '\\' '/')")
  done
fi
for entry in "${SDD_GITIGNORE_ENTRIES[@]}"; do
  [ -z "$entry" ] && continue
  if [ -f ".gitignore" ]; then
    if ! grep -qF "$entry" ".gitignore" 2>/dev/null; then
      # Ensure file ends with newline before appending
      [ -s ".gitignore" ] && [ "$(tail -c 1 .gitignore)" != "" ] && echo "" >> ".gitignore"
      echo "$entry" >> ".gitignore"
    fi
  else
    echo "$entry" > ".gitignore"
  fi
done
echo "   📝 .gitignore actualizado — cache, credentials, mcp.json excluidos"

# Safety: un-track any gitignored files that were already committed
for entry in "${SDD_GITIGNORE_ENTRIES[@]}"; do
  [ -z "$entry" ] && continue
  # Remove trailing slash for git rm check
  clean_entry="${entry%/}"
  if git ls-files --error-unmatch "$clean_entry" &>/dev/null 2>&1; then
    git rm -r --cached "$clean_entry" &>/dev/null 2>&1 || true
    echo "   ⚠️  $clean_entry estaba tracked — removido del index (ya está en .gitignore)"
  fi
done

# --- 9b. Optimization tools (interactive install per role) ---
echo ""
echo "📊 Optimization tools:"
echo "   ✅ server-memory: activo (npx, no requiere instalación)"

# lazy-mcp — status
if [ "$USE_MCP_PROXY" = true ]; then
  echo "   ✅ lazy-mcp: activo (npx lazy-mcp@latest — on-demand tool loading)"
else
  echo "   ℹ️  lazy-mcp: no activo (usar --mcp-proxy para habilitar proxy on-demand)"
fi

# codebase-memory — npx, no requiere instalación
echo "   ✅ codebase-memory: activo (npx — knowledge graph + dead code)"

# diagrams + graphviz — developer only (para diagramas de infraestructura PNG)
if [ "$ROLE" = "developer" ] || [ "$ROLE" = "all" ]; then
  if command -v dot &>/dev/null; then
    echo "   ✅ graphviz: instalado ($(dot -V 2>&1 | head -1))"
    if $PYTHON -c "import diagrams" 2>/dev/null; then
      echo "   ✅ diagrams: instalado (Python diagrams library)"
    else
      echo "   ℹ️  diagrams: no instalado (opcional — pip install diagrams)"
    fi
  else
    echo "   ℹ️  graphviz: no instalado (opcional — sin él, solo diagramas Mermaid)"
    if [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]] || [[ "$OSTYPE" == "win32" ]] || [[ -n "$WINDIR" ]]; then
      echo "      Instalar: winget install Graphviz.Graphviz && pip install diagrams"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      echo "      Instalar: brew install graphviz && pip install diagrams"
    else
      echo "      Instalar: sudo apt install graphviz && pip install diagrams"
    fi
  fi
fi

# --- 9. Install pre-commit hook (protect standards) ---
mkdir -p .githooks
cat > .githooks/pre-commit << 'HOOK'
#!/bin/bash
# SDD Standard Protection — blocks local changes to synced standard files
# LOCAL files (product.md, design-system-theme.md) are excluded — they are project-specific
PROTECTED=$(git diff --cached --name-only \
  | grep -E "\.(kiro|cursor|claude|agents|windsurf|github)/(steering|powers|hooks)/" \
  | grep -v "product\.md" \
  | grep -v "design-system-theme\.md" \
  || true)
if [ -n "$PROTECTED" ]; then
  echo ""
  echo "❌ No puedes modificar archivos del standard SDD:"
  echo "$PROTECTED"
  echo ""
  echo "Estos archivos se actualizan solo via: bash sdd-sync.sh"
  echo "Si necesitas cambios, hazlos en el repo unipago-sdd-standard."
  exit 1
fi
HOOK
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks 2>/dev/null || true
echo "   🔒 Pre-commit hook instalado — archivos del standard protegidos"

# --- Cleanup moved to end (after step 10a which needs adapter files) ---

echo ""
echo "✅ Sync completado - v$REMOTE_VERSION"
echo "   IDE: $IDE ($TARGET_DIR)"
echo "   Role: $ROLE"
if [ -n "$STACKS_LOADED" ]; then
  echo "   Stacks:$STACKS_LOADED"
fi
echo ""

# --- 10a. Copy MCP to secondary IDEs ---
if [ "$MULTI_IDE" = true ]; then
  for extra_ide in $ALL_IDES; do
    [ "$extra_ide" = "$IDE" ] && continue
    EXTRA_DIR="${IDE_DIRS[$extra_ide]}"
    if [ -n "$EXTRA_DIR" ]; then
      # Find source MCP — antigravity always gets direct, others get proxy if available
      if [ "$extra_ide" = "antigravity" ] && [ -f ".sdd-cache/mcp-direct.json" ]; then
        SRC_MCP=".sdd-cache/mcp-direct.json"
      elif [ "$USE_MCP_PROXY" = true ] && [ -f ".sdd-cache/mcp-proxy.json" ]; then
        SRC_MCP=".sdd-cache/mcp-proxy.json"
      else
        SRC_MCP="$TARGET_DIR/settings/mcp.json"
        [ ! -f "$SRC_MCP" ] && SRC_MCP="$TARGET_DIR/mcp_config.json"
      fi
      if [ -f "$SRC_MCP" ]; then
        MCP_IGNORE=$(ide_adapter "$extra_ide" mcp "$SRC_MCP" "$EXTRA_DIR")
        if [ -f ".gitignore" ]; then
          if ! grep -qF "$MCP_IGNORE" ".gitignore" 2>/dev/null; then
            echo "$MCP_IGNORE" >> ".gitignore"
          fi
        fi
      fi
      echo "   ✅ $extra_ide: MCP copiado"
    fi
  done
fi

# --- 10b. Commit standard files (every sync, all IDEs) ---
if [ "$HAS_GIT_IDENTITY" = true ]; then
  # Build list of dirs to commit
  COMMIT_DIRS="$TARGET_DIR .githooks sdd-sync.sh .sdd-config.json .gitignore .sdd-standards-version .sdd-credentials.template.json specs product.md design-system-theme.md docs/architecture"
  if [ "$MULTI_IDE" = true ]; then
    for extra_ide in $ALL_IDES; do
      [ "$extra_ide" = "$IDE" ] && continue
      EXTRA_DIR="${IDE_DIRS[$extra_ide]}"
      [ -n "$EXTRA_DIR" ] && COMMIT_DIRS="$COMMIT_DIRS $EXTRA_DIR"
    done
  fi
  STANDARD_CHANGES=$(git status --porcelain 2>/dev/null | head -1)
  if [ -n "$STANDARD_CHANGES" ]; then
    # Add each path individually — skip silently if it doesn't exist
    for item in $COMMIT_DIRS; do
      [ -e "$item" ] && git add "$item" 2>/dev/null
    done
    # Also add .gitattributes if it exists
    [ -e ".gitattributes" ] && git add .gitattributes 2>/dev/null
    if git rev-parse HEAD >/dev/null 2>&1; then
      git commit --no-verify -m "chore: update SDD standard (v$REMOTE_VERSION)" 2>/dev/null
      echo "   ✅ Standard files committed (--no-verify)"
    else
      git commit --no-verify -m "chore: initial SDD standard setup (v$REMOTE_VERSION)" 2>/dev/null
      echo "   ✅ Commit inicial creado"
    fi
  fi
else
  # No git identity — commit with generic author so setup isn't lost
  COMMIT_DIRS="$TARGET_DIR .githooks sdd-sync.sh .sdd-config.json .gitignore .sdd-standards-version .sdd-credentials.template.json specs product.md design-system-theme.md docs/architecture"
  if [ "$MULTI_IDE" = true ]; then
    for extra_ide in $ALL_IDES; do
      [ "$extra_ide" = "$IDE" ] && continue
      EXTRA_DIR="${IDE_DIRS[$extra_ide]}"
      [ -n "$EXTRA_DIR" ] && COMMIT_DIRS="$COMMIT_DIRS $EXTRA_DIR"
    done
  fi
  STANDARD_CHANGES=$(git status --porcelain 2>/dev/null | head -1)
  if [ -n "$STANDARD_CHANGES" ]; then
    for item in $COMMIT_DIRS; do
      [ -e "$item" ] && git add "$item" 2>/dev/null
    done
    [ -e ".gitattributes" ] && git add .gitattributes 2>/dev/null
    GIT_AUTHOR="SDD Sync <sdd-sync@unipago.com>"
    if git rev-parse HEAD >/dev/null 2>&1; then
      git commit --no-verify --author="$GIT_AUTHOR" -m "chore: update SDD standard (v$REMOTE_VERSION)" 2>/dev/null
    else
      git commit --no-verify --author="$GIT_AUTHOR" -m "chore: initial SDD standard setup (v$REMOTE_VERSION)" 2>/dev/null
    fi
    echo "   ✅ Standard files committed (author: SDD Sync)"
    echo "   ℹ️  Configura tu git identity y haz amend si lo deseas:"
    echo "      git config --global user.name 'Tu Nombre'"
    echo "      git config --global user.email 'tu@empresa.com'"
    echo "      git commit --amend --reset-author --no-edit"
  fi
fi

echo "👉 Próximos pasos:"

if [ -z "$STACKS_LOADED" ]; then
  echo "   1. cp .sdd-credentials.template.json .sdd-credentials.json → llena tus credenciales"
  echo "   2. En $IDE: 'Escanea este proyecto' (project-scanner) o 'Inicializa el product.md' (project-initializer)"
  echo "      El scanner activará stacks + configurará MCPs automáticamente"
else
  if [ ! -f ".sdd-credentials.json" ]; then
    echo "   1. cp .sdd-credentials.template.json .sdd-credentials.json → llena tus credenciales"
    echo "   2. bash sdd-sync.sh --refresh (para aplicar credentials al MCP)"
  else
    echo "   1. Edita product.md con la info de tu proyecto"
  fi
fi

# Role-specific first action
echo ""
case "$ROLE" in
  analyst)
    echo "📋 Tu primer comando como Analista:"
    echo "   'Necesito crear requirements para [feature]'"
    ;;
  developer)
    echo "💻 Tu primer comando como Developer:"
    echo "   'Necesito diseñar la arquitectura para [feature]'"
    ;;
  qa)
    echo "🧪 Tu primer comando como QA:"
    echo "   'Necesito crear un test plan para [feature]'"
    ;;
  all)
    echo "🚀 Comienza según tu rol:"
    echo "   📋 Analista:  'Necesito crear requirements para [feature]'"
    echo "   💻 Developer: 'Necesito diseñar la arquitectura para [feature]'"
    echo "   🧪 QA:        'Necesito crear un test plan para [feature]'"
    ;;
esac

# --- Final cleanup ---
rm -rf "$TEMP_DIR"