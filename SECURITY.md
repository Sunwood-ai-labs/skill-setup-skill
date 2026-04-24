# Security Policy

## Supported Versions

This repository currently supports the `main` branch.

## Reporting a Vulnerability

Please report security issues privately through GitHub security advisories when available. If advisories are not enabled for this repository, contact the repository owner through the GitHub profile associated with the project.

## Security Notes

Skill Setup works with local filesystem paths, git remotes, and junction registrations. Review manifests before running restore on a target PC, especially when they come from another machine.

The restore script refuses to overwrite existing repositories, existing non-junction skill paths, and repositories with local changes. It also stops on failed `git clone`, `git fetch`, or `git checkout` operations before registering a skill junction.
