--!strict

-- typemarshaller.luau

export type ReceiptInfo = {
	PlayerId: number,
	PlaceIdWherePurchased: number,
	PurchaseId: string,
	ProductId: number,
	-- deprecated
	CurrencyType: Enum.CurrencyType,
	CurrencySpent: number,
}

export type Product = {
	[string]: {
		Name: string,
		Details: string,
		Id: number,
		Cost: number,
		Callback: (...unknown) -> ...unknown,
	},
}

export type ProductInfo = {
	Name: string,
	Description: string,
	PriceInRobux: number,
	ProductId: number,
	ProductType: string,
	--[[
      ISO 6801
   ]]
	Created: string,
	--[[
      ISO 6801
   ]]
	Updated: string,
	ContentRatingTypeId: number,
	MinimumMembershipLevel: number,
	IsPublicDomain: boolean,
	TargetId: number,
}

-- combat

export type ProjectileConfig = {
	direction: Vector3,
	projectile: BasePart?,
	speed: number?,
	gravity: Vector3?,
}

-- features

export type GlidingConfig = {
	speed: number?,
	down_force: number?,
	glider_model: Model?,
}

-- player related

export type Character = Model & {
	Humanoid: Humanoid & {
		HumanoidDescription: HumanoidDescription & {
			[string]: (AccessoryDescription | BodyPartDescription)?,
		},
		Animator: Animator,
	},
	HumanoidRootPart: BasePart,
	BodyColors: BodyColors,
	PrimaryPart: BasePart,
	Animate: LocalScript & {
		ScaleDampeningPercent: NumberValue,
		PlayEmote: BindableEvent,
		cheer: StringValue,
		climb: StringValue,
		dance: StringValue,
		dance2: StringValue,
		dance3: StringValue,
		fall: StringValue,
		idle: StringValue,
		jump: StringValue,
		laugh: StringValue,
		mood: StringValue,
		point: StringValue,
		pose: StringValue,
		run: StringValue,
		sit: StringValue,
		swim: StringValue,
		swimidle: StringValue,
		toollunge: StringValue,
		toolnone: StringValue,
		toolslash: StringValue,
		walk: StringValue,
		wave: StringValue,
	},
	Head: BasePart,
}

export type ProfileData = {
	cards: {
		string: number,
	},
	prisms: number,
	level: string,
	experience: number,
	last_login: number,
	equipped_card: string,
	victories: number,
	emotes: {
		{
			name: string,
			identification: number,
			-- add more fields if necessary
			-- e.g., description: string,
			--       rarity: string,
			--       etc.
		}
	},
	equipped_emotes: {
		string: any,
	},
	achievements: {
		{
			name: string,
			description: string,
			points: number,
		}
	},
	quests: {
		{
			name: string,
			description: string,
			inquirer_img: string | Instance, -- img id or a model
			progress: number,
			date_acquired: number, -- unix timestamp millis
			date_completed: number?,
			module: ModuleScript?,
		} -- another cyclic module dependency
	},
	products: {
		[number]: {
			id: number,
			reciept_info: ReceiptInfo,
			times_bought: {
				[string]: number, ---@type date format: unixtimestamp
			},
		},
	},
	keybinds: {
		string: number,
	},
}

export type Profile = {
	Data: ProfileData,
}

export type Quest = {
	name: string,
	description: string,
	inquirer_img: number | Instance, -- img id or a model
	progress: number,
	date_acquired: number, -- unix timestamp millis
	date_completed: number?,
	completed: boolean?,
	module: ModuleScript?,
}

export type LucideIcon = {
	IconName: string,
	Id: number,
	Url: string,
	ImageRectSize: Vector2,
	ImageRectOffset: Vector2,
}

return nil
