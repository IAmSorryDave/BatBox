#!/usr/bin/env python3
"""VERSION file manager with Jinja2 templating."""

import os
import re
from pathlib import Path
from jinja2 import Environment, FileSystemLoader, Template
from typing import Tuple


class VersionManager:
    """Manages semantic versioning with Jinja2 templating."""

    VERSION_PATTERN = re.compile(r'(\d+)\.(\d+)\.(\d+)(?:-(.*?))?(?:\+(.*?))?$')

    def __init__(self, version_file: str = 'VERSION', template_dir: str = '.'):
        """
        Initialize version manager.

        Args:
            version_file: Path to VERSION file
            template_dir: Directory for Jinja2 templates
        """
        self.version_file = Path(version_file)
        self.env = Environment(loader=FileSystemLoader(template_dir))
        self.major = 0
        self.minor = 0
        self.patch = 0
        self.prerelease = None
        self.build = None
        self.load()

    def load(self) -> None:
        """Load version from VERSION file."""
        if self.version_file.exists():
            content = self.version_file.read_text().strip()
            self._parse_version(content)
        else:
            self.major, self.minor, self.patch = 0, 0, 1

    def _parse_version(self, version_str: str) -> None:
        """Parse semantic version string."""
        match = self.VERSION_PATTERN.match(version_str)
        if not match:
            raise ValueError(f"Invalid version format: {version_str}")
        
        self.major, self.minor, self.patch = map(int, match.groups()[:3])
        self.prerelease = match.group(4)
        self.build = match.group(5)

    def __str__(self) -> str:
        """Return current version as string."""
        version = f"{self.major}.{self.minor}.{self.patch}"
        if self.prerelease:
            version += f"-{self.prerelease}"
        if self.build:
            version += f"+{self.build}"
        return version

    def bump_major(self) -> None:
        """Increment major version, reset minor and patch."""
        self.major += 1
        self.minor = 0
        self.patch = 0
        self.prerelease = None
        self.build = None

    def bump_minor(self) -> None:
        """Increment minor version, reset patch."""
        self.minor += 1
        self.patch = 0
        self.prerelease = None
        self.build = None

    def bump_patch(self) -> None:
        """Increment patch version."""
        self.patch += 1
        self.prerelease = None
        self.build = None

    def set_prerelease(self, prerelease: str) -> None:
        """Set prerelease identifier (alpha, beta, rc, etc)."""
        self.prerelease = prerelease
        self.build = None

    def set_build(self, build: str) -> None:
        """Set build metadata."""
        self.build = build

    def save(self) -> None:
        """Write version to VERSION file."""
        self.version_file.write_text(f"{self}\n")

    def render_template(self, template_name: str) -> str:
        """
        Render a Jinja2 template with version context.

        Args:
            template_name: Name of template file in template_dir

        Returns:
            Rendered template string
        """
        template = self.env.get_template(template_name)
        return template.render(
            major=self.major,
            minor=self.minor,
            patch=self.patch,
            prerelease=self.prerelease,
            build=self.build,
            version=str(self),
        )

    def render_string(self, template_string: str) -> str:
        """Render a template string directly."""
        template = Template(template_string)
        return template.render(
            major=self.major,
            minor=self.minor,
            patch=self.patch,
            prerelease=self.prerelease,
            build=self.build,
            version=str(self),
        )


if __name__ == '__main__':
    # Example usage
    vm = VersionManager('VERSION')
    
    print(f"Current version: {vm}")
    
    # Bump versions
    vm.bump_patch()
    print(f"After patch bump: {vm}")
    
    # Set prerelease
    vm.set_prerelease('alpha.1')
    print(f"With prerelease: {vm}")
    
    # Render templates
    template_str = "Version: {{ version }} ({{ major }}.{{ minor }}.{{ patch }})"
    print(f"Rendered: {vm.render_string(template_str)}")
    
    # Save to file
    vm.save()
    print(f"Saved to {vm.version_file}")
