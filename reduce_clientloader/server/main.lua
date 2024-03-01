local Instance = ReduceSystem:CreateInstance()

AddEventHandler("onServerResourceStart", function(startedResource)
    if startedResource ~= Instance.ResourceName then return end

    Instance:LogSuccess("^2Successfully ^0started, thanks for purchase!")

    Instance:RegisterSubCommand("info", function(args)
        local resourceName = args[1]

        if resourceName then
            local resourceStarted = Instance:GetResourceState(resourceName, { "started" })

            if resourceStarted then
                local _, resourceInfo, __ = xpcall(
                    function()
                        return exports[resourceName]:GetResourceInfo()
                    end, function()
                        return false
                    end
                )

                if resourceInfo then
                    local protectedFiles = {}

                    for i=1, #resourceInfo do
                        local protectedFile = resourceInfo[i]

                        table.insert(protectedFiles, protectedFile)
                    end

                    protectedFiles = table.concat(protectedFiles, ", ")

                    Instance:LogInfo(("^3%s ^0protected file(s) were found:\n%s"):format(#resourceInfo, protectedFiles))
                else
                    Instance:LogInfo(("No protected file(s) could be found - ^3%s"):format(resourceName))
                end
            else
                Instance:LogError(("The resource was not found or is not started - ^3%s"):format(resourceName))
            end
        else
            Instance:LogError("No resource was specified")
        end
    end)

    Instance:RegisterSubCommand("install", function(args)
        local resourceName = args[1]

        if resourceName then
            Instance:ClientloaderInstall(resourceName)

            ExecuteCommand("refresh")
        else
            for i=0, GetNumResources() -1 do
                local resourceName = GetResourceByFindIndex(i)

                Instance:ClientloaderInstall(resourceName)
            end

            ExecuteCommand("refresh")
        end
    end)

    Instance:RegisterSubCommand("uninstall", function(args)
        local resourceName = args[1]

        if resourceName then
            Instance:ClientloaderUninstall(resourceName)

            ExecuteCommand("refresh")
        else
            for i=0, GetNumResources() -1 do
                local resourceName = GetResourceByFindIndex(i)

                Instance:ClientloaderUninstall(resourceName)
            end

            ExecuteCommand("refresh")
        end
    end)

    Instance:LoadSubCommands("clientloader")
end)