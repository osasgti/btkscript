local showUI = true
local scriptEnabled = false
local ID_BLACK = 11550
local ID_BGL = 7188
local ID_DL = 1796
local ID_WL = 242
local ID_GEMS = 112
local ID_BET_BLOCK = 1422
local ID_CHAND = 5640
local START_WEBHOOK = "https://discord.com/api/webhooks/1541790687379464253/zI0zpz0h4V52B1CxDUOzvSG4Tawkz7pB-kEAbVePSaVD97H0tM5HPXT-5g1AxL3vtahT"
local INVALID_START_WEBHOOK = "https://discord.com/api/webhooks/1541792771214671934/iJxcqkCdc3-wUgwgBwBDeQZyVdnv9eYUr4AIOs1rXou8WCTwBOEDXJ0nYXSYEA9vXYW3"
local ROOM_WEBHOOK = "https://discord.com/api/webhooks/1541790695025811496/IQ7P7kE6QHXOIEyVxa86GEgq4IFXLfh60k3jUF9n0I5xpVSzcUHgooGusrRbQ-sKOpyK"

local roomCenters = {
    [1] = { x = 50, y = 34 },
    [2] = { x = 50, y = 16 },
    [3] = { x = 36, y = 29 },
    [4] = { x = 64, y = 29 },
    [5] = { x = 36, y = 23 },
    [6] = { x = 64, y = 23 }
}

local shadowFarmPositions = {
    [1] = { x = 59, y = 33 },
    [2] = { x = 59, y = 17 },
    [3] = { x = 27, y = 29 },
    [4] = { x = 73, y = 29 },
    [5] = { x = 27, y = 23 },
    [6] = { x = 73, y = 23 }
}

local currentRoom = nil
local D1Pos, D2Pos, W1Pos, W2Pos, P1Pos, P2Pos, DonPos, R1Pos, R2Pos, PH = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil

local function rect(x1, x2, y1, y2)
    local positions = {}
    for y = y1, y2 do
        for x = x1, x2 do
            table.insert(positions, {x = x, y = y})
        end
    end
    return positions
end

local function positionsForRoom(roomNumber)
    local center = roomCenters[roomNumber]
    local cx, cy = center.x, center.y

    if roomNumber == 1 then
        return {
            d1 = { x = cx - 3, y = cy - 1 }, d2 = { x = cx + 3, y = cy - 1 },
            w1 = { x = cx - 4, y = cy - 1 }, w2 = { x = cx + 4, y = cy - 1 },
            p1 = {{ x = cx - 5, y = cy + 1 }, { x = cx - 4, y = cy + 1 }, { x = cx - 3, y = cy + 1 }},
            p2 = {{ x = cx + 5, y = cy + 1 }, { x = cx + 4, y = cy + 1 }, { x = cx + 3, y = cy + 1 }},
            don = {{ x = cx - 2, y = cy + 3 }, { x = cx - 1, y = cy + 3 }, { x = cx, y = cy + 3 }, { x = cx + 1, y = cy + 3 }, { x = cx + 2, y = cy + 3 }},
            r1 = rect(cx - 6, cx - 3, cy - 2, cy - 1),
            r2 = rect(cx + 3, cx + 6, cy - 2, cy - 1),
            center = { x = cx, y = cy }
        }
    elseif roomNumber == 2 then
        return {
            d1 = { x = cx - 3, y = cy + 1 }, d2 = { x = cx + 3, y = cy + 1 },
            w1 = { x = cx - 4, y = cy + 1 }, w2 = { x = cx + 4, y = cy + 1 },
            p1 = {{ x = cx - 5, y = cy - 1 }, { x = cx - 4, y = cy - 1 }, { x = cx - 3, y = cy - 1 }},
            p2 = {{ x = cx + 5, y = cy - 1 }, { x = cx + 4, y = cy - 1 }, { x = cx + 3, y = cy - 1 }},
            don = {{ x = cx - 2, y = cy - 3 }, { x = cx - 1, y = cy - 3 }, { x = cx, y = cy - 3 }, { x = cx + 1, y = cy - 3 }, { x = cx + 2, y = cy - 3 }},
            r1 = rect(cx - 6, cx - 3, cy + 1, cy + 2),
            r2 = rect(cx + 3, cx + 6, cy + 1, cy + 2),
            center = { x = cx, y = cy }
        }
    end

    return {
        d1 = { x = cx - 3, y = cy + 1 }, d2 = { x = cx + 3, y = cy + 1 },
        w1 = { x = cx - 4, y = cy + 1 }, w2 = { x = cx + 4, y = cy + 1 },
        p1 = {{ x = cx - 1, y = cy - 1 }, { x = cx - 1, y = cy }, { x = cx - 1, y = cy + 1 }},
        p2 = {{ x = cx + 1, y = cy - 1 }, { x = cx + 1, y = cy }, { x = cx + 1, y = cy + 1 }},
        don = {{ x = cx - 2, y = cy - 3 }, { x = cx - 1, y = cy - 3 }, { x = cx, y = cy - 3 }, { x = cx + 1, y = cy - 3 }, { x = cx + 2, y = cy - 3 }},
        r1 = rect(cx - 6, cx - 3, cy - 1, cy + 1),
        r2 = rect(cx + 3, cx + 6, cy - 1, cy + 1),
        center = { x = cx, y = cy }
    }
end

local function setRoom(roomNumber)
    local positions = positionsForRoom(roomNumber)
    currentRoom = roomNumber
    D1Pos, D2Pos = positions.d1, positions.d2
    W1Pos, W2Pos = positions.w1, positions.w2
    P1Pos, P2Pos, DonPos = positions.p1, positions.p2, positions.don
    R1Pos, R2Pos, PH = positions.r1, positions.r2, positions.center
end

local function detectRoom()
    local world = GetWorld()
    if not world or tostring(world.name or ""):upper() ~= "BTK" then
        return false, "Script was run outside world BTK"
    end

    local player = GetLocal()
    if not player or not player.pos then
        return false, "Local player position was unavailable"
    end

    local playerX = math.floor(player.pos.x / 32)
    local playerY = math.floor(player.pos.y / 32)
    local matchedRoom = nil

    for roomNumber, center in pairs(roomCenters) do
        if playerX == center.x and playerY == center.y then
            matchedRoom = roomNumber
            break
        end
    end

    if not matchedRoom then
        return false, "Player was not standing at a room center"
    end

    local positions = positionsForRoom(matchedRoom)
    local d1 = GetTile(positions.d1.x, positions.d1.y)
    local d2 = GetTile(positions.d2.x, positions.d2.y)
    if not d1 or not d2 or d1.fg ~= ID_BET_BLOCK or d2.fg ~= ID_BET_BLOCK then
        return false, "Room center was found but its BTK layout was invalid"
    end

    setRoom(matchedRoom)
    return true
end
local p1BetDL, p2BetDL = 0, 0
local p1Name, p2Name = "nil", "nil"
local p1UserID, p2UserID = 0, 0
local totalPrizeDL = 0
local currentTaxDL = 0
local winnerSide = nil
local p1Gems, p2Gems = 0, 0
local gameLogs = {}
local dropWin = false
local tpClick = false
local kick = false
local spamEnabled = false
local spamRunning = false
local spamMessage = ""
local nextSpamTime = os.time() + 7
local startWebhookSent = false
local takeRunning = false
local currencyCommandRunning = false
local autoConvertPaused = false
local ignoreCollectedMessages = false

local function enableModFly()
    if type(ChangeValue) ~= "function" then return false end
    return pcall(ChangeValue, "ModFly", true)
end

local function inventoryAmount(itemID)
    for _, item in pairs(GetInventory() or {}) do
        if item.id == itemID then return item.amount or 0 end
    end
    return 0
end

local function cleanName(name)
    local cleaned = tostring(name or "Unknown")
        :gsub("`.", "")
        :gsub("%s*%(%d+%)%s*$", "")
    while cleaned:match("%s*%[[^%]]+%]%s*$") do
        cleaned = cleaned:gsub("%s*%[[^%]]+%]%s*$", "")
    end
    cleaned = cleaned:gsub("%s+[oO][fF]%s+[lL][eE][gG][eE][nN][dD]%s*$", "")
    cleaned = cleaned:gsub("^%s*@+%s*", "")
    return cleaned:gsub("^%s*(.-)%s*$", "%1")
end

local function playerNameInArea(area)
    local localPlayer = GetLocal()
    local localNetID = localPlayer and (localPlayer.netid or localPlayer.netID) or nil
    local localUserID = localPlayer and localPlayer.userid or nil

    for _, player in pairs(GetPlayerList() or {}) do
        local netID = player.netid or player.netID
        if player.pos and netID ~= localNetID and (not localUserID or player.userid ~= localUserID) then
            local playerX = math.floor(player.pos.x / 32)
            local playerY = math.floor(player.pos.y / 32)
            for _, position in ipairs(area or {}) do
                if playerX == position.x and playerY == position.y then
                    return cleanName(player.name), tonumber(player.userid) or 0
                end
            end
        end
    end

    return "nil", 0
end

local function jsonEscape(value)
    return tostring(value or "")
        :gsub("\\", "\\\\")
        :gsub("\"", "\\\"")
        :gsub("\n", "\\n")
        :gsub("\r", "")
end

local function sendInvalidStartWebhook(reason)
    local player = GetLocal()
    local world = GetWorld()
    local playerX, playerY = -1, -1
    if player and player.pos then
        playerX = math.floor(player.pos.x / 32)
        playerY = math.floor(player.pos.y / 32)
    end

    local description = string.format(
        "**%s** (`%d`) ran the Manual BTK script from an invalid location.\n\n" ..
        "World: `%s`\nPosition: `(%d, %d)`\nReason: %s",
        cleanName(player and player.name),
        (player and player.userid) or 0,
        (world and world.name) or "Unknown",
        playerX,
        playerY,
        reason or "Unknown"
    )

    local payload = string.format(
        '{"embeds":[{"title":"Invalid Manual BTK Start","description":"%s","color":15548997,"timestamp":"%s"}]}',
        jsonEscape(description),
        os.date("!%Y-%m-%dT%H:%M:%SZ")
    )
    MakeRequest(INVALID_START_WEBHOOK, "POST", { ["Content-Type"] = "application/json" }, payload)
end

local function sendStartWebhook(bankBGL)
    if startWebhookSent or not currentRoom then return end
    startWebhookSent = true

    local player = GetLocal()
    local description = string.format(
        "**%s** (`%d`) has started the BTK script in Room %d.\n\n" ..
        "<:blc:1282591669883244596> In Inventory: %d\n" ..
        "<:bgl:1327480606136991816> In Inventory: %d\n" ..
        "<a:dl:1435231345839312896> In Inventory: %d\n\n" ..
        "<:bgl:1327480606136991816> In Bank: %d",
        cleanName(player and player.name),
        (player and player.userid) or 0,
        currentRoom,
        inventoryAmount(ID_BLACK),
        inventoryAmount(ID_BGL),
        inventoryAmount(ID_DL),
        bankBGL or 0
    )

    local payload = string.format(
        '{"content":"@everyone","allowed_mentions":{"parse":["everyone"]},"embeds":[{"title":"Manual BTK Started","description":"%s","color":5763719,"timestamp":"%s"}]}',
        jsonEscape(description),
        os.date("!%Y-%m-%dT%H:%M:%SZ")
    )
    MakeRequest(START_WEBHOOK, "POST", { ["Content-Type"] = "application/json" }, payload)
end

local function formatSmartDL(dl)
    local black = math.floor(dl / 10000)
    local bgl = math.floor((dl % 10000) / 100)
    local d = dl % 100
    local parts = {}
    if black > 0 then table.insert(parts, black .. " BLACK") end
    if bgl > 0 then table.insert(parts, bgl .. " BGL") end
    if d > 0 then table.insert(parts, d .. " DL") end
    return #parts > 0 and table.concat(parts, " ") or "0 DL"
end

local function CreateDialog(text)
    SendVariantList({[0] = "OnDialogRequest", [1] = text})
end

local function menubar()
    local menuDialog = [[
add_label_with_icon|big|`9Commands`0 :|left|5770|
add_smalltext|`b/wd `b- `9Drop `9WL`0|
add_smalltext|`b/dd `b- `9Drop `cDL`0|
add_smalltext|`b/bd `b- `9Drop `eBGL`0|
add_smalltext|`b/bdl `b- `9Drop `bBLACK| 
end_dialog|menud|Close|
]]
    CreateDialog(menuDialog)
end

local function updateBar()
    local dialog = [[
add_label_with_icon|big|`@Osas `eBTK Proxy|left|11550|
add_textbox|`bProxy Version `0: `2v1.0.0|
add_spacer|small|
add_label_with_icon|small|`2v1.0.0|left|834|
add_textbox|`2Update Logs `0=|
add_smalltext|`b- `9ImGui Panel BTK|
add_smalltext|`b- `9Simple Setup, Only Run Script|
add_smalltext|`b- `9Supports `b/wd`9, `b/dd`9, `b/bd`9, `b/bdl `9for now|
add_smalltext|`b- `9Added Logs Tab|
add_textbox|`4Bug Fixes `0=|
add_smalltext|`b- `9None yet...|
add_spacer|small|
add_button|menuu|`bCommand/Menu Bar||
end_dialog|hsj|Close|
]]
    CreateDialog(dialog)
end

local function cLog(str)
    LogToConsole("`0[ `@Osas `0] `0"..str)
end

local function path(x, y)
    SendPacketRaw(false, {
        px = x,
        py = y,
        x = x * 32,
        y = y * 32
    })
end

local function returnHostPosition()
    if not PH then return end
    FindPath(PH.x, PH.y, 1000)
    Sleep(300)
    SendPacketRaw(false, {
        type = 0,
        x = PH.x * 32,
        y = PH.y * 32,
        px = -1,
        py = -1,
        state = 48
    })
end

local function deployShadowFarm()
    local position = shadowFarmPositions[currentRoom]
    if not position then return false end

    FindPath(position.x, position.y, 1000)
    Sleep(700)
    SendPacket(2, "action|dialog_return\ndialog_name|shadowfarm\nbuttonClicked|deploy")
    Sleep(700)
    returnHostPosition()
    Sleep(500)
    return true
end

local function place(x, y)
    SendPacketRaw(false, {
        type = 3,
        value = 5640,
        px = x,
        py = y,
        x = x * 32,
        y = y * 32
    })
end

local function placeBlockTile(x, y)
    place(x, y)
end

local function textoverlay(text)
    SendVariantList({[0] = "OnTextOverlay", [1] = text})
end

local function inv(id)
    for _, item in pairs(GetInventory()) do
        if item.id == id then
            return item.amount
        end
    end
    return 0
end

local function inventoryValueDL()
    return inv(ID_BLACK) * 10000 + inv(ID_BGL) * 100 + inv(ID_DL)
end

local function takeChandeliers(requiredAmount)
    requiredAmount = math.max(1, tonumber(requiredAmount) or 1)

    if inv(ID_CHAND) >= requiredAmount then
        if PH then FindPath(PH.x, PH.y, 1000) end
        return true
    end

    FindPath(50, 24, 1000)
    Sleep(500)
    SendPacketRaw(false, { type = 3, value = 32, x = 50 * 32, y = 25 * 32, px = 50, py = 25, netid = 0, state = 0 })
    Sleep(500)
    SendPacket(2, "action|dialog_return\ndialog_name|magplant_edit\nx|50|\ny|25|\nbuttonClicked|getRemote")
    for _ = 1, 10 do
        if inv(ID_CHAND) >= requiredAmount then break end
        Sleep(500)
    end
    if PH then FindPath(PH.x, PH.y, 1000) end
    return inv(ID_CHAND) >= requiredAmount
end

local function convertDLToBGL()
    while not autoConvertPaused and inv(ID_DL) >= 100 do
        local before = inv(ID_DL)
        SendPacket(2, "action|dialog_return\ndialog_name|telephone\nnum|53785|\nx|" .. PH.x .. "|\ny|" .. PH.y .. "|\nbuttonClicked|bglconvert")
        Sleep(1000)
        if inv(ID_DL) >= before then break end
    end
end

local function convertWLToDL()
    while not autoConvertPaused and inv(ID_WL) >= 100 do
        local before = inv(ID_WL)
        SendPacketRaw(false, {type = 10, value = ID_WL})
        Sleep(600)
        if inv(ID_WL) >= before then break end
    end
end

local function placeChandeliers()
    local tiles = {}
    for _, tile in ipairs(P1Pos) do table.insert(tiles, tile) end
    for _, tile in ipairs(P2Pos) do table.insert(tiles, tile) end

    for _, tile in ipairs(tiles) do
        local worldTile = GetTile(tile.x, tile.y)
        if worldTile and worldTile.fg == 0 then
            if inv(ID_CHAND) <= 0 then return false end
            place(tile.x, tile.y)
            Sleep(150)
        end
    end

    return true
end

local function sendRoomGameWebhook()
    local player = GetLocal()
    local winner = "Draw"
    if winnerSide == "left" then
        winner = "Left (P1: " .. p1Name .. ")"
    elseif winnerSide == "right" then
        winner = "Right (P2: " .. p2Name .. ")"
    end
    local description = string.format(
        "Host: **%s** (`%d`)\nRoom: `%d`\nPlayer 1: **%s** (`%d`)\nPlayer 2: **%s** (`%d`)\nBet: `%s` vs `%s`\nGems: `%d - %d`\nWinner: **%s**",
        cleanName(player and player.name),
        (player and player.userid) or 0,
        currentRoom,
        p1Name,
        p1UserID,
        p2Name,
        p2UserID,
        formatSmartDL(p1BetDL),
        formatSmartDL(p2BetDL),
        p1Gems,
        p2Gems,
        winner
    )
    local payload = string.format(
        '{"embeds":[{"title":"Manual BTK Game Log","description":"%s","color":3447003,"timestamp":"%s"}]}',
        jsonEscape(description),
        os.date("!%Y-%m-%dT%H:%M:%SZ")
    )
    MakeRequest(ROOM_WEBHOOK, "POST", { ["Content-Type"] = "application/json" }, payload)
end

local function logGame()
    local winner = "Draw"
    if winnerSide == "left" then
        winner = "Left (P1: " .. p1Name .. ")"
    elseif winnerSide == "right" then
        winner = "Right (P2: " .. p2Name .. ")"
    end
    local log = string.format(
        "== GAME %d ==\nPlayer 1: %s (%d)\nPlayer 2: %s (%d)\nBet: %s vs %s\nGems: %d - %d\nWinner: %s",
        #gameLogs + 1,
        p1Name,
        p1UserID,
        p2Name,
        p2UserID,
        formatSmartDL(p1BetDL),
        formatSmartDL(p2BetDL),
        p1Gems,
        p2Gems,
        winner
    )
    table.insert(gameLogs, 1, log)
    RunThread(sendRoomGameWebhook)
end

local function ngomong(text)
    SendPacket(2, "action|input\n|text|`0[ `@Osas `0] " .. text)
end

local function announceCollected(amount, color, name)
    if amount <= 0 then return end
    local msg = "`0Collected `2" .. amount .. " " .. color .. name
    ngomong(msg)
    cLog(msg)
    textoverlay(msg)
end

local function pickupAt(tile)
    for _, o in pairs(GetObjectList()) do
        if math.floor(o.pos.x / 32) == tile.x and math.floor(o.pos.y / 32) == tile.y then
            SendPacketRaw(false, {type = 11, value = o.oid, x = o.pos.x, y = o.pos.y})
        end
    end
end

local function pickupFromList(posList)
    for _, pos in ipairs(posList) do
        pickupAt(pos)
        Sleep(200)
    end
end

local function parseCollectedBet(tile)
    local total = 0
    for _, o in pairs(GetObjectList()) do
        local ox, oy = math.floor(o.pos.x / 32), math.floor(o.pos.y / 32)
        if ox == tile.x and oy == tile.y then
            if o.id == ID_BLACK then total = total + o.amount * 10000
            elseif o.id == ID_BGL then total = total + o.amount * 100
            elseif o.id == ID_DL then total = total + o.amount end
        end
    end
    return total
end

local function getGems(posList)
    local total = 0
    for _, o in pairs(GetObjectList()) do
        if o.id == ID_GEMS then
            local ox, oy = math.floor(o.pos.x / 32), math.floor(o.pos.y / 32)
            for _, pos in ipairs(posList) do
                if ox == pos.x and oy == pos.y then
                    total = total + o.amount
                    break
                end
            end
        end
    end
    return total
end

local function drop(x, y)
    local lx, ly = math.floor(GetLocal().pos.x / 32), math.floor(GetLocal().pos.y / 32)
    if math.abs(lx - x) > 8 or math.abs(ly - y) > 8 then return end
    if GetTile(x, y).collidable then return end

    local z = 0

    if winnerSide == "left" then
        z = -1
    elseif winnerSide == "right" then
        z = 1
    else
        if not GetTile(x + 1, y).collidable then z = 1
        elseif not GetTile(x - 1, y).collidable then z = -1
        else return end
    end

    SendPacketRaw(false, {
        type = 0,
        x = (x + z) * 32,
        y = y * 32,
        px = -1,
        py = -1,
        state = (z == 1 and 48 or 32)
    })
end

local function dropTaxCurrency(amount)
    local black = math.floor(amount / 10000)
    local remaining = amount % 10000
    local bgl = math.floor(remaining / 100)
    remaining = remaining % 100
    local dl = math.floor(remaining)
    local wl = math.floor((remaining - dl) * 100 + 0.5)

    if black > 0 and inv(ID_BLACK) >= black then
        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. ID_BLACK .. "|\nitem_count|" .. black)
        Sleep(600)
    end

    if bgl > 0 then
        if inv(ID_BGL) < bgl and inv(ID_BLACK) > 0 then
            SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
            Sleep(1000)
        end
        if inv(ID_BGL) >= bgl then
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. ID_BGL .. "|\nitem_count|" .. bgl)
            Sleep(600)
        end
    end

    if dl > 0 then
        if inv(ID_DL) < dl and inv(ID_BGL) > 0 then
            SendPacketRaw(false, {type = 10, value = ID_BGL})
            Sleep(1000)
        end
        if inv(ID_DL) >= dl then
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. ID_DL .. "|\nitem_count|" .. dl)
            Sleep(600)
        end
    end

    if wl > 0 then
        if inv(ID_WL) < wl and inv(ID_DL) > 0 then
            SendPacketRaw(false, {type = 10, value = ID_DL})
            Sleep(1000)
        end
        if inv(ID_WL) >= wl then
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. ID_WL .. "|\nitem_count|" .. wl)
            Sleep(600)
        end
    end
end

local MAX_DROPPED_STACKS = 20
local ITEMS_PER_STACK = 250

local function taxCurrencyAmounts(amount)
    local black = math.floor(amount / 10000)
    local remaining = amount % 10000
    local bgl = math.floor(remaining / 100)
    remaining = remaining % 100
    local dl = math.floor(remaining)
    local wl = math.floor((remaining - dl) * 100 + 0.5)

    return {
        [ID_BLACK] = black,
        [ID_BGL] = bgl,
        [ID_DL] = dl,
        [ID_WL] = wl
    }
end

local function donationTileHasSpace(tile, amount)
    local stackCount = 0
    local freeSpaceByItem = {}

    for _, object in pairs(GetObjectList() or {}) do
        local objectX = math.floor(object.pos.x / 32)
        local objectY = math.floor(object.pos.y / 32)
        if objectX == tile.x and objectY == tile.y then
            local objectAmount = tonumber(object.amount) or 0
            stackCount = stackCount + 1
            freeSpaceByItem[object.id] = (freeSpaceByItem[object.id] or 0)
                + math.max(0, ITEMS_PER_STACK - objectAmount)
        end
    end

    for itemID, dropAmount in pairs(taxCurrencyAmounts(amount)) do
        if dropAmount > 0 then
            local amountNeedingNewStacks = math.max(
                0,
                dropAmount - (freeSpaceByItem[itemID] or 0)
            )
            stackCount = stackCount
                + math.ceil(amountNeedingNewStacks / ITEMS_PER_STACK)

            if stackCount > MAX_DROPPED_STACKS then
                return false
            end
        end
    end

    return stackCount <= MAX_DROPPED_STACKS
end

local function faceLeftAt(x, y)
    pcall(function()
        local player = GetLocal()
        if player then player.isleft = true end
    end)

    SendPacketRaw(false, {
        type = 0,
        x = x * 32,
        y = y * 32,
        px = -1,
        py = -1,
        state = 48
    })
end

local function donateHalfTax(tax)
    if not tax or tax <= 0 or not DonPos then return end
    local halfTax = tax / 2

    table.sort(DonPos, function(a, b)
        return a.x < b.x
    end)

    for _, tile in ipairs(DonPos) do
        if donationTileHasSpace(tile, halfTax) then
            FindPath(tile.x + 1, tile.y, 1000)
            Sleep(900)

            local before = inventoryValueDL() + inv(ID_WL) / 100
            faceLeftAt(tile.x + 1, tile.y)
            Sleep(700)
            dropTaxCurrency(halfTax)
            Sleep(1200)

            local after = inventoryValueDL() + inv(ID_WL) / 100
            if after < before then break end
        end
    end
end

AddHook("onsendpacket", "manual_drop_and_pull", function(type, str)
    if not scriptEnabled then return end
    if not str then return end

    local cmd, amount = str:match("text|%s*/(%a+)%s*(%d*)")
    amount = tonumber(amount)

    if cmd == "bd" and amount and amount > 0 then
        local haveBGL = inv(ID_BGL)
        local haveBLACK = inv(ID_BLACK)

        if haveBGL < amount then
            if haveBLACK > 0 then
                SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
                ngomong("`9Converted `1Black Gem Lock `9to `e100 BGL.")
            else
                ngomong("`4Not enough BGL or Black to convert.")
            end
            return true
        end

        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. ID_BGL .. "|\nitem_count|" .. amount)
        local msg = "`0Dropped `2" .. amount .. " `eBlue Gem Lock"
        ngomong(msg)
        cLog(msg)
        textoverlay(msg)
        return true

    elseif cmd == "wd" and amount and amount > 0 then
        if currencyCommandRunning then return true end
        currencyCommandRunning = true
        autoConvertPaused = true
        RunThread(function()
            while inv(ID_WL) < amount and inv(ID_DL) > 0 do
                local before = inv(ID_WL)
                SendPacketRaw(false, {type = 10, value = ID_DL})
                Sleep(600)
                if inv(ID_WL) <= before then break end
            end

            if inv(ID_WL) >= amount then
                SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. ID_WL .. "|\nitem_count|" .. amount)
                local msg = "`0Dropped `2" .. amount .. " `9World Lock"
                ngomong(msg)
                cLog(msg)
                textoverlay(msg)
                Sleep(300)
            else
                ngomong("`4Not enough World Locks or Diamond Locks.")
            end

            autoConvertPaused = false
            currencyCommandRunning = false
        end)
        return true

    elseif cmd == "bdl" and amount and amount > 0 then
        SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. ID_BLACK .. "|\nitem_count|" .. amount)
        local msg = "`0Dropped `2" .. amount .. " `bBlack Gem Lock"
        ngomong(msg)
        cLog(msg)
        textoverlay(msg)
        return true

    elseif cmd == "dd" and amount and amount > 0 then
        if currencyCommandRunning then return true end
        currencyCommandRunning = true
        autoConvertPaused = true
        RunThread(function()
            while inv(ID_DL) < amount and inv(ID_BGL) > 0 do
                local before = inv(ID_DL)
                SendPacketRaw(false, {type = 10, value = ID_BGL})
                Sleep(600)
                if inv(ID_DL) <= before then break end
            end

            if inv(ID_DL) >= amount then
                SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|" .. ID_DL .. "|\nitem_count|" .. amount)
                local msg = "`0Dropped `2" .. amount .. " `1Diamond Lock"
                ngomong(msg)
                cLog(msg)
                textoverlay(msg)
                Sleep(300)
            else
                ngomong("`4Not enough Diamond Locks or Blue Gem Locks.")
            end

            autoConvertPaused = false
            currencyCommandRunning = false
        end)
        return true

    elseif cmd == "menu" or str:find("buttonClicked|menuu") or str:find("buttonClicked|socialmenu") then
        menubar()
        return true
    end

end)

local function fastPlayerAction(position, mouseDown, enabled, action)
    local WRENCH_ID = 32
    local MAX_TOUCH_DISTANCE = 16
    local TOUCH_OFFSET_X = 12
    local TOUCH_OFFSET_Y = 10

    if not enabled or not mouseDown then return false end
    if not position or not position.x or not position.y then return false end

    local success, playerItems = pcall(GetPlayerItems)
    local selectedItem = success and playerItems and playerItems.backpack
        and tonumber(playerItems.backpack.selected) or 0
    if selectedItem ~= WRENCH_ID then
        SetItemSelected(WRENCH_ID)
    end

    local localPlayer = GetLocal()
    local localNetID = localPlayer and (localPlayer.netid or localPlayer.netID) or nil
    local target = nil
    local closestDistance = MAX_TOUCH_DISTANCE * MAX_TOUCH_DISTANCE

    for _, player in pairs(GetPlayerList() or {}) do
        local netID = player.netid or player.netID
        if player.pos and netID and netID ~= localNetID then
            local dx = (player.pos.x + TOUCH_OFFSET_X) - position.x
            local dy = (player.pos.y + TOUCH_OFFSET_Y) - position.y
            local distance = dx * dx + dy * dy
            if distance <= closestDistance then
                target = player
                closestDistance = distance
            end
        end
    end

    if not target then return false end

    local netID = target.netid or target.netID
    local name = target.name or "Unknown"
    SendPacket(2, "action|dialog_return\ndialog_name|popup\nnetID|" .. netID .. "|\nbuttonClicked|" .. action)
    if action == "kick" then
        ngomong("`4Kicked ``" .. name)
        textoverlay("`4Kicked ``" .. name)
    else
        ngomong("`9Gas? ``" .. name)
        textoverlay("`9Pulled ``" .. name)
    end
    return true
end

local function fastPull(position, mouseDown)
    return fastPlayerAction(position, mouseDown, pull, "pull")
end

local function fastKick(position, mouseDown)
    return fastPlayerAction(position, mouseDown, kick, "kick")
end

AddHook("onworldtouch", "tp_click_handler", function(pos, mouseDown)
    if not scriptEnabled then return end
    if fastKick(pos, mouseDown) then return true end
    if fastPull(pos, mouseDown) then return true end
    if tpClick and mouseDown then
        local tileX = math.floor(pos.x / 32)
        local tileY = math.floor(pos.y / 32)
        RunThread(function()
            FindPath(tileX, tileY, 1000)
        end)
        return true
    end
end)

AddHook("onvariant", "handle_telephone_dialog", function(var)
    if not scriptEnabled then return end
    if var[0] == "OnConsoleMessage" then
        local console = tostring(var[1] or "")
        if ignoreCollectedMessages and console:find("`oCollected", 1, true) then
            return true
        end
        if console:find("`oCollected", 1, true) then
            local amount = console:match("(%d+)%s+CreativePS%s+Black Gem Lock")
            if amount then
                announceCollected(tonumber(amount) or 0, "`b", "Black Gem Lock")
                return true
            end

            amount = console:match("(%d+)%s+CreativePS%s+Blue Gem Lock")
            if amount then
                announceCollected(tonumber(amount) or 0, "`e", "Blue Gem Lock")
                return true
            end

            amount = console:match("(%d+)%s+CreativePS%s+Diamond Lock")
            if amount then
                announceCollected(tonumber(amount) or 0, "`1", "Diamond Lock")
                return true
            end

            amount = console:match("(%d+)%s+CreativePS%s+World Lock")
            if amount then
                announceCollected(tonumber(amount) or 0, "`9", "World Lock")
                return true
            end
        end
    end

    if var[0] == "OnSDBroadcast" then
        cLog("`4#BLOCKED SDB")
        return true
    end

    local dialog = tostring(var[1] or "")
    if var[0] == "OnDialogRequest" and dialog:lower():find("bgl bank", 1, true) then
        local found = dialog:match("You have [`%w%s%p]-`%$(%d+)``")
            or dialog:match("%$([%d,]+)%s*BGL")
        local bankBGL = tonumber((tostring(found or "0"):gsub(",", ""))) or 0
        RunThread(function() sendStartWebhook(bankBGL) end)
        return true
    end

    if var[0] == "OnDialogRequest" and dialog:lower():find("exchange for 100 diamond lock", 1, true) then
        return true
    end

    if var[0] == "OnDialogRequest" and dialog:lower():find("get remote", 1, true) then
        return true
    end
end)

AddHook("ondraw", "btk_ui", function()
    if not scriptEnabled or not showUI then return end

    ImGui.Begin("OSAS BTK PROXY | Room " .. (currentRoom or "Unknown"))

    if ImGui.BeginTabBar("MainTabBar") then

        if ImGui.BeginTabItem("BTK") then
            ImGui.Text("-- Return Center --")
            if ImGui.Button("Return Center", ImVec2(200, 75)) then
                RunThread(function()
                    if PH then
                        returnHostPosition()
                        textoverlay("`2Returned to Room " .. currentRoom .. " center")
                    end
                end)
            end

            ImGui.Spacing()
            ImGui.Text("-- BTK Command --")
            if ImGui.Button("Take", ImVec2(100, 100)) and not takeRunning then
                takeRunning = true
                RunThread(function()
                    if not currentRoom then
                        textoverlay("`4Use Check Position first")
                    elseif currencyCommandRunning then
                        textoverlay("`4Wait for the currency command to finish")
                    else
                        p1Name, p1UserID = playerNameInArea(R1Pos)
                        p2Name, p2UserID = playerNameInArea(R2Pos)
                        p1BetDL = parseCollectedBet(D1Pos) + parseCollectedBet(W1Pos)
                        p2BetDL = parseCollectedBet(D2Pos) + parseCollectedBet(W2Pos)
                        if p1BetDL <= 0 or p2BetDL <= 0 then
                            totalPrizeDL = 0
                            currentTaxDL = 0
                            textoverlay("`4Both players must drop a bet")
                        else
                            autoConvertPaused = true
                            if not takeChandeliers() then
                                textoverlay("`4Could not take chandeliers from Magplant")
                            else
                                local expectedTotal = p1BetDL + p2BetDL
                                local inventoryBefore = inventoryValueDL()
                                ignoreCollectedMessages = true
                                pickupAt(D1Pos)
                                pickupAt(W1Pos)
                                pickupAt(D2Pos)
                                pickupAt(W2Pos)

                                local collectedTotal = 0
                                for _ = 1, 10 do
                                    Sleep(300)
                                    collectedTotal = inventoryValueDL() - inventoryBefore
                                    if collectedTotal >= expectedTotal then break end
                                end
                                ignoreCollectedMessages = false

                                if collectedTotal ~= expectedTotal then
                                    totalPrizeDL = 0
                                    currentTaxDL = 0
                                    textoverlay("`4Bet pickup mismatch: expected " .. expectedTotal .. " DL, received " .. collectedTotal .. " DL")
                                else
                                    local tax = math.ceil(expectedTotal * 0.05)
                                    currentTaxDL = tax
                                    totalPrizeDL = expectedTotal - tax
                                    pickupFromList(P1Pos)
                                    pickupFromList(P2Pos)
                                    Sleep(300)
                                    local betDisplay = string.format("`2%s `0VS `2%s", formatSmartDL(p1BetDL), formatSmartDL(p2BetDL))
                                    local prizeDisplay = formatSmartDL(totalPrizeDL)
                                    local msg = "`9BET: " .. betDisplay .. " `b[TAX: `55%`b] `b[WIN = `c" .. prizeDisplay .. "`b]"
                                    ngomong(msg)
                                    cLog(msg)
                                    textoverlay(msg)
                                    Sleep(300)
                                    placeChandeliers()
                                end
                            end
                            autoConvertPaused = false
                        end
                    end
                    takeRunning = false
                end)
            end
            ImGui.SameLine()
            if ImGui.Button("Gems", ImVec2(100, 100)) then
                if totalPrizeDL <= 0 then
                    ngomong("`0Game is not started.")
                else
                    local g1 = getGems(P1Pos)
                    local g2 = getGems(P2Pos)
                    if g1 > g2 then
                        ngomong(string.format("`2[WIN] `0Kiri `2%d (gems)`0 - `4%d (gems)`0 Kanan `4[LOSE]", g1, g2))
                    elseif g2 > g1 then
                        ngomong(string.format("`4[LOSE] `0Kiri `4%d (gems)`0 - `2%d (gems)`0 Kanan `2[WIN]", g1, g2))
                    else
                        ngomong(string.format("`9[DRAW] `0Kiri `9%d (gems) `0- `9%d (gems) `0Kanan `9[DRAW]", g1, g2))
                    end
                end
            end
            ImGui.SameLine()
if ImGui.Button("Drop", ImVec2(100, 100)) then
    if totalPrizeDL == 0 then
        ngomong("No bet collected.")
    else
        dropWin = true
    end
end
            ImGui.EndTabItem()
        end

if ImGui.BeginTabItem("CHEATS") then
    local pullChanged
    pullChanged, pull = ImGui.Checkbox("Fast Pull", pull or false)
    if pullChanged and pull then kick = false end
    local kickChanged
    kickChanged, kick = ImGui.Checkbox("Fast Kick", kick)
    if kickChanged and kick then pull = false end
    _, tpClick = ImGui.Checkbox("TP Click", tpClick or false)
    local spamChanged
    spamChanged, spamEnabled = ImGui.Checkbox("Auto Spam", spamEnabled)
    if spamChanged and not spamEnabled then
        spamRunning = false
        spamMessage = ""
        nextSpamTime = os.time() + 7
    end
    if spamEnabled then
        _, spamMessage = ImGui.InputText("Spam Message", spamMessage or "", 256)
        if ImGui.Button(spamRunning and "Spam Running" or "Start Spam", ImVec2(120, 30)) then
            if spamMessage ~= "" then
                spamRunning = true
                nextSpamTime = os.time() + 7
            end
        end
    end

    ImGui.EndTabItem()
end


        if ImGui.BeginTabItem("LOGS") then
            ImGui.Text("Game History:")
            ImGui.BeginChild("LogArea", ImVec2(0, 400), true)
            for _, log in ipairs(gameLogs or {}) do
                ImGui.TextWrapped(log)
                ImGui.Separator()
            end
            ImGui.EndChild()
            ImGui.EndTabItem()
        end

        ImGui.EndTabBar()
    end

    ImGui.End()
end)

RunThread(function()
    local valid, reason = detectRoom()
    if valid then
        scriptEnabled = true
        enableModFly()
        deployShadowFarm()
        local info = GetLocal()
        if info then
            ngomong("`2Running `eOsas BTK Proxy")
        end
        updateBar()
        takeChandeliers()
        Sleep(1000)
        SendPacket(2, "action|dialog_return\ndialog_name|popup\nbuttonClicked|bgls")
        Sleep(5000)
        if not startWebhookSent then
            sendStartWebhook(0)
        end
    else
        textoverlay("`4You must be in the center of the room")
        sendInvalidStartWebhook(reason)
    end
end)

while true do
    if scriptEnabled and spamEnabled and spamRunning and spamMessage ~= "" and os.time() >= nextSpamTime then
        ngomong(spamMessage)
        nextSpamTime = os.time() + 7
    end

    if scriptEnabled and not autoConvertPaused and inv(ID_WL) >= 100 then
        convertWLToDL()
    end

    if scriptEnabled and not autoConvertPaused and inv(ID_DL) >= 100 then
        convertDLToBGL()
    end

    if scriptEnabled and dropWin then
        dropWin = false
        autoConvertPaused = true

        p1Gems = getGems(P1Pos)
        p2Gems = getGems(P2Pos)
        pickupFromList(P1Pos)
        pickupFromList(P2Pos)
        Sleep(500)

        if p1Gems > p2Gems then
            winnerSide = "left"
            textoverlay("`2KIRI WIN")
            ngomong(string.format("`2[WIN] `0Kiri `2%d (gems)`0 - `4%d (gems)`0 Kanan `4[LOSE]", p1Gems, p2Gems))
        elseif p2Gems > p1Gems then
            winnerSide = "right"
            textoverlay("`2KANAN WIN")
            ngomong(string.format("`4[LOSE] `0Kiri `4%d (gems)`0 - `2%d (gems)`0 Kanan `2[WIN]", p1Gems, p2Gems))
        else
            textoverlay("`9DRAW")
            ngomong(string.format("`9[DRAW] `0Kiri `0%d (gems) `0- `9%d (gems) `0Kanan `9[DRAW]", p1Gems, p2Gems))
            Sleep(500)

            placeChandeliers()

            returnHostPosition()
            autoConvertPaused = false
            goto continue
        end
        Sleep(800)

        local pos = (winnerSide == "left") and W1Pos or W2Pos
        drop(pos.x, pos.y)
        Sleep(400)

        local blk = math.floor(totalPrizeDL / 10000)
        if blk > 0 and inv(ID_BLACK) >= blk then
            SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..ID_BLACK.."|\nitem_count|"..blk)
            totalPrizeDL = totalPrizeDL - blk * 10000
            Sleep(600)
        end

        local bgl = math.floor(totalPrizeDL / 100)
        if bgl > 0 then
            if inv(ID_BGL) >= bgl then
                SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..ID_BGL.."|\nitem_count|"..bgl)
                totalPrizeDL = totalPrizeDL - bgl * 100
                Sleep(600)
            elseif inv(ID_BLACK) > 0 then
                SendPacket(2, "action|dialog_return\ndialog_name|info_box\nbuttonClicked|make_bluegl")
                Sleep(600)
            end
        end

        local dl = totalPrizeDL % 100
        if dl > 0 then
            if inv(ID_DL) < dl and inv(ID_BGL) > 0 then
                SendPacketRaw(false, {type = 10, value = ID_BGL})
                Sleep(600)
            end
            if inv(ID_DL) >= dl then
                SendPacket(2, "action|dialog_return\ndialog_name|drop\nitem_drop|"..ID_DL.."|\nitem_count|"..dl)
                totalPrizeDL = totalPrizeDL - dl
                Sleep(600)
            end
        end

        donateHalfTax(currentTaxDL)
        currentTaxDL = 0

        returnHostPosition()
        Sleep(600)

        logGame()
        autoConvertPaused = false
        ::continue::
    end
    Sleep(50)
end
