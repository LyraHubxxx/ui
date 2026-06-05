--[[
    Blade Ball Standalone/Headless Script (UI Removed)
    Includes: Autoparry, Spam, AI Play, Walkable Immortal, Skin Changer, Emotes,
    Target Player, Brutal Avatar Changer, Curve Math, Rain, Plasma Trails.
    
    INSTRUCTIONS: Change values in the "Configuration" table below to toggle features.
]]

if _G.Sigma then 
    return warn('Already loaded.') 
end
_G.Sigma = true

-- ============================================================================
-- ⚙️ CONFIGURATION (EDIT THIS TO TOGGLE FEATURES)
-- ============================================================================
local Config = {
    Autoparry = {
        Enabled = true,              -- Set to true to enable Autoparry
        Method = "KeyPress (F)",     -- "KeyPress (F)" or "MouseClick"
        Triggerbot = false,          -- Auto-parry targeted balls early
        Accuracy = 1,                -- Autoparry accuracy (1 - 10)
    },
    Spam = {
        ManualSpam = false,          -- Enable manual spam logic
        ManualMethod = "KeyPress (F)",
        AutoSpam = false,            -- Enable auto spam logic
        Rate = 240                   -- Spam rate clicks/sec
    },
    Detections = {
        Infinity = true,             -- Bypass Infinity Ball
        Deathslash = true,           -- Bypass Deathslash
        Timehole = true,             -- Bypass Timehole
        SlashesOfFury = true,        -- Bypass Slashes of Fury
        Phantom = true               -- Bypass Phantom Ball
    },
    Visuals = {
        ESP = false,                 -- Player ESP
        ESPColor = Color3.fromRGB(135, 80, 255),
        TeamCheck = false,
        NightMode = false,
        DisableCamShake = false,
        Rain = false,                -- Custom Rain Visuals
        RainColor = Color3.fromRGB(100, 200, 255),
        Plasma = false,              -- Custom Plasma Trail Visuals
        PlasmaColor = Color3.fromRGB(0, 255, 255)
    },
    PlayerMods = {
        WalkSpeed = { Enabled = false, Value = 16 },
        JumpPower = { Enabled = false, Value = 50 },
        FOV = { Enabled = false, Value = 70 },
        Spinbot = { Enabled = false, Speed = 50 }
    },
    Misc = {
        AIPlay = false,              -- Auto-play AI bot
        AIJumping = true,
        AIJumpChance = 50,
        AIUpdateFrequency = 6,
        DisableEffects = false
    },
    Exclusive = {
        Immortal = false,            -- Walkable Semi-Immortal Bypass
        ImmortalRadius = 25,
        ImmortalHeight = 30,
        Emotes = false,              -- Built-in Emotes
        AutoStopEmote = true,        -- Stop emote when moving
        SelectedEmote = "None",      -- Emote Name
        
        SkinChanger = false,         -- Local Skin Changer
        SwordModelName = "",         -- Name of the sword model
        SwordAnimName = "",          -- Name of the sword animation
        SwordFXName = "",            -- Name of the sword FX
        
        TargetPlayerName = "",       -- Player Name to lock onto for targeting
        AvatarChangerName = ""       -- Player Name whose avatar you want to copy locally
    },
    Curve = {
        Mode = 1 -- 1: Camera, 2: Random, 3: Accelerated, 4: Backwards, 5: Slow, 6: High
    }
}

-- Apply global configurations expected by the system
getgenv().AutoParryMode = Config.Autoparry.Method
getgenv().ManualSpamMode = Config.Spam.ManualMethod
getgenv().AutoStopEmote = Config.Exclusive.AutoStopEmote

getgenv().skinChangerEnabled = Config.Exclusive.SkinChanger
getgenv().changeSwordModel = Config.Exclusive.SkinChanger
getgenv().swordModel = Config.Exclusive.SwordModelName
getgenv().changeSwordAnimation = Config.Exclusive.SkinChanger
getgenv().swordAnimations = Config.Exclusive.SwordAnimName
getgenv().changeSwordFX = Config.Exclusive.SkinChanger
getgenv().swordFX = Config.Exclusive.SwordFXName


-- ============================================================================
-- CORE SERVICES & VARIABLES
-- ============================================================================
local Players           = cloneref and cloneref(game:GetService('Players')) or game:GetService('Players')
local ReplicatedStorage = cloneref and cloneref(game:GetService('ReplicatedStorage')) or game:GetService('ReplicatedStorage')
local UserInputService  = cloneref and cloneref(game:GetService('UserInputService')) or game:GetService('UserInputService')
local RunService        = cloneref and cloneref(game:GetService('RunService')) or game:GetService('RunService')
local TweenService      = cloneref and cloneref(game:GetService('TweenService')) or game:GetService('TweenService')
local Stats             = cloneref and cloneref(game:GetService('Stats')) or game:GetService('Stats')
local Debris            = cloneref and cloneref(game:GetService('Debris')) or game:GetService('Debris')
local Workspace         = cloneref and cloneref(game:GetService('Workspace')) or game:GetService('Workspace')
local HttpService       = cloneref and cloneref(game:GetService('HttpService')) or game:GetService('HttpService')
local VIM               = cloneref and cloneref(game:GetService("VirtualInputManager")) or game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera or workspace:WaitForChild("Camera", 10)

if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

local Alive = workspace:FindFirstChild("Alive") or workspace:WaitForChild("Alive")
local Runtime = workspace:FindFirstChild("Runtime") or workspace:WaitForChild("Runtime")


-- ============================================================================
-- SYSTEM BASE LOGIC & PROPERTIES
-- ============================================================================
local System = {
    __properties = {
        __autoparry_enabled = Config.Autoparry.Enabled,
        __triggerbot_enabled = Config.Autoparry.Triggerbot,
        __manual_spam_enabled = Config.Spam.ManualSpam,
        __auto_spam_enabled = Config.Spam.AutoSpam,
        __play_animation = false,
        __accuracy = Config.Autoparry.Accuracy,
        __divisor_multiplier = 1.1,
        __parried = false,
        __training_parried = false,
        __spam_threshold = 1.5,
        __parries = 0,
        __grab_animation = nil,
        __tornado_time = tick(),
        __connections = {},
        __spam_accumulator = 0,
        __spam_rate = Config.Spam.Rate,
        __infinity_active = false,
        __deathslash_active = false,
        __timehole_active = false,
        __slashesoffury_active = false,
        __slashesoffury_count = 0,
    },
    
    __config = {
        __detections = {
            __infinity = Config.Detections.Infinity,
            __deathslash = Config.Detections.Deathslash,
            __timehole = Config.Detections.Timehole,
            __slashesoffury = Config.Detections.SlashesOfFury,
            __phantom = Config.Detections.Phantom
        }
    },
    
    __triggerbot = {
        __enabled = Config.Autoparry.Triggerbot,
        __is_parrying = false,
        __parries = 0,
        __max_parries = 10000,
        __parry_delay = 0.5
    }
}

local PF = nil
local SC = nil

if ReplicatedStorage:FindFirstChild("Controllers") then
    for _, child in ipairs(ReplicatedStorage.Controllers:GetChildren()) do
        if child.Name:match("^SwordsController%s*$") then
            SC = child
        end
    end
end

if LocalPlayer.PlayerGui:FindFirstChild("Hotbar") and LocalPlayer.PlayerGui.Hotbar:FindFirstChild("Block") then
    for _, v in next, getconnections(LocalPlayer.PlayerGui.Hotbar.Block.Activated) do
        if SC and getfenv(v.Function).script == SC then
            PF = v.Function
            break
        end
    end
end

local function update_divisor()
    System.__properties.__divisor_multiplier = 0.75 + (System.__properties.__accuracy - 1) * (3 / 99)
end
update_divisor()

-- ============================================================================
-- CORE SYSTEM MECHANICS (ANIMATION, BALL, PLAYER, PARRY)
-- ============================================================================
System.animation = {}

function System.animation.play_grab_parry()
    if not System.__properties.__play_animation then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass('Humanoid')
    local animator = humanoid and humanoid:FindFirstChildOfClass('Animator')
    if not humanoid or not animator then return end
    
    local sword_name
    if getgenv().skinChangerEnabled then
        sword_name = getgenv().swordAnimations
    else
        sword_name = character:GetAttribute('CurrentlyEquippedSword')
    end
    if not sword_name then return end
    
    local sword_api = ReplicatedStorage.Shared.SwordAPI.Collection
    local parry_animation = sword_api.Default:FindFirstChild('GrabParry')
    if not parry_animation then return end
    
    local sword_data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(sword_name)
    if not sword_data or not sword_data['AnimationType'] then return end
    
    for _, object in pairs(sword_api:GetChildren()) do
        if object.Name == sword_data['AnimationType'] then
            if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                local animation_type = object:FindFirstChild('GrabParry') and 'GrabParry' or 'Grab'
                parry_animation = object[animation_type]
            end
        end
    end
    
    if System.__properties.__grab_animation and System.__properties.__grab_animation.IsPlaying then
        System.__properties.__grab_animation:Stop()
    end
    
    System.__properties.__grab_animation = animator:LoadAnimation(parry_animation)
    System.__properties.__grab_animation.Priority = Enum.AnimationPriority.Action4
    System.__properties.__grab_animation:Play()
end

System.ball = {}

function System.ball.get()
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return nil end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then
            ball.CanCollide = false
            return ball
        end
    end
    return nil
end

function System.ball.get_all()
    local balls_table = {}
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return balls_table end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then
            ball.CanCollide = false
            table.insert(balls_table, ball)
        end
    end
    return balls_table
end

System.player = {}
local Closest_Entity = nil

function System.player.get_closest()
    local max_distance = math.huge
    local closest_entity = nil
    if not Alive then return nil end
    for _, entity in pairs(Alive:GetChildren()) do
        if entity ~= LocalPlayer.Character and entity.PrimaryPart then
            local distance = LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
            if distance < max_distance then
                max_distance = distance
                closest_entity = entity
            end
        end
    end
    Closest_Entity = closest_entity
    return closest_entity
end

System.parry = {}
function System.parry.execute()
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then return end
    
    local method = getgenv().AutoParryMode or "KeyPress (F)"
    
    if method == "KeyPress (F)" then
        pcall(function()
            if keypress and keyrelease then
                keypress(0x46)
                task.wait()
                keyrelease(0x46)
            else
                VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                task.wait()
                VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
            end
        end)
    elseif method == "MouseClick" then
        if mouse1click then
            pcall(mouse1click)
        else
            pcall(function()
                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait()
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
    end
    
    if System.__properties.__parries <= 10000 then
        System.__properties.__parries = System.__properties.__parries + 1
        task.delay(0.5, function()
            if System.__properties.__parries > 0 then System.__properties.__parries = System.__properties.__parries - 1 end
        end)
    end
end

function System.parry.execute_action()
    System.animation.play_grab_parry()
    System.parry.execute()
end

local function linear_predict(a, b, time_volume) return a + (b - a) * time_volume end

System.detection = {
    __ball_properties = { __aerodynamic_time = tick(), __last_warping = tick(), __lerp_radians = 0, __curving = tick() }
}

function System.detection.is_curved()
    local ball_properties = System.detection.__ball_properties
    local ball = System.ball.get()
    if not ball then return false end
    
    local zoomies = ball:FindFirstChild('zoomies')
    if not zoomies then return false end
    
    local velocity = zoomies.VectorVelocity
    local ball_direction = velocity.Unit
    local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dot = direction:Dot(ball_direction)
    
    local speed = velocity.Magnitude
    local speed_threshold = math.min(speed / 100, 40)
    
    local direction_difference = (ball_direction - velocity).Unit
    local direction_similarity = direction:Dot(direction_difference)
    local dot_difference = dot - direction_similarity
    local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    
    local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()
    local dot_threshold = 0.5 - (ping / 1000)
    local reach_time = distance / speed - (ping / 1000)
    local ball_distance_threshold = 15 - math.min(distance / 1000, 15) + speed_threshold
    
    local clamped_dot = math.clamp(dot, -1, 1)
    local radians = math.rad(math.asin(clamped_dot))
    
    ball_properties.__lerp_radians = linear_predict(ball_properties.__lerp_radians, radians, 0.8)
    
    if speed > 0 and reach_time > ping / 10 then ball_distance_threshold = math.max(ball_distance_threshold - 15, 15) end
    if distance < ball_distance_threshold then return false end
    if dot_difference < dot_threshold then return true end
    
    if ball_properties.__lerp_radians < 0.018 then ball_properties.__last_warping = tick() end
    if (tick() - ball_properties.__last_warping) < (reach_time / 1.5) then return true end
    if (tick() - ball_properties.__curving) < (reach_time / 1.5) then return true end
    
    return dot < dot_threshold
end

-- ============================================================================
-- REMOTES FOR ABILITIES DETECTIONS
-- ============================================================================
ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(_, d) System.__properties.__deathslash_active = d or false end)
ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(_, b) System.__properties.__infinity_active = b or false end)

pcall(function()
    local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
    net["RE/TimeHoleActivate"].OnClientEvent:Connect(function(player)
        if player == LocalPlayer or player == LocalPlayer.Name or (player and player.Name == LocalPlayer.Name) then
            System.__properties.__timehole_active = true
        end
    end)
    net["RE/TimeHoleDeactivate"].OnClientEvent:Connect(function() System.__properties.__timehole_active = false end)
    
    net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(player)
        if player == LocalPlayer or player == LocalPlayer.Name or (player and player.Name == LocalPlayer.Name) then
            System.__properties.__slashesoffury_active = true
            System.__properties.__slashesoffury_count = 0
        end
    end)
    net["RE/SlashesOfFuryEnd"].OnClientEvent:Connect(function()
        System.__properties.__slashesoffury_active = false
        System.__properties.__slashesoffury_count = 0
    end)
    net["RE/SlashesOfFuryParry"].OnClientEvent:Connect(function() System.__properties.__slashesoffury_count = System.__properties.__slashesoffury_count + 1 end)
    net["RE/SlashesOfFuryCatch"].OnClientEvent:Connect(function()
        task.spawn(function()
            while System.__properties.__slashesoffury_active and System.__properties.__slashesoffury_count < 36 do
                if System.__config.__detections.__slashesoffury then
                    System.parry.execute()
                    task.wait(0.05)
                else break end
            end
        end)
    end)
end)

Runtime.ChildAdded:Connect(function(Object)
    if System.__config.__detections.__phantom and (Object.Name == "maxTransmission" or Object.Name == "transmissionpart") then
        local Weld = Object:FindFirstChildWhichIsA("WeldConstraint")
        local Character = LocalPlayer.Character
        if Weld and Character and Weld.Part1 == Character:FindFirstChild("HumanoidRootPart") then
            local CurrentBall = System.ball.get()
            Weld:Destroy()
            if CurrentBall then
                local FocusConnection
                FocusConnection = RunService.RenderStepped:Connect(function()
                    local Highlighted = CurrentBall:GetAttribute("highlighted")
                    if Highlighted == true then
                        ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                        System.__properties.__parried = true
                        task.delay(1, function() System.__properties.__parried = false end)
                    elseif Highlighted == false then
                        FocusConnection:Disconnect()
                    end
                end)
                task.delay(3, function() if FocusConnection and FocusConnection.Connected then FocusConnection:Disconnect() end end)
            end
        end
    end
end)

-- ============================================================================
-- AUTOPARRY & SPAM LOGIC
-- ============================================================================
System.triggerbot = {}
function System.triggerbot.trigger(ball)
    if System.__triggerbot.__is_parrying or System.__triggerbot.__parries > System.__triggerbot.__max_parries then return end
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then return end
    
    System.__triggerbot.__is_parrying = true
    System.__triggerbot.__parries = System.__triggerbot.__parries + 1
    
    System.animation.play_grab_parry()
    System.parry.execute()
    
    task.delay(System.__triggerbot.__parry_delay, function()
        if System.__triggerbot.__parries > 0 then System.__triggerbot.__parries = System.__triggerbot.__parries - 1 end
    end)
    
    local connection
    connection = ball:GetAttributeChangedSignal('target'):Once(function()
        System.__triggerbot.__is_parrying = false
        if connection then connection:Disconnect() end
    end)
    
    task.spawn(function()
        local start_time = tick()
        repeat RunService.Heartbeat:Wait() until (tick() - start_time >= 1 or not System.__triggerbot.__is_parrying)
        System.__triggerbot.__is_parrying = false
    end)
end

function System.triggerbot.loop()
    if not System.__triggerbot.__enabled then return end
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then return end
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:IsA('BasePart') and ball:GetAttribute('target') == LocalPlayer.Name then
            System.triggerbot.trigger(ball)
            break
        end
    end
end

function System.triggerbot.enable(enabled)
    System.__triggerbot.__enabled = enabled
    if enabled then
        if not System.__properties.__connections.__triggerbot then System.__properties.__connections.__triggerbot = RunService.Heartbeat:Connect(System.triggerbot.loop) end
    else
        if System.__properties.__connections.__triggerbot then
            System.__properties.__connections.__triggerbot:Disconnect()
            System.__properties.__connections.__triggerbot = nil
        end
        System.__triggerbot.__is_parrying = false
        System.__triggerbot.__parries = 0
    end
end

System.manual_spam = {}
function System.manual_spam.loop(delta)
    if not System.__properties.__manual_spam_enabled or not LocalPlayer.Character or LocalPlayer.Character.Parent ~= Alive then return end
    System.__properties.__spam_accumulator = System.__properties.__spam_accumulator + delta
    local interval = 1 / System.__properties.__spam_rate
    if System.__properties.__spam_accumulator >= interval then
        System.__properties.__spam_accumulator = 0
        System.parry.execute()
        if getgenv().ManualSpamAnimationFix and PF then pcall(PF) end
    end
end

function System.manual_spam.start()
    if System.__properties.__connections.__manual_spam then System.__properties.__connections.__manual_spam:Disconnect() end
    System.__properties.__manual_spam_enabled = true
    System.__properties.__connections.__manual_spam = RunService.Heartbeat:Connect(System.manual_spam.loop)
end

function System.manual_spam.stop()
    System.__properties.__manual_spam_enabled = false
    if System.__properties.__connections.__manual_spam then
        System.__properties.__connections.__manual_spam:Disconnect()
        System.__properties.__connections.__manual_spam = nil
    end
end

System.auto_spam = {}
function System.auto_spam:get_entity_properties()
    System.player.get_closest()
    if not Closest_Entity then return false end
    return { Velocity = Closest_Entity.PrimaryPart.Velocity, Direction = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit, Distance = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude }
end

function System.auto_spam:get_ball_properties()
    local ball = System.ball.get()
    if not ball then return false end
    local ball_velocity = Vector3.zero
    local ball_direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    return { Velocity = ball_velocity, Direction = ball_direction, Distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude, Dot = ball_direction:Dot(ball_velocity.Unit) }
end

function System.auto_spam.spam_service(self)
    local ball = System.ball.get()
    local entity = System.player.get_closest()
    if not ball or not entity or not entity.PrimaryPart then return 0 end
    
    local speed = ball.AssemblyLinearVelocity.Magnitude
    local dot = ((LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit):Dot(ball.AssemblyLinearVelocity.Unit)
    local target_distance = LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
    local maximum_spam_distance = self.Ping + math.min(speed / 6, 255)
    
    if self.Entity_Properties.Distance > maximum_spam_distance or self.Ball_Properties.Distance > maximum_spam_distance or target_distance > maximum_spam_distance then return 0 end
    local maximum_dot = math.clamp(dot, -1, 0) * (5 - math.min(speed / 5, 5))
    return maximum_spam_distance - maximum_dot
end

function System.auto_spam.start()
    if System.__properties.__connections.__auto_spam then System.__properties.__connections.__auto_spam:Disconnect() end
    System.__properties.__auto_spam_enabled = true
    System.__properties.__connections.__auto_spam = RunService.PreSimulation:Connect(function()
        local ball = System.ball.get()
        if not ball or System.__properties.__slashesoffury_active then return end
        local zoomies = ball:FindFirstChild('zoomies')
        if not zoomies then return end
        
        System.player.get_closest()
        local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()
        local ping_threshold = math.clamp(ping / 10, 1, 16)
        local ball_target = ball:GetAttribute('target')
        local ball_props = System.auto_spam:get_ball_properties()
        local entity_props = System.auto_spam:get_entity_properties()
        
        if not ball_props or not entity_props or not ball_target then return end
        local spam_accuracy = System.auto_spam.spam_service({Ball_Properties = ball_props, Entity_Properties = entity_props, Ping = ping_threshold})
        local target_distance = LocalPlayer:DistanceFromCharacter(Closest_Entity.PrimaryPart.Position)
        local distance = LocalPlayer:DistanceFromCharacter(ball.Position)
        
        if target_distance > spam_accuracy or distance > spam_accuracy then return end
        if LocalPlayer.Character:GetAttribute('Pulsed') then return end
        if ball_target == LocalPlayer.Name and target_distance > 30 and distance > 30 then return end
        
        if distance <= spam_accuracy and System.__properties.__parries > System.__properties.__spam_threshold then
            System.parry.execute()
            if getgenv().AutoSpamAnimationFix and PF then pcall(PF) end
        end
    end)
end

function System.auto_spam.stop()
    System.__properties.__auto_spam_enabled = false
    if System.__properties.__connections.__auto_spam then System.__properties.__connections.__auto_spam:Disconnect(); System.__properties.__connections.__auto_spam = nil end
end

System.autoparry = {}
function System.autoparry.start()
    if System.__properties.__connections.__autoparry then System.__properties.__connections.__autoparry:Disconnect() end
    System.__properties.__connections.__autoparry = RunService.PreSimulation:Connect(function()
        if not System.__properties.__autoparry_enabled or not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
        
        local balls = System.ball.get_all()
        local one_ball = System.ball.get()
        local training_ball = workspace:FindFirstChild("TrainingBalls") and workspace.TrainingBalls:FindFirstChildWhichIsA("BasePart")
        
        for _, ball in pairs(balls) do
            if System.__triggerbot.__enabled or getgenv().BallVelocityAbove800 or not ball then continue end
            local zoomies = ball:FindFirstChild('zoomies')
            if not zoomies then continue end
            
            ball:GetAttributeChangedSignal('target'):Once(function() System.__properties.__parried = false end)
            if System.__properties.__parried then continue end
            
            local ball_target = ball:GetAttribute('target')
            local velocity = zoomies.VectorVelocity
            local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
            local ping_threshold = math.clamp(Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 100, 5, 17)
            local speed = velocity.Magnitude
            
            local speed_divisor = (2.4 + math.min(math.max(speed - 9.5, 0), 650) * 0.002) * System.__properties.__divisor_multiplier
            local parry_accuracy = ping_threshold + math.max(speed / speed_divisor, 9.5)
            local curved = System.detection.is_curved()
            
            if ball:FindFirstChild('AeroDynamicSlashVFX') then ball.AeroDynamicSlashVFX:Destroy(); System.__properties.__tornado_time = tick() end
            if Runtime:FindFirstChild('Tornado') and (tick() - System.__properties.__tornado_time) < (Runtime.Tornado:GetAttribute('TornadoTime') or 1) + 0.314159 then continue end
            if one_ball and one_ball:GetAttribute('target') == LocalPlayer.Name and curved then continue end
            if ball:FindFirstChild('ComboCounter') or LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then continue end
            
            if (System.__config.__detections.__infinity and System.__properties.__infinity_active) or (System.__config.__detections.__deathslash and System.__properties.__deathslash_active) or (System.__config.__detections.__timehole and System.__properties.__timehole_active) or (System.__config.__detections.__slashesoffury and System.__properties.__slashesoffury_active) then continue end
            
            if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                if getgenv().CooldownProtection and LocalPlayer.PlayerGui.Hotbar.Block.UIGradient.Offset.Y < 0.4 then ReplicatedStorage.Remotes.AbilityButtonPress:Fire(); continue end
                
                if getgenv().AutoAbility and LocalPlayer.PlayerGui.Hotbar.Ability.UIGradient.Offset.Y == 0.5 then
                    local abs = LocalPlayer.Character:FindFirstChild("Abilities")
                    if abs then
                        for _, ab in pairs({"Raging Deflection", "Rapture", "Calming Deflection", "Aerodynamic Slash", "Fracture", "Death Slash"}) do
                            if abs:FindFirstChild(ab) and abs[ab].Enabled then
                                System.__properties.__parried = true
                                ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                                task.wait(2.432)
                                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
                                break
                            end
                        end
                        if System.__properties.__parried then continue end
                    end
                end
                
                System.parry.execute_action()
                System.__properties.__parried = true
            end
            
            local last_parrys = tick()
            repeat RunService.Stepped:Wait() until (tick() - last_parrys) >= 1 or not System.__properties.__parried
            System.__properties.__parried = false
        end

        if training_ball and training_ball:GetAttribute("realBall") then
            local zoomies = training_ball:FindFirstChild('zoomies')
            if zoomies then
                training_ball:GetAttributeChangedSignal('target'):Once(function() System.__properties.__training_parried = false end)
                if not System.__properties.__training_parried then
                    local speed = zoomies.VectorVelocity.Magnitude
                    local distance = LocalPlayer:DistanceFromCharacter(training_ball.Position)
                    local ping_threshold = math.clamp(Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 100, 5, 17)
                    local speed_divisor = (2.4 + math.min(math.max(speed - 9.5, 0), 650) * 0.002) * System.__properties.__divisor_multiplier
                    
                    if training_ball:GetAttribute('target') == LocalPlayer.Name and distance <= (ping_threshold + math.max(speed / speed_divisor, 9.5)) then
                        System.parry.execute_action()
                        System.__properties.__training_parried = true
                        local last_parrys = tick()
                        repeat RunService.Stepped:Wait() until (tick() - last_parrys) >= 1 or not System.__properties.__training_parried
                        System.__properties.__training_parried = false
                    end
                end
            end
        end
    end)
end

function System.autoparry.stop()
    if System.__properties.__connections.__autoparry then System.__properties.__connections.__autoparry:Disconnect(); System.__properties.__connections.__autoparry = nil end
end


-- ============================================================================
-- SYSTEM: EMOTES (ANIMATION SYSTEM)
-- ============================================================================
local animation_system = {
    storage = {},
    current = nil,
    track = nil
}

function animation_system.load_animations()
    pcall(function()
        local emotes_folder = game:GetService("ReplicatedStorage").Misc.Emotes
        for _, animation in pairs(emotes_folder:GetChildren()) do
            if animation:IsA("Animation") and animation:GetAttribute("EmoteName") then
                local emote_name = animation:GetAttribute("EmoteName")
                animation_system.storage[emote_name] = animation
            end
        end
    end)
end

function animation_system.play(emote_name)
    local animation_data = animation_system.storage[emote_name]
    if not animation_data or not LocalPlayer.Character then return false end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end
    
    if animation_system.track then
        animation_system.track:Stop()
        animation_system.track:Destroy()
    end
    
    animation_system.track = animator:LoadAnimation(animation_data)
    animation_system.track:Play()
    animation_system.current = emote_name
    return true
end

function animation_system.stop()
    if animation_system.track then
        animation_system.track:Stop()
        animation_system.track:Destroy()
        animation_system.track = nil
    end
    animation_system.current = nil
end

function animation_system.start()
    if not System.__properties.__connections.animations then
        System.__properties.__connections.animations = RunService.Heartbeat:Connect(function()
            if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
            
            local speed = LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity.Magnitude
            if speed > 30 and getgenv().AutoStopEmote then
                if animation_system.track and animation_system.track.IsPlaying then
                    animation_system.track:Stop()
                end
            else
                if animation_system.current and (not animation_system.track or not animation_system.track.IsPlaying) then
                    animation_system.play(animation_system.current)
                end
            end
        end)
    end
end

function animation_system.cleanup()
    animation_system.stop()
    if System.__properties.__connections.animations then
        System.__properties.__connections.animations:Disconnect()
        System.__properties.__connections.animations = nil
    end
end


-- ============================================================================
-- SYSTEM: WALKABLE SEMI-IMMORTAL (DESYNC)
-- ============================================================================
local WalkableSemiImmortal = {}
local immortalState = { enabled = false, notify = false, heartbeatConnection = nil }
local immortalDesyncData = { originalCFrame = nil, originalVelocity = nil }
local immortalCache = { character = nil, hrp = nil, head = nil, headOffset = Vector3.new(0, 0, 0), aliveFolder = nil }
local immortalHooks = { oldIndex = nil }
local immortalConstants = { emptyCFrame = CFrame.new(), radius = Config.Exclusive.ImmortalRadius, baseHeight = 5, riseHeight = Config.Exclusive.ImmortalHeight, cycleSpeed = 11.9, velocity = Vector3.new(1, 1, 1) }

local function immortalUpdateCache()
    local character = LocalPlayer.Character
    if not character then
        immortalCache.character = nil
        immortalCache.hrp = nil
        immortalCache.head = nil
        return
    end
    
    if character ~= immortalCache.character or not immortalCache.hrp or not immortalCache.head then
        immortalCache.character = character
        immortalCache.hrp = character:FindFirstChild("HumanoidRootPart")
        immortalCache.head = character:FindFirstChild("Head")
        
        if immortalCache.hrp then
            immortalCache.headOffset = Vector3.new(0, immortalCache.hrp.Size.Y * 0.5 + 0.5, 0)
        end
    end
end

local function immortalIsInAliveFolder()
    local aliveFolder = workspace:FindFirstChild("Alive")
    return aliveFolder and immortalCache.character and immortalCache.character.Parent == aliveFolder
end

local function immortalCalculateOrbitPosition(hrp)
    local angle = math.random(-2147483647, 2147483647) * 1000
    local cycle = math.floor(tick() * immortalConstants.cycleSpeed) % 2
    local yOffset = cycle == 0 and 0 or immortalConstants.riseHeight
    
    local pos = hrp.Position
    local yBase = pos.Y - hrp.Size.Y * 0.5 + immortalConstants.baseHeight + yOffset
    
    return CFrame.new(pos.X + math.cos(angle) * immortalConstants.radius, yBase, pos.Z + math.sin(angle) * immortalConstants.radius)
end

local function performImmortalDesync()
    immortalUpdateCache()
    if not immortalState.enabled or not immortalCache.hrp or not immortalIsInAliveFolder() then return end
    
    local hrp = immortalCache.hrp
    immortalDesyncData.originalCFrame = hrp.CFrame
    immortalDesyncData.originalVelocity = hrp.AssemblyLinearVelocity
    
    hrp.CFrame = immortalCalculateOrbitPosition(hrp)
    hrp.AssemblyLinearVelocity = immortalConstants.velocity
    
    RunService.RenderStepped:Wait()
    
    hrp.CFrame = immortalDesyncData.originalCFrame
    hrp.AssemblyLinearVelocity = immortalDesyncData.originalVelocity
end

function WalkableSemiImmortal.toggle(enabled)
    if immortalState.enabled == enabled then return end
    immortalState.enabled = enabled
    getgenv().Walkablesemiimortal = enabled
    
    if enabled then
        if not immortalState.heartbeatConnection then
            immortalState.heartbeatConnection = RunService.Heartbeat:Connect(performImmortalDesync)
        end
    else
        if immortalState.heartbeatConnection then
            immortalState.heartbeatConnection:Disconnect()
            immortalState.heartbeatConnection = nil
        end
        immortalDesyncData.originalCFrame = nil
        immortalDesyncData.originalVelocity = nil
    end
end

LocalPlayer.CharacterRemoving:Connect(function()
    immortalCache.character = nil
    immortalCache.hrp = nil
    immortalCache.head = nil
    immortalCache.aliveFolder = nil
    immortalDesyncData.originalCFrame = nil
    immortalDesyncData.originalVelocity = nil
end)

immortalHooks.oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not immortalState.enabled or checkcaller() or key ~= "CFrame" or not immortalCache.hrp or not immortalIsInAliveFolder() then
        return immortalHooks.oldIndex(self, key)
    end
    
    if self == immortalCache.hrp then
        return immortalDesyncData.originalCFrame or immortalConstants.emptyCFrame
    elseif self == immortalCache.head and immortalDesyncData.originalCFrame then
        return immortalDesyncData.originalCFrame + immortalCache.headOffset
    end
    
    return immortalHooks.oldIndex(self, key)
end))


-- ============================================================================
-- SYSTEM: SKIN CHANGER 
-- ============================================================================
task.spawn(function()
    local swordInstancesInstance = ReplicatedStorage:WaitForChild("Shared",9e9):WaitForChild("ReplicatedInstances",9e9):WaitForChild("Swords",9e9)
    local swordInstances = require(swordInstancesInstance)

    local swordsController

    while task.wait() and (not swordsController) do
        for i,v in getconnections(ReplicatedStorage.Remotes.FireSwordInfo.OnClientEvent) do
            if v.Function and islclosure(v.Function) then
                local upvalues = getupvalues(v.Function)
                if #upvalues == 1 and type(upvalues[1]) == "table" then
                    swordsController = upvalues[1]
                    break
                end
            end
        end
    end

    function getSlashName(swordName)
        local slashName = swordInstances:GetSword(swordName)
        return (slashName and slashName.SlashName) or "SlashEffect"
    end

    function setSword()
        if not getgenv().skinChangerEnabled then return end
        
        setupvalue(rawget(swordInstances,"EquipSwordTo"),3,false)
        
        if getgenv().changeSwordModel then
            swordInstances:EquipSwordTo(LocalPlayer.Character, getgenv().swordModel)
        end
        
        if getgenv().changeSwordAnimation then
            swordsController:SetSword(getgenv().swordAnimations)
        end
    end

    local playParryFunc
    local parrySuccessAllConnection

    while task.wait() and not parrySuccessAllConnection do
        for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent) do
            if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
                parrySuccessAllConnection = v
                playParryFunc = v.Function
                v:Disable()
            end
        end
    end

    local parrySuccessClientConnection
    while task.wait() and not parrySuccessClientConnection do
        for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessClient.Event) do
            if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
                parrySuccessClientConnection = v
                v:Disable()
            end
        end
    end

    getgenv().slashName = getSlashName(getgenv().swordFX)

    local lastOtherParryTimestamp = 0
    ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
        setthreadidentity(2)
        local args = {...}
        if tostring(args[4]) ~= LocalPlayer.Name then
            lastOtherParryTimestamp = tick()
        elseif getgenv().skinChangerEnabled and getgenv().changeSwordFX then
            args[1] = getgenv().slashName
            args[3] = getgenv().swordFX
        end
        return playParryFunc(unpack(args))
    end)

    getgenv().updateSword = function()
        if getgenv().changeSwordFX then
            getgenv().slashName = getSlashName(getgenv().swordFX)
        end
        setSword()
    end

    task.spawn(function()
        while task.wait(1) do
            if getgenv().skinChangerEnabled and getgenv().changeSwordModel then
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then
                    setSword()
                end
                if char and (not char:FindFirstChild(getgenv().swordModel)) then
                    setSword()
                end
                for _,v in (char and char:GetChildren()) or {} do
                    if v:IsA("Model") and v.Name ~= getgenv().swordModel then
                        v:Destroy()
                    end
                    task.wait()
                end
            end
        end
    end)
end)

-- ============================================================================
-- SYSTEM: AI AUTO-PLAY 
-- ============================================================================
local AutoPlayModule = {}
AutoPlayModule.CONFIG = { 
    DEFAULT_DISTANCE = 30, MULTIPLIER_THRESHOLD = 70, TRAVERSING = 25, DIRECTION = 1, 
    JUMP_PERCENTAGE = Config.Misc.AIJumpChance, DOUBLE_JUMP_PERCENTAGE = Config.Misc.AIJumpChance, 
    JUMPING_ENABLED = Config.Misc.AIJumping, MOVEMENT_DURATION = 0.8, OFFSET_FACTOR = 0.7, 
    GENERATION_THRESHOLD = 0.25, PLAYER_DISTANCE_ENABLED = false, MINIMUM_PLAYER_DISTANCE = 15, 
    UPDATE_FREQUENCY = Config.Misc.AIUpdateFrequency, POSITION_UPDATE_RATE = 0.1, 
    BALL_CHECK_RATE = 0.2, PLAYER_CHECK_RATE = 0.5 
}
AutoPlayModule.ball = nil
AutoPlayModule.lobbyChoice = nil
AutoPlayModule.animationCache = nil
AutoPlayModule.doubleJumped = false
AutoPlayModule.ELAPSED = 0
AutoPlayModule.CONTROL_POINT = nil
AutoPlayModule.LAST_GENERATION = 0
AutoPlayModule.signals = {}
AutoPlayModule.Closest_Entity = nil
AutoPlayModule.frameThrottle = 0

local aiTimeCache = { lastPositionUpdate = 0, lastBallCheck = 0, lastPlayerCheck = 0, lastFloorCheck = 0 }
local aiResultCache = { floor = nil, lastBallDirection = nil, lastPlayerPosition = nil, lastRandomPosition = nil, ballSpeed = 0 }

local serviceCache = {}
local function getService(name)
    if not serviceCache[name] then serviceCache[name] = cloneref and cloneref(game:GetService(name)) or game:GetService(name) end
    return serviceCache[name]
end
AutoPlayModule.customService = setmetatable({}, { __index = function(self, name) return getService(name) end })

AutoPlayModule.playerHelper = {
    isAlive = function(player)
        if not player or not player:IsA("Player") then return false end
        local character = player.Character
        if not character then return false end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        return rootPart and humanoid and humanoid.Health > 0
    end,
    inLobby = function(character) return character and character.Parent == AutoPlayModule.customService.Workspace.Dead end,
    onGround = function(character) return character and character.Humanoid.FloorMaterial ~= Enum.Material.Air end
}

AutoPlayModule.playerProximity = {
    findClosestPlayer = function()
        local currentTime = tick()
        if currentTime - aiTimeCache.lastPlayerCheck < AutoPlayModule.CONFIG.PLAYER_CHECK_RATE then return AutoPlayModule.Closest_Entity end
        aiTimeCache.lastPlayerCheck = currentTime
        local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
        if not AutoPlayModule.playerHelper.isAlive(localPlayer) then
            AutoPlayModule.Closest_Entity = nil
            return nil
        end
        local maxDistance = math.huge
        local foundEntity = nil
        local localPosition = localPlayer.Character.HumanoidRootPart.Position
        local aliveFolder = AutoPlayModule.customService.Workspace:FindFirstChild("Alive")
        local searchFolders = aliveFolder and {aliveFolder} or {}
        if not aliveFolder then
            for _, player in pairs(AutoPlayModule.customService.Players:GetPlayers()) do
                if player ~= localPlayer and player.Character then table.insert(searchFolders, player.Character.Parent) end
            end
        end
        for _, folder in pairs(searchFolders) do
            if folder then
                for _, entity in pairs(folder:GetChildren()) do
                    if entity ~= localPlayer.Character then
                        local primaryPart = entity:FindFirstChild("HumanoidRootPart")
                        if primaryPart then
                            local distance = (localPosition - primaryPart.Position).Magnitude
                            if distance < maxDistance then
                                maxDistance = distance
                                foundEntity = entity
                            end
                        end
                    end
                end
            end
        end
        AutoPlayModule.Closest_Entity = foundEntity
        return foundEntity
    end,
    getEntityProperties = function()
        local closestPlayer = AutoPlayModule.playerProximity.findClosestPlayer()
        local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
        if not closestPlayer or not localPlayer.Character or not localPlayer.Character.HumanoidRootPart then return false end
        local primaryPart = closestPlayer:FindFirstChild("HumanoidRootPart")
        if not primaryPart then return false end
        local localPosition = localPlayer.Character.HumanoidRootPart.Position
        local entityPosition = primaryPart.Position
        local entityDirection = (localPosition - entityPosition).Unit
        local entityDistance = (localPosition - entityPosition).Magnitude
        return { Velocity = primaryPart.Velocity, Direction = entityDirection, Distance = entityDistance, Position = entityPosition }
    end,
    isPlayerTooClose = function()
        if not AutoPlayModule.CONFIG.PLAYER_DISTANCE_ENABLED then return false end
        local entityProps = AutoPlayModule.playerProximity.getEntityProperties()
        return entityProps and entityProps.Distance < AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE
    end,
    getAvoidancePosition = function()
        local entityProps = AutoPlayModule.playerProximity.getEntityProperties()
        local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
        if not entityProps or not localPlayer.Character or not localPlayer.Character.HumanoidRootPart then return nil end
        local playerPosition = localPlayer.Character.HumanoidRootPart.Position
        local avoidanceDirection = entityProps.Direction * AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE * 1.5
        local avoidancePosition = playerPosition + avoidanceDirection
        local floor = AutoPlayModule.map.getFloor()
        if floor then avoidancePosition = Vector3.new(avoidancePosition.X, floor.Position.Y + 5, avoidancePosition.Z) end
        return avoidancePosition
    end
}

function AutoPlayModule.isLimited()
    local passedTime = tick() - AutoPlayModule.LAST_GENERATION
    return passedTime < AutoPlayModule.CONFIG.GENERATION_THRESHOLD
end

function AutoPlayModule.percentageCheck(limit)
    if AutoPlayModule.isLimited() then return false end
    local percentage = math.random(1, 100)
    AutoPlayModule.LAST_GENERATION = tick()
    return limit >= percentage
end

AutoPlayModule.ballUtils = {
    getBall = function()
        local currentTime = tick()
        if currentTime - aiTimeCache.lastBallCheck < AutoPlayModule.CONFIG.BALL_CHECK_RATE then return end
        aiTimeCache.lastBallCheck = currentTime
        local ballsFolder = AutoPlayModule.customService.Workspace:FindFirstChild("Balls")
        if not ballsFolder then AutoPlayModule.ball = nil; return end
        for _, object in pairs(ballsFolder:GetChildren()) do
            if object:GetAttribute("realBall") then
                AutoPlayModule.ball = object
                return
            end
        end
        AutoPlayModule.ball = nil
    end,
    getDirection = function()
        if not AutoPlayModule.ball then return aiResultCache.lastBallDirection end
        local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
        if not localPlayer.Character or not localPlayer.Character.HumanoidRootPart then return aiResultCache.lastBallDirection end
        local direction = (localPlayer.Character.HumanoidRootPart.Position - AutoPlayModule.ball.Position).Unit
        aiResultCache.lastBallDirection = direction
        return direction
    end,
    getVelocity = function()
        if not AutoPlayModule.ball then return end
        local zoomies = AutoPlayModule.ball:FindFirstChild("zoomies")
        return zoomies and zoomies.VectorVelocity
    end,
    getSpeed = function()
        if not AutoPlayModule.ball then return aiResultCache.ballSpeed end
        local velocity = AutoPlayModule.ballUtils.getVelocity()
        if velocity then aiResultCache.ballSpeed = velocity.Magnitude end
        return aiResultCache.ballSpeed
    end,
    isExisting = function() return AutoPlayModule.ball ~= nil end
}

AutoPlayModule.lerp = function(start, finish, alpha) return start + (finish - start) * alpha end
AutoPlayModule.quadratic = function(start, middle, finish, alpha)
    local firstLerp = AutoPlayModule.lerp(start, middle, alpha)
    local secondLerp = AutoPlayModule.lerp(middle, finish, alpha)
    return AutoPlayModule.lerp(firstLerp, secondLerp, alpha)
end

AutoPlayModule.getCandidates = function(middle, theta, offsetLength)
    local halfPi = math.pi * 0.5
    local cosTheta = math.cos(theta)
    local sinTheta = math.sin(theta)
    local firstCandidate = middle + Vector3.new(cosTheta * math.cos(halfPi) - sinTheta * math.sin(halfPi), 0, sinTheta * math.cos(halfPi) + cosTheta * math.sin(halfPi)) * offsetLength
    local secondCandidate = middle + Vector3.new(cosTheta * math.cos(-halfPi) - sinTheta * math.sin(-halfPi), 0, sinTheta * math.cos(-halfPi) + cosTheta * math.sin(-halfPi)) * offsetLength
    return firstCandidate, secondCandidate
end

AutoPlayModule.getControlPoint = function(start, finish)
    local middle = (start + finish) * 0.5
    local difference = start - finish
    if difference.Magnitude < 5 then return finish end
    local theta = math.atan2(difference.Z, difference.X)
    local offsetLength = difference.Magnitude * AutoPlayModule.CONFIG.OFFSET_FACTOR
    local firstCandidate, secondCandidate = AutoPlayModule.getCandidates(middle, theta, offsetLength)
    local dotValue = start - middle
    return (firstCandidate - middle):Dot(dotValue) < 0 and firstCandidate or secondCandidate
end

AutoPlayModule.getCurve = function(start, finish, delta)
    AutoPlayModule.ELAPSED = AutoPlayModule.ELAPSED + delta
    local timeElapsed = math.clamp(AutoPlayModule.ELAPSED / AutoPlayModule.CONFIG.MOVEMENT_DURATION, 0, 1)
    if timeElapsed >= 1 then
        local distance = (start - finish).Magnitude
        if distance >= 10 then AutoPlayModule.ELAPSED = 0 end
        AutoPlayModule.CONTROL_POINT = nil
        return finish
    end
    if not AutoPlayModule.CONTROL_POINT then AutoPlayModule.CONTROL_POINT = AutoPlayModule.getControlPoint(start, finish) end
    return AutoPlayModule.quadratic(start, AutoPlayModule.CONTROL_POINT, finish, timeElapsed)
end

AutoPlayModule.map = {
    getFloor = function()
        local currentTime = tick()
        if aiResultCache.floor and currentTime - aiTimeCache.lastFloorCheck < 5 then return aiResultCache.floor end
        aiTimeCache.lastFloorCheck = currentTime
        local floor = AutoPlayModule.customService.Workspace:FindFirstChild("FLOOR")
        if floor then
            aiResultCache.floor = floor
            return floor
        end
        local workspace = AutoPlayModule.customService.Workspace
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                local size = part.Size
                if size.X > 50 and size.Z > 50 and part.Position.Y < 5 then
                    aiResultCache.floor = part
                    return part
                end
            end
        end
        return aiResultCache.floor
    end
}

AutoPlayModule.getRandomPosition = function()
    local currentTime = tick()
    if currentTime - aiTimeCache.lastPositionUpdate < AutoPlayModule.CONFIG.POSITION_UPDATE_RATE then return aiResultCache.lastRandomPosition end
    aiTimeCache.lastPositionUpdate = currentTime
    local floor = AutoPlayModule.map.getFloor()
    if not floor or not AutoPlayModule.ballUtils.isExisting() then return aiResultCache.lastRandomPosition end
    if AutoPlayModule.playerProximity.isPlayerTooClose() then
        local avoidancePosition = AutoPlayModule.playerProximity.getAvoidancePosition()
        if avoidancePosition then
            aiResultCache.lastRandomPosition = avoidancePosition
            return avoidancePosition
        end
    end
    local ballDirection = AutoPlayModule.ballUtils.getDirection()
    if not ballDirection then return aiResultCache.lastRandomPosition end
    ballDirection = ballDirection * AutoPlayModule.CONFIG.DIRECTION
    local ballSpeed = AutoPlayModule.ballUtils.getSpeed()
    local speedThreshold = math.min(ballSpeed * 0.1, AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD)
    local speedMultiplier = AutoPlayModule.CONFIG.DEFAULT_DISTANCE + speedThreshold
    local negativeDirection = ballDirection * speedMultiplier
    local currentTimeScaled = currentTime * 0.83333
    local sine = math.sin(currentTimeScaled) * AutoPlayModule.CONFIG.TRAVERSING
    local cosine = math.cos(currentTimeScaled) * AutoPlayModule.CONFIG.TRAVERSING
    local traversing = Vector3.new(sine, 0, cosine)
    local finalPosition = floor.Position + negativeDirection + traversing
    if AutoPlayModule.CONFIG.PLAYER_DISTANCE_ENABLED then
        local entityProps = AutoPlayModule.playerProximity.getEntityProperties()
        if entityProps and entityProps.Distance < AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE * 2 then
            local avoidanceOffset = entityProps.Direction * AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE
            finalPosition = finalPosition + avoidanceOffset
        end
    end
    aiResultCache.lastRandomPosition = finalPosition
    return finalPosition
end

AutoPlayModule.lobby = {
    isChooserAvailable = function()
        local spawn = AutoPlayModule.customService.Workspace:FindFirstChild("Spawn")
        return spawn and spawn.NewPlayerCounter and spawn.NewPlayerCounter.GUI and spawn.NewPlayerCounter.GUI.SurfaceGui and spawn.NewPlayerCounter.GUI.SurfaceGui.Top and spawn.NewPlayerCounter.GUI.SurfaceGui.Top.Options and spawn.NewPlayerCounter.GUI.SurfaceGui.Top.Options.Visible
    end,
    updateChoice = function(choice) AutoPlayModule.lobbyChoice = choice end,
    getMapChoice = function()
        local choice = AutoPlayModule.lobbyChoice or math.random(1, 3)
        local spawn = AutoPlayModule.customService.Workspace:FindFirstChild("Spawn")
        if not spawn or not spawn.NewPlayerCounter or not spawn.NewPlayerCounter.Colliders then return nil end
        return spawn.NewPlayerCounter.Colliders:FindFirstChild(tostring(choice))
    end,
    getPadPosition = function()
        if not AutoPlayModule.lobby.isChooserAvailable() then
            AutoPlayModule.lobbyChoice = nil
            return
        end
        local choice = AutoPlayModule.lobby.getMapChoice()
        return choice and choice.Position, choice and choice.Name
    end
}

AutoPlayModule.movement = {
    removeCache = function() AutoPlayModule.animationCache = nil end,
    createJumpVelocity = function(player)
        local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local velocity = Instance.new("BodyVelocity")
        velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        velocity.Velocity = Vector3.new(0, 80, 0)
        velocity.Parent = rootPart
        AutoPlayModule.customService.Debris:AddItem(velocity, 0.001)
        local replicatedStorage = AutoPlayModule.customService.ReplicatedStorage
        local remotes = replicatedStorage:FindFirstChild("Remotes")
        local doubleJump = remotes and remotes:FindFirstChild("DoubleJump")
        if doubleJump then doubleJump:FireServer() end
    end,
    playJumpAnimation = function(player)
        if not AutoPlayModule.animationCache then
            local replicatedStorage = AutoPlayModule.customService.ReplicatedStorage
            local assets = replicatedStorage:FindFirstChild("Assets")
            local tutorial = assets and assets:FindFirstChild("Tutorial")
            local animations = tutorial and tutorial:FindFirstChild("Animations")
            local doubleJumpAnim = animations and animations:FindFirstChild("DoubleJump")
            if doubleJumpAnim and player.Character and player.Character.Humanoid and player.Character.Humanoid.Animator then
                AutoPlayModule.animationCache = player.Character.Humanoid.Animator:LoadAnimation(doubleJumpAnim)
            end
        end
        if AutoPlayModule.animationCache then AutoPlayModule.animationCache:Play() end
    end,
    doubleJump = function(player)
        if AutoPlayModule.doubleJumped or not player.Character then return end
        if not AutoPlayModule.percentageCheck(AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE) then return end
        AutoPlayModule.doubleJumped = true
        AutoPlayModule.movement.createJumpVelocity(player)
        AutoPlayModule.movement.playJumpAnimation(player)
    end,
    jump = function(player)
        if not AutoPlayModule.CONFIG.JUMPING_ENABLED or not player.Character then return end
        if not AutoPlayModule.playerHelper.onGround(player.Character) then
            AutoPlayModule.movement.doubleJump(player)
            return
        end
        if not AutoPlayModule.percentageCheck(AutoPlayModule.CONFIG.JUMP_PERCENTAGE) then return end
        AutoPlayModule.doubleJumped = false
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end,
    move = function(player, playerPosition)
        if player.Character and player.Character.Humanoid then player.Character.Humanoid:MoveTo(playerPosition) end
    end,
    stop = function(player)
        if player.Character and player.Character.HumanoidRootPart and player.Character.Humanoid then
            player.Character.Humanoid:MoveTo(player.Character.HumanoidRootPart.Position)
        end
    end
}

AutoPlayModule.signal = {
    connect = function(name, connection, callback)
        if not name then name = AutoPlayModule.customService.HttpService:GenerateGUID() end
        AutoPlayModule.signals[name] = connection:Connect(callback)
        return AutoPlayModule.signals[name]
    end,
    disconnect = function(name)
        if not name or not AutoPlayModule.signals[name] then return end
        AutoPlayModule.signals[name]:Disconnect()
        AutoPlayModule.signals[name] = nil
    end,
    stop = function()
        for name, connection in pairs(AutoPlayModule.signals) do
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
                AutoPlayModule.signals[name] = nil
            end
        end
    end
}

AutoPlayModule.findPath = function(inLobby, delta)
    local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
    if not localPlayer.Character or not localPlayer.Character.HumanoidRootPart then return nil end
    local rootPosition = localPlayer.Character.HumanoidRootPart.Position
    if inLobby then
        local padPosition, padNumber = AutoPlayModule.lobby.getPadPosition()
        local choice = tonumber(padNumber)
        if choice then
            AutoPlayModule.lobby.updateChoice(choice)
            if getgenv().AutoVote then
                local replicatedStorage = AutoPlayModule.customService.ReplicatedStorage
                local packages = replicatedStorage:FindFirstChild("Packages")
                local index = packages and packages:FindFirstChild("_Index")
                local net = index and index:FindFirstChild("sleitnick_net@0.1.0")
                local netFolder = net and net:FindFirstChild("net")
                local updateVotes = netFolder and netFolder:FindFirstChild("RE/UpdateVotes")
                if updateVotes then updateVotes:FireServer("FFA") end
            end
        end
        if not padPosition then return nil end
        return AutoPlayModule.getCurve(rootPosition, padPosition, delta)
    end
    local randomPosition = AutoPlayModule.getRandomPosition()
    if not randomPosition then return nil end
    return AutoPlayModule.getCurve(rootPosition, randomPosition, delta)
end

AutoPlayModule.followPath = function(delta)
    AutoPlayModule.frameThrottle = AutoPlayModule.frameThrottle + 1
    if AutoPlayModule.frameThrottle % AutoPlayModule.CONFIG.UPDATE_FREQUENCY ~= 0 then return end
    local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
    if not AutoPlayModule.playerHelper.isAlive(localPlayer) then
        AutoPlayModule.movement.removeCache()
        return
    end
    local inLobby = localPlayer.Character.Parent == AutoPlayModule.customService.Workspace.Dead
    local path = AutoPlayModule.findPath(inLobby, delta * AutoPlayModule.CONFIG.UPDATE_FREQUENCY)
    if not path then
        AutoPlayModule.movement.stop(localPlayer)
        return
    end
    AutoPlayModule.movement.move(localPlayer, path)
    AutoPlayModule.movement.jump(localPlayer)
end

AutoPlayModule.finishThread = function()
    AutoPlayModule.signal.disconnect("auto-play")
    AutoPlayModule.signal.disconnect("synchronize")
    local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
    if AutoPlayModule.playerHelper.isAlive(localPlayer) then
        AutoPlayModule.movement.stop(localPlayer)
    end
    for key, _ in pairs(aiResultCache) do aiResultCache[key] = nil end
    for key, _ in pairs(aiTimeCache) do aiTimeCache[key] = 0 end
end

AutoPlayModule.runThread = function()
    AutoPlayModule.signal.connect("auto-play", AutoPlayModule.customService.RunService.PostSimulation, AutoPlayModule.followPath)
    AutoPlayModule.signal.connect("synchronize", AutoPlayModule.customService.RunService.PostSimulation, AutoPlayModule.ballUtils.getBall)
end


-- ============================================================================
-- VISUALS, ESP, PLAYER MODS
-- ============================================================================
System.visuals = {
    __esp_enabled = Config.Visuals.ESP, __esp_team_check = Config.Visuals.TeamCheck, 
    __esp_color = Config.Visuals.ESPColor, __esp_highlight_cache = {},
    __night_mode = Config.Visuals.NightMode, __night_color = Color3.fromRGB(10, 10, 15),
    __original_lighting = { Ambient = game:GetService("Lighting").Ambient, Brightness = game:GetService("Lighting").Brightness, ClockTime = game:GetService("Lighting").ClockTime }
}

function System.visuals.update_esp()
    if not System.visuals.__esp_enabled then
        for p, h in pairs(System.visuals.__esp_highlight_cache) do h:Destroy(); System.visuals.__esp_highlight_cache[p] = nil end
        return
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if System.visuals.__esp_team_check and player.Team == LocalPlayer.Team then
                if System.visuals.__esp_highlight_cache[player] then System.visuals.__esp_highlight_cache[player]:Destroy(); System.visuals.__esp_highlight_cache[player] = nil end
            else
                if not System.visuals.__esp_highlight_cache[player] or System.visuals.__esp_highlight_cache[player].Parent ~= player.Character then
                    if System.visuals.__esp_highlight_cache[player] then System.visuals.__esp_highlight_cache[player]:Destroy() end
                    local hl = Instance.new("Highlight")
                    hl.Name = "LyraESP_" .. player.Name; hl.FillColor = System.visuals.__esp_color; hl.OutlineColor = Color3.new(1, 1, 1); hl.FillTransparency = 0.5; hl.OutlineTransparency = 0.2; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = player.Character
                    System.visuals.__esp_highlight_cache[player] = hl
                end
                System.visuals.__esp_highlight_cache[player].FillColor = System.visuals.__esp_color
            end
        else
            if System.visuals.__esp_highlight_cache[player] then System.visuals.__esp_highlight_cache[player]:Destroy(); System.visuals.__esp_highlight_cache[player] = nil end
        end
    end
end

function System.visuals.toggle_night_mode(state)
    System.visuals.__night_mode = state
    local Lighting = game:GetService("Lighting")
    if state then Lighting.Ambient = System.visuals.__night_color; Lighting.Brightness = 0.2; Lighting.ClockTime = 0
    else Lighting.Ambient = System.visuals.__original_lighting.Ambient; Lighting.Brightness = System.visuals.__original_lighting.Brightness; Lighting.ClockTime = System.visuals.__original_lighting.ClockTime end
end

System.player_mods = { 
    __walkspeed_enabled = Config.PlayerMods.WalkSpeed.Enabled, 
    __walkspeed_value = Config.PlayerMods.WalkSpeed.Value, 
    __jumppower_enabled = Config.PlayerMods.JumpPower.Enabled, 
    __jumppower_value = Config.PlayerMods.JumpPower.Value, 
    __fov_enabled = Config.PlayerMods.FOV.Enabled, 
    __fov_value = Config.PlayerMods.FOV.Value, 
    __spinbot_enabled = Config.PlayerMods.Spinbot.Enabled, 
    __spinbot_speed = Config.PlayerMods.Spinbot.Speed, 
    __cam_shake_disabled = Config.PlayerMods.DisableCamShake 
}

function System.player_mods.update_movement()
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if System.player_mods.__walkspeed_enabled then humanoid.WalkSpeed = System.player_mods.__walkspeed_value end
    if System.player_mods.__jumppower_enabled then humanoid.UseJumpPower = true; humanoid.JumpPower = System.player_mods.__jumppower_value end
end
function System.player_mods.update_fov() Camera.FieldOfView = System.player_mods.__fov_enabled and System.player_mods.__fov_value or 70 end
function System.player_mods.spinbot_loop()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and System.player_mods.__spinbot_enabled then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(System.player_mods.__spinbot_speed), 0) end
end
function System.player_mods.disable_camera_shake(state)
    System.player_mods.__cam_shake_disabled = state
    if state then pcall(function() for _, scr in pairs(LocalPlayer:WaitForChild("PlayerScripts"):GetDescendants()) do if scr.Name:lower():find("shake") and scr:IsA("ModuleScript") then local s, m = pcall(require, scr); if s and type(m)=="table" and m.Shake then m.Shake = function() end end end end end) end
end

RunService.RenderStepped:Connect(function()
    System.visuals.update_esp()
    System.player_mods.update_fov()
    System.player_mods.spinbot_loop()
    if System.player_mods.__walkspeed_enabled or System.player_mods.__jumppower_enabled then System.player_mods.update_movement() end
end)


-- ============================================================================
-- MODULE ADD-ONS (TARGET PLAYER, AVATAR CHANGER, CURVE MATH, VISUAL FX)
-- ============================================================================
local Features = {}

-- [[ 1. Target Player ]]
Features.TargetPlayer = {
    Enabled = (Config.Exclusive.TargetPlayerName ~= ""),
    SelectedTarget = Config.Exclusive.TargetPlayerName,
    PlayerMap = {}
}
function Features.TargetPlayer.updatePlayerList()
    table.clear(Features.TargetPlayer.PlayerMap)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            Features.TargetPlayer.PlayerMap[player.DisplayName] = player.Name
            Features.TargetPlayer.PlayerMap[player.Name] = player.Name
        end
    end
end
function Features.TargetPlayer.getTargetPlayer()
    if not Features.TargetPlayer.Enabled or not Features.TargetPlayer.SelectedTarget then return nil end
    return Players:FindFirstChild(Features.TargetPlayer.SelectedTarget)
end
Players.PlayerAdded:Connect(function() task.wait(0.5); Features.TargetPlayer.updatePlayerList() end)
Players.PlayerRemoving:Connect(function(player) 
    if Features.TargetPlayer.SelectedTarget == player.Name then Features.TargetPlayer.SelectedTarget = nil end
    task.wait(0.5); Features.TargetPlayer.updatePlayerList() 
end)
Features.TargetPlayer.updatePlayerList()


-- [[ 2. Brutal Avatar Changer ]]
Features.AvatarChanger = {
    Enabled = (Config.Exclusive.AvatarChangerName ~= "")
}
local function descriptions_match(a, b)
    if not a or not b then return false end
    local keys = {"Shirt", "Pants", "ShirtGraphic", "Head", "Face", "BodyTypeScale", "HeightScale"}
    for _, k in ipairs(keys) do
        if (a[k] ~= nil and b[k] ~= nil) and tostring(a[k]) ~= tostring(b[k]) then return false end
    end
    return true
end
local function force_apply_brutal(hum, desc)
    if not hum or not desc then return false end
    for _ = 1, 15 do
        pcall(function() hum:ApplyDescriptionClientServer(desc) end)
        task.wait(0.05)
        local applied = pcall(function() return hum:GetAppliedDescription() end)
        if applied and descriptions_match(applied, desc) then return true end
    end
    pcall(function() hum.Description = Instance.new("HumanoidDescription") end)
    task.wait(0.1)
    for _ = 1, 15 do
        pcall(function() hum:ApplyDescriptionClientServer(desc) end)
        task.wait(0.05)
        local applied = pcall(function() return hum:GetAppliedDescription() end)
        if applied and descriptions_match(applied, desc) then return true end
    end
    return false
end
function Features.AvatarChanger.setAvatar(targetName)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or targetName == "" then return end
    local success, desc = pcall(function()
        local id = Players:GetUserIdFromNameAsync(targetName)
        return Players:GetHumanoidDescriptionFromUserId(id)
    end)
    if success and desc then
        pcall(function()
            LocalPlayer:ClearCharacterAppearance()
            hum.Description = Instance.new("HumanoidDescription")
        end)
        task.wait(0.05)
        force_apply_brutal(hum, desc)
    end
end


-- [[ 3. Ball Curve Math Logic ]]
Features.Curve = { Mode = Config.Curve.Mode }
function Features.Curve.get_cframe()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return Camera.CFrame end
    
    local targetPart
    local targetedPlayer = Features.TargetPlayer.getTargetPlayer()
    if targetedPlayer and targetedPlayer.Character and targetedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        targetPart = targetedPlayer.Character.HumanoidRootPart
    end
    
    local target_pos = targetPart and targetPart.Position or (root.Position + Camera.CFrame.LookVector * 100)
    
    local curve_functions = {
        function() return Camera.CFrame end,
        function() return CFrame.new(root.Position, target_pos + Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))) end,
        function() return CFrame.new(root.Position, target_pos + Vector3.new(0, 5, 0)) end,
        function() 
            local direction = (root.Position - target_pos).Unit
            local backwards_pos = root.Position + direction * 10000 + Vector3.new(0, 1000, 0)
            return CFrame.new(Camera.CFrame.Position, backwards_pos)
        end,
        function() return CFrame.new(root.Position, target_pos + Vector3.new(0, -9e18, 0)) end,
        function() return CFrame.new(root.Position, target_pos + Vector3.new(0, 9e18, 0)) end
    }
    
    local selected_function = curve_functions[Features.Curve.Mode] or curve_functions[1]
    return selected_function()
end


-- [[ 4. Visuals (Rain & Plasma Trails) ]]
Features.Visuals = {
    Rain = {
        Enabled = Config.Visuals.Rain, Particles = {}, MaxParticles = 5000,
        SpawnArea = 500, FallSpeed = 25, SpawnHeight = 100, SpawnRate = 3,
        Color = Config.Visuals.RainColor
    },
    Plasma = {
        Enabled = Config.Visuals.Plasma, Active = false, NumTrails = 8,
        TrailColor = Config.Visuals.PlasmaColor, Attachments = {}, LastBall = nil
    }
}
local ParticleFolder = Workspace:FindFirstChild("MagicalParticles") or Instance.new("Folder", Workspace)
ParticleFolder.Name = "MagicalParticles"

local function spawn_rain()
    local r = Features.Visuals.Rain
    if not r.Enabled or #r.Particles >= r.MaxParticles then return end
    local char = LocalPlayer.Character
    local pos = char and char.PrimaryPart and char.PrimaryPart.Position or Camera.CFrame.Position
    for _ = 1, r.SpawnRate do
        local particle = Instance.new("Part")
        particle.Size = Vector3.new(0.9, 0.9, 0.9)
        particle.Shape = Enum.PartType.Ball
        particle.Material = Enum.Material.Neon
        particle.Color = r.Color
        particle.CanCollide = false
        particle.Anchored = true
        particle.Position = Vector3.new(pos.X + math.random(-r.SpawnArea, r.SpawnArea), pos.Y + r.SpawnHeight, pos.Z + math.random(-r.SpawnArea, r.SpawnArea))
        particle.Parent = ParticleFolder
        table.insert(r.Particles, { Part = particle, Velocity = Vector3.new(math.random(-2, 2), -r.FallSpeed, math.random(-2, 2)), TimeAlive = 0, FloatFreq = math.random(2, 4), FloatAmp = math.random(2, 5) })
    end
end

local function update_rain(delta)
    local r = Features.Visuals.Rain
    local char = LocalPlayer.Character
    local pos = char and char.PrimaryPart and char.PrimaryPart.Position or Camera.CFrame.Position
    for i = #r.Particles, 1, -1 do
        local p = r.Particles[i]
        if not p.Part or not p.Part.Parent then table.remove(r.Particles, i); continue end
        p.TimeAlive = p.TimeAlive + delta
        local float_x = math.sin(p.TimeAlive * p.FloatFreq) * p.FloatAmp * delta
        local float_z = math.cos(p.TimeAlive * p.FloatFreq) * p.FloatAmp * delta
        local new_pos = p.Part.Position + Vector3.new(p.Velocity.X * delta + float_x, p.Velocity.Y * delta, p.Velocity.Z * delta + float_z)
        p.Part.Position = new_pos
        if new_pos.Y < pos.Y - 20 or (new_pos - pos).Magnitude > r.SpawnArea * 1.5 then p.Part:Destroy(); table.remove(r.Particles, i) end
    end
end

local function create_plasma(ball)
    local p = Features.Visuals.Plasma
    if p.Active then return end
    p.Active = true
    p.Attachments = {}
    for i = 1, p.NumTrails do
        local angle = (i / p.NumTrails) * math.pi * 2
        local radius = math.random(150, 250) / 100
        local height = math.random(-150, 150) / 100
        local a0 = Instance.new("Attachment", ball); local a1 = Instance.new("Attachment", ball)
        local trail = Instance.new("Trail", ball)
        trail.Attachment0 = a0; trail.Attachment1 = a1; trail.Lifetime = 0.6; trail.FaceCamera = true; trail.LightEmission = 1; trail.Color = ColorSequence.new(p.TrailColor)
        table.insert(p.Attachments, { a0 = a0, a1 = a1, trail = trail, baseAngle = angle, angle = 0, speed = math.random(15, 30) / 10, spiralSpeed = math.random(25, 45) / 10, baseRadius = radius, baseHeight = height })
    end
end

local function animate_plasma(delta)
    local p = Features.Visuals.Plasma
    if not p.Active then return end
    for _, t in ipairs(p.Attachments) do
        t.angle = t.angle + t.speed * delta
        local spiral = t.angle * t.spiralSpeed
        t.a0.Position = Vector3.new(math.cos(t.baseAngle + t.angle) * t.baseRadius, t.baseHeight + math.sin((t.baseAngle + t.angle) * 3) * 0.8, math.sin(t.baseAngle + t.angle) * t.baseRadius)
        t.a1.Position = Vector3.new(math.cos(t.baseAngle + t.angle + math.pi) * t.baseRadius, -t.baseHeight + math.cos((t.baseAngle + t.angle) * 2.5) * 0.8, math.sin(t.baseAngle + t.angle + math.pi) * t.baseRadius)
    end
end

local function cleanup_plasma(ball)
    if not ball then return end
    for _, obj in pairs(ball:GetChildren()) do
        if obj:IsA("Trail") or (obj:IsA("Attachment") and not obj.Name:match("Attachment")) then obj:Destroy() end
    end
    Features.Visuals.Plasma.Active = false; Features.Visuals.Plasma.Attachments = {}
end

RunService.Heartbeat:Connect(function(delta)
    if Features.Visuals.Rain.Enabled then spawn_rain() end
    update_rain(delta)
    
    local ball = System.ball.get()
    local p = Features.Visuals.Plasma
    if p.Enabled then
        if ball and ball ~= p.LastBall then
            if p.LastBall then cleanup_plasma(p.LastBall) end
            create_plasma(ball)
            p.LastBall = ball
        elseif not ball and p.LastBall then
            cleanup_plasma(p.LastBall)
            p.LastBall = nil
        end
        if ball and p.Active then animate_plasma(delta) end
    else
        if p.LastBall then cleanup_plasma(p.LastBall); p.LastBall = nil end
    end
end)

-- ============================================================================
-- INITIALIZE MODULES ON START
-- ============================================================================

-- Autoparry
if Config.Autoparry.Enabled then System.autoparry.start() end

-- Spam 
if Config.Spam.ManualSpam then System.manual_spam.start() end
if Config.Spam.AutoSpam then System.auto_spam.start() end

-- AI Play
if Config.Misc.AIPlay then AutoPlayModule.runThread() end
LocalPlayer.PlayerScripts.EffectScripts.ClientFX.Disabled = Config.Misc.DisableEffects

-- Exclusives
WalkableSemiImmortal.toggle(Config.Exclusive.Immortal)
System.visuals.toggle_night_mode(Config.Visuals.NightMode)
System.player_mods.disable_camera_shake(Config.PlayerMods.DisableCamShake)

if Config.Exclusive.Emotes then
    animation_system.start()
    if Config.Exclusive.SelectedEmote ~= "None" and Config.Exclusive.SelectedEmote ~= "" then
        animation_system.play(Config.Exclusive.SelectedEmote)
    end
end

-- Target Player System Hook
getgenv().SelectedTarget = Features.TargetPlayer.SelectedTarget

-- Avatar Changer Hook
if Features.AvatarChanger.Enabled then
    task.spawn(function()
        Features.AvatarChanger.setAvatar(Config.Exclusive.AvatarChangerName)
    end)
end

print("[System] Blade Ball Headless Modules Initialized Successfully.")
