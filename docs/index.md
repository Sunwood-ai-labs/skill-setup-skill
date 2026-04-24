---
layout: home

hero:
  name: Skill Setup
  text: Move Codex skills between Windows PCs.
  tagline: Export a manifest from one machine, clone the git-backed skill repositories, and rebuild .codex\skills junctions on the next machine.
  image:
    src: /skill-setup-header.png
    alt: Skill Setup migration banner
  actions:
    - theme: brand
      text: Export Guide
      link: /guide/export
    - theme: alt
      text: Restore Guide
      link: /guide/restore

features:
  - title: Manifest-based
    details: Records each registered junction, origin URL, branch, commit, repo folder, and dirty state.
  - title: Git-backed
    details: Restores committed skill repositories from origin and checks out the exported commit by default.
  - title: Windows-native
    details: Uses PowerShell and directory junctions to recreate Codex skill registrations under the target user profile.
---

<ol class="skill-setup-flow">
  <li><strong>1. Export</strong> Inspect registered skill junctions on the source PC.</li>
  <li><strong>2. Move Manifest</strong> Copy the JSON manifest to the target PC.</li>
  <li><strong>3. Restore</strong> Clone repos, check out commits, and register junctions.</li>
</ol>

## Start Here

Use the export guide on the source PC, then follow the restore guide on the target PC. The safety guide explains which existing paths are refused and why uncommitted changes are not copied.
