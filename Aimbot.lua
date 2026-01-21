--[[

	Aimbot Module
	IP's Hub

	Original base by Exunys
	Fixed & Rebranded by Karlos_Division

]]

--// Ensure Hub Exists
getgenv().AirHub = getgenv().AirHub or {}

--// Cache
local pcall, getgenv, next, setmetatable, Vector2new, CFramenew, Color3fromRGB, Drawingnew, TweenInfonew, stringupper, mousemoverel =
	pcall, getgenv, next, setmetatable, Vector2.new, CFrame.new, Color3.fromRGB, Drawing.new, TweenInfo.new, string.upper,
	mousemoverel or (Input and Input.MouseMove)

--// Prevent double load
if getgenv().AirHub.Aimbot then return end

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Variables
local RequiredDistance = 2000
local Typing = false
local Running = false
local ServiceConnections = {}
local Animation
local OriginalSensitivity

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

--// Helpers
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
			if v ~= LocalPlayer
				and v.Character
				and v.Character:FindFirstChild(Environment.Settings.LockPart)
				and v.Character:FindFirstChildOfClass("Humanoid")
				and v.Character.Humanoid.Health > 0 then

				if Environment.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end

				local vec, onscreen =
					Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)

				if onscreen then
					local dist = (UserInputService:GetMouseLocation() - ConvertVector(vec)).Magnitude
					if dist < RequiredDistance then
						RequiredDistance = dist
						Environment.Locked = v
					end
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

--// Main Loop
local function Load()
	OriginalSensitivity = UserInputService.MouseDeltaSensitivity

	ServiceConnections.RenderStepped =
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

--// Input Handling (THIS WAS MISSING)
ServiceConnections.InputBegan =
	UserInputService.InputBegan:Connect(function(input)
		if Typing then return end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			if Environment.Settings.Toggle then
				Running = not Running
				if not Running then CancelLock() end
			else
				Running = true
			end
		end
	end)

ServiceConnections.InputEnded =
	UserInputService.InputEnded:Connect(function(input)
		if Typing then return end
		if not Environment.Settings.Toggle and input.UserInputType == Enum.UserInputType.MouseButton2 then
			Running = false
			CancelLock()
		end
	end)

UserInputService.TextBoxFocused:Connect(function()
	Typing = true
end)

UserInputService.TextBoxFocusReleased:Connect(function()
	Typing = false
end)

--// Load
Load()
