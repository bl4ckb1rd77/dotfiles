from __future__ import annotations

import argparse
import json
import subprocess
from typing import Callable, Iterable, Iterator, TypedDict


class Workspace(TypedDict):
    name: str


def print_workspaces(names: Iterable[str]) -> None:
    workspace_iter: Iterator[Workspace] = iter(json.loads(
        subprocess.check_output(['i3-msg', '-t', 'get_workspaces'])))
    workspaces: list[Workspace] = []
    workspace = next(workspace_iter, None)
    for name in names:
        if workspace and workspace['name'] == name:
            workspaces.append(workspace)
            workspace = next(workspace_iter, None)
        else:
            workspaces.append({'name': name})
    print(json.dumps(workspaces), flush=True)


def subscribe(callback: Callable[[bytes], None]) -> None:
    listener = subprocess.Popen(
        ['i3-msg', '-t', 'subscribe', '-m', '["workspace", "output"]'],
        stdout=subprocess.PIPE,
    )
    assert listener.stdout is not None, 'makes typechecker happy'
    for line in listener.stdout:
        callback(line)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('workspaces', nargs='+', metavar='WORKSPACE')
    args = parser.parse_args()
    workspaces: list[str] = args.workspaces
    print_workspaces(workspaces)
    subscribe(lambda _: print_workspaces(workspaces))


if __name__ == '__main__':
    main()
