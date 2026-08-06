# list
ls:
    just --list

# build web
build-web:
    flutter build web --wasm

# open web
open-web: build-web
    python3 -m http.server 8080 --directory build/web
    xdg-open http://localhost:8080
