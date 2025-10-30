if not session:ready() then return end
session:answer()
freeswitch.consoleLog("INFO", "Hello Lua dialplan triggered!\n")

local sounds_dir = "/usr/local/freeswitch/sounds/en/us/callie/ivr/48000/"

-- main greeting
session:streamFile(sounds_dir .. "ivr-hello.wav")

while session:ready() do
    session:streamFile(sounds_dir .. "ivr-sales.wav")
    session:streamFile(sounds_dir .. "ivr-technical_support.wav")

    -- baca 1 digit, timeout 10s, 1 percobaan, terminator "", valid 0-9, flags 0
    local dtmf = session:read(1, 10000, 1, "", "0123456789", 0)

    if dtmf == "1" then
        session:streamFile(sounds_dir .. "ivr-hold_connect_call.wav")
        session:transfer("1001", "XML", "default")
        break
    elseif dtmf == "2" then
        session:streamFile(sounds_dir .. "ivr-hold_connect_call.wav")
        session:transfer("1002", "XML", "default")
        break
    else
        session:streamFile(sounds_dir .. "ivr-that_was_an_invalid_entry.wav")
    end
end

session:hangup()
