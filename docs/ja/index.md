---
layout: home

hero:
  name: Skill Setup
  text: Windows PC 間で Codex skills を移行します。
  tagline: source PC で manifest を export し、target PC で git-backed skill repo を clone して .codex\skills の junction を復元します。
  image:
    src: /skill-setup-header.png
    alt: Skill Setup migration banner
  actions:
    - theme: brand
      text: エクスポート手順
      link: /ja/guide/export
    - theme: alt
      text: 復元手順
      link: /ja/guide/restore

features:
  - title: Manifest-based
    details: 登録 junction、origin URL、branch、commit、repo folder、dirty state を記録します。
  - title: Git-backed
    details: committed skill repo を origin から復元し、既定では export 時点の commit を checkout します。
  - title: Windows-native
    details: PowerShell と directory junction を使って、target user profile 配下の Codex skill 登録を再作成します。
---

<ol class="skill-setup-flow">
  <li><strong>1. エクスポート</strong> source PC の登録済み skill junction を調べます。</li>
  <li><strong>2. Manifest 移動</strong> JSON manifest を target PC にコピーします。</li>
  <li><strong>3. 復元</strong> repo を clone し、commit を checkout して junction を登録します。</li>
</ol>

## Start Here

source PC では export guide、target PC では restore guide から進めてください。safety guide には、既存 path を拒否する条件と未コミット変更をコピーしない理由をまとめています。
