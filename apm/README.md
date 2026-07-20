# APM

外部配布されているskills、agents、hooks、plugins、MCP serverの依存関係を管理します。

- `apm.yml`: 利用する外部依存と展開先
- `apm.lock.yaml`: 解決したcommitとcontent hash
- `.agents/`、`.claude/`、`.codex/`、`.github/`: APMが生成した成果物
- `apm_modules/`: lockから再生成できるためGit管理しないcache

自作設定の正本はここへ置かず、`../agents/` または各ツールのディレクトリへ置きます。APM生成物と自作ファイルで同じ名前を使わないでください。
