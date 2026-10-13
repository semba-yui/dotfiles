# 入力は [既存の settings.json, Nix で宣言した設定]。
# hook は他のツールも同じイベントへ登録するため、配列を置き換えずに宣言した hook を足す。
# 前回の宣言を記録していないので、Nix から外したり変えたりした hook は既存側に残り、手で消す必要がある。
.[0] as $current
| .[1] as $declared
| ($current * $declared)
| if $declared | has("hooks") then
    .hooks = reduce ($declared.hooks | to_entries[]) as $event (
      $current.hooks // {};
      (.[$event.key] // []) as $existing
      | .[$event.key] = $existing + [$event.value[] | select(IN($existing[]) | not)]
    )
  else
    .
  end
