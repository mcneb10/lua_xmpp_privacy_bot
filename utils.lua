-- Various utility functions used by the bot

function log_callback(source, level, message, ...)
    local output = string.format(
        "%s %s [%s]: %s",
        os.date(),
        source,
        level,
        string.format(message, ...)
    )
    if config.verbosity == 0 then
        if level ~= "debug" then
            print(output)
        end
    elseif config.verbosity == 1 then
        print(output)
    end
end

--[[
    Make a new logger with `name`
]]--
function setup_log(name)
    local log_module = require("util.logger")
    log_module.add_level_sink("debug", log_callback)
    log_module.add_level_sink("info", log_callback)
    log_module.add_level_sink("warn", log_callback)
    log_module.add_level_sink("error", log_callback)
    return log_module.init(name)
end

-- Read a file in it's entirety, returning an empty string on failure
function read_all_text(file)
    local file = io.open(file, "rb")
    if not file then
        print(string.format("Failed to open file \"%s\"!", file))
        return ""
    end
    local text = file:read("*all")
    file:close()
    return text
end

function send_reply_link(room, match, site, instance, event)
    local msg = string.format("> %s\nPrivate frontend: %s", match, string.gsub(match, site, instance))
    if config.use_reply_xep then
        room:send(verse.message()
            -- Set message text
            :body(msg):up()
            -- Set reply block
            :tag("reply", {
                xmlns = 'urn:xmpp:reply:0',
                to = event.stanza.attr.from,
                id = event.stanza.attr.id,
            }))
    else
        room:send_message(msg)
    end
end

-- Choose instance from available services
function choose_instance(services)
    -- TODO: make it try all available frontends before falling back
    -- Return instance if overrided in config
    if services.force_instance then 
        return services.force_instance
    end
    -- Choose a random frontend
    local frontend = services.frontends[math.random(#services.frontends)]
    -- Get list of instances for frontend
    for _, service_instance_list in pairs(config.instances) do
        if service_instance_list.type == frontend then
            -- Based on config choose instance
            if config.random_frontend then
                -- TODO: cache this?
                local usable_instances = {}
                for _, instance_url_list in pairs(service_instance_list.instances) do
                    -- Instance URLs are split by pipes
                    for instance in string.gmatch(instance_url_list, "[^|]+") do
                        if instance.match(instance, "[.]onion$") then
                            if config.prefered_website_medium == "onion" then
                                table.insert(usable_instances, instance)
                            end
                        elseif instance.match(instance, "[.]i2p$") then
                            if config.prefered_website_medium == "eepsite" then
                                table.insert(usable_instances, instance)
                            end
                        elseif instance.match(instance, "[[][%d:]+[]]") then
                            if config.prefered_website_medium == "yggdrasil" then
                                table.insert(usable_instances, instance)
                            end
                        else
                            -- Assume clearnet
                            if config.prefered_website_medium == "clearnet" then
                                table.insert(usable_instances, instance)
                            end
                        end                                        
                    end
                end
                return string.gsub(usable_instances[math.random(#usable_instances)], "https?://", "")
            else
                return string.gsub(service_instance_list.fallback, "https?://", "")
            end
        end
    end
    return string.format("%s-no-instances-available", frontend)
end

-- Config file
dofile("config.lua")

-- Load subsitutions
local services_text = read_all_text("services.json")
local json = require("util.json")
local services, err = json.decode(services_text)
if services then
    config.instances = services
else
    print(string.format("Error loading \"services.json\": %s", err))
end
