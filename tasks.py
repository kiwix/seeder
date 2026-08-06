# pyright: strict, reportUntypedFunctionDecorator=false
import os
import pathlib
import platform
import shlex
import sys

from invoke.context import Context
from invoke.tasks import task  # pyright: ignore [reportUnknownVariableType]

from kiwixseeder.__about__ import __version__

use_pty = not os.getenv("CI", "")


@task(optional=["args"], help={"args": "pytest additional arguments"})
def test(ctx: Context, args: str = ""):
    """run tests (without coverage)"""
    ctx.run(f"pytest {args}", pty=use_pty)


@task(
    optional=["args", "html"],
    help={
        "args": "pytest additional arguments",
        "html": "flag to export html report",
    },
)
def coverage(ctx: Context, args: str = "", *, html: bool = False):
    """run tests and report coverage"""
    ctx.run(f"coverage run -m pytest {args}", pty=use_pty)
    ctx.run("coverage combine", warn=True, pty=use_pty)
    ctx.run("coverage report --show-missing", pty=use_pty)
    ctx.run("coverage xml", pty=use_pty)
    if html:
        ctx.run("coverage html", pty=use_pty)


@task(optional=["args"], help={"args": "ruff additional arguments"})
def lint(ctx: Context, args: str = "."):
    args = args or "."  # needed for hatch script
    ctx.run("ruff --version", pty=use_pty)
    ctx.run(f"ruff check {args}", pty=use_pty)


@task(optional=["args"], help={"args": "check tools (pyright) additional arguments"})
def check(ctx: Context, args: str = ""):
    """check static types with pyright"""
    ctx.run("pyright --version")
    ctx.run(f"pyright {args}", pty=use_pty)


@task(optional=["args"], help={"args": "ruff additional arguments"})
def fix(ctx: Context, args: str = "."):
    """fix all ruff rules"""
    args = args or "."  # needed for hatch script
    ctx.run(f"ruff check --fix {args}", pty=use_pty)
    lint(ctx, args)


@task(
    optional=["filename", "compress"],
    help={
        "filename": "output filename or fullname for the output binary",
        "no-compress": "dont zstd-compress binary (faster startup on macOS)",
    },
)
def binary(ctx: Context, filename: str = "", *, no_compress: bool = False):
    """build a standalone binary executable with nuitka"""
    fpath = (
        pathlib.Path(
            filename
            or f"kiwix-seeder_{platform.system().lower()}"
            f"_{__version__}{'-nc' if no_compress else ''}"
        )
        .expanduser()
        .resolve()
    )
    fpath.parent.mkdir(parents=True, exist_ok=True)
    pyexe = shlex.quote(sys.executable)

    command = [
        str(pyexe),
        "-m",
        "nuitka",
        "--onefile",
        "--python-flag=no_site,no_asserts,no_docstrings",
        "--include-package=kiwixseeder",
        "--show-modules",
        "--warn-implicit-exceptions",
        "--warn-unusual-code",
        "--assume-yes-for-downloads",
        f'--output-dir="{fpath.parent!s}"',
        f'--output-filename="{fpath.name}"',
        "--remove-output",
        "--no-progressbar",
    ]
    if no_compress:
        command.append("--onefile-no-compression")
    command.append("src/kiwixseeder/")
    ctx.run(" ".join(command))
