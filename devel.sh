docker build . -t module_devel:upstream

docker run --rm -it \
    -v "$(pwd)":/usr/local/openresty-module-src \
    module_devel:upstream bash
