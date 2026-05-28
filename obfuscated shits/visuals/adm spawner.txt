task.spawn(
    function()
        local load = require(game.ReplicatedStorage:WaitForChild("Fsys")).load

        set_thread_identity(2)
        local clientData = load("ClientData")
        local items = load("KindDB")
        local router = load("RouterClient")
        local downloader = load("DownloadClient")
        local animationManager = load("AnimationManager")
        local petRigs = load("new:PetRigs")
        set_thread_identity(8)

        local petModels = {}
        local pets = {}
        local equippedPet = nil
        local mountedPet = nil
        local currentMountTrack = nil

        local function updateData(key, action)
            local data = clientData.get(key)
            local clonedData = table.clone(data)
            clientData.predict(key, action(clonedData))
        end

        local function getUniqueId()
            local HttpService = game:GetService("HttpService")
            return HttpService:GenerateGUID(false)
        end

        local function getPetModel(kind)
            if petModels[kind] then
                return petModels[kind]
            end
            local streamed = downloader.promise_download_copy("Pets", kind):expect()
            petModels[kind] = streamed
            return streamed
        end

        local function createPet(id, properties)
            local uniqueId = getUniqueId()
            local pet = nil

            set_thread_identity(2)
            updateData(
                "inventory",
                function(inventory)
                    local newPets = table.clone(inventory.pets)
                    local item = items[id]
                    pet = {
                        unique = uniqueId,
                        category = "pets",
                        id = id,
                        kind = item.kind,
                        newness_order = 0,
                        properties = properties
                    }
                    newPets[uniqueId] = pet
                    inventory.pets = newPets
                    return inventory
                end
            )

            set_thread_identity(8)
            pets[uniqueId] = {data = pet, model = nil}
            return pet
        end

        local function neonify(model, entry)
            local petModel = model:FindFirstChild("PetModel")
            if not petModel then
                return
            end
            for neonPart, configuration in pairs(entry.neon_parts) do
                local trueNeonPart = petRigs.get(petModel).get_geo_part(petModel, neonPart)
                trueNeonPart.Material = configuration.Material
                trueNeonPart.Color = configuration.Color
            end
        end

        local function addPetWrapper(wrapper)
            updateData(
                "pet_char_wrappers",
                function(petWrappers)
                    wrapper.unique = #petWrappers + 1
                    wrapper.index = #petWrappers + 1
                    petWrappers[#petWrappers + 1] = wrapper
                    return petWrappers
                end
            )
        end

        local function addPetState(state)
            updateData(
                "pet_state_managers",
                function(petStates)
                    petStates[#petStates + 1] = state
                    return petStates
                end
            )
        end

        local function findIndex(array, finder)
            for index, value in pairs(array) do
                if finder(value, index) then
                    return index
                end
            end
            return nil
        end

        local function removePetWrapper(uniqueId)
            updateData(
                "pet_char_wrappers",
                function(petWrappers)
                    local index =
                        findIndex(
                        petWrappers,
                        function(wrapper)
                            return wrapper.pet_unique == uniqueId
                        end
                    )
                    if not index then
                        return petWrappers
                    end
                    table.remove(petWrappers, index)
                    for wrapperIndex, wrapper in pairs(petWrappers) do
                        wrapper.unique = wrapperIndex
                        wrapper.index = wrapperIndex
                    end
                    return petWrappers
                end
            )
        end

        local function clearPetState(uniqueId)
            local pet = pets[uniqueId]
            if not pet or not pet.model then
                return
            end
            updateData(
                "pet_state_managers",
                function(states)
                    local index =
                        findIndex(
                        states,
                        function(state)
                            return state.char == pet.model
                        end
                    )
                    if not index then
                        return states
                    end
                    local clonedStates = table.clone(states)
                    clonedStates[index] = table.clone(clonedStates[index])
                    clonedStates[index].states = {}
                    return clonedStates
                end
            )
        end

        local function setPetState(uniqueId, id)
            local pet = pets[uniqueId]
            if not pet or not pet.model then
                return
            end
            updateData(
                "pet_state_managers",
                function(states)
                    local index =
                        findIndex(
                        states,
                        function(state)
                            return state.char == pet.model
                        end
                    )
                    if not index then
                        return states
                    end
                    local clonedStates = table.clone(states)
                    clonedStates[index] = table.clone(clonedStates[index])
                    clonedStates[index].states = {{id = id}}
                    return clonedStates
                end
            )
        end

        local function attachPlayerToPet(pet)
            local character = game.Players.LocalPlayer.Character
            if not character or not character.PrimaryPart then
                return false
            end
            local ridePosition = pet:FindFirstChild("RidePosition", true)
            if not ridePosition then
                return false
            end

            local sourceAttachment = Instance.new("Attachment")
            sourceAttachment.Parent = ridePosition
            sourceAttachment.Position = Vector3.new(0, 1.237, 0)
            sourceAttachment.Name = "SourceAttachment"

            local stateConnection = Instance.new("RigidConstraint")
            stateConnection.Name = "StateConnection"
            stateConnection.Attachment0 = sourceAttachment
            stateConnection.Attachment1 = character.PrimaryPart.RootAttachment
            stateConnection.Parent = character
            return true
        end

        local function clearPlayerState()
            updateData(
                "state_manager",
                function(state)
                    local clonedState = table.clone(state)
                    clonedState.states = {}
                    clonedState.is_sitting = false
                    return clonedState
                end
            )
        end

        local function setPlayerState(id)
            updateData(
                "state_manager",
                function(state)
                    local clonedState = table.clone(state)
                    clonedState.states = {{id = id}}
                    clonedState.is_sitting = true
                    return clonedState
                end
            )
        end

        local function removePetState(uniqueId)
            local pet = pets[uniqueId]
            if not pet or not pet.model then
                return
            end
            updateData(
                "pet_state_managers",
                function(petStates)
                    local index =
                        findIndex(
                        petStates,
                        function(state)
                            return state.char == pet.model
                        end
                    )
                    if not index then
                        return petStates
                    end
                    table.remove(petStates, index)
                    return petStates
                end
            )
        end

        local function unmount(uniqueId)
            local pet = pets[uniqueId]
            if not pet or not pet.model then
                return
            end
            if currentMountTrack then
                currentMountTrack:Stop()
                currentMountTrack:Destroy()
            end
            local sourceAttachment = pet.model:FindFirstChild("SourceAttachment", true)
            if sourceAttachment then
                sourceAttachment:Destroy()
            end
            if game.Players.LocalPlayer.Character then
                for _, d in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if d:IsA("BasePart") and d:GetAttribute("HaveMass") then
                        d.Massless = false
                    end
                end
            end
            clearPetState(uniqueId)
            clearPlayerState()
            pet.model:ScaleTo(1)
            mountedPet = nil
        end

        local function mount(uniqueId, playerState, petState)
            local pet = pets[uniqueId]
            if not pet or not pet.model then
                return
            end
            local player = game.Players.LocalPlayer
            if not player.Character or not player.Character.PrimaryPart then
                return
            end
            mountedPet = uniqueId
            setPetState(uniqueId, petState)
            setPlayerState(playerState)
            pet.model:ScaleTo(2)
            attachPlayerToPet(pet.model)
            currentMountTrack =
                player.Character.Humanoid.Animator:LoadAnimation(animationManager.get_track("PlayerRidingPet"))
            player.Character.Humanoid.Sit = true
            for _, d in pairs(player.Character:GetDescendants()) do
                if d:IsA("BasePart") and d.Massless == false then
                    d.Massless = true
                    d:SetAttribute("HaveMass", true)
                end
            end
            currentMountTrack:Play()
        end

        local function fly(uniqueId)
            mount(uniqueId, "PlayerFlyingPet", "PetBeingFlown")
        end
        local function ride(uniqueId)
            mount(uniqueId, "PlayerRidingPet", "PetBeingRidden")
        end

        local function unequip(item)
            local pet = pets[item.unique]
            if not pet or not pet.model then
                return
            end
            unmount(item.unique)
            removePetWrapper(item.unique)
            removePetState(item.unique)
            pet.model:Destroy()
            pet.model = nil
            equippedPet = nil
        end

        local function equip(item)
            if equippedPet then
                unequip(equippedPet)
            end
            local petModel = getPetModel(item.kind):Clone()
            petModel.Parent = workspace
            pets[item.unique].model = petModel
            if item.properties.neon or item.properties.mega_neon then
                neonify(petModel, items[item.kind])
            end
            equippedPet = item
            addPetWrapper(
                {
                    char = petModel,
                    mega_neon = item.properties.mega_neon,
                    neon = item.properties.neon,
                    player = game.Players.LocalPlayer,
                    entity_controller = game.Players.LocalPlayer,
                    controller = game.Players.LocalPlayer,
                    rp_name = item.properties.rp_name or "",
                    pet_trick_level = item.properties.pet_trick_level,
                    pet_unique = item.unique,
                    pet_id = item.id,
                    location = {
                        full_destination_id = "housing",
                        destination_id = "housing",
                        house_owner = game.Players.LocalPlayer
                    },
                    pet_progression = {
                        friendship_level = item.properties.friendship_level,
                        age = item.properties.age,
                        percentage = 0
                    },
                    are_colors_sealed = false,
                    is_pet = true
                }
            )
            addPetState(
                {
                    char = petModel,
                    player = game.Players.LocalPlayer,
                    store_key = "pet_state_managers",
                    is_sitting = false,
                    chars_connected_to_me = {},
                    states = {}
                }
            )
        end

        local oldGet = router.get
        local function createRemoteFunctionMock(callback)
            return {
                InvokeServer = function(_, ...)
                    return callback(...)
                end
            }
        end
        local function createRemoteEventMock(callback)
            return {
                FireServer = function(_, ...)
                    return callback(...)
                end
            }
        end

        local equipRemote =
            createRemoteFunctionMock(
            function(uniqueId, metadata)
                local pet = pets[uniqueId]
                if not pet then
                    return
                end
                equip(pet.data)
                return true, {action = "equip", is_server = true}
            end
        )
        local unequipRemote =
            createRemoteFunctionMock(
            function(uniqueId)
                local pet = pets[uniqueId]
                if not pet then
                    return
                end
                unequip(pet.data)
                return true, {action = "unequip", is_server = true}
            end
        )
        local rideRemote =
            createRemoteFunctionMock(
            function(item)
                ride(item.pet_unique)
            end
        )
        local flyRemote =
            createRemoteFunctionMock(
            function(item)
                fly(item.pet_unique)
            end
        )
        local unmountRemoteFunction =
            createRemoteFunctionMock(
            function()
                unmount(mountedPet)
            end
        )
        local unmountRemoteEvent =
            createRemoteEventMock(
            function()
                unmount(mountedPet)
            end
        )

        router.get = function(name)
            if name == "ToolAPI/Equip" then
                return equipRemote
            end
            if name == "ToolAPI/Unequip" then
                return unequipRemote
            end
            if name == "AdoptAPI/RidePet" then
                return rideRemote
            end
            if name == "AdoptAPI/FlyPet" then
                return flyRemote
            end
            if name == "AdoptAPI/ExitSeatStatesYield" then
                return unmountRemoteFunction
            end
            if name == "AdoptAPI/ExitSeatStates" then
                return unmountRemoteEvent
            end
            return oldGet(name)
        end

        for _, charWrapper in pairs(clientData.get("pet_char_wrappers")) do
            oldGet("ToolAPI/Unequip"):InvokeServer(charWrapper.pet_unique)
        end

        local Loads = require(game.ReplicatedStorage.Fsys).load
        local InventoryDB = Loads("InventoryDB")

        function GetPetByName(name)
            for i, v in pairs(InventoryDB.pets) do
                if v.name:lower() == name:lower() then
                    return v.id
                end
            end
            return false
        end

        -- ────────────────────────────────────────────────────────────────
        -- Auto Load Feature + Chat Command
        -- ────────────────────────────────────────────────────────────────
        local SaveFileName = "Lynx_AutoPets.json"
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local autoLoadEnabled = false
        local savedPets = {}

        local function savePets()
            if not autoLoadEnabled then return end
            local data = HttpService:JSONEncode(savedPets)
            writefile(SaveFileName, data)
        end

        local function loadSavedPets()
            if not isfile(SaveFileName) then return end
            local data = readfile(SaveFileName)
            local decoded = HttpService:JSONDecode(data)
            if type(decoded) ~= "table" then return end

            for _, entry in ipairs(decoded) do
                local petId = entry.id
                local petType = entry.type or "FR"

                if petId then
                    local props = {
                        pet_trick_level = 0,
                        rideable = true,
                        flyable = true,
                        friendship_level = 0,
                        age = 1,
                        ailments_completed = 0,
                        rp_name = ""
                    }

                    if petType == "NFR" then
                        props.neon = true
                    elseif petType == "MFR" then
                        props.mega_neon = true
                    end

                    createPet(petId, props)
                    task.wait(0.25)
                end
            end
        end

        -- Check for auto-load on script start
        local shouldAutoLoad = false
        if isfile(SaveFileName) then
            local success, data = pcall(function()
                return HttpService:JSONDecode(readfile(SaveFileName))
            end)
            if success and type(data) == "table" and #data > 0 then
                shouldAutoLoad = true
                autoLoadEnabled = true
                task.spawn(loadSavedPets)
            end
        end

        -- Chat command: ,autoload off
        LocalPlayer.Chatted:Connect(function(msg)
            if msg:lower() == ",autoload off" then
                autoLoadEnabled = false
                if isfile(SaveFileName) then
                    delfile(SaveFileName)
                end
                savedPets = {}

                -- Show GUI immediately
                task.spawn(function()
                    local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

                    WindUI:Popup(
                        {
                            Title = "RAYZ HUB",
                            Icon = "cuboid",
                            IconThemed = true,
                            Content = "Sub to RAYZ-HUB in youtube and join our discord server",
                            Buttons = {
                                {
                                    Title = "Cancel",
                                    Callback = function() end,
                                    Variant = "Secondary"
                                },
                                {
                                    Title = "Continue",
                                    Icon = "arrow-right",
                                    Callback = function()
                                        Confirmed = true
                                    end,
                                    Variant = "Primary"
                                }
                            }
                        }
                    )

                    repeat wait() until Confirmed

                    local Window = WindUI:CreateWindow(
                        {
                            Title = "RAYZ HUB",
                            Icon = "rbxassetid://121054081718087",
                            Author = "discord.gg/rayzhub",
                            Folder = "ChunkHubmm2",
                            Size = UDim2.fromOffset(420, 350),
                            Transparent = false,
                            Theme = "Dark",
                            User = {
                                Enabled = true,
                                Callback = function() end,
                                Anonymous = false
                            },
                            SideBarWidth = 150,
                            ScrollBarEnabled = true
                        }
                    )

                    Window:EditOpenButton(
                        {
                            Title = "RAYZ HUB",
                            Icon = "rbxassetid://121054081718087",
                            CornerRadius = UDim.new(0, 16),
                            StrokeThickness = 2,
                            Color = ColorSequence.new(Color3.fromHex("5787d2"), Color3.fromHex("ffffff")),
                            OnlyMobile = false,
                            Enabled = true,
                            Draggable = true
                        }
                    )

                    Window:SetToggleKey(Enum.KeyCode.K)

                    local PetsTab = Window:Tab({ Title = "Pets", Icon = "heart", Desc = "Spawn pets" })
                    local DiscordTab = Window:Tab({ Title = "Discord", Icon = "users", Desc = "Copy our Discord Invite" })

                    DiscordTab:Paragraph({
                        Title = "Join our Discord!",
                        Desc = "Join our discord for more scripts",
                        Image = "users",
                        Color = "Blue"
                    })

                    DiscordTab:Button({
                        Title = "Copy Invite",
                        Icon = "users",
                        Callback = function()
                            task.spawn(function()
                                setclipboard("https://discord.gg/rayzhub")
                                WindUI:Notify({
                                    Title = "Discord Invite Copied!",
                                    Content = "The invite link has been copied to your clipboard.",
                                    Icon = "users",
                                    Duration = 4,
                                    Color = "Green"
                                })
                            end)
                        end
                    })

                    PetsTab:Paragraph({
                        Title = "Pet Spawner",
                        Desc = "Enter the pet name and choose pet type before spawning",
                        Image = "heart",
                        Color = "Blue"
                    })

                    PetsTab:Input({
                        Title = "Pet Name",
                        Value = "",
                        InputIcon = "search",
                        Placeholder = "Enter pet name",
                        Callback = function(input)
                            task.spawn(function()
                                petName = input
                                warn("Pet name set to:", petName)
                            end)
                        end
                    })

                    PetsTab:Dropdown({
                        Title = "Type",
                        Values = {"FR", "NFR", "MFR"},
                        Multi = false,
                        Default = "FR",
                        Callback = function(value)
                            task.spawn(function()
                                petType = value
                                warn("Pet type set to:", petType)
                            end)
                        end
                    })
                    PetsTab:Toggle({
                        Title = "Auto Load Pets on Rejoin (must put script in auto execute.)",
                        Default = false,
                        Callback = function(value)
                            autoLoadEnabled = value
                            if value then
                                savePets()
                                WindUI:Notify({
                                    Title = "Auto Load",
                                    Content = "Enabled - pets will be auto-spawned on rejoin",
                                    Duration = 3
                                })
                            else
                                if isfile(SaveFileName) then
                                    delfile(SaveFileName)
                                end
                                WindUI:Notify({
                                    Title = "Auto Load",
                                    Content = "Disabled - saved pets cleared",
                                    Duration = 3
                                })
                            end
                        end
                    })

                    PetsTab:Button({
                        Title = "Spawn Pet",
                        Icon = "sparkles",
                        Callback = function()
                            task.spawn(function()
                                if not petName or petName == "" then
                                    warn("Please enter a pet name!")
                                    return
                                end
                                local petId = GetPetByName(petName)
                                if not petId then
                                    warn("Pet not found!")
                                    WindUI:Notify({
                                        Title = "Error",
                                        Content = "Pet Not Found. Join our Discord for Help! discord.gg/SnXQCYzGjx",
                                        Icon = "shield-alert",
                                        Duration = 2
                                    })
                                    return
                                end

                                local props = {
                                    pet_trick_level = 0,
                                    rideable = true,
                                    flyable = true,
                                    friendship_level = 0,
                                    age = 1,
                                    ailments_completed = 0,
                                    rp_name = ""
                                }

                                if petType == "NFR" then
                                    props.neon = true
                                elseif petType == "MFR" then
                                    props.mega_neon = true
                                end

                                createPet(petId, props)

                                if autoLoadEnabled then
                                    table.insert(savedPets, {id = petId, type = petType})
                                    savePets()
                                end
                            end)
                            WindUI:Notify({
                                Title = "Spawning Item",
                                Content = "Spawned " .. petName .. " " .. petType,
                                Icon = "loader",
                                Duration = 2
                            })
                        end
                    })
                end)
            end
        end)

        -- Only show GUI on first run if NOT auto-loading
        if not shouldAutoLoad then
            local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

            WindUI:Popup(
                {
                    Title = "RAYZ HUB",
                    Icon = "cuboid",
                    IconThemed = true,
                    Content = "Sub to RAYZ-HUB in youtube and join our discord server",
                    Buttons = {
                        {
                            Title = "Cancel",
                            Callback = function() end,
                            Variant = "Secondary"
                        },
                        {
                            Title = "Continue",
                            Icon = "arrow-right",
                            Callback = function()
                                Confirmed = true
                            end,
                            Variant = "Primary"
                        }
                    }
                }
            )

            repeat wait() until Confirmed

            local Window = WindUI:CreateWindow(
                {
                    Title = "RAYZ HUB",
                    Icon = "rbxassetid://121054081718087",
                    Author = "discord.gg/rayzhub",
                    Folder = "ChunkHubmm2",
                    Size = UDim2.fromOffset(420, 350),
                    Transparent = false,
                    Theme = "Dark",
                    User = {
                        Enabled = true,
                        Callback = function() end,
                        Anonymous = false
                    },
                    SideBarWidth = 150,
                    ScrollBarEnabled = true
                }
            )

            Window:EditOpenButton(
                {
                    Title = "RAYZ HUB",
                    Icon = "rbxassetid://121054081718087",
                    CornerRadius = UDim.new(0, 16),
                    StrokeThickness = 2,
                    Color = ColorSequence.new(Color3.fromHex("5787d2"), Color3.fromHex("ffffff")),
                    OnlyMobile = false,
                    Enabled = true,
                    Draggable = true
                }
            )

            Window:SetToggleKey(Enum.KeyCode.K)

            local PetsTab = Window:Tab({ Title = "Pets", Icon = "heart", Desc = "Spawn pets" })
            local DiscordTab = Window:Tab({ Title = "Discord", Icon = "users", Desc = "Copy our Discord Invite" })

            DiscordTab:Paragraph({
                Title = "Join our Discord!",
                Desc = "Join our Discord to Get Best Scripts!",
                Image = "users",
                Color = "Blue"
            })

            DiscordTab:Button({
                Title = "Copy Invite",
                Icon = "users",
                Callback = function()
                    task.spawn(function()
                        setclipboard("https://discord.gg/SnXQCYzGjx")
                        WindUI:Notify({
                            Title = "Discord Invite Copied!",
                            Content = "The invite link has been copied to your clipboard.",
                            Icon = "users",
                            Duration = 4,
                            Color = "Green"
                        })
                    end)
                end
            })

            PetsTab:Paragraph({
                Title = "Pet Spawner",
                Desc = "Enter the pet name and choose pet type before spawning",
                Image = "heart",
                Color = "Blue"
            })

            PetsTab:Input({
                Title = "Pet Name",
                Value = "",
                InputIcon = "search",
                Placeholder = "Enter pet name",
                Callback = function(input)
                    task.spawn(function()
                        petName = input
                        warn("Pet name set to:", petName)
                    end)
                end
            })

            PetsTab:Dropdown({
                Title = "Type",
                Values = {"FR", "NFR", "MFR"},
                Multi = false,
                Default = "FR",
                Callback = function(value)
                    task.spawn(function()
                        petType = value
                        warn("Pet type set to:", petType)
                    end)
                end
            })

            PetsTab:Toggle({
                Title = "Auto Load Pets on Rejoin (must put script in auto execute.)",
                Default = autoLoadEnabled,
                Callback = function(value)
                    autoLoadEnabled = value
                    if value then
                        savePets()
                        WindUI:Notify({
                            Title = "Auto Load",
                            Content = "Enabled - pets will be auto-spawned on rejoin",
                            Duration = 3
                        })
                    else
                        if isfile(SaveFileName) then
                            delfile(SaveFileName)
                        end
                        WindUI:Notify({
                            Title = "Auto Load",
                            Content = "Disabled - saved pets cleared",
                            Duration = 3
                        })
                    end
                end
            })

            PetsTab:Button({
                Title = "Spawn Pet",
                Icon = "sparkles",
                Callback = function()
                    task.spawn(function()
                        if not petName or petName == "" then
                            warn("Please enter a pet name!")
                            return
                        end
                        local petId = GetPetByName(petName)
                        if not petId then
                            warn("Pet not found!")
                            WindUI:Notify({
                                Title = "Error",
                                Content = "Pet Not Found. Join our Discord for Help! discord.gg/SnXQCYzGjx",
                                Icon = "shield-alert",
                                Duration = 2
                            })
                            return
                        end

                        local props = {
                            pet_trick_level = 0,
                            rideable = true,
                            flyable = true,
                            friendship_level = 0,
                            age = 1,
                            ailments_completed = 0,
                            rp_name = ""
                        }

                        if petType == "NFR" then
                            props.neon = true
                        elseif petType == "MFR" then
                            props.mega_neon = true
                        end

                        createPet(petId, props)

                        if autoLoadEnabled then
                            table.insert(savedPets, {id = petId, type = petType})
                            savePets()
                        end
                    end)
                    WindUI:Notify({
                        Title = "Spawning Item",
                        Content = "Spawned " .. petName .. " " .. petType,
                        Icon = "loader",
                        Duration = 2
                    })
                end
            })
        end
    end
)

