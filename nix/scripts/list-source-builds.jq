# 入力はビルド予定の derivation を渡した `nix derivation show` の出力。そのうちパッケージを
# ソースからビルドするものの名前を返す。
# preferLocalBuild は Home Manager の設定生成にも付いていないものがあり、パッケージと見分けられない。
# 設定生成は src も srcs も持たないため、その有無で分ける。
# derivations を持たない形式に変わったら、空の一覧として通さず、反復に失敗して update を止める。
[
  .derivations[]
  | ((.env // {}) + (.structuredAttrs // {})) as $attributes
  | select($attributes.src != null or $attributes.srcs != null)
  | .name
]
| sort[]
