#!/usr/bin/env python3
"""Generates the CSS custom-property block in web/styles.css from
lib/theme.dart.

WHY THIS EXISTS
    The design tokens have to be readable from two places: Dart (so
    components can reference them and so code that needs an actual value
    — canvas, generated SVG, a chart fill — can get one) and CSS (so a
    theme switch is one attribute rather than a re-render).

    Only one of those can be the source of truth. It is lib/theme.dart.
    This script propagates it, so nobody has to remember to update a
    hex in two files and nobody discovers six months later that they
    disagree.

WHY PYTHON AND NOT DART
    It is a build-time text transform with no runtime dependency on the
    app, and it must be runnable without the Dart toolchain installed —
    which is the situation this repo is currently in.

USAGE
    python3 tool/gen_theme_css.py           # rewrite web/styles.css
    python3 tool/gen_theme_css.py --check   # verify, exit 1 on drift

    --check is what CI should run: it fails if styles.css does not match
    what theme.dart currently says, which is the only way this stays
    honest once someone edits a colour in a hurry.
"""

import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THEME = os.path.join(ROOT, "lib", "theme.dart")
STYLES = os.path.join(ROOT, "web", "styles.css")

BEGIN = "/* ── BEGIN GENERATED TOKENS — do not edit by hand ──────────────────── */"
END = "/* ── END GENERATED TOKENS ──────────────────────────────────────────── */"

# ── THE OS-FOLLOWING SWITCH ──────────────────────────────────────────
#
# FLIP THIS TO True ONLY WHEN NO FILE REFERENCES KolaDashboardColors.
#
# Why it is False right now: 37 components still interpolate DARK HEX
# directly into their inline styles (the deprecated compatibility layer
# in theme.dart). Those values do not respond to a theme change, because
# they are not references — they are literals baked into the markup.
#
# So if the token block honoured `prefers-color-scheme: light`, every
# user whose phone or laptop is in light mode would immediately get a
# #FAF6EF page behind 37 components still painting #1B1B1E cards and
# #F3EEE7 text. Light-on-light. The app would be unusable for them, and
# nobody would have chosen anything — it would just happen, at sunrise,
# on a device setting we never asked about.
#
# Dark is therefore forced until the migration finishes. `data-theme`
# still works for testing a converted screen in light mode; it is only
# the automatic OS-driven path that is held back, because that is the
# one that fires without anyone opting in.
#
# The check for flipping it: `grep -rn KolaDashboard lib/` is empty.
FOLLOW_SYSTEM = False


def parse_class(src, name):
    """Returns {constName: literal} for one abstract class.

    Handles BOTH quote styles. The colour tokens are single-quoted; the
    font stacks are double-quoted precisely because their values contain
    single quotes ("'Space Grotesk', sans-serif"). A parser that assumed
    one style silently dropped the fonts.
    """
    m = re.search(r"abstract class %s \{(.*?)\n\}" % name, src, re.S)
    if not m:
        raise SystemExit("could not find `abstract class %s` in theme.dart" % name)
    out = {}
    for k, single, double in re.findall(
            r"static const (\w+) = (?:'([^'\n]*)'|\"([^\"\n]*)\");", m.group(1)):
        out[k] = single if single else double
    return out


def resolve(src, cls, raw_cls, raw):
    """Extra consts on KolaDark/KolaLight, resolving `_D.x` references."""
    m = re.search(r"abstract class %s \{(.*?)\n\}" % cls, src, re.S)
    out = {}
    for name, val in re.findall(r"static const (\w+) = ([^;]+);", m.group(1)):
        val = val.strip()
        if val.startswith("'"):
            out[name] = val.strip("'")
        elif val.startswith(raw_cls + "."):
            key = val.split(".", 1)[1]
            if key not in raw:
                raise SystemExit("%s.%s references unknown %s" % (cls, name, val))
            out[name] = raw[key]
    return out


def kebab(name):
    """bg -> bg | mutedStrong -> muted-strong | tint0Surface -> tint-0-surface"""
    s = re.sub(r"([a-z])([A-Z])", r"\1-\2", name)
    s = re.sub(r"([a-z])(\d)", r"\1-\2", s)
    s = re.sub(r"(\d)([A-Za-z])", r"\1-\2", s)
    return s.lower()


# Emitted in this order, with these headings, so the generated CSS reads
# as a designed token set rather than an alphabetical dump.
GROUPS = [
    ("surfaces", ["bg", "card", "border", "pill"]),
    ("text", ["text", "mutedStrong", "muted"]),
    ("brand", ["accent", "accentFill", "accentText"]),
    ("semantic", ["success", "danger", "warning"]),
    ("semantic surfaces", ["successBg", "dangerBg", "warningBg",
                           "infoBg", "infoText", "successBright"]),
    ("category tints", ["tint0Surface", "tint0Icon", "tint1Surface", "tint1Icon",
                        "tint2Surface", "tint2Icon", "tint3Surface", "tint3Icon"]),
]


def render(values, indent="  "):
    lines = []
    for heading, keys in GROUPS:
        lines.append("%s/* %s */" % (indent, heading))
        for k in keys:
            if k not in values:
                raise SystemExit("token `%s` missing from theme.dart" % k)
            lines.append("%s--kola-%s: %s;" % (indent, kebab(k), values[k]))
        lines.append("")
    return "\n".join(lines).rstrip()


def build():
    src = io.open(THEME, encoding="utf-8").read()

    dark = parse_class(src, "_D")
    light = parse_class(src, "_L")
    dark.update(resolve(src, "KolaDark", "_D", dark))
    light.update(resolve(src, "KolaLight", "_L", light))

    fonts = parse_class(src, "KolaFonts")
    motion = parse_class(src, "KolaMotion")

    return "\n".join([
        BEGIN,
        "/* Generated from lib/theme.dart by tool/gen_theme_css.py.",
        " * Edit the Dart, then re-run the script. Editing this block",
        " * directly will be overwritten and will make the two disagree",
        " * in the meantime. */",
        "",
        "/* Dark is the default: no attribute set, no OS preference",
        " * expressed, this is what renders. */",
        ":root {",
        render(dark),
        "",
        "  /* typefaces */",
        "  --kola-font-display: %s;" % fonts["display"],
        "  --kola-font-sans: %s;" % fonts["sans"],
        "  --kola-font-mono: %s;" % fonts["mono"],
        "",
        "  /* motion — theme-independent, so declared once here rather",
        "   * than repeated in the light block */",
        "  --kola-motion-instant: %s;" % motion["instant"],
        "  --kola-motion-fast: %s;" % motion["fast"],
        "  --kola-motion-base: %s;" % motion["base"],
        "  --kola-motion-slow: %s;" % motion["slow"],
        "  --kola-ease: %s;" % motion["ease"],
        "  --kola-ease-out: %s;" % motion["easeOut"],
        "}",
        "",
        "/* An explicit choice, set on <html>. This is currently the ONLY",
        " * way to get light mode — the OS-driven path below is disabled. */",
        ":root[data-theme='light'] {",
        render(light),
        "}",
        "",
        follow_system_block(light),
        END,
    ])


def follow_system_block(light):
    """The OS-driven light block, emitted live or as a commented stub.

    See FOLLOW_SYSTEM at the top of this file for why it is currently
    held back. It is emitted as a comment rather than omitted so that
    turning it on is visibly one flag, not a rediscovery.
    """
    body = "\n".join([
        "/* No explicit choice: follow the operating system. Scoped to",
        " * :not([data-theme]) so a user who HAS chosen keeps their choice",
        " * when their phone flips to night mode at sunset. */",
        "@media (prefers-color-scheme: light) {",
        "  :root:not([data-theme]) {",
        render(light, indent="    "),
        "  }",
        "}",
    ])

    if FOLLOW_SYSTEM:
        return body

    return "\n".join([
        "/* OS-FOLLOWING IS DISABLED. Not an oversight — see FOLLOW_SYSTEM",
        " * in tool/gen_theme_css.py. In short: 37 components still paint",
        " * dark hex literals that cannot respond to a theme change, so",
        " * honouring the OS here would hand every light-mode user a light",
        " * page full of dark-on-dark components, without their asking.",
        " *",
        " * Set FOLLOW_SYSTEM = True and re-run this script once",
        " * `grep -rn KolaDashboard lib/` comes back empty. */",
        "",
        "/*",
        body.replace("*/", "* /"),
        "*/",
    ])


def main():
    check = "--check" in sys.argv
    generated = build()

    css = io.open(STYLES, encoding="utf-8").read()
    if BEGIN not in css or END not in css:
        raise SystemExit(
            "web/styles.css has no generated-token markers. Add:\n"
            "  %s\n  %s" % (BEGIN, END))

    start = css.index(BEGIN)
    stop = css.index(END) + len(END)
    updated = css[:start] + generated + css[stop:]

    if check:
        if updated != css:
            print("DRIFT: web/styles.css does not match lib/theme.dart.")
            print("Run: python3 tool/gen_theme_css.py")
            return 1
        print("styles.css is in sync with theme.dart")
        return 0

    if updated == css:
        print("styles.css already in sync — nothing written")
        return 0

    io.open(STYLES, "w", encoding="utf-8", newline="\n").write(updated)
    n = len(re.findall(r"--kola-", generated))
    print("wrote web/styles.css (%d custom properties across 3 blocks)" % n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
