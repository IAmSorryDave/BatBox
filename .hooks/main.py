

from argparse import ArgumentParser
from utilities import VersionFileManager

parser, semver = ArgumentParser(), VersionFileManager()

parser.add_argument("--major", action="store_true", help="Increment Semver by Major.")

parser.add_argument("--minor", action="store_true", help="Increment Semver by Minor.")

parser.add_argument("--patch", action="store_true", help="Increment Semver by Patch.")

parser.add_argument("--pre", action="store_true", help="Increment Semver by Pre-release.")

parser.add_argument("--build", action="store_true", help="Increment Semver by Build.")

if __name__ == '__main__':

    args = parser.parse_args()

    if args.patch:

        semver.bump_patch()

    if args.minor:

        semver.bump_minor()

    if args.major:

        semver.bump_major()

    if args.pre:

        semver.bump_prerelease()

    if args.build:

        semver.bump_build()

