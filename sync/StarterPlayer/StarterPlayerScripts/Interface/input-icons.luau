--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local batch = require(ReplicatedStorage.Utility.batch)

-- input-icons.luau

local module_mt = setmetatable({}, {})

export type Icons = {
	[Enum.KeyCode | Enum.UserInputType]: string,
}

export type Device = {
	Keyboard: Icons,
	Gamepad: Icons,
}

local dark_icons = {
	Keyboard = {
		[Enum.KeyCode.A] = "rbxassetid://127980983969670",
		[Enum.KeyCode.B] = "rbxassetid://132826901781090",
		[Enum.KeyCode.C] = "rbxassetid://117066609339539",
		[Enum.KeyCode.D] = "rbxassetid://118764072178365",
		[Enum.KeyCode.E] = "rbxassetid://78502312238119",
		[Enum.KeyCode.F] = "rbxassetid://76246667526269",
		[Enum.KeyCode.G] = "rbxassetid://107263701124947",
		[Enum.KeyCode.H] = "rbxassetid://97888859001849",
		[Enum.KeyCode.I] = "rbxassetid://89520840212090",
		[Enum.KeyCode.J] = "rbxassetid://86123803109013",
		[Enum.KeyCode.K] = "rbxassetid://108144330322159",
		[Enum.KeyCode.L] = "rbxassetid://86725345233243",
		[Enum.KeyCode.M] = "rbxassetid://99470980266527",
		[Enum.KeyCode.N] = "rbxassetid://86132801084027",
		[Enum.KeyCode.O] = "rbxassetid://129303149188014",
		[Enum.KeyCode.P] = "rbxassetid://79427330258568",
		[Enum.KeyCode.Q] = "rbxassetid://132246897271996",
		[Enum.KeyCode.R] = "rbxassetid://79898342339834",
		[Enum.KeyCode.S] = "rbxassetid://85592222603585",
		[Enum.KeyCode.T] = "rbxassetid://121737669059586",
		[Enum.KeyCode.U] = "rbxassetid://97015308190487",
		[Enum.KeyCode.V] = "rbxassetid://133777911864442",
		[Enum.KeyCode.W] = "rbxassetid://107990292205150",
		[Enum.KeyCode.X] = "rbxassetid://96546213642905",
		[Enum.KeyCode.Y] = "rbxassetid://76997820063716",
		[Enum.KeyCode.Z] = "rbxassetid://132217417969921",

		[Enum.KeyCode.One] = "rbxassetid://105952178062127",
		[Enum.KeyCode.Two] = "rbxassetid://72798829598611",
		[Enum.KeyCode.Three] = "rbxassetid://74981451822001",
		[Enum.KeyCode.Four] = "rbxassetid://108243997920508",
		[Enum.KeyCode.Five] = "rbxassetid://108216411357279",
		[Enum.KeyCode.Six] = "rbxassetid://139673512464818",
		[Enum.KeyCode.Seven] = "rbxassetid://91825826713896",
		[Enum.KeyCode.Eight] = "rbxassetid://128333678786299",
		[Enum.KeyCode.Nine] = "rbxassetid://131934247434784",
		[Enum.KeyCode.Zero] = "rbxassetid://130512867051182",

		[Enum.KeyCode.LeftControl] = "rbxassetid://105852104162952",
		[Enum.KeyCode.RightControl] = "rbxassetid://105852104162952",
		[Enum.KeyCode.LeftShift] = "rbxassetid://134221092382990",
		[Enum.KeyCode.RightShift] = "rbxassetid://134221092382990",
		[Enum.KeyCode.LeftAlt] = "rbxassetid://77191326262010",
		[Enum.KeyCode.RightAlt] = "rbxassetid://77191326262010",
		[Enum.KeyCode.Tab] = "rbxassetid://102886153606985",
		[Enum.KeyCode.CapsLock] = "rbxassetid://126983676180347",
		[Enum.KeyCode.Backspace] = "rbxassetid://88701958987628",
		[Enum.KeyCode.KeypadEnter] = "rbxassetid://86849363836001",
		[Enum.KeyCode.Space] = "rbxassetid://127347084341397",
		[Enum.KeyCode.Tilde] = "rbxassetid://127341340387973",

		[Enum.KeyCode.Insert] = "rbxassetid://102263691782328",
		[Enum.KeyCode.Home] = "rbxassetid://129924584225896",
		[Enum.KeyCode.Delete] = "rbxassetid://112714906796757",
		[Enum.KeyCode.End] = "rbxassetid://85304476474721",
		[Enum.KeyCode.PageUp] = "rbxassetid://96984233189204",
		[Enum.KeyCode.PageDown] = "rbxassetid://96003766436423",
		[Enum.KeyCode.Minus] = "rbxassetid://121573319223773",
		[Enum.KeyCode.Plus] = "rbxassetid://104007330219818",
		[Enum.KeyCode.BackSlash] = "rbxassetid://136625505645381",
		[Enum.KeyCode.Question] = "rbxassetid://107797999389065",
		[Enum.KeyCode.LeftBracket] = "rbxassetid://75143868699631",
		[Enum.KeyCode.RightBracket] = "rbxassetid://120873805058394",
		[Enum.KeyCode.Semicolon] = "rbxassetid://111201823291067",
		[Enum.KeyCode.GreaterThan] = "rbxassetid://122365689869795",
		[Enum.KeyCode.LessThan] = "rbxassetid://103644203453151",
		[Enum.KeyCode.Escape] = "rbxassetid://88870028781226",

		[Enum.KeyCode.Up] = "rbxassetid://118657268494396",
		[Enum.KeyCode.Right] = "rbxassetid://91161549690919",
		[Enum.KeyCode.Down] = "rbxassetid://80143776839577",
		[Enum.KeyCode.Left] = "rbxassetid://93589790398363",

		[Enum.UserInputType.MouseButton1] = "rbxassetid://106347604031645",
		[Enum.UserInputType.MouseButton2] = "rbxassetid://79573734300184",
		[Enum.UserInputType.MouseButton3] = "rbxassetid://138517865308665",
		[Enum.UserInputType.MouseWheel] = "rbxassetid://133380565547289",
	},
	Gamepad = {
		[Enum.KeyCode.ButtonL1] = "rbxassetid://86424254919520",
		[Enum.KeyCode.ButtonL2] = "rbxassetid://82652826840027",
		[Enum.KeyCode.ButtonL3] = "rbxassetid://99526545977048",
		[Enum.KeyCode.ButtonR1] = "rbxassetid://123971997746177",
		[Enum.KeyCode.ButtonR2] = "rbxassetid://104438871805053",
		[Enum.KeyCode.ButtonR3] = "rbxassetid://78640754630861",

		[Enum.KeyCode.ButtonA] = "rbxassetid://85014498129241",
		[Enum.KeyCode.ButtonB] = "rbxassetid://75083838842052",
		[Enum.KeyCode.ButtonX] = "rbxassetid://138203273595821",
		[Enum.KeyCode.ButtonY] = "rbxassetid://86066508051187",

		[Enum.KeyCode.DPadUp] = "rbxassetid://107488279351292",
		[Enum.KeyCode.DPadDown] = "rbxassetid://93154814600549",
		[Enum.KeyCode.DPadLeft] = "rbxassetid://124146897990290",
		[Enum.KeyCode.DPadRight] = "rbxassetid://117194004743792",

		[Enum.KeyCode.Menu] = "rbxassetid://83463538173924",
	},
}

local light_icons = {
	Keyboard = {
		[Enum.KeyCode.A] = "rbxassetid://122197956331720",
		[Enum.KeyCode.B] = "rbxassetid://138122784714462",
		[Enum.KeyCode.C] = "rbxassetid://112269350003032",
		[Enum.KeyCode.D] = "rbxassetid://138770271134688",
		[Enum.KeyCode.E] = "rbxassetid://94028859599068",
		[Enum.KeyCode.F] = "rbxassetid://131702503730277",
		[Enum.KeyCode.G] = "rbxassetid://121609794178479",
		[Enum.KeyCode.H] = "rbxassetid://77776651140874",
		[Enum.KeyCode.I] = "rbxassetid://140497731786838",
		[Enum.KeyCode.J] = "rbxassetid://117203215116082",
		[Enum.KeyCode.K] = "rbxassetid://71330849501285",
		[Enum.KeyCode.L] = "rbxassetid://123421292108228",
		[Enum.KeyCode.M] = "rbxassetid://104107625532068",
		[Enum.KeyCode.N] = "rbxassetid://84083241201481",
		[Enum.KeyCode.O] = "rbxassetid://73020316958982",
		[Enum.KeyCode.P] = "rbxassetid://99121299386961",
		[Enum.KeyCode.Q] = "rbxassetid://91464896711890",
		[Enum.KeyCode.R] = "rbxassetid://94018279031513",
		[Enum.KeyCode.S] = "rbxassetid://121874037539067",
		[Enum.KeyCode.T] = "rbxassetid://129958111247107",
		[Enum.KeyCode.U] = "rbxassetid://88457305542489",
		[Enum.KeyCode.V] = "rbxassetid://76969178950490",
		[Enum.KeyCode.W] = "rbxassetid://75632892950550",
		[Enum.KeyCode.X] = "rbxassetid://132550853335011",
		[Enum.KeyCode.Y] = "rbxassetid://117099617847608",
		[Enum.KeyCode.Z] = "rbxassetid://114788234784266",

		[Enum.KeyCode.One] = "rbxassetid://87214341748899",
		[Enum.KeyCode.Two] = "rbxassetid://114645597381949",
		[Enum.KeyCode.Three] = "rbxassetid://85894592416474",
		[Enum.KeyCode.Four] = "rbxassetid://71979637891316",
		[Enum.KeyCode.Five] = "rbxassetid://114630841984771",
		[Enum.KeyCode.Six] = "rbxassetid://80505193897332",
		[Enum.KeyCode.Seven] = "rbxassetid://128120858225085",
		[Enum.KeyCode.Eight] = "rbxassetid://95059347879780",
		[Enum.KeyCode.Nine] = "rbxassetid://117262205732075",
		[Enum.KeyCode.Zero] = "rbxassetid://140309253472983",

		[Enum.KeyCode.LeftControl] = "rbxassetid://125162600457608",
		[Enum.KeyCode.RightControl] = "rbxassetid://125162600457608",
		[Enum.KeyCode.LeftShift] = "rbxassetid://109762030406601",
		[Enum.KeyCode.RightShift] = "rbxassetid://109762030406601",
		[Enum.KeyCode.LeftAlt] = "rbxassetid://77209258271852",
		[Enum.KeyCode.RightAlt] = "rbxassetid://77209258271852",
		[Enum.KeyCode.Tab] = "rbxassetid://88381950166432",
		[Enum.KeyCode.CapsLock] = "rbxassetid://111108954866164",
		[Enum.KeyCode.Backspace] = "rbxassetid://71470915905257",
		[Enum.KeyCode.KeypadEnter] = "rbxassetid://82150526477450",
		[Enum.KeyCode.Space] = "rbxassetid://76685717738799",
		[Enum.KeyCode.Tilde] = "rbxassetid://117971562451317",

		[Enum.KeyCode.Insert] = "rbxassetid://81782876674611",
		[Enum.KeyCode.Home] = "rbxassetid://116068356061022",
		[Enum.KeyCode.Delete] = "rbxassetid://126463489514045",
		[Enum.KeyCode.End] = "rbxassetid://128593440255971",
		[Enum.KeyCode.PageUp] = "rbxassetid://123418308626632",
		[Enum.KeyCode.PageDown] = "rbxassetid://132249550976909",
		[Enum.KeyCode.Minus] = "rbxassetid://73640656237008",
		[Enum.KeyCode.Plus] = "rbxassetid://80670030842750",
		[Enum.KeyCode.BackSlash] = "rbxassetid://109108231279007",
		[Enum.KeyCode.Question] = "rbxassetid://75913352156542",
		[Enum.KeyCode.LeftBracket] = "rbxassetid://115165261997657",
		[Enum.KeyCode.RightBracket] = "rbxassetid://140704483217689",
		[Enum.KeyCode.Semicolon] = "rbxassetid://100731468717339",
		[Enum.KeyCode.GreaterThan] = "rbxassetid://94198052589693",
		[Enum.KeyCode.LessThan] = "rbxassetid://122332713899546",
		[Enum.KeyCode.Escape] = "rbxassetid://85446410190975",

		[Enum.KeyCode.Up] = "rbxassetid://108869827999882",
		[Enum.KeyCode.Right] = "rbxassetid://116165045478014",
		[Enum.KeyCode.Down] = "rbxassetid://112528724223853",
		[Enum.KeyCode.Left] = "rbxassetid://87090699654252",

		[Enum.UserInputType.MouseButton1] = "rbxassetid://102349916400213",
		[Enum.UserInputType.MouseButton2] = "rbxassetid://132175446041871",
		[Enum.UserInputType.MouseButton3] = "rbxassetid://89996528989274",
		[Enum.UserInputType.MouseWheel] = "rbxassetid://75215218440075",
	},
	Gamepad = {
		[Enum.KeyCode.ButtonL1] = "rbxassetid://86424254919520",
		[Enum.KeyCode.ButtonL2] = "rbxassetid://82652826840027",
		[Enum.KeyCode.ButtonL3] = "rbxassetid://99526545977048",
		[Enum.KeyCode.ButtonR1] = "rbxassetid://123971997746177",
		[Enum.KeyCode.ButtonR2] = "rbxassetid://104438871805053",
		[Enum.KeyCode.ButtonR3] = "rbxassetid://78640754630861",

		[Enum.KeyCode.ButtonA] = "rbxassetid://85014498129241",
		[Enum.KeyCode.ButtonB] = "rbxassetid://75083838842052",
		[Enum.KeyCode.ButtonX] = "rbxassetid://138203273595821",
		[Enum.KeyCode.ButtonY] = "rbxassetid://86066508051187",

		[Enum.KeyCode.DPadUp] = "rbxassetid://107488279351292",
		[Enum.KeyCode.DPadDown] = "rbxassetid://93154814600549",
		[Enum.KeyCode.DPadLeft] = "rbxassetid://124146897990290",
		[Enum.KeyCode.DPadRight] = "rbxassetid://117194004743792",

		[Enum.KeyCode.Menu] = "rbxassetid://83463538173924",
	},
}

batch(dark_icons)
batch(light_icons)

local function rawget_icons()
	local list = {}

	for device_type, icons in pairs(dark_icons :: { [Enum.UserInputType]: { [Enum.KeyCode]: string } }) do
		list[device_type] = {}

		for input_type, asset_id in pairs(icons) do
			list[device_type][input_type] = {
				Dark = dark_icons[device_type][input_type],
				Light = light_icons[device_type][input_type],
			}
		end
	end

	return list :: { [Enum.UserInputType]: { [Enum.KeyCode]: { Dark: string, Light: string } } }
end

module_mt.__index = {
	GetIcons = function(): { [Enum.UserInputType]: { [Enum.KeyCode]: { Dark: string, Light: string } } }
		return rawget_icons()
	end,
}

return module_mt
