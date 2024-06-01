-- Main privacy bot configuration file
config = {
    -- Log verbosity
    verbosity = 1,
    -- Bot nickname
    name = "Privacy Link Bot",
    --[[
    This will set the type of url to replace the service domain with. Can be:
        - clearnet
        - onion
        - eepsite
        - yggdrasil
        - TODO: make it work and more types?
    ]]--
    prefered_website_medium = "clearnet",
    -- Choose random frontend instead of fallback one, will force clearnet
    random_frontend = true,
    -- List of desired frontends to extract from `services.json`
    sites = {
        -- Key is domain pattern
        ["reddit[.]com"] = {
            -- Specify which frontents should be used
            frontends = { "libreddit", "redlib" }
        },
        ["instagram[.]com"] = {
            frontends = { "proxigram" }
        },
        ["github[.]com"] = {
            frontends = { "gothub" }
        },
        ["google[.]com"] = {
            frontends = { "searxng" }
        },
        ["youtube[.]com"] = {
            frontends = { "piped", "invidious"}
        },
        ["www[.]youtube[.]com"] = {
            frontends = { "piped", "invidious"}
        },
        ["youtu[.]be"] = {
            frontends = { "piped", "invidious", }
        },
        ["twitter[.]com"] = {
            frontends = { "nitter", }
        },
        ["x[.]com"] = {
            frontends = { "nitter", }
        },
        ["wikipedia[.]org"] = {
            frontends = { "wikiless", }
        },
        ["medium[.]com"] = {
            frontends = { "scribe", }
        },
        ["imgur[.]com"] = {
            frontends = { "rimgo", }
        },
        ["translate[.]google[.]com"] = {
            frontends = { "lingva", }
        },
        ["tiktok[.]com"] = {
            frontends = { "proxitok", }
        },
        ["fandom[.]com"] = {
            frontends = { "breezewiki", }
        },
        -- TODO: the rest
    }
}

-- Load config file with private information
dofile("config_private.lua")

