#!/usr/bin/env bash

set -euo pipefail

if [[ $# != 1 ]]; then
  printf 'Usage: update-flake-inputs.sh <flake-directory>\n' >&2
  exit 2
fi

# 公開直後に取り下げられた版や乗っ取られた版を取り込まないよう、公開から一定期間たったコミットだけを採用する。
minimum_release_age_days=7
cutoff_epoch=$(($(date +%s) - minimum_release_age_days * 86400))
cutoff="$(date -u -r "$cutoff_epoch" +%Y-%m-%dT%H:%M:%SZ)"

# 未認証でも 1 時間に 60 回まで使えるため、gh の認証は任意にする。
github_token="$(gh auth token 2>/dev/null || true)"

cd "$1"

# nixpkgs のチャンネルは Hydra のテストを通った版にしか進まない。途中のコミットを選ぶとバイナリキャッシュが
# 効かなくなるため、待機期間を設けずチャンネルの先頭に追従する。
echo "nixpkgs を更新します。"
nix flake update nixpkgs

# rev で固定した入力は flake.nix の書き換えでしか動かさないため対象外にする。
# タブは IFS の空白として連続が 1 つにまとめられるため、ブランチ指定がない欄は空にせず "-" にする。
jq -r '
  .nodes as $nodes
  | $nodes.root.inputs | to_entries[]
  | select((.value | type) == "string" and .key != "nixpkgs")
  | .key as $name
  | $nodes[.value]
  | select(.original.type == "github" and .original.rev == null)
  | [$name, .original.owner, .original.repo, (.original.ref // "-"), .locked.lastModified]
  | @tsv' flake.lock |
  while IFS=$'\t' read -r name owner repo ref locked_epoch; do
    query="until=$cutoff&per_page=1"
    [[ $ref == - ]] || query="sha=$ref&$query"
    # shellcheck disable=SC2086 # トークンがないときはヘッダーごと省くため、意図的に分割させる。
    read -r sha committed_at < <(
      curl -fsSL ${github_token:+--header "Authorization: Bearer $github_token"} \
        "https://api.github.com/repos/$owner/$repo/commits?$query" |
        jq -r '.[0] | [.sha, .commit.committer.date] | @tsv'
    )
    committed_epoch="$(date -u -j -f %Y-%m-%dT%H:%M:%SZ "$committed_at" +%s)"

    if ((committed_epoch <= locked_epoch)); then
      echo "$name: 公開から ${minimum_release_age_days} 日を過ぎた新しいコミットはありません。"
      continue
    fi
    echo "$name を ${sha:0:12}（${committed_at}）へ更新します。"
    nix flake update "$name" --override-input "$name" "github:$owner/$repo/$sha" </dev/null
  done
