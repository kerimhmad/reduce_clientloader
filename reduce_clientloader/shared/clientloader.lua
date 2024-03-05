local ReduceSystem = {}

function ReduceSystem:CreateInstance()
    local obj = {
        ResourceName = GetCurrentResourceName(),
        ResourceExports = exports,

        Clientloader = {
            Event = "reduce_clientloader(%s)",
            Convar = "大ᖇEᗪᑌᑕE_ᑕᒪIEᑎTᒪOᗩᗪEᖇ(%s:%s)大", -- Change this Convar to something else!

            Files = {},
            Players = {},

            Loaded = false,
            Loading = false
        }
    }

    obj.ResourceFilesNum = GetNumResourceMetadata(obj.ResourceName, "reduce_clientloader")
    obj.ResourceDebug = GetResourceMetadata(obj.ResourceName, "reduce_debugMode")

    if obj.ResourceDebug == "yes" then
        obj.ResourceDebug = true
    elseif obj.ResourceDebug == "no" then
        obj.ResourceDebug = false
    else
        obj.ResourceDebug = false
    end

    function obj.GetResourceFilesNum()
        return obj.ResourceFilesNum
    end

    setmetatable(obj, self)
    self.__index = self

    return obj
end

function ReduceSystem:Encrypt(data, key)
    local result = ""

    for i=1, #data do
        result = result .. string.char((string.byte(data:sub(i, i)) ~ key) & 255)
    end

    return result
end

function ReduceSystem:Decrypt(data, key)
    return self:Encrypt(data, key)
end

function ReduceSystem:LogError(debug, message)
    local prefix = "^0(^4reduce_clientloader^0): ^1(!)^0 %s^0"

    if not message then return end

    if debug then
        if self.ResourceDebug then
            print((prefix):format(tostring(message)))
        end
    else
        print((prefix):format(tostring(message)))
    end
end

function ReduceSystem:LogSuccess(debug, message)
    local prefix = "^0(^4reduce_clientloader^0): ^2(!)^0 %s^0"

    if not message then return end

    if debug then
        if self.ResourceDebug then
            print((prefix):format(tostring(message)))
        end
    else
        print((prefix):format(tostring(message)))
    end
end

function ReduceSystem:LogInfo(debug, message)
    local prefix = "^0(^4reduce_clientloader^0): ^3(!)^0 %s^0"

    if not message then return end

    if debug then
        if self.ResourceDebug then
            print((prefix):format(tostring(message)))
        end
    else
        print((prefix):format(tostring(message)))
    end
end

function ReduceSystem:TableHasData(data, table)
    for _, tableData in ipairs(table) do
        if tableData == data then
            return true
        end
    end

    return false
end

function ReduceSystem:RequestClientFiles()
    if IsDuplicityVersion() then return end

    LocalPlayer.state:set((self.Clientloader.Event):format(self.ResourceName), math.random(0xdeadbea7), true)

    self:LogInfo(true, "Request file(s) from the server...")
end

function ReduceSystem:SendClientFiles(player)
    if not IsDuplicityVersion() then return end

    player = player:gsub("player:", "")

    Player(tonumber(player)).state:set((self.Clientloader.Event):format(self.ResourceName), self.Clientloader.Files, true)

    self:LogSuccess(true, ("Sends ^3%s ^0file(s) to player: ^3%s^0"):format(#self.Clientloader.Files, player))
end

function ReduceSystem:LoadClientFiles()
    if not self.Clientloader.Loaded and not self.Clientloader.Loading then
        local filesNum = 0

        if IsDuplicityVersion() then
            self.Clientloader.Loading = true

            for i=1, self.ResourceFilesNum do
                local fileName = GetResourceMetadata(self.ResourceName, "reduce_clientloader", i -1)

                if fileName and not self:TableHasData(fileName, self.Clientloader.Files) then
                    local fileCode = LoadResourceFile(self.ResourceName, fileName)

                    if fileCode then
                        SetConvarReplicated((self.Clientloader.Convar):format(self.ResourceName, fileName), json.encode({ roblox = self:Encrypt(fileCode, self.ResourceFilesNum) }))

                        table.insert(self.Clientloader.Files, fileName)

                        filesNum = filesNum +1

                        self:LogSuccess(true, ("File ^3%s ^0has been loaded"):format(fileName))
                    else
                        self:LogError(true, ("There was an ^1error ^0loading ^3%s^0, code: ^11^0"):format(fileName)) -- Error: 1
                    end
                end

                Wait(0)
            end

            if filesNum > 0 then
                self:LogSuccess(true, ("^3%s ^0file(s) were loaded"):format(filesNum))
            else
                self:LogInfo(true, "No file(s) were loaded")
            end

            self.Clientloader.Loaded = true
            self.Clientloader.Loading = false
        else
            self.Clientloader.Loading = true

            for _, fileName in ipairs(self.Clientloader.Files) do
                local fileCode = json.decode(GetConvar((self.Clientloader.Convar):format(self.ResourceName, fileName), nil)).roblox

                if fileCode then
                    --[[local fileSpawned, fileSpawnError = load(self:Decrypt(fileCode, self.ResourceFilesNum), ("@reduce_clientloader: @%s/%s"):format(self.ResourceName, fileName), "bt")

                    if fileSpawned then
                        local fileLoaded, fileError = pcall(fileSpawned)

                        if fileLoaded then
                            filesNum = filesNum +1

                            self:LogSuccess(true, ("File ^3%s ^0has been loaded"):format(fileName))
                        else
                            self:LogError(false, ("There was an ^1error ^0loading ^3%s^0, code: ^1(1) %s^0"):format(fileName, fileError))
                        end
                    else
                        self:LogError(false, ("There was an ^1error ^0loading ^3%s^0, code: ^1(2) %s^0"):format(fileName, fileSpawnError))
                    end--]]

                    local fileSpawned, fileSpawnError = pcall(load(self:Decrypt(fileCode, self.ResourceFilesNum), ("@reduce_clientloader: @%s/%s"):format(self.ResourceName, fileName), "bt"))

                    if fileSpawned then
                        filesNum = filesNum +1

                        self:LogSuccess(true, ("File ^3%s ^0has been loaded"):format(fileName))
                    else
                        self:LogError(false, ("There was an ^1error ^0loading ^3%s^0, code: ^1(2) %s^0"):format(fileName, fileSpawnError))
                    end
                else
                    self:LogError(true, ("There was an ^1error ^0loading ^3%s^0, code: ^1(1)^0"):format(fileName)) -- Error: 1
                end
            end

            self.Clientloader.Files = {}

            if filesNum > 0 then
                self:LogSuccess(true, ("^3%s ^0file(s) were loaded"):format(filesNum))
            else
                self:LogInfo(true, "No file(s) were loaded")
            end

            self.Clientloader.Loaded = true
            self.Clientloader.Loading = false
        end
    end
end

function ReduceSystem:CrashInstance()
    local message = [[
        ^1------------ Reduce Clientloader ------------^0
        ^1An error was detected, please contact support^0
        ^1------------ Reduce Clientloader ------------^0
    ]]

    if IsDuplicityVersion() then
        print(message)

        while true do os.exit() end
    else
        print(message)

        while true do ForceSocialClubUpdate() end
    end
end

local Instance = ReduceSystem:CreateInstance()

if Instance.GetResourceFilesNum() > 0 then
    if IsDuplicityVersion() then
        Instance:LoadClientFiles()

        SetTimeout(2 * 60000, function()
            if not Instance.Clientloader.Loaded then
                Instance:CrashInstance()
            end
        end)

        AddStateBagChangeHandler((Instance.Clientloader.Event):format(Instance.ResourceName), nil, function(player, key, data)
            if type(data) ~= "number" or GetInvokingResource() ~= nil then return end

            player = tostring(player)

            if not Instance.Clientloader.Players[player] then
                Instance.Clientloader.Players[player] = true

                while not Instance.Clientloader.Loaded do Wait(500) end

                Instance:SendClientFiles(player)
            end
        end)

        exports("GetResourceInfo", function()
            while not Instance.Clientloader.Loaded do Wait(500) end

            return Instance.Clientloader.Files
        end)
    else
        Instance:RequestClientFiles()

        CreateThread(function()
            while true do
                Wait(0)

                if Instance.Clientloader.Loaded or Instance.Clientloader.Loading then break end

                Instance:RequestClientFiles()

                Wait(1000)
            end
        end)

        SetTimeout(2 * 60000, function()
            if not Instance.Clientloader.Loaded then
                Instance:CrashInstance()
            end
        end)

        AddStateBagChangeHandler((Instance.Clientloader.Event):format(Instance.ResourceName), nil, function(player, key, data)
            if type(data) ~= "table" or GetInvokingResource() ~= nil then return end

            player = tostring(player)

            if not Instance.Clientloader.Players[player] then
                Instance.Clientloader.Players[player] = true

                Instance.Clientloader.Files = data

                Instance:LoadClientFiles()
            end
        end)

        exports = Instance.ResourceExports
    end
end

-- dont skid this :)
