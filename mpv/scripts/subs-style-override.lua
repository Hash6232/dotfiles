local mp = require "mp"

local styled = false

function toggle_style()
    if not styled then
        mp.set_property("sub-ass-override", "force")
        mp.set_property("sub-font-size", "48")
        mp.set_property("sub-color", "#FFFFFF")
        mp.set_property("sub-border-color", "#000000")
        mp.set_property("sub-border-size", "5")
        mp.set_property("sub-bold", "1")
        styled = true
        mp.osd_message("Sub Style Override ON")
    else
        mp.set_property("sub-ass-override", "no")
        styled = false
        mp.osd_message("Sub Style Override OFF")
    end
end

mp.register_script_message("subs-style-override", toggle_style)
