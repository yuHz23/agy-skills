#!/usr/bin/env python3
"""PreInvocation iron-law reminder for Antigravity (agy-skills).

Prints a short ephemeral reminder before each model call so the
anti-fake-work rules survive long sessions (Antigravity has no automatic
context compaction). Ephemeral messages are dropped after the current turn,
so this costs one line of context per invocation.

Output (stdout):
    {"injectSteps": [{"ephemeralMessage": "..."}]}
"""
import json
import sys

REMINDER = (
    "Iron Law: no completion claims without fresh evidence — cite the command, "
    "exit code, and output excerpt from THIS session. Never fake or "
    "self-certify results; list any mocks/placeholders used."
)

print(json.dumps({"injectSteps": [{"ephemeralMessage": REMINDER}]}))