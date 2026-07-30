local Players = game:GetService("Players")
local plr = Players.LocalPlayer

local Kick = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/not-gato/gatostuff/refs/heads/main/raw/scripts/uKick.lua"
))().cKick

local BannedUsers = {
    [9850758639] = "You Are Not Welcome Here.",
    [7826981289] = "Certain Suspicious Actions Detected!",
    [2602862453] = "guhh?!",
    [1421155812] = "Suspicious Behavior :p",
    [4362887571] = "No Reason Given.",
    [7203846147] = "Hands up Skid!"
}

local BannedGames = {
    [4924922222] = "Please get your stinky Brookhaven out of here.",
}

local function banKick(reason)
    Kick(
        "UNXHub",
        "<font color='rgb(255,0,0)'>You have been <b>BANNED</b> from using UNXHub</font>\n\n"
        .. "Reason: <font color='rgb(255,0,0)'>" .. tostring(reason or "No reason provided.") .. "</font>\n\n"
        .. "<font color='rgb(0,255,0)'>To appeal this ban join "
        .. "<font color='rgb(0,128,255)'><b>https://discord.gg/zpaMS8qUfB</b></font></font>"
    )
end

local function gKick(reason)
    Kick(
        "UNXHub",
        "<font color='rgb(255,0,0)'>The game you're playing has been <b>BANNED</b> from UNXHub</font>\n\n"
        .. "Reason: <font color='rgb(255,0,0)'>" .. tostring(reason or "No reason provided.") .. "</font>\n\n"
        .. "<font color='rgb(0,255,0)'>Join our discord btw :) "
        .. "<font color='rgb(0,128,255)'><b>https://discord.gg/zpaMS8qUfB</b></font></font>"
    )
end

if BannedUsers[plr.UserId] then
    warn("[API]: User banned:", BannedUsers[plr.UserId])
    banKick(BannedUsers[plr.UserId])
    return
end

if BannedGames[game.PlaceId] then
    warn("[API]: Game blocked:", BannedGames[game.PlaceId])
    gKick(BannedGames[game.PlaceId])
    return
end

print("[API]: All checks passed.")
