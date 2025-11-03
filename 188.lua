if not session then return end

local SOUNDS = "/usr/local/freeswitch/sounds/en/us/callie/ivr/16000"

session:answer()
session:sleep(500)

-- Welcome
session:streamFile(SOUNDS .. "/ivr-welcome.wav")
session:sleep(2000)

-- Ask for input
session:streamFile(SOUNDS .. "/ivr-please_enter_pin_followed_by_pound.wav")

local choice = session:getDigits(1, "#", 8000)
session:consoleLog("info", "=== User pressed: [" .. tostring(choice) .. "] ===\n")

-- Respond based on input
if choice == "1" then
    session:streamFile(SOUNDS .. "/ivr-you_are_number_one.wav")
    session:sleep(2000)
elseif choice == "2" then
    session:streamFile(SOUNDS .. "/ivr-this_is_number_two.wav")
    session:sleep(2000)
elseif choice == "3" then
    session:streamFile(SOUNDS .. "/ivr-you_have_selected_the_echo_test.wav")
    session:sleep(1000)
    session:execute("echo", "")
else
    session:streamFile(SOUNDS .. "/ivr-invalid_entry.wav")
    session:sleep(1000)
end

-- Goodbye
session:sleep(1000)
session:streamFile(SOUNDS .. "/ivr-thank_you_for_calling.wav")
session:sleep(1000)
session:streamFile(SOUNDS .. "/ivr-goodbye.wav")
session:sleep(2000)
session:hangup()