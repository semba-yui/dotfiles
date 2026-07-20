#!/usr/bin/env bash
# =============================================================================
# Claude Code カスタムステータスライン
# =============================================================================
#
# [What] Claude Code のステータスバーに以下を3行で表示するスクリプト:
#   1行目: コンテキスト使用率 / モデル名 / セッションコスト(USD+JPY) / トークン数 / ブランチ
#   2行目: 5時間ローリングウィンドウのレート制限使用率 + リセット時刻
#   3行目: 7日間（週次）レート制限使用率 + リセット時刻
#
# [Why] Claude Code のデフォルト UI ではレート制限やコストの確認手段が限られている。
#   使いすぎを未然に防ぐため、常時表示で可視化する。
#
# [Why not] リアルタイム為替レート取得は外部API依存+レイテンシ増加のため採用せず、
#   固定レート（USD_TO_JPY）で近似値を表示する。
#
# [表示例]
#   Context: ▓▓░░░░░░░░  12%  Sonnet 5  s:$0.45(約¥71)  ↓10.1k ↑2.2k  ⎇ feature/xxx
#   Rate 5h: ▓▓▓░░░░░░░░  30%  ↻2時間15分 (14:30)
#   Rate 7d: ▓▓▓▓░░░░░░░░  42%  ↻3日5時間 (4/11 17:00)
#
# [依存] jq, awk, date, git (macOS 標準。`date -r <epoch>` は BSD date の仕様。
#   Linux の GNU date では意味が異なるため、macOS 以外への移植時は要修正)
#
# [設定方法] claude/.claude/settings.json の statusLine ブロックで参照する。
# =============================================================================

set -euo pipefail

# --- 設定値 ---
# [Why not] リアルタイム為替取得は外部依存+遅延のため固定レートを使用
# 必要に応じてこの値を更新する
USD_TO_JPY=162

# --- stdin から Claude Code が渡す JSON を読み取る ---
# [What] Claude Code はステータスライン更新のたびに、セッション情報を JSON で stdin に流す
input=$(cat)

# =============================================================================
# データ抽出
# =============================================================================
# [Why] jq の `// fallback` でフィールド未存在時のエラーを防止
# [Why not] grep/sed ではなく jq を使う理由: JSON 構造が保証されており、
#   パス指定で安全に値を取り出せるため

# モデル表示名（例: "Sonnet 5"）
MODEL=$(printf '%s' "$input" | jq -r '.model.display_name // "?"')

# コンテキストウィンドウ使用率（0-100の整数。セッション序盤は null になりうるため // 0 でガード）
PCT=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // 0 | floor | tostring')

# セッション累計コスト（USD）
SESSION_COST=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0')

# 作業ディレクトリ（git ブランチ取得のフォールバック用）
CWD=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# 現在のコンテキストウィンドウに含まれる入力/出力トークン数
# [Why] context_window.used_percentage とは異なる指標。
#   used_percentage は「現在のコンテキストウィンドウの消費率」。
# [Why not] "セッション累計" ではない点に注意: Claude Code v2.1.132 以降、
#   total_input_tokens / total_output_tokens は直近の API レスポンス時点で
#   コンテキストウィンドウに乗っているトークン数を指し、/compact 等でリセットされる。
#   セッション全体の累計トークン数を返す公式フィールドは存在しない。
INPUT_TOKENS=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(printf '%s' "$input" | jq -r '.context_window.total_output_tokens // 0')

# レート制限（Claude.ai Pro/Max/Team のみ。API Key 利用時は存在しない）
# [Why] `// empty` を使う理由: セッション開始直後や API Key 利用時はフィールド自体が
#   存在しない。`// empty` なら空文字が返り、後続の if [ -n ] で安全にスキップできる。
#   `// 0` だと「0%」と「データなし」の区別がつかなくなる
RATE_5H=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
RATE_5H_RESET=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
RATE_7D=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
RATE_7D_RESET=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Git ブランチ
# [Why] worktree.branch を優先する理由: Agent tool の isolation: "worktree" 使用時、
#   CWD とは異なるブランチで作業している場合がある。worktree 情報が正確。
# [Why not] worktree.name や worktree.path は通常作業では空のため表示しない
BRANCH=$(printf '%s' "$input" | jq -r '.worktree.branch // ""')
if [ -z "$BRANCH" ] && [ -n "$CWD" ]; then
  BRANCH=$(cd "$CWD" && git branch --show-current 2>/dev/null || echo "")
fi

# =============================================================================
# ANSI カラー定義
# =============================================================================
# [Why] $'\033[...' 形式を使う理由: 変数に実際の ESC 文字を格納でき、
#   printf 時に追加のエスケープ処理が不要になる
R=$'\033[0m'       # リセット
BOLD=$'\033[1m'    # 太字
DIM=$'\033[2m'     # 薄字（補助情報用）
GREEN=$'\033[32m'  # 0-49%: 余裕あり
YELLOW=$'\033[33m' # 50-74%: 注意
RED=$'\033[31m'    # 75%+: 危険

CYAN=$'\033[36m'   # ラベル・モデル名用

# =============================================================================
# 共通関数
# =============================================================================

# --- バー生成 ---
# [What] パーセンテージを ▓ と ░ で視覚化（幅10文字固定）
# [Why] 幅10文字の理由: 1文字=10% で直感的に読める
# [Why not] Unicode のプログレスバー文字（█▉▊等）は等幅フォントでの幅が
#   環境依存のため、▓/░ の2種で統一
make_bar() {
  local pct="$1" width=10
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}▓"; done
  for ((i=0; i<empty; i++)); do bar="${bar}░"; done
  echo "$bar"
}

# --- 色選択 ---
# [What] パーセンテージに応じた ANSI カラーコードを返す
# [Why] 閾値 50/75 の理由: コンテキストとレート制限の両方に共通で使える汎用閾値。
#   75% 超で赤にすることで、制限到達前に気づける余裕を持たせる
pick_color() {
  local pct="$1"
  if   [ "$pct" -ge 75 ]; then printf '%s' "$RED"
  elif [ "$pct" -ge 50 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

# --- トークン数フォーマット ---
# [What] 1000以上を "12.3k" 形式に短縮
# [Why] 生の数値（例: 123456）は長すぎてステータスラインの幅を圧迫する
# [Why not] M（百万）表記は通常セッションで到達しにくいため未対応
fmt_tokens() {
  local t="$1"
  if [ "$t" -ge 1000 ]; then
    awk "BEGIN{printf \"%.1fk\", $t/1000}"
  else
    echo "$t"
  fi
}

# --- コストフォーマット ---
# [What] USD 表示 + 固定レートでの円換算を併記（例: "$0.45(約¥71)"）
# [Why] 円換算があると体感しやすい
# [Why not] リアルタイム為替は外部API依存+ステータスライン更新ごとにHTTPリクエストが
#   走りレイテンシが増加するため、固定レートで妥協する
fmt_cost() {
  local v="$1"
  if [[ "$v" =~ ^[0-9] ]]; then
    local yen
    yen=$(awk "BEGIN{printf \"%.0f\", $v * $USD_TO_JPY}")
    printf "\$%.2f(約¥%s)" "$v" "$yen"
  else
    printf "%s" "$v"
  fi
}

# --- リセット残り時間 + 時刻フォーマット ---
# [What] Unix タイムスタンプ（秒）から「↻残り時間 (リセット時刻)」形式の文字列を生成
# [Why] 残り時間だけでは「いつリセットされるか」が直感的にわからない。
#   逆にリセット時刻だけでは「あとどれくらい待つか」の計算が必要。両方出す。
fmt_reset() {
  local reset_at="$1"
  local now
  now=$(date +%s)
  local diff=$(( reset_at - now ))
  if [ "$diff" -le 0 ]; then echo "リセット済み"; return; fi

  local days=$(( diff / 86400 ))
  local hours=$(( (diff % 86400) / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))

  # 残り時間（日本語表記）
  local remaining="↻"
  if [ "$days" -gt 0 ]; then remaining="${remaining}${days}日${hours}時間"
  elif [ "$hours" -gt 0 ]; then remaining="${remaining}${hours}時間${mins}分"
  else remaining="${remaining}${mins}分"
  fi

  # リセット時刻（ローカルタイムゾーン = マシン設定に依存、通常 JST）
  # [Why] 3パターンに分ける理由:
  #   - 24時間以内: 日付不要、時刻だけで十分
  #   - 同年内: 年は冗長なので月/日のみ
  #   - 年またぎ: 12月末の週次制限で1月にリセットされるケースに対応
  local reset_time reset_year current_year
  reset_year=$(date -r "$reset_at" "+%Y")
  current_year=$(date "+%Y")
  if [ "$diff" -lt 86400 ]; then
    reset_time=$(date -r "$reset_at" "+%H:%M")
  elif [ "$reset_year" != "$current_year" ]; then
    reset_time=$(date -r "$reset_at" "+%Y/%-m/%-d %H:%M")
  else
    reset_time=$(date -r "$reset_at" "+%-m/%-d %H:%M")
  fi

  echo "${remaining} (${reset_time})"
}

# =============================================================================
# 値の準備
# =============================================================================

CTX_BAR=$(make_bar "$PCT")
CTX_COLOR=$(pick_color "$PCT")
COST_FMT=$(fmt_cost "$SESSION_COST")
IN_FMT=$(fmt_tokens "$INPUT_TOKENS")
OUT_FMT=$(fmt_tokens "$OUTPUT_TOKENS")

BRANCH_STR=""
[ -n "$BRANCH" ] && BRANCH_STR="  ${DIM}⎇ ${BRANCH}${R}"

# =============================================================================
# 出力
# =============================================================================
# [Why] ラベルを "Context:" / "Rate 5h:" / "Rate 7d:" で統一する理由:
#   いずれも8文字幅で、バーの開始位置が縦に揃う。
# [Why not] モデル名をラベルに含めない理由（例: "Context(Sonnet):"）:
#   モデル名が長い場合にラベル幅が崩れ、バーの縦位置がずれるため。バーの後に配置する。

# 1行目: コンテキスト + セッション情報
printf "${BOLD}${CYAN}Context${R}: ${CTX_COLOR}%s  %d%%${R}  ${BOLD}${CYAN}%s${R}  ${DIM}s:%s${R}  ${DIM}↓%s ↑%s${R}%s\n" \
  "$CTX_BAR" "$PCT" "$MODEL" "$COST_FMT" "$IN_FMT" "$OUT_FMT" "$BRANCH_STR"

# 2行目: 5時間ローリングウィンドウのレート制限
# [Why] if [ -n ] でガードする理由: セッション開始直後（最初の API 応答前）や
#   API Key 利用時はフィールドが存在せず空文字になる。表示すると "0%" と紛らわしい。
if [ -n "$RATE_5H" ]; then
  RATE_5H_INT=${RATE_5H%.*}
  RATE_5H_BAR=$(make_bar "$RATE_5H_INT")
  RATE_5H_COLOR=$(pick_color "$RATE_5H_INT")
  RATE_5H_RESET_FMT=""
  [ -n "$RATE_5H_RESET" ] && RATE_5H_RESET_FMT=$(fmt_reset "$RATE_5H_RESET")
  printf "${RATE_5H_COLOR}Rate 5h${R}: ${RATE_5H_COLOR}%s  %d%%${R}  ${DIM}%s${R}\n" \
    "$RATE_5H_BAR" "$RATE_5H_INT" "$RATE_5H_RESET_FMT"
fi

# 3行目: 7日間（週次）レート制限
if [ -n "$RATE_7D" ]; then
  RATE_7D_INT=${RATE_7D%.*}
  RATE_7D_BAR=$(make_bar "$RATE_7D_INT")
  RATE_7D_COLOR=$(pick_color "$RATE_7D_INT")
  RATE_7D_RESET_FMT=""
  [ -n "$RATE_7D_RESET" ] && RATE_7D_RESET_FMT=$(fmt_reset "$RATE_7D_RESET")
  printf "${RATE_7D_COLOR}Rate 7d${R}: ${RATE_7D_COLOR}%s  %d%%${R}  ${DIM}%s${R}\n" \
    "$RATE_7D_BAR" "$RATE_7D_INT" "$RATE_7D_RESET_FMT"
fi
