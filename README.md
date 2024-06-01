# Lua XMPP Privacy Bot

This bot replaces links to popular sites such as youtube with privacy respecting front ends such as individuous. It is written in 100% pure lua

# How to run

Make sure `make`, `tar`, `gzip`, `lua`, and `luarocks` are installed.

Then do `luarocks install luasocket luaexpat luasec`

Next configure the bot to your liking in `config.lua`. Also don't forget to copy `config_private_example.lua` to `config_private.lua` and fill that out as well.

Then run the `./run` script to run the bot. It will download the farside `services.json` list and compile the `verse.lua` xmpp library.

# List of supported front ends

**TODO**