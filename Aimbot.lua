--[[

	Aimbot Module
	IP's Hub

]]

--// Cache
local pcall, getgenv, next, setmetatable, Vector2new, CFramenew, Color3fromRGB, Drawingnew, TweenInfonew, stringupper, mousemoverel =
	pcall, getgenv, next, setmetatable, Vector2.new, CFrame.new, Color3.fromRGB, Drawing.new, TweenInfo.new, string.upper,
	mousemoverel or (Input and Input.MouseMove)

--// Launching checks
if not getgenv().AirHub or getgenv().AirHub.Aimbot then return end

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Variables
local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity =
	2000, false, false, {}

--// Environment
getgenv().AirHub.Aimbot = {
	Settings = {
		Enabled = false,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		Sensitivity = 0,
		ThirdPerson = false,
		ThirdPersonSensitivity = 3,
		TriggerKey = "MouseButton2",
		Toggle = false,
		LockPart = "Head"
	},
	FOVSettings = {
		Enabled = true,
		Visible = true,
		Amount = 90,
		Color = Color3fromRGB(255,255,255),
		LockedColor = Color3fromRGB(255,70,70),
		Transparency = 0.5,
		Sides = 60,
		Thickness = 1,
		Filled = false
	},
	FOVCircle = Drawingnew("Circle")
}

local Environment = getgenv().AirHub.Aimbot

--// Core
local function ConvertVector(v)
	return Vector2new(v.X, v.Y)
end

local function CancelLock()
	Environment.Locked = nil
	Environment.FOVCircle.Color = Environment.FOVSettings.Color
	UserInputService.MouseDeltaSensitivity = OriginalSensitivity
	if Animation then Animation:Cancel() end
end

local function GetClosestPlayer()
	if not Environment.Locked then
		RequiredDistance = Environment.FOVSettings.Amount
		for _, v in next, Players:GetPlayers() do
			if v ~= LocalPlayer and v.Character
				and v.Character:FindFirstChild(Environment.Settings.LockPart)
				and v.Character:FindFirstChildOfClass("Humanoid") then

				if Environment.Settings.TeamCheck and v.TeamColor == LocalPlayer.TeamColor then continue end
				if Environment.Settings.AliveCheck and v.Character.Humanoid.Health <= 0 then continue end

				local vec, onscreen =
					Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
				local dist = (UserInputService:GetMouseLocation() - ConvertVector(vec)).Magnitude

				if dist < RequiredDistance and onscreen then
					RequiredDistance = dist
					Environment.Locked = v
				end
			end
		end
	else
		local vec = Camera:WorldToViewportPoint(
			Environment.Locked.Character[Environment.Settings.LockPart].Position)
		if (UserInputService:GetMouseLocation() - ConvertVector(vec)).Magnitude > RequiredDistance then
			CancelLock()
		end
	end
end

local function Load()
	OriginalSensitivity = UserInputService.MouseDeltaSensitivity

	ServiceConnections.RenderSteppedConnection =
		RunService.RenderStepped:Connect(function()
			if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
				Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
				Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
				Environment.FOVCircle.Position = UserInputService:GetMouseLocation()
			else
				Environment.FOVCircle.Visible = false
			end

			if Running and Environment.Settings.Enabled then
				GetClosestPlayer()
				if Environment.Locked then
					Camera.CFrame = CFramenew(
						Camera.CFrame.Position,
						Environment.Locked.Character[Environment.Settings.LockPart].Position
					)
					UserInputService.MouseDeltaSensitivity = 0
					Environment.FOVCircle.Color = Environment.FOVSettings.LockedColor
				end
			end
		end)
end

Environment.Functions = {}

function Environment.Functions:Exit()
	for _, v in next, ServiceConnections do v:Disconnect() end
	Environment.FOVCircle:Remove()
	getgenv().AirHub.Aimbot = nil
end

function Environment.Functions:Restart()
	for _, v in next, ServiceConnections do v:Disconnect() end
	Load()
end

setmetatable(Environment.Functions, {__newindex = warn})

Load()
