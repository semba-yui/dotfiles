{
  apm-cli,
  python3Packages,
}:

# APM の必須 runtime dependency は、llm/openai の optional dependency から推移的に
# 得られる保証がないため、APM package 自身へ直接追加する。
apm-cli.overridePythonAttrs (previousAttrs: {
  dependencies = previousAttrs.dependencies ++ [ python3Packages.websockets ];
})
