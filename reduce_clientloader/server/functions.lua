ReduceSystem = {}

function ReduceSystem:CreateInstance()
    local obj = {
        ResourceName = GetCurrentResourceName(),

        SubCommands = {}
    }

    obj.ResourceVersion = GetResourceMetadata(obj.ResourceName, "version")

    setmetatable(obj, self)
    self.__index = self

    return obj
end

function ReduceSystem:LogError(message)
    local prefix = "^1(!)^0 %s^0"

    if not message then return end

    print((prefix):format(tostring(message)))
end

function ReduceSystem:LogSuccess(message)
    local prefix = "^2(!)^0 %s^0"

    if not message then return end

    print((prefix):format(tostring(message)))
end

function ReduceSystem:LogInfo(message)
    local prefix = "^3(!)^0 %s^0"

    if not message then return end

    print((prefix):format(tostring(message)))
end

function ReduceSystem:RegisterSubCommand(name, handler, hide)
    self.SubCommands[name] = handler
end

function ReduceSystem:LoadSubCommands(command)
    RegisterCommand(command, function(source, args, raw)
        if source == 0 then
            local subCommand = args[1]

            if subCommand then
                local commandFound = false

                for name, handler in pairs(self.SubCommands) do
                    if subCommand == name then
                        commandFound = true

                        table.remove(args, 1)

                        handler(args)

                        break
                    end
                end

                if not commandFound then
                    self:LogError(("^3%s ^0is not a valid sub command"):format(subCommand))
                end
            else
                self:LogError("No sub command was specified")
            end
        end
    end)
end

function ReduceSystem:GetResourceState(resourceName, states)
    local resourceState = GetResourceState(resourceName)

    if resourceState then
        for _, state in ipairs(states) do
            if resourceState == state then
                return true
            end
        end
    end

    return false
end

function ReduceSystem:GetResourceFiles(resourceName, files)
    for _, file in ipairs(files) do
        local fileName = LoadResourceFile(resourceName, file)

        if fileName then
            return file
        end
    end

    return false
end

function ReduceSystem:ClientloaderInstall(resourceName)
    local blacklist = {}

    blacklist.resources = {
        ["sessionmanager"] = true,
        ["spawnmanager"] = true,
        ["monitor"] = true
    }

    blacklist.files = {
        ".fxap",
        "cache.dnzwtf",
        "license.api"
    }

    if not blacklist.resources[resourceName] then
        local resourceFound = self:GetResourceState(resourceName, { "started", "starting", "stopped", "stopping" })

        if resourceFound then
            local blacklistedFile = self:GetResourceFiles(resourceName, blacklist.files)

            if not blacklistedFile then
                local fxmanifest = {}
                local __resource = {}

                fxmanifest.file = LoadResourceFile(resourceName, "fxmanifest.lua")
                __resource.file = LoadResourceFile(resourceName, "__resource.lua")

                if fxmanifest.file or __resource.file then
                    local client_scripts = GetNumResourceMetadata(resourceName, "client_script")

                    if client_scripts > 0 then
                        local blacklistedFormat = nil

                        for i=1, client_scripts do
                            local client_script = GetResourceMetadata(resourceName, "client_script", i -1)

                            if client_script then
                                if client_script.find(client_script, "*") then
                                    blacklistedFormat = "*"

                                    break
                                elseif client_script.find(client_script, "@") then
                                    blacklistedFormat = "@"
                                end
                            else
                                self:LogError(("An error ^1(2) ^0occurred, try again later... - ^3%s"):format(resourceName))
                            end
                        end

                        if not blacklistedFormat then
                            local shared_script = ("shared_script '@%s/shared/clientloader.lua'"):format(self.ResourceName)
                            local lua54 = "lua54 'yes'"

                            if fxmanifest.file then
                                local reduce_clientloader = GetNumResourceMetadata(resourceName, "reduce_clientloader")

                                if reduce_clientloader == 0 then
                                    SaveResourceFile(self.ResourceName, ("server/manifests/%s.txt"):format(resourceName), fxmanifest.file, -1)
                                end

                                if not fxmanifest.file.match(fxmanifest.file, shared_script) then
                                    fxmanifest.file = ("%s\n\n%s"):format(shared_script, fxmanifest.file)
                                end

                                if not fxmanifest.file.match(fxmanifest.file, "lua54") then
                                    fxmanifest.file = ("%s\n\n%s"):format(lua54, fxmanifest.file)
                                end

                                if fxmanifest.file.match(fxmanifest.file, "client_scripts") then
                                    fxmanifest.file = fxmanifest.file:gsub("client_scripts", "reduce_clientloader")
                                end

                                if fxmanifest.file.match(fxmanifest.file, "client_script") then
                                    fxmanifest.file = fxmanifest.file:gsub("client_script", "reduce_clientloader")
                                end

                                SaveResourceFile(resourceName, "fxmanifest.lua", fxmanifest.file, -1)

                                self:LogSuccess(("The installation was completed successfully - ^3%s"):format(resourceName))
                            elseif __resource.file then
                                local reduce_clientloader = GetNumResourceMetadata(resourceName, "reduce_clientloader")

                                if reduce_clientloader == 0 then
                                    SaveResourceFile(self.ResourceName, ("server/manifests/%s.txt"):format(resourceName), fxmanifest.file, -1)
                                end

                                if not __resource.file.match(__resource.file, shared_script) then
                                    __resource.file = ("%s\n\n%s"):format(shared_script, __resource.file)
                                end

                                if not __resource.file.match(__resource.file, "lua54") then
                                    __resource.file = ("%s\n\n%s"):format(lua54, __resource.file)
                                end

                                if __resource.file.match(__resource.file, "client_scripts") then
                                    __resource.file = __resource.file:gsub("client_scripts", "reduce_clientloader")
                                end

                                if __resource.file.match(__resource.file, "client_script") then
                                    __resource.file = __resource.file:gsub("client_script", "reduce_clientloader")
                                end

                                SaveResourceFile(resourceName, "__resource.lua", __resource.file, -1)

                                self:LogSuccess(("The installation was completed successfully - ^3%s"):format(resourceName))
                            end
                        else
                            self:LogError(("The installation was aborted, reason: A forbidden format (^3%s^0) was found - ^3%s"):format(blacklistedFormat, resourceName))
                        end
                    else
                        self:LogError(("No protectable file(s) were found - ^3%s"):format(resourceName))
                    end
                else
                    self:LogError(("No manifest file was found - ^3%s"):format(resourceName))
                end
            else
                self:LogError(("The installation was aborted, reason: A forbidden file (^3%s^0) was found - ^3%s"):format(blacklistedFile, resourceName))
            end
        else
            self:LogError(("The resource was not found - ^3%s"):format(resourceName))
        end
    else
        self:LogError(("An error ^1(1) ^0occurred, try again later... - ^3%s"):format(resourceName))
    end
end

function ReduceSystem:ClientloaderUninstall(resourceName)
    local blacklist = {}

    blacklist.resources = {
        ["sessionmanager"] = true,
        ["spawnmanager"] = true,
        ["monitor"] = true
    }

    blacklist.files = {
        ".fxap",
        "cache.dnzwtf",
        "license.api"
    }

    if not blacklist.resources[resourceName] then
        local resourceFound = self:GetResourceState(resourceName, { "started", "starting", "stopped", "stopping" })

        if resourceFound then
            local fxmanifest = {}
            local __resource = {}

            fxmanifest.file = LoadResourceFile(resourceName, "fxmanifest.lua")
            __resource.file = LoadResourceFile(resourceName, "__resource.lua")

            if fxmanifest.file or __resource.file then
                if fxmanifest.file then
                    fxmanifest.backupFile = LoadResourceFile(self.ResourceName, ("server/manifests/%s.txt"):format(resourceName))

                    if fxmanifest.backupFile then
                        SaveResourceFile(resourceName, "fxmanifest.lua", fxmanifest.backupFile, -1)

                        self:LogSuccess(("The manifest file has been successfully restored - ^3%s"):format(resourceName))
                    else
                        self:LogError(("No backup manifest file was found - ^3%s"):format(resourceName))
                    end
                elseif  __resource.file then
                    __resource.backupFile = LoadResourceFile(self.ResourceName, ("server/manifests/%s.txt"):format(resourceName))

                    if __resource.backupFile then
                        SaveResourceFile(resourceName, "__resource.lua", __resource.backupFile, -1)

                        self:LogSuccess(("The manifest file has been successfully restored - ^3%s"):format(resourceName))
                    else
                        self:LogError(("No backup manifest file was found - ^3%s"):format(resourceName))
                    end
                end
            else
                self:LogError(("No manifest file was found - ^3%s"):format(resourceName))
            end
        else
            self:LogError(("The resource was not found - ^3%s"):format(resourceName))
        end
    else
        self:LogError(("An error ^1(1) ^0occurred, try again later... - ^3%s"):format(resourceName))
    end
end