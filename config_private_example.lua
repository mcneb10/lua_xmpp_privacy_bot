-- JID for the bot
config.jid = "bot@server.net"
-- Bot password, stored in plaintext
config.password = "password"

-- Rooms the bot will attempt to join
config.rooms_to_join = {
    -- Normal room
    {jid = "room@server.net",},
    -- Password protected room, password stored in plaintext
    {jid = "protected@server.net", password = "pass"},
}