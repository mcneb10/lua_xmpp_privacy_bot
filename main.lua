-- Get the verse lib
verse = require("verse")
-- Setup logging and config
require("utils")
local log = setup_log(string.format("%s_main", config.name))
log("info", "Log initialized")
-- Get the client lib
local client_lib = verse.init("client")
-- Make the client
local client = client_lib.new()
-- Load client plugins
client:add_plugin("groupchat")
client:add_plugin("version")
-- Client hooks
client:hook("disconnected", function()
    log("error", "XMPP connetion lost. Quitting...")
    os.exit(1)
end)
client:hook("authentication-failure", function()
    log("error", "Failed to authenticate with XMPP Server. Quitting...")
    os.exit(1)
end)
client:hook("authentication-success", function()
    log("info", "XMPP authentication sucessful!")
end)
client:hook("ready", function()
    log("info", "Client ready")

    -- Main code goes here
    for _, room in pairs(config.rooms_to_join) do
        local room, err = client:join_room(room.jid, config.name, {}, config.password)

        if room then
            -- Run on message events
            room:hook("message", function(event)
                if event.stanza.attr.type == "groupchat"
                    and not string.find(event.stanza.attr.from, "/" .. config.name)
                    and not event.stanza:get_child("delay", "urn:xmpp:delay") then
                    local body = event.stanza:get_child_text("body")
                    if body then
                        for site, services in pairs(config.sites) do
                            local instance = choose_instance(services.frontends)
                            for match in string.gmatch(body, string.format("%%s(%s/%%S+)", site)) do
                                send_reply_link(room, match, site, instance, event)
                            end
                            for match in string.gmatch(body, string.format("(https?://%s/%%S+)", site)) do
                                send_reply_link(room, match, site, instance, event)
                            end
                        end
                    end
                end
            end)
            log("info", "Joined room \"%s\"", room.jid)
        else
            log("error", "Error joining room \"%s\": %s", room.jid, err)
        end
    end
end)

log("info", "Connecting to server...")

client:connect_client(config.jid, config.password)

verse.loop()

log("info", "Verse loop exited. Quitting...")
