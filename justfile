set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

default:
    just --list

build:
    python build_mod.py

install-local:
    python build_mod.py --install-local

secrets:
    uvx pre-commit run gitleaks --all-files

precommit:
    uvx pre-commit run --all-files

hook-install:
    uvx pre-commit install

