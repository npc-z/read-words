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
  ];

  languages.dart.enable = true;

  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  enterShell = ''
    flutter --version
  '';
}
