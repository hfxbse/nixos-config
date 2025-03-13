#!/usr/bin/env python

import argparse
import json
import subprocess

def fetch_packages(lock):
    out = { "packages": [] }

    for package in lock["packages"]:
        source, name = package["rootUri"].rsplit('/', 1)

        if "pub.dev" not in source:
            continue

        url = f"https://pub.dev/api/archives/{name}.tar.gz"
        hash = subprocess.check_output(
            ["nix-prefetch-url", "--unpack", "--type", "sha256", url],
            text=True
        ).splitlines()[-1]

        hash = subprocess.check_output(
            ["nix", "hash", "convert", "--hash-algo", "sha256", hash],
            text=True
        ).splitlines()[-1]

        out['packages'].append({"url": url, "hash": hash, "name": name})

    return out


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="pub lock hash fetcher",
        description="Generations a list of download urls and matching hashes form a dart pub lock file"
    )

    parser.add_argument("--source", default=".dart_tool/package_config.json")
    parser.add_argument("--out", default="package-sources.json")
    args = parser.parse_args()

    with open(args.source) as file:
        lock = json.load(file)

    result = fetch_packages(lock)

    with open(args.out, "w") as file:
        json.dump(result, file, indent = 2)
