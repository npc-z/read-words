{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  env.GREET = "read-words";

  packages = [
    pkgs.flutter
    pkgs.jq
    pkgs.chromium
  ];

  languages.dart.enable = true;

  # Web 端到端验证:playwright(浏览器用系统 chromium,见 scripts/web_check.py)
  languages.python.enable = true;
  languages.python.venv.enable = true;
  languages.python.venv.requirements = ./requirements-dev.txt;

  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  enterShell = ''
    flutter --version
  '';
}
