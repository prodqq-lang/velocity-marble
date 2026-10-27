--[[
    Utility GUI
    Tabs: Movement (Velocity Changer) | Visuals (Hidden ESP) | Trail (20 presets) | Settings
    Toggle visibility with RightShift.
    Re-executing cleans up the previous run automatically.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local env = getgenv()

-- clean up previous execution
if env.UtilityUnload then
	pcall(env.UtilityUnload)
end

local conns = {}
local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(conns, c)
	return c
end

----------------------------------------------------------------
-- Theme
----------------------------------------------------------------
local C = {
	bg = Color3.fromRGB(13, 13, 13),
	panel = Color3.fromRGB(22, 22, 22),
	panel2 = Color3.fromRGB(28, 28, 28),
	off = Color3.fromRGB(38, 38, 38),
	line = Color3.fromRGB(60, 36, 46),
	accent = Color3.fromRGB(255, 105, 150),
	accentDark = Color3.fromRGB(120, 50, 75),
	text = Color3.fromRGB(235, 235, 235),
	dim = Color3.fromRGB(125, 125, 125),
}
local FONT = Enum.Font.Code
local DEFAULT_THEME = { accent = C.accent, accentDark = C.accentDark, line = C.line }

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function label(parent, text, size, color, pos, sz, align)
	return new("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		Text = text,
		TextSize = size or 13,
		TextColor3 = color or C.text,
		Position = pos or UDim2.new(),
		Size = sz or UDim2.new(1, 0, 1, 0),
		TextXAlignment = align or Enum.TextXAlignment.Left,
	}, parent)
end

----------------------------------------------------------------
-- Settings defaults (all off until you flip the switches)
----------------------------------------------------------------
env.VelocityChanger = false
env.XVelocity = 0
env.YVelocity = nil -- nil = keep real Y velocity
env.ZVelocity = 0

env.TrailEnabled = false
env.TrailLifetime = 6
env.TrailWidth = 5
env.TrailSpeed = 0.15
env.TrailSpread = 0.35
env.TrailGlow = 0.3 -- 0 = true colors, 1 = very bright / washes to white
env.TrailPreset = 1

env.HiddenESP = false
env.ThemeFollowsTrail = true

----------------------------------------------------------------
-- Root GUI
----------------------------------------------------------------
local parentGui = (gethui and gethui()) or CoreGui
local gui = new("ScreenGui", {
	Name = "UtilityGUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
}, parentGui)

local main = new("Frame", {
	Name = "Main",
	BackgroundColor3 = C.bg,
	BorderSizePixel = 0,
	Size = UDim2.fromOffset(620, 420),
	Position = UDim2.new(0.5, -310, 0.5, -210),
}, gui)
new("UIStroke", { Color = Color3.fromRGB(45, 45, 45), Thickness = 1 }, main)

-- title bar
local titleBar = new("Frame", {
	BackgroundColor3 = C.bg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 30),
}, main)
label(titleBar, "qq hud marble edition", 13, C.accent, UDim2.fromOffset(12, 0), UDim2.new(1, -24, 1, 0))
new("Frame", { BackgroundColor3 = C.line, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1) }, titleBar)

-- dragging
do
	local dragging, dragStart, startPos
	connect(titleBar.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	connect(UIS.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	connect(UIS.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- tab bar
local tabBar = new("Frame", {
	BackgroundColor3 = C.bg, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 32),
}, main)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, tabBar)
new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, tabBar)
-- divider lives on main (not tabBar) so the list layout doesn't treat it as a tab
new("Frame", { BackgroundColor3 = C.line, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 61), Size = UDim2.new(1, 0, 0, 1) }, main)

-- footer
local footer = new("Frame", {
	BackgroundColor3 = C.bg, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -20), Size = UDim2.new(1, 0, 0, 20),
}, main)
label(footer, "Version 1.2 (Checkpoints for the lazy guys)", 11, C.dim, UDim2.fromOffset(10, 0), UDim2.new(0.7, -10, 1, 0))
label(footer, "RightShift = toggle", 11, C.dim, UDim2.new(0.7, 0, 0, 0), UDim2.new(0.3, -10, 1, 0), Enum.TextXAlignment.Right)

-- content area
local content = new("Frame", {
	BackgroundColor3 = C.panel, BorderSizePixel = 0,
	Position = UDim2.fromOffset(8, 70), Size = UDim2.new(1, -16, 1, -98),
}, main)

----------------------------------------------------------------
-- Tabs
----------------------------------------------------------------
local pages, tabButtons = {}, {}

local function selectTab(name)
	for n, page in pairs(pages) do
		page.Visible = (n == name)
	end
	for n, b in pairs(tabButtons) do
		local active = (n == name)
		b.btn.TextColor3 = active and C.accent or C.dim
		b.line.Visible = active
	end
end

local function addTab(name)
	local btn = new("TextButton", {
		BackgroundTransparency = 1, Font = FONT, Text = name, TextSize = 13, TextColor3 = C.dim,
		Size = UDim2.fromOffset(#name * 8 + 28, 32), AutoButtonColor = false,
	}, tabBar)
	local line = new("Frame", {
		BackgroundColor3 = C.accent, BorderSizePixel = 0, Position = UDim2.new(0, 8, 1, -2),
		Size = UDim2.new(1, -16, 0, 2), Visible = false,
	}, btn)
	tabButtons[name] = { btn = btn, line = line }
	connect(btn.MouseButton1Click, function() selectTab(name) end)

	local page = new("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false,
	}, content)
	pages[name] = page
	return page
end

local function scrollPage(parent, pos, size)
	local sf = new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = pos or UDim2.new(), Size = size or UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
	}, parent)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
	}, sf)
	return sf
end

----------------------------------------------------------------
-- Components
----------------------------------------------------------------
local function Section(parent, text)
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24) }, parent)
	label(row, text, 13, C.accent, UDim2.new(), UDim2.new(1, 0, 0, 20))
	new("Frame", { BackgroundColor3 = C.line, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 1) }, row)
	return row
end

local function Toggle(parent, text, default, cb)
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26) }, parent)
	new("Frame", { BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromOffset(4, 4), Position = UDim2.new(0, 2, 0.5, -2) }, row)
	label(row, text, 13, C.text, UDim2.fromOffset(12, 0), UDim2.new(1, -60, 1, 0))

	local track = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = C.off, BorderSizePixel = 0,
		Size = UDim2.fromOffset(34, 16), Position = UDim2.new(1, -38, 0.5, -8),
	}, row)
	local knob = new("Frame", {
		BackgroundColor3 = C.dim, BorderSizePixel = 0, Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(3, 3),
	}, track)

	local state = false
	local function set(v, silent)
		state = v
		local ti = TweenInfo.new(0.12)
		TweenService:Create(track, ti, { BackgroundColor3 = v and C.accentDark or C.off }):Play()
		TweenService:Create(knob, ti, {
			Position = v and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
			BackgroundColor3 = v and C.accent or C.dim,
		}):Play()
		if not silent and cb then cb(v) end
	end
	connect(track.MouseButton1Click, function() set(not state) end)
	set(default, true)
	return { Set = set, Get = function() return state end }
end

local function Slider(parent, text, min, max, default, decimals, cb)
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38) }, parent)
	label(row, text, 13, C.dim, UDim2.fromOffset(2, 0), UDim2.new(0.6, 0, 0, 18))
	local valueLabel = label(row, "", 12, C.dim, UDim2.new(0.6, 0, 0, 0), UDim2.new(0.4, 0, 0, 18), Enum.TextXAlignment.Right)

	local bar = new("Frame", {
		BackgroundColor3 = C.off, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 6),
	}, row)
	local fill = new("Frame", { BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0) }, bar)
	local marker = new("Frame", {
		BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromOffset(3, 12), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
	}, bar)
	local hit = new("TextButton", {
		Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 22),
	}, row)

	local fmt = "%." .. decimals .. "f"
	local value = default
	local function update(v, silent)
		value = math.clamp(v, min, max)
		local a = (value - min) / (max - min)
		fill.Size = UDim2.new(a, 0, 1, 0)
		marker.Position = UDim2.new(a, 0, 0.5, 0)
		valueLabel.Text = string.format(fmt, value)
		if not silent and cb then cb(value) end
	end
	local function fromX(x)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		local mult = 10 ^ decimals
		update(math.floor((min + (max - min) * a) * mult + 0.5) / mult)
	end

	local dragging = false
	connect(hit.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromX(input.Position.X)
		end
	end)
	connect(UIS.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end)
	connect(UIS.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	update(default, true)
	return { Set = update, Get = function() return value end }
end

local function Button(parent, text, cb)
	local b = new("TextButton", {
		BackgroundColor3 = C.panel2, BorderSizePixel = 0, Font = FONT, Text = text, TextSize = 13, TextColor3 = C.text,
		AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 28),
	}, parent)
	new("UIStroke", { Color = C.accentDark, Thickness = 1 }, b)
	connect(b.MouseEnter, function() b.BackgroundColor3 = C.off end)
	connect(b.MouseLeave, function() b.BackgroundColor3 = C.panel2 end)
	connect(b.MouseButton1Click, function() if cb then cb() end end)
	return b
end

local function Note(parent, text, height)
	local l = label(parent, text, 12, C.dim, nil, UDim2.new(1, 0, 0, height or 30))
	l.TextWrapped = true
	l.TextYAlignment = Enum.TextYAlignment.Top
	return l
end

----------------------------------------------------------------
-- MOVEMENT TAB : Velocity Changer
----------------------------------------------------------------
local movePage = addTab("Movement")
local moveScroll = scrollPage(movePage)

Section(moveScroll, "Velocity Changer")
Toggle(moveScroll, "Enabled", false, function(v) env.VelocityChanger = v end)
Slider(moveScroll, "X Velocity", -500, 500, 0, 0, function(v) env.XVelocity = v end)

local ySlider
local yOverride = false
Toggle(moveScroll, "Override Y Velocity", false, function(v)
	yOverride = v
	env.YVelocity = v and ySlider.Get() or nil
end)
ySlider = Slider(moveScroll, "Y Velocity", -500, 500, 0, 0, function(v)
	if yOverride then env.YVelocity = v end
end)
Slider(moveScroll, "Z Velocity", -500, 500, 0, 0, function(v) env.ZVelocity = v end)
Note(moveScroll, "Y override off = your real Y velocity is kept (no hopping).", 30)

if env.VelocityConn then
	pcall(function() env.VelocityConn:Disconnect() end)
end
do
	local busy = false
	env.VelocityConn = RunService.PostSimulation:Connect(function()
		if not env.VelocityChanger or busy then return end

		local char = LocalPlayer.Character
		local part = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
		if not part then return end

		busy = true
		local real = part.AssemblyLinearVelocity

		part.AssemblyLinearVelocity = Vector3.new(
			env.XVelocity or real.X,
			env.YVelocity or real.Y,
			env.ZVelocity or real.Z
		)

		RunService.PreRender:Wait()

		if part.Parent then
			part.AssemblyLinearVelocity = real
		end
		busy = false
	end)
end

----------------------------------------------------------------
-- VISUALS TAB : Hidden ESP (rainbow gradient title)
----------------------------------------------------------------
local visPage = addTab("Visuals")
local visScroll = scrollPage(visPage)

local espContainer = new("Folder", { Name = "HiddenESP" }, gui)
local tracked = {}
local rainbowGradients = {}

local TARGET_NAME = "Hidden"
local UPDATE_RATE = 0.1

local function getRoot()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position or Camera.CFrame.Position
end

local function toHex(c)
	return string.format("#%02x%02x%02x",
		math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function isValid(part)
	return part.Parent ~= nil and part:IsDescendantOf(workspace) and part.Parent.Name == TARGET_NAME
end

local function untrack(part)
	local info = tracked[part]
	if info then
		rainbowGradients[info.grad] = nil
		info.gui:Destroy()
		tracked[part] = nil
	end
end

local function updateInfo(info, part, dist)
	info.nameLabel.Text = string.format('<font color="%s">%s</font>', toHex(part.Color), part.Name)
	info.distLabel.Text = string.format("[%d studs]", dist)
end

local function track(part)
	if tracked[part] or not part:IsA("BasePart") then return end

	local bb = new("BillboardGui", {
		Name = "HiddenTag", Adornee = part, AlwaysOnTop = true, Size = UDim2.new(0, 100, 0, 40),
		StudsOffset = Vector3.new(0, 1.5, 0), LightInfluence = 0, ResetOnSpawn = false, Enabled = env.HiddenESP,
	}, espContainer)
	new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, bb)

	local function line(order, color)
		return new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 13), Font = FONT, TextSize = 11,
			TextColor3 = color, TextStrokeTransparency = 0.4, RichText = true, LayoutOrder = order,
		}, bb)
	end

	local title = line(1, Color3.new(1, 1, 1))
	title.Text = TARGET_NAME
	local grad = new("UIGradient", {}, title) -- rainbow, animated below
	local nameLabel = line(2, Color3.new(1, 1, 1))
	local distLabel = line(3, Color3.fromRGB(180, 180, 180))

	local info = { gui = bb, grad = grad, nameLabel = nameLabel, distLabel = distLabel }
	tracked[part] = info
	rainbowGradients[grad] = true
	updateInfo(info, part, math.floor((part.Position - getRoot()).Magnitude))
end

local function trackHidden(hidden)
	for _, child in ipairs(hidden:GetChildren()) do
		if child:IsA("BasePart") then
			track(child)
		elseif child:IsA("Model") then
			local p = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart", true)
			if p then track(p) end
		end
	end
	if hidden:IsA("BasePart") then track(hidden) end
end

task.spawn(function()
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst.Name == TARGET_NAME then trackHidden(inst) end
	end
end)

connect(workspace.DescendantAdded, function(inst)
	if inst.Name == TARGET_NAME then
		task.defer(trackHidden, inst)
	elseif inst:IsA("BasePart") and inst.Parent and inst.Parent.Name == TARGET_NAME then
		track(inst)
	end
end)

do
	local acc = 0
	connect(RunService.Heartbeat, function(dt)
		if not env.HiddenESP then return end
		acc += dt
		if acc < UPDATE_RATE then return end
		acc = 0
		local origin = getRoot()
		for part, info in pairs(tracked) do
			if not isValid(part) then
				untrack(part)
			else
				updateInfo(info, part, math.floor((part.Position - origin).Magnitude))
			end
		end
	end)

	-- animated rainbow for the "Hidden" title
	connect(RunService.RenderStepped, function()
		if not env.HiddenESP or next(rainbowGradients) == nil then return end
		local shift = (os.clock() * 0.35) % 1
		local pts = {}
		for i = 0, 6 do
			local t = i / 6
			pts[#pts + 1] = ColorSequenceKeypoint.new(t, Color3.fromHSV((shift + t) % 1, 0.85, 1))
		end
		local seq = ColorSequence.new(pts)
		for g in pairs(rainbowGradients) do
			g.Color = seq
		end
	end)
end

Section(visScroll, "Hidden ESP")
Toggle(visScroll, "Enabled", false, function(v)
	env.HiddenESP = v
	for _, info in pairs(tracked) do
		info.gui.Enabled = v
	end
end)
Note(visScroll, "Hidden stuff nigga", 44)

----------------------------------------------------------------
-- Checkpoint ESP: highlights everything under "_checkpoints"
-- (works whether _checkpoints is a Folder or a Model)
----------------------------------------------------------------
env.CheckpointESP = false
env.CheckpointHighlight = true
env.CheckpointLabels = true

local CP_NAME = "_checkpoints"
local cpContainer = new("Folder", { Name = "CheckpointESP" }, gui)
local cpTracked = {}    -- [target] = { hl, gui, grad, dist, off }
local cpContainers = {} -- [_checkpoints instance] = true
local cpCount = 0

-- true if inst sits directly under _checkpoints (or under Folders inside it)
local function cpInside(inst)
	local p = inst.Parent
	while p and p ~= workspace do
		if p.Name == CP_NAME then return true end
		if not p:IsA("Folder") then return false end
		p = p.Parent
	end
	return false
end

local function cpAdornee(target)
	if target:IsA("BasePart") then return target end
	if target:IsA("Model") then
		return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
	end
end

local function cpRefresh(info)
	info.hl.Enabled = env.CheckpointESP and env.CheckpointHighlight
	info.gui.Enabled = env.CheckpointESP and env.CheckpointLabels
end

local function cpUntrack(target)
	local info = cpTracked[target]
	if info then
		info.hl:Destroy()
		info.gui:Destroy()
		cpTracked[target] = nil
	end
end

local function cpTrack(target)
	if cpTracked[target] then return end
	if not (target:IsA("Model") or target:IsA("BasePart")) then return end
	local part = cpAdornee(target)
	if not part then return end

	local hl = new("Highlight", {
		Name = "CheckpointHL", Adornee = target, FillTransparency = 0.55, OutlineTransparency = 0,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, FillColor = Color3.new(1, 1, 1),
		OutlineColor = Color3.new(1, 1, 1), Enabled = false,
	}, cpContainer, true)

	local bb = new("BillboardGui", {
		Name = "CheckpointTag", Adornee = part, AlwaysOnTop = true, Size = UDim2.new(0, 110, 0, 40),
		StudsOffset = Vector3.new(0, 2, 0), LightInfluence = 0, ResetOnSpawn = false, Enabled = false,
	}, cpContainer, true)
	new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, bb, true)

	local function line(order, color)
		return new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 13), Font = FONT, TextSize = 11,
			TextColor3 = color, TextStrokeTransparency = 0.4, LayoutOrder = order,
		}, bb, true)
	end

	local title = line(1, Color3.new(1, 1, 1))
	title.Text = "Checkpoint"
	local grad = new("UIGradient", {}, title, true) -- rainbow, animated below
	local nameLabel = line(2, Color3.new(1, 1, 1))
	nameLabel.Text = target.Name
	local distLabel = line(3, Color3.fromRGB(180, 180, 180))

	cpCount += 1
	local info = { hl = hl, gui = bb, grad = grad, dist = distLabel, off = (cpCount * 0.08) % 1 }
	cpTracked[target] = info
	distLabel.Text = string.format("[%d studs]", (part.Position - getRoot()).Magnitude)
	cpRefresh(info)
end

local function cpScanContainer(c)
	cpContainers[c] = true
	for _, x in ipairs(c:GetDescendants()) do
		if (x:IsA("Model") or x:IsA("BasePart")) and cpInside(x) then
			cpTrack(x)
		end
	end
end

task.spawn(function()
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst.Name == CP_NAME then cpScanContainer(inst) end
	end
end)

connect(workspace.DescendantAdded, function(inst)
	if inst.Name == CP_NAME then
		task.defer(cpScanContainer, inst)
	elseif (inst:IsA("Model") or inst:IsA("BasePart")) and cpInside(inst) then
		task.defer(cpTrack, inst)
	end
end)

do
	local acc, scanAcc = 0, 0
	connect(RunService.Heartbeat, function(dt)
		if not env.CheckpointESP then return end
		acc += dt
		scanAcc += dt

		-- every couple of seconds, pick up anything that streamed in late
		if scanAcc > 2 then
			scanAcc = 0
			for c in pairs(cpContainers) do
				if c:IsDescendantOf(workspace) then
					cpScanContainer(c)
				else
					cpContainers[c] = nil
				end
			end
		end

		if acc < 0.1 then return end
		acc = 0
		local origin = getRoot()
		for target, info in pairs(cpTracked) do
			local part = cpAdornee(target)
			if not part or not target:IsDescendantOf(workspace) or not cpInside(target) then
				cpUntrack(target)
			else
				info.gui.Adornee = part
				info.dist.Text = string.format("[%d studs]", (part.Position - origin).Magnitude)
			end
		end
	end)

	-- rainbow billboard title + rainbow highlight
	connect(RunService.RenderStepped, function()
		if not env.CheckpointESP or next(cpTracked) == nil then return end
		local shift = (os.clock() * 0.35) % 1
		local pts = {}
		for i = 0, 6 do
			local t = i / 6
			pts[#pts + 1] = ColorSequenceKeypoint.new(t, Color3.fromHSV((shift + t) % 1, 0.85, 1))
		end
		local seq = ColorSequence.new(pts)
		for _, info in pairs(cpTracked) do
			info.grad.Color = seq
			local col = Color3.fromHSV((shift + info.off) % 1, 0.85, 1)
			info.hl.FillColor = col
			info.hl.OutlineColor = col
		end
	end)
end

Section(visScroll, "Checkpoint ESP")
Toggle(visScroll, "Enabled", false, function(v)
	env.CheckpointESP = v
	for _, info in pairs(cpTracked) do cpRefresh(info) end
end)
Toggle(visScroll, "Highlight", true, function(v)
	env.CheckpointHighlight = v
	for _, info in pairs(cpTracked) do cpRefresh(info) end
end)
Toggle(visScroll, "Billboard labels", true, function(v)
	env.CheckpointLabels = v
	for _, info in pairs(cpTracked) do cpRefresh(info) end
end)
Note(visScroll, "Do you take me for a fucking idiot avec?", 44)

----------------------------------------------------------------
-- TRAIL TAB : presets + settings
----------------------------------------------------------------
local PRESETS = {
	{ "Forest",        "Deep woodland greens and moss.",      { Color3.fromRGB(16, 82, 40), Color3.fromRGB(46, 139, 60), Color3.fromRGB(144, 214, 100), Color3.fromRGB(34, 110, 70) } },
	{ "River",         "Cool flowing blues and teal.",        { Color3.fromRGB(20, 80, 160), Color3.fromRGB(40, 150, 210), Color3.fromRGB(120, 220, 230), Color3.fromRGB(30, 110, 180) } },
	{ "Sunset",        "Orange sky melting into magenta.",    { Color3.fromRGB(255, 140, 50), Color3.fromRGB(255, 80, 90), Color3.fromRGB(200, 60, 140), Color3.fromRGB(255, 190, 80) } },
	{ "Ocean",         "Deep sea navy to bright aqua.",       { Color3.fromRGB(10, 40, 110), Color3.fromRGB(10, 110, 190), Color3.fromRGB(60, 220, 220), Color3.fromRGB(20, 70, 150) } },
	{ "Aurora",        "Northern lights green and violet.",   { Color3.fromRGB(60, 255, 150), Color3.fromRGB(60, 190, 230), Color3.fromRGB(150, 90, 240), Color3.fromRGB(70, 230, 190) } },
	{ "Nebula",        "Purple, blue and pink space dust.",   { Color3.fromRGB(150, 70, 255), Color3.fromRGB(70, 110, 255), Color3.fromRGB(80, 220, 255), Color3.fromRGB(255, 100, 200) } },
	{ "Ember",         "Glowing coals, red to gold.",         { Color3.fromRGB(120, 20, 10), Color3.fromRGB(230, 70, 20), Color3.fromRGB(255, 170, 40), Color3.fromRGB(180, 40, 15) } },
	{ "Glacier",       "Icy whites and pale blues.",          { Color3.fromRGB(190, 235, 255), Color3.fromRGB(120, 190, 240), Color3.fromRGB(235, 250, 255), Color3.fromRGB(90, 160, 225) } },
	{ "Blossom",       "Soft cherry blossom pinks.",          { Color3.fromRGB(255, 190, 210), Color3.fromRGB(255, 130, 175), Color3.fromRGB(255, 225, 235), Color3.fromRGB(235, 110, 160) } },
	{ "Toxic",         "Radioactive lime and acid green.",    { Color3.fromRGB(170, 255, 0), Color3.fromRGB(60, 200, 40), Color3.fromRGB(220, 255, 80), Color3.fromRGB(30, 140, 30) } },
	{ "Midnight",      "Dark indigo with a faint glow.",      { Color3.fromRGB(15, 15, 60), Color3.fromRGB(50, 40, 130), Color3.fromRGB(100, 90, 210), Color3.fromRGB(25, 25, 90) } },
	{ "Cotton Candy",  "Sweet pastel pink and sky blue.",     { Color3.fromRGB(255, 170, 220), Color3.fromRGB(170, 210, 255), Color3.fromRGB(255, 210, 240), Color3.fromRGB(190, 170, 255) } },
	{ "Lava",          "Molten red and bright yellow.",       { Color3.fromRGB(90, 10, 5), Color3.fromRGB(240, 40, 10), Color3.fromRGB(255, 200, 30), Color3.fromRGB(200, 25, 10) } },
	{ "Dunes",         "Warm desert sand and amber.",         { Color3.fromRGB(235, 200, 140), Color3.fromRGB(210, 150, 80), Color3.fromRGB(250, 225, 175), Color3.fromRGB(180, 115, 60) } },
	{ "Mint",          "Fresh mint and seafoam.",             { Color3.fromRGB(150, 255, 210), Color3.fromRGB(80, 220, 180), Color3.fromRGB(200, 255, 235), Color3.fromRGB(60, 190, 160) } },
	{ "Galaxy",        "Deep purple, blue and star pink.",    { Color3.fromRGB(40, 15, 90), Color3.fromRGB(90, 40, 190), Color3.fromRGB(40, 90, 220), Color3.fromRGB(255, 120, 200) } },
	{ "Autumn",        "Falling leaves, red to gold.",        { Color3.fromRGB(170, 40, 20), Color3.fromRGB(230, 120, 30), Color3.fromRGB(240, 190, 50), Color3.fromRGB(130, 70, 25) } },
	{ "Neon City",     "Hot pink and electric cyan.",         { Color3.fromRGB(255, 40, 160), Color3.fromRGB(140, 50, 255), Color3.fromRGB(30, 230, 255), Color3.fromRGB(255, 90, 210) } },
	{ "Storm",         "Thunderhead greys with lightning.",   { Color3.fromRGB(70, 80, 100), Color3.fromRGB(120, 135, 165), Color3.fromRGB(240, 240, 120), Color3.fromRGB(50, 60, 85) } },
	{ "Rainbow",       "The full spectrum, all the way.",     { Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 190, 50), Color3.fromRGB(80, 230, 90), Color3.fromRGB(60, 150, 255), Color3.fromRGB(190, 80, 255) } },
}

local trailPage = addTab("Trail")

-- left: preset list
local presetList = new("ScrollingFrame", {
	BackgroundColor3 = C.bg, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(0, 170, 1, -12),
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
}, trailPage)
new("UIListLayout", { Padding = UDim.new(0, 0) }, presetList)

-- right: details + settings
local trailScroll = scrollPage(trailPage, UDim2.fromOffset(184, 0), UDim2.new(1, -184, 1, 0))

local presetTitle = label(trailScroll, "", 14, C.accent, nil, UDim2.new(1, 0, 0, 20))
local presetDesc = label(trailScroll, "", 12, C.dim, nil, UDim2.new(1, 0, 0, 16))
local previewBar = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 14) }, trailScroll)
local previewGrad = new("UIGradient", {}, previewBar)

local function paletteSequence(colors)
	local pts = {}
	for i, col in ipairs(colors) do
		pts[#pts + 1] = ColorSequenceKeypoint.new((i - 1) / #colors, col)
	end
	pts[#pts + 1] = ColorSequenceKeypoint.new(1, colors[1])
	return ColorSequence.new(pts)
end

-- Theme: recolors every accent-colored element in the GUI
local function applyTheme(theme)
	local old = { C.accent, C.accentDark, C.line }
	local new_ = { theme.accent, theme.accentDark, theme.line }
	C.accent, C.accentDark, C.line = theme.accent, theme.accentDark, theme.line

	local function remap(col)
		for i = 1, 3 do
			if col == old[i] then return new_[i] end
		end
		return nil
	end

	for _, d in ipairs(gui:GetDescendants()) do
		if not d:IsDescendantOf(espContainer) and not d:IsDescendantOf(cpContainer) then
			if d:IsA("GuiObject") then
				local bg = remap(d.BackgroundColor3)
				if bg then d.BackgroundColor3 = bg end
				if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
					local tc = remap(d.TextColor3)
					if tc then d.TextColor3 = tc end
				end
				if d:IsA("ScrollingFrame") then
					local sc = remap(d.ScrollBarImageColor3)
					if sc then d.ScrollBarImageColor3 = sc end
				end
			elseif d:IsA("UIStroke") then
				local c = remap(d.Color)
				if c then d.Color = c end
			end
		end
	end
end

local function themeFromPalette(colors)
	-- pick the most vivid color in the palette and build accent / dark / line from its hue
	local bestH, bestS, bestScore = 0, 0.6, -1
	for _, col in ipairs(colors) do
		local h, s, v = col:ToHSV()
		local score = s * v
		if score > bestScore then
			bestScore, bestH, bestS = score, h, s
		end
	end
	local s = math.clamp(bestS, 0.4, 0.8)
	applyTheme({
		accent = Color3.fromHSV(bestH, s, 1),
		accentDark = Color3.fromHSV(bestH, s * 0.6, 0.45),
		line = Color3.fromHSV(bestH, 0.35, 0.26),
	})
end

local presetButtons = {}
local function selectPreset(i)
	env.TrailPreset = i
	local p = PRESETS[i]
	if env.ThemeFollowsTrail then
		themeFromPalette(p[3])
	end
	presetTitle.Text = p[1]
	presetDesc.Text = p[2]
	previewGrad.Color = paletteSequence(p[3])
	for idx, b in ipairs(presetButtons) do
		local on = idx == i
		b.BackgroundColor3 = on and C.panel2 or C.bg
		b.TextColor3 = on and C.accent or C.dim
	end
end

for i, p in ipairs(PRESETS) do
	local b = new("TextButton", {
		BackgroundColor3 = C.bg, BorderSizePixel = 0, Font = FONT, TextSize = 13, TextColor3 = C.dim,
		Text = p[1], TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 26),
	}, presetList)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)
	presetButtons[i] = b
	connect(b.MouseButton1Click, function() selectPreset(i) end)
end

Section(trailScroll, "Trail")
Toggle(trailScroll, "Enabled", false, function(v) env.TrailEnabled = v end)

-- trail construction
local trailObjects = {}
local glowTrail, coreTrail
local trailAttachments = {} -- { a0, a1, widthMul }

local function applyWidth()
	for _, t in ipairs(trailAttachments) do
		local half = (env.TrailWidth * t.mul) / 2
		t.a0.Position = Vector3.new(0, half, 0)
		t.a1.Position = Vector3.new(0, -half, 0)
	end
end

local function makeTrail(part, widthMul, transparencyStart)
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailTop"
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailBottom"
	a1.Parent = part
	table.insert(trailAttachments, { a0 = a0, a1 = a1, mul = widthMul })

	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = env.TrailLifetime
	trail.MinLength = 0
	trail.MaxLength = 0
	trail.FaceCamera = true
	trail.LightEmission = env.TrailGlow
	trail.LightInfluence = 0
	trail.Texture = ""
	trail.Enabled = env.TrailEnabled
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.6, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, transparencyStart),
		NumberSequenceKeypoint.new(0.5, math.clamp(transparencyStart + 0.25, 0, 1)),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = part

	table.insert(trailObjects, a0)
	table.insert(trailObjects, a1)
	table.insert(trailObjects, trail)
	return trail
end

local function clearTrail()
	for _, o in ipairs(trailObjects) do
		if o and o.Parent then o:Destroy() end
	end
	table.clear(trailObjects)
	table.clear(trailAttachments)
	glowTrail, coreTrail = nil, nil
end

local function buildTrail(char)
	clearTrail()
	local part = char:WaitForChild("HumanoidRootPart", 10)
	if not part then return end
	glowTrail = makeTrail(part, 1.0, 0.35)
	coreTrail = makeTrail(part, 0.3, 0.15)
	applyWidth()
end

if LocalPlayer.Character then
	task.spawn(buildTrail, LocalPlayer.Character)
end
connect(LocalPlayer.CharacterAdded, function(char)
	buildTrail(char)
end)

-- palette sampling (loops smoothly)
local function samplePalette(colors, p)
	p = p % 1
	local n = #colors
	local x = p * n
	local i = math.floor(x)
	local f = x - i
	return colors[i % n + 1]:Lerp(colors[(i + 1) % n + 1], f)
end

local function gradient(colors, offset, whiteMix)
	local pts = {}
	local steps = 8
	local spread = env.TrailSpread
	for i = 0, steps do
		local t = i / steps
		local col = samplePalette(colors, offset - t * spread)
		if whiteMix > 0 then col = col:Lerp(Color3.new(1, 1, 1), whiteMix) end
		pts[#pts + 1] = ColorSequenceKeypoint.new(t, col)
	end
	return ColorSequence.new(pts)
end

local t0 = os.clock()
connect(RunService.RenderStepped, function()
	if not glowTrail or not glowTrail.Parent or not coreTrail then return end

	local enabled = env.TrailEnabled
	glowTrail.Enabled = enabled
	coreTrail.Enabled = enabled
	if not enabled then return end

	glowTrail.Lifetime = env.TrailLifetime
	coreTrail.Lifetime = env.TrailLifetime

	local colors = PRESETS[env.TrailPreset][3]
	local shift = (os.clock() - t0) * env.TrailSpeed
	glowTrail.LightEmission = env.TrailGlow
	coreTrail.LightEmission = env.TrailGlow * 0.6
	glowTrail.Color = gradient(colors, shift, 0)
	coreTrail.Color = gradient(colors, shift, 0.12) -- slightly lighter core, still colored
end)

Slider(trailScroll, "Lifetime (s)", 0.5, 20, 6, 1, function(v) env.TrailLifetime = v end)
Slider(trailScroll, "Width (studs)", 0.5, 20, 5, 1, function(v) env.TrailWidth = v; applyWidth() end)
Slider(trailScroll, "Flow Speed", 0, 1, 0.15, 2, function(v) env.TrailSpeed = v end)
Slider(trailScroll, "Color Spread", 0.05, 1, 0.35, 2, function(v) env.TrailSpread = v end)
Slider(trailScroll, "Glow (lower = truer color)", 0, 1, 0.3, 2, function(v) env.TrailGlow = v end)

selectPreset(1)

----------------------------------------------------------------
-- SETTINGS TAB
----------------------------------------------------------------
local setPage = addTab("Settings")
local setScroll = scrollPage(setPage)
Section(setScroll, "Interface")
Toggle(setScroll, "Theme follows trail preset", true, function(v)
	env.ThemeFollowsTrail = v
	if v then
		themeFromPalette(PRESETS[env.TrailPreset][3])
	else
		applyTheme(DEFAULT_THEME)
	end
end)
Note(setScroll, "RightShift hides / shows this window. Drag the title bar to move it.", 30)
Button(setScroll, "Unload GUI", function()
	if env.UtilityUnload then env.UtilityUnload() end
end)

----------------------------------------------------------------
-- Toggle key + unload
----------------------------------------------------------------
connect(UIS.InputBegan, function(input)
	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
	end
end)

env.UtilityUnload = function()
	env.VelocityChanger = false
	env.TrailEnabled = false
	env.HiddenESP = false
	env.CheckpointESP = false
	for _, c in ipairs(conns) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(conns)
	if env.VelocityConn then
		pcall(function() env.VelocityConn:Disconnect() end)
		env.VelocityConn = nil
	end
	clearTrail()
	espContainer:Destroy()
	gui:Destroy()
	env.UtilityUnload = nil
end

selectTab("Movement")
