--------------------------
-->> Services
--------------------------

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

local UpdateChecker = require(script.Parent.UpdateChecker)

--------------------------
-->> CustomWidget
--------------------------

local PluginGUI = script.GUI

local WeldPanel, Background = PluginGUI:WaitForChild("WeldPanel"), PluginGUI:WaitForChild("Background")

local UX  = {}

for _, object in pairs(WeldPanel:GetChildren()) do
	UX[object.Name] = object
end

local WidgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right, 
	false, 
	true,
	510, 
	190,   
	510,  
	190
)

local PluginWidget = plugin:CreateDockWidgetPluginGui("WelderWidget", WidgetInfo)
PluginWidget.Title = "Welding Menu"

for _, object in pairs(PluginGUI:GetChildren()) do
	object.Parent = PluginWidget
end

--------------------------
-->> Plugin
--------------------------

local Toolbar = plugin:CreateToolbar("Welder")

local Welds_Button = Toolbar:CreateButton("welds_button", "Weld two or more parts together", "rbxassetid://7195857365", "Weld")
local Motor_Button = Toolbar:CreateButton("motor_button", "Create an editable Motor6D between two or more parts", "rbxassetid://7195857365", "Motor6D")

--------------------------
-->> Studio Colors
--------------------------

local Studio = settings().Studio
  
local Shadow  
local MainText
local MainButton
local MainBackground

--------------------------
-->> Values
--------------------------

local Mode = "WeldConstraint"

local ToWeld0    = {}
local ToWeld1    = {}
local WeldParent = nil

--------------------------
-->> GUI Functions
--------------------------

local function ToggleWidget(Button)
	--: Toggling enabled state of the widget
	
	if (Mode == Button and PluginWidget.Enabled) then
		PluginWidget.Enabled = false
	elseif (Mode == Button and not PluginWidget.Enabled) then
		PluginWidget.Enabled = true
	elseif (not PluginWidget.Enabled) then
		PluginWidget.Enabled = true
	end
	
	Mode = Button
	UX["Reference"].Text = Mode
	
	if (Mode == "WeldConstraint") then
		UX["Reference"].Text = "Weld"
	end
end


local function TextFeedback(Text)
	local originalColor = Text.TextColor3
	
	Text.TextColor3 = MainButton
	task.wait(.05)
	Text.TextColor3 = originalColor
end

--------------------------
-->> Welding Functions
--------------------------

UX["Reset"].MouseButton1Click:Connect(function()
	ToWeld0    = {}
	ToWeld1    = {}
	WeldParent = nil

	UX["Selected2"].Text = ""
	UX["Selected1"].Text = ""
	UX["Selected0"].Text = ""
end)

UX["Button0"].MouseButton1Click:Connect(function()
	local Selected = Selection:Get()
	local Warned   = false
	
	ToWeld0 = {}
	
	if (#Selected > 0) then
		WeldParent = Selected[1]
		UX["Selected2"].Text = WeldParent.Name
		
		for _, part in pairs(Selected) do
			if (part:IsA("BasePart")) then
				table.insert(ToWeld0, 1, part)
			else
				if (not Warned) then
					Warned = true
					warn("Welder: One or more selected Instances are not BaseParts.")
				end
			end
		end
	end
	
	local ConcatTable = {}

	for i = 1, #ToWeld0 do
		table.insert(ConcatTable, 1, ToWeld0[i].Name)
	end

	UX["Selected0"].Text = table.concat(ConcatTable, ", ")
	
	TextFeedback(UX["Reference"]) --: Feedback action
end)

UX["Button1"].MouseButton1Click:Connect(function()
	local Selected = Selection:Get()
	local Warned   = false
	
	ToWeld1 = {}
	
	if (#Selected > 0) then
		for _, part in pairs(Selected) do
			if (part:IsA("BasePart")) then
				table.insert(ToWeld1, 1, part)
			else
				if (not Warned) then
					Warned = true
					warn("Welder: One or more selected Instances are not BaseParts.")
				end
			end
		end
	end
	
	local ConcatTable = {}

	for i = 1, #ToWeld1 do
		table.insert(ConcatTable, 1, ToWeld1[i].Name)
	end

	UX["Selected1"].Text = table.concat(ConcatTable, ", ")
	
	TextFeedback(UX["Reference"]) --: Feedback action
end)

UX["Button2"].MouseButton1Click:Connect(function()
	local Selected = Selection:Get()
	
	WeldParent = nil
	
	if (#Selected == 1) then
		WeldParent = Selected[1]
		UX["Selected2"].Text = WeldParent.Name
	else
		warn("Welder: Selected number of parents is invalid. Please select only one.")
	end
	
	TextFeedback(UX["Reference"]) --: Feedback action
end)

UX["Confirm"].MouseButton1Click:Connect(function()
	--: Sanity Checks
	
	if (#ToWeld0 <= 0) then
		warn("Welder: No Part0 was selected.") return
	end
	
	if (#ToWeld1 <= 0) then
		warn("Welder: No Part1 was selected.") return
	end
	
	if (#ToWeld0 == 1 and #ToWeld1 == 1 and ToWeld0[1] == ToWeld1[1]) then
		warn("Welder: Can't weld a part to itself.")
	end
	
	-------------------------------------------------------------------------
	
	local Welds = {}

	ChangeHistoryService:SetWaypoint("Creating welds")
	
	for v0 = 1, #ToWeld0 do
		for v1 = 1, #ToWeld1 do
			local Weld = Instance.new(Mode)
			Weld.Part0 = ToWeld0[v0]
			Weld.Part1 = ToWeld1[v1]
			
			if (Weld:IsA("Motor6D")) then
				Weld.C0 = ToWeld1[v1].CFrame:ToObjectSpace(ToWeld0[v0].CFrame):Inverse()
			end
			
			Weld.Name  = Mode
			table.insert(Welds, 1, Weld)
		end
	end
	
	if (not WeldParent or WeldParent.Parent == nil) then
		warn("Welder: Selected parent does not longer exist.")
	end
	
	for i = 1, #Welds do
		Welds[i].Parent = WeldParent
	end
	
	Welds = {}
	
	-->> Text to indicate that the action was completed.
	
	UX["Completed"].TextTransparency = 1
	UX["Completed"].Visible = true
	
	for i = 1, 0, -.1 do
		UX["Completed"].TextTransparency = i
		task.wait()
	end
	
	task.wait(2)
	
	for i = 0, 1, .05 do
		UX["Completed"].TextTransparency = i
		task.wait()
	end
	
	UX["Completed"].TextTransparency = 0
	UX["Completed"].Visible = false
end)

local function syncGuiColors(objects)
	local function setColors()
		MainBackground = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
		MainButton     = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
		MainText       = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		Shadow         = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Dark)
		
		for _, ui_object in pairs(objects) do
			ui_object.BackgroundColor3 = MainBackground

			for _, ui in pairs(ui_object:GetDescendants()) do
				if (ui:IsA("Frame")) then
					ui.BackgroundColor3 = Shadow
				end
				
				if (ui:IsA("ImageButton")) then
					ui.ImageColor3 = MainButton
				end
				
				if (ui:IsA("TextButton") or ui:IsA("TextLabel")) then
					ui.TextColor3 = MainText
					ui.BackgroundColor3 = Shadow
				end
			end
		end
	end

	setColors()

	Studio.ThemeChanged:Connect(setColors)
end

syncGuiColors({Background, WeldPanel})

Welds_Button.Click:Connect(function() ToggleWidget("WeldConstraint") Welds_Button:SetActive(false) end)
Motor_Button.Click:Connect(function() ToggleWidget("Motor6D") Motor_Button:SetActive(false) end)

UpdateChecker()