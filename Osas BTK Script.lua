        local function inv(id)
            for _, item in pairs(GetInventory()) do
                if item.id == id then
                    return item.amount
                end
            end
            return 0
        end

        local function pickupAt(tile)
            if not tile or not tile.x or not tile.y then return end
            for _, o in pairs(GetObjectList() or {}) do
                local ox, oy = math.floor(o.pos.x / 32), math.floor(o.pos.y / 32)
                if ox == tile.x and oy == tile.y then
                    SendPacketRaw(false, {type = 11, value = o.oid, x = o.pos.x, y = o.pos.y})
                    Sleep(1)
                end
            end
        end

    local movementLocked = false
    local GHOST_SKIN = 4294967140
    local GHOST_COOLDOWN_SECONDS = 3
    local ghosted = nil
    local waitingForGhostChange = false
    local ghostChangeReceived = false
    local nextGhostCommandTime = 0

    local function sendGhostCommand()
        while os.time() < nextGhostCommandTime do
            Sleep(100)
        end

        ghostChangeReceived = false
        waitingForGhostChange = true
        SendPacket(2, "action|input\n|text|/ghost")
        nextGhostCommandTime = os.time() + GHOST_COOLDOWN_SECONDS

        local waited = 0
        while not ghostChangeReceived and waited < 2500 do
            Sleep(50)
            waited = waited + 50
        end

        waitingForGhostChange = false
        return ghostChangeReceived
    end

    local function ensureGhosted()
        if ghosted == true then return true end

        -- If the first /ghost produces another skin, we were already ghosted and
        -- the command toggled ghost off. Send it once more to turn ghost back on.
        sendGhostCommand()
        if ghosted ~= true then
            Sleep(300)
            sendGhostCommand()
        end

        return ghosted == true
    end

    local function ensureUnghosted()
        if ghosted ~= true then return true end
        sendGhostCommand()
        return ghosted == false
    end

    local function ghostOnceAfterCollect()
        if ghosted == true then return true end
        sendGhostCommand()
        return ghosted == true
    end

    local centers = {
        [1] = {x=50, y=34},
        [2] = {x=50, y=16},
        [3] = {x=36, y=29},
        [4] = {x=64, y=29},
        [5] = {x=36, y=23},
        [6] = {x=64, y=23}
    }

    local IGL = {x=50, y=31}

    function getRoomLocks(roomId)
        local c = centers[roomId]
        if not c then return nil end

        local flagY = (roomId == 1) and (c.y - 2) or (c.y - 1)

        local data = {
            stand = {x = c.x, y = c.y},
            flag  = {x = c.x, y = flagY}
        }

        if roomId == 1 or roomId == 2 then
            data.lockA = {x = c.x - 4, y = c.y}
            data.lockB = {x = c.x + 4, y = c.y}

        elseif roomId == 3 or roomId == 4 then
            data.lockA = {x = c.x - 1, y = c.y - 2}
            data.lockB = {x = c.x + 1, y = c.y - 2}

        elseif roomId == 5 or roomId == 6 then
            data.lockA = {x = c.x - 1, y = c.y + 2}
            data.lockB = {x = c.x + 1, y = c.y + 2}
        end

        return data
    end

    local dialogData = nil

    local function moveTo(x,y)
        FindPath(x,y,500)
        Sleep(300)
    end

    local function findPathAndWait(x, y, timeout)
        FindPath(x, y, 500)

        local waited = 0
        timeout = timeout or 3000
        while waited < timeout do
            local player = GetLocal()
            if player and player.pos then
                local playerX = math.floor(player.pos.x / 32)
                local playerY = math.floor(player.pos.y / 32)
                if playerX == x and playerY == y then
                    return true
                end
            end

            Sleep(50)
            waited = waited + 50
        end

        return false
    end

    local function wrench(x,y)
        SendPacketRaw(false,{type=3,value=32,x=x*32,y=y*32,px=x,py=y,netid=0,state=0})
        Sleep(500)
    end

    local function accessLock(x,y,netid)
        SendPacket(2,
            "action|dialog_return\n" ..
            "dialog_name|lock_edit\n" ..
            "x|"..x.."|\n" ..
            "y|"..y.."|\n" ..
            "targetNetID|"..netid
        )
        Sleep(500)
    end

    local function buildRemoveAllPacket(dialog)
        local x = dialog:match("embed_data|x|(%d+)")
        local y = dialog:match("embed_data|y|(%d+)")
        if not x or not y then return end

        local packet = {
            "action|dialog_return",
            "dialog_name|lock_edit",
            "x|"..x.."|",
            "y|"..y.."|"
        }
        local found = false
        local seen = {}

        for userid in dialog:gmatch("access_on_userid_(%d+)") do
            if not seen[userid] then
                seen[userid] = true
                found = true
                table.insert(packet, "access_on_userid_"..userid.."|0")
            end
        end

        if not found then return end
        return table.concat(packet, "\n")
    end

    local function accessUserIDs(dialog)
        local userids = {}
        for userid in tostring(dialog or ""):gmatch("access_on_userid_(%d+)") do
            userids[userid] = true
        end
        return userids
    end

    local function buildRemoveSelectedPacket(dialog, userids)
        local x = dialog:match("embed_data|x|(%d+)")
        local y = dialog:match("embed_data|y|(%d+)")
        if not x or not y then return end

        local packet = {
            "action|dialog_return",
            "dialog_name|lock_edit",
            "x|"..x.."|",
            "y|"..y.."|"
        }
        local found = false

        for userid in dialog:gmatch("access_on_userid_(%d+)") do
            if userids[userid] then
                table.insert(packet, "access_on_userid_"..userid.."|0")
                found = true
            end
        end

        if not found then return end
        return table.concat(packet, "\n")
    end

    AddHook("OnVariant","capture_dialog",function(v, netid)
        if v[0] == "OnChangeSkin" then
            local localPlayer = GetLocal()
            local localNetID = localPlayer and (localPlayer.netid or localPlayer.netID)
            if not netid or netid == -1 or netid == 0 or not localNetID or netid == localNetID then
                local skin = tonumber(v[1])
                ghosted = skin == GHOST_SKIN
                if waitingForGhostChange then
                    ghostChangeReceived = true
                end
            end
        end

        if v[0]=="OnDialogRequest"
        and v[1]
        and v[1]:find("embed_data|x|")
        and v[1]:find("access_on_userid_") then
            dialogData=v[1]
        end
    end)

    AddHook("OnVariant","acc_remove",function(v)
        if v[0]~="OnTalkBubble" then return end

        local netid=v[1]
        local msg=(v[2] or ""):gsub("[`^]","")

        local sender
        for _,p in pairs(GetPlayerList() or {}) do
            if p.netid==netid then sender=p.userid break end
        end

        local allowed={[3]=true,[474089]=true,[356170]=true}
        if not sender or not allowed[sender] then return end

        local accRoom,uid=msg:match("^!acc%s+(%S+)%s+(%d+)$")
        local remRoom=msg:match("^!remove%s+(%d+)$")
    local cleanMsg = msg:gsub("^%s+",""):gsub("%s+$",""):lower()
    local collectCmd = cleanMsg == "!collect"
    local removeAllCmd = cleanMsg == "!removeall"

    if collectCmd then
        RunThread(function()
            movementLocked = true

            for roomId = 1, 6 do
                local c = centers[roomId]

                if c then
                    local donY = (roomId == 1) and (c.y + 3) or (c.y - 3)
                    local teleX = c.x
                    local teleY
                    if roomId >= 2 and roomId <= 6 then
                        teleY = c.y
                    else
                        teleY = c.y + 2
                    end

                    for x = c.x - 2, c.x + 2 do
                        local tile = {
                            x = x,
                            y = donY
                        }

                        local hasCurrency = false

                        for _, o in pairs(GetObjectList() or {}) do
                            local ox = math.floor(o.pos.x / 32)
                            local oy = math.floor(o.pos.y / 32)

                            if ox == tile.x and oy == tile.y then
                                if o.id == 242 or o.id == 1796 or o.id == 7188 or o.id == 11550 then
                                    hasCurrency = true
                                    break
                                end
                            end
                        end

                        if hasCurrency then
                            findPathAndWait(tile.x + 1, tile.y, 3000)
                            Sleep(150)
                            ensureUnghosted()
                            Sleep(200)

                            local attempts = 0

                            while attempts < 100 do
                                local dropExists = false

                                for _, o in pairs(GetObjectList() or {}) do
                                    local ox = math.floor(o.pos.x / 32)
                                    local oy = math.floor(o.pos.y / 32)

                                    if ox == tile.x and oy == tile.y then
                                        if o.id == 242 or o.id == 1796 or o.id == 7188 or o.id == 11550 then
                                            dropExists = true
                                            break
                                        end
                                    end
                                end

                                if not dropExists then
                                    break
                                end

                                pickupAt(tile)
                                Sleep(100)

                                if inv(7188) > 0 then
                                    SendPacket(2,
                                        "action|dialog_return\n" ..
                                        "dialog_name|bank_deposit\n" ..
                                        "bgl_count|" .. inv(7188)
                                    )
                                    Sleep(500)
                                end

    if inv(1796) >= 100 then
        findPathAndWait(teleX, teleY - 1, 3000)
        Sleep(150)

        while inv(1796) >= 100 do
            SendPacket(2,
                "action|dialog_return\n" ..
                "dialog_name|telephone\n" ..
                "num|53785|\n" ..
                "x|" .. teleX .. "|\n" ..
                "y|" .. teleY .. "|\n" ..
                "buttonClicked|bglconvert"
            )
            Sleep(750)
        end
    end
                                while inv(242) >= 100 do
                                    SendPacketRaw(false,{
                                        type = 10,
                                        value = 242
                                    })
                                    Sleep(750)
                                end

                                findPathAndWait(tile.x + 1, tile.y, 3000)
                                Sleep(150)

                                attempts = attempts + 1
                            end

                            ghostOnceAfterCollect()
                        end
                    end
                end
            end

            findPathAndWait(50, 24, 3000)
            Sleep(150)

            movementLocked = false
        end)
    end

        if accRoom and uid then
            RunThread(function()
                movementLocked=true

                uid=tonumber(uid)
                local tnet
                for _,p in pairs(GetPlayerList() or {}) do
                    if p.userid==uid then tnet=p.netid break end
                end
                if not tnet then movementLocked=false return end

                local roomId = tonumber(accRoom)
                local locksData = getRoomLocks(roomId)
                if locksData then
                    moveTo(locksData.stand.x, locksData.stand.y)
                    accessLock(locksData.flag.x, locksData.flag.y, tnet)
                    accessLock(locksData.lockA.x, locksData.lockA.y, tnet)
                    accessLock(locksData.lockB.x, locksData.lockB.y, tnet)
                end

                moveTo(IGL.x, IGL.y-1)
                accessLock(IGL.x, IGL.y, tnet)

                FindPath(50,24,500)
                Sleep(500)

                movementLocked=false
            end)
        end

        if remRoom or removeAllCmd then
            RunThread(function()
                movementLocked=true

                local function removeAt(x,y,selectedUserIDs)
                    dialogData=nil
                    wrench(x,y)
                    local t=0
                    while not dialogData and t<2000 do
                        Sleep(50)
                        t=t+50
                    end
                    if dialogData then
                        local pkt
                        if selectedUserIDs then
                            pkt = buildRemoveSelectedPacket(dialogData, selectedUserIDs)
                        else
                            pkt = buildRemoveAllPacket(dialogData)
                        end
                        if pkt then SendPacket(2,pkt) end
                    end
                    Sleep(200)
                    return accessUserIDs(dialogData)
                end

                local function removeRoom(roomId)
                    local locksData = getRoomLocks(roomId)
                    if not locksData then return {} end

                    local roomUserIDs = {}
                    local function removeRoomLock(x, y)
                        local foundUserIDs = removeAt(x, y)
                        for userid in pairs(foundUserIDs) do
                            roomUserIDs[userid] = true
                        end
                    end

                    moveTo(locksData.stand.x, locksData.stand.y)
                    removeRoomLock(locksData.flag.x, locksData.flag.y)
                    removeRoomLock(locksData.lockA.x, locksData.lockA.y)
                    removeRoomLock(locksData.lockB.x, locksData.lockB.y)
                    return roomUserIDs
                end

                if removeAllCmd then
                    for roomId = 1, 6 do
                        removeRoom(roomId)
                    end

                    moveTo(IGL.x, IGL.y-1)
                    removeAt(IGL.x, IGL.y)
                else
                    local roomUserIDs = removeRoom(tonumber(remRoom))

                    moveTo(IGL.x, IGL.y-1)
                    removeAt(IGL.x, IGL.y, roomUserIDs)
                end

                FindPath(50,24,500)
                Sleep(500)

                movementLocked=false
            end)
        end
    end)

    RunThread(function()
        ensureGhosted()

        while true do
            local w = GetWorld()
            if not w or w.name ~= "BTK" then
                RequestJoinWorld("BTK")
                Sleep(2500)
            else
                if not movementLocked then
                    local me = GetLocal()
                    if me and me.pos then
                        local tx = math.floor(me.pos.x / 32)
                        local ty = math.floor(me.pos.y / 32)
                        if tx ~= 50 or ty ~= 24 then
                            FindPath(50,24,500)
                            Sleep(500)
                        end
                    end
                end
            end
            Sleep(500)
        end
    end)
