#!/usr/bin/env python3
"""Gentoo entry point for the system-managed Resolve MCP server."""

import os
import runpy
import sys

APP_DIR = "@DATADIR@"
sys.path.insert(0, APP_DIR)

# Resolve 21.1 also ships its scripting module with the embedded interpreter.
# Keep explicit PYTHONPATH entries first and pass the fallback to panel children.
RESOLVE_MODULES = "@RESOLVE_HOME@/ResolvePython/lib/modules"
if os.path.isfile(os.path.join(RESOLVE_MODULES, "DaVinciResolveScript.py")):
    sys.path.append(RESOLVE_MODULES)
    os.environ["PYTHONPATH"] = os.pathsep.join(
        path for path in (os.environ.get("PYTHONPATH"), RESOLVE_MODULES) if path
    )

# Updates are managed by Portage; upstream can still be queried explicitly.
os.environ.setdefault("DAVINCI_RESOLVE_MCP_UPDATE_CHECK", "0")

if "@MODULE@" == "src.control_panel":
    runpy.run_module("src.control_panel", run_name="__main__")
elif "--version" in sys.argv:
    import json

    with open(os.path.join(APP_DIR, "package.json"), encoding="utf-8") as handle:
        print(json.load(handle)["version"])
elif "--help" in sys.argv or "-h" in sys.argv:
    print("Usage: davinci-resolve-mcp [--full] [--transport stdio|sse|streamable-http]")
    print("Run as the desktop user running DaVinci Resolve.")
    print("Local browser interface: davinci-resolve-mcp-control-panel [--help]")
else:
    runpy.run_module("src.server", run_name="__main__")
