local mp = require 'mp'
local utils = require 'mp.utils'

function has_audio()
    local tracks = mp.get_property_native("track-list")
    for _, track in ipairs(tracks) do
        if track["type"] == "audio" then
            return true
        end
    end
    return false
end

function is_soundpost(filename)
    local audio_url_encoded = filename:match("%[sound=([^%]]+)%]")
    if audio_url_encoded then
        return true
    end
    return false
end

function url_decode(filename)
    local audio_url_encoded = filename:match("%[sound=([^%]]+)%]")
    return audio_url_encoded:gsub("%%(%x%x)", function(h)
        return string.char(tonumber(h, 16))
    end)
end

function load_external_audio(url)
    mp.set_property("pause", "yes")
    mp.osd_message("Loading external sound..", 10)

    mp.msg.info("Loading external audio: " .. url)

    local success = mp.commandv("audio-add", url, "auto", "yes")
    if not success then
        mp.msg.error("Failed to add external audio: " .. url)
        mp.set_property("pause", "no") -- fallback unpause
        return
    end

    mp.set_property_number("aid", 1) -- switch to external audio

    mp.set_property("loop", "inf")
    mp.set_property("mute", "no")
    mp.set_property("pause", "no")

    mp.add_timeout(1, function()
        mp.osd_message("") -- clear OSD message
    end)
end

mp.register_event("file-loaded", function()
    if has_audio() then return end
    
    local path = mp.get_property("path")
    local _, filename = utils.split_path(path)

    if not is_soundpost(filename) then return end

    local decoded_url = url_decode(filename)
    if not decoded_url:match("^%a+://") then
        decoded_url = "https://" .. decoded_url
    end

    load_external_audio(decoded_url)
end)
