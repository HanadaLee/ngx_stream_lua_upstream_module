# vim:set ft= ts=4 sw=4 et:

BEGIN {
    $ENV{TEST_NGINX_RESTY_LUALIB} ||= "/usr/local/openresty/lualib";
    $ENV{TEST_NGINX_INIT_BY_LUA} =
        "package.path = '$ENV{TEST_NGINX_RESTY_LUALIB}/?.lua;' "
        . ".. (package.path or ''); require 'resty.core'";
}

use Test::Nginx::Socket::Lua::Stream;

repeat_each(1);
plan tests => repeat_each() * blocks() * 3;

no_long_string();
run_tests();

__DATA__

=== TEST 1: list upstreams and configured servers
--- stream_config
    upstream primary_backend {
        server 127.0.0.1:9001 weight=3 max_fails=4 fail_timeout=5s;
        server 127.0.0.1:9002 backup down;
    }

    upstream secondary_backend {
        server 127.0.0.1:9003;
    }
--- stream_server_config
    content_by_lua_block {
        local upstream = require "ngx.upstream"
        local names = upstream.get_upstreams()
        table.sort(names)

        local servers = assert(upstream.get_servers("primary_backend"))
        ngx.say(table.concat(names, ","))
        ngx.say(servers[1].name, ":", servers[1].weight, ":",
                servers[1].max_fails, ":", servers[1].fail_timeout)
        ngx.say(servers[2].name, ":", servers[2].backup, ":",
                servers[2].down)

        local missing, err = upstream.get_servers("missing")
        ngx.say(missing == nil)
        ngx.say(err)
    }
--- stream_response
primary_backend,secondary_backend
127.0.0.1:9001:3:4:5
127.0.0.1:9002:true:true
true
upstream not found
--- no_error_log
[error]



=== TEST 2: primary and backup peer state can be changed
--- stream_config
    upstream backend {
        server 127.0.0.1:9011 weight=2;
        server 127.0.0.1:9012 backup;
    }
--- stream_server_config
    content_by_lua_block {
        local upstream = require "ngx.upstream"
        local primary = assert(upstream.get_primary_peers("backend"))
        local backup = assert(upstream.get_backup_peers("backend"))

        ngx.say(primary[1].name, ":", primary[1].weight, ":",
                primary[1].down == nil)
        ngx.say(backup[1].name, ":", backup[1].weight, ":",
                backup[1].down == nil)

        assert(upstream.set_peer_down("backend", false, 0, true))
        assert(upstream.set_peer_down("backend", true, 0, true))

        primary = assert(upstream.get_primary_peers("backend"))
        backup = assert(upstream.get_backup_peers("backend"))
        ngx.say(primary[1].down)
        ngx.say(backup[1].down)

        assert(upstream.set_peer_down("backend", false, 0, false))
        assert(upstream.set_peer_down("backend", true, 0, false))
    }
--- stream_response
127.0.0.1:9011:2:true
127.0.0.1:9012:1:true
true
true
--- no_error_log
[error]



=== TEST 3: invalid peers and missing proxy context
--- stream_config
    upstream backend {
        server 127.0.0.1:9021;
    }
--- stream_server_config
    content_by_lua_block {
        local upstream = require "ngx.upstream"
        local ok, err = upstream.set_peer_down("backend", false, 2, true)

        ngx.say(ok == nil)
        ngx.say(err)
        ngx.say(upstream.current_upstream_name() == nil)
    }
--- stream_response
true
bad peer id
true
--- no_error_log
[error]
