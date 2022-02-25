-- @noindex

macros = {
    ["f"]   = "sf bs",
    ["gr"] = "*f len 0.25b rep 15 sel 0-1 nud 0.05b sa fxo",
    ["md"] = "sm del sa",
    
    ["st1"] = "*f len 4b d3 st > d5 rs st sa > rs del sa sfo col",
    ["st2"] = "*f len 8b d3 st > col d4 rss 0.8 st pir 0.5 is tr 7 sa > rss 0.01 rev col sa",
    ["st3"] = "*f *st2 ten -5 pir -2 fxe sfo",
    ["st4"] = "*f len 8b st st st sfo col d8 rs st pir -0.05 col rs rev sa > rss 0.2 del sa ten -7 fxe rss 0.2 del sa",

    ["r1"] = "*f len 0.25b rep 15 sel 0-1 nud 0.05b sa sel 1-0-1 is m del sa fxo si 5 st st col is col sa pir 1 sa sl rev sa fxe sl len 0.20b sa",
    ["r2"] = "*f len 0.25b rep 15 sel 0-1 nud 0.07b sa fxo sfo pir 1 col sl len 0.18b sa",
    ["r3"] = "*f *gr sel 1-0-1-1-1-1 col is sfo rev v -10 col sa sl len 0.20b sa sel 0-0-0-0-0-1 tr 12 col sa",
    ["r4"] = "*f *r6 rs st st sa rs rs rev col sa sfo",
    ["r5"] = "*f len 4b d5 st > sel 1-0-0 d3 st > col sa pir 1",
    ["r6"] = "*f len 0.25b rep 15 st ten -7 pir 1 fxe col",

    ["p1"] = "*f len 32b d4 d4 rss 0.4 st sa > > rss 0.1 rev sa sfo col",
}