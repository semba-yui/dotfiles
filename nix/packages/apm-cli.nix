{ apm-cli }:

# APM は websockets の上限を宣言しているが、使うのは sync.client.connect と send/recv だけで、
# 上限の先にある非互換変更に当たらない。上限のせいで nixpkgs の websockets と組めず build が落ちるため外す。
apm-cli.overridePythonAttrs (previousAttrs: {
  pythonRelaxDeps = (previousAttrs.pythonRelaxDeps or [ ]) ++ [ "websockets" ];
})
