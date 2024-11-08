# Part of the Carbon Language project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

"""Supports running a tool from the install filegroup."""

_RUN_TOOL_TMPL = """#!/usr/bin/env python3

import os
import sys

# These will be relative locations in bazel-out.
_SCRIPT_LOCATION = "{0}"
_TOOL_LOCATION = "{1}"

# Make sure we have the expected structure.
if not __file__.endswith(_SCRIPT_LOCATION):
    exit(
        "Unable to figure out path:\\n"
        f"  __file__: {{__file__}}\\n"
        f"  script: {{_SCRIPT_LOCATION}}\\n"
    )

# Run the tool using the absolute path, forwarding arguments.
tool_path = __file__.removesuffix(_SCRIPT_LOCATION) + _TOOL_LOCATION
os.execv(tool_path, [tool_path] + sys.argv[1:])
"""

def _run_tool_impl(ctx):
    content = _RUN_TOOL_TMPL.format(ctx.outputs.executable.path, ctx.file.tool.path)
    ctx.actions.write(
        output = ctx.outputs.executable,
        is_executable = True,
        content = content,
    )
    return [
        DefaultInfo(
            runfiles = ctx.runfiles(files = ctx.files.data),
        ),
        RunEnvironmentInfo(environment = ctx.attr.env),
    ]

run_tool = rule(
    doc = "Helper for running a tool in a filegroup.",
    implementation = _run_tool_impl,
    attrs = {
        "data": attr.label_list(allow_files = True),
        "env": attr.string_dict(),
        "tool": attr.label(
            allow_single_file = True,
            executable = True,
            cfg = "target",
            mandatory = True,
        ),
    },
    executable = True,
)
