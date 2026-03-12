#!/usr/bin/env python3
import argparse
import subprocess
from pathlib import Path

SKILL_DIR = Path('/root/.openclaw/workspace/ikoL/skills/exa-search')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--profile', choices=['tech', 'social'], required=True)
    parser.add_argument('--out-dir', required=True)
    args = parser.parse_args()

    cmd = ['npx', 'tsx', 'scripts/run_pipeline.ts', '--profile', args.profile, '--out-dir', args.out_dir]
    subprocess.run(cmd, cwd=str(SKILL_DIR), check=True)
    print(args.out_dir)


if __name__ == '__main__':
    main()
