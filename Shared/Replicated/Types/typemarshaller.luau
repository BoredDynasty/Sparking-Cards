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
	affinity: number, -- skill points
	skills: { string: boolean },
	level: Rank,
	experience: number,
	last_login: number,
	equipped_card: string,
	victories: number,
	options: {
		[string]: any,
	},
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
		[string]: any,
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

export type Rank =
	"Bronze I"
	| "Iron II"
	| "Gold III"
	| "Platinum IV"
	| "Emerald V"
	| "Master VI"
	| "Elite VII"
	| "Ruby VIII"
	| "Prismatic IX"
	| "Sparking X"

export type Party = {
	party_id: string,
	leader_id: number,
	members: { number },
	settings: PartySettings,
	state: "idle" | "searching" | "in_match",

	-- instance methods
	AddMember: (self: Party, player_id: number) -> boolean,
	RemoveMember: (self: Party, player_id: number) -> boolean,
	SetSettings: (self: Party, settings: PartySettings) -> (),
	StartSearching: (self: Party) -> boolean,
	StopSearching: (self: Party) -> boolean,
	SetPartyState: (self: Party, state: "idle" | "searching" | "in_match") -> (),
	GenerateJoinCode: (self: Party) -> string,
	GenerateSpectateCode: (self: Party) -> string,
	Destroy: (self: Party) -> (),
}

-- matchmaking types
export type QueuePlayerInfo = {
	userId: number,
	start: number, -- unix timestamp
}

export type QueuePartyInfo = {
	party_id: string,
	leader: number,
	size: number,
	start: number,
}

export type QueueInfo = {
	players: { QueuePlayerInfo },
	parties: { QueuePartyInfo },
}

export type MatchInfo = {
	match_id: string,
	place_id: number,
	private_server_id: string?,
	access_code: string?,
	players: { number },
}

export type MatchmakingJoinResult = {
	success: boolean,
	message: string?,
}

-- party types & module signatures
export type PartySettings = {
	mode: "Solo" | "Duo" | "Squad",
	modifiers: { string },
	allow_spectators: boolean,
	friends_only: boolean,
}

export type PartyModule = {
	new: (leader_id: number) -> Party?,
	GetParties: () -> { Party },
	GetPartyForPlayer: (player_id: number) -> Party?,
	GetPartyById: (party_id: string) -> Party?,
	AddMember: (self: Party, player_id: number) -> boolean,
	RemoveMember: (self: Party, player_id: number) -> boolean,
	SetSettings: (self: Party, settings: PartySettings) -> (),
	StartSearching: (self: Party) -> boolean,
	StopSearching: (self: Party) -> boolean,
	Destroy: (self: Party) -> (),
	SetPartyState: (self: Party, state: "idle" | "searching" | "in_match") -> (),
}

export type MatchmakerModule = {
	JoinQueueForPlayer: (self: any, player: Player) -> boolean,
	LeaveQueueForPlayer: (self: any, player: Player) -> boolean,
	JoinQueueForParty: (self: any, party: Party) -> boolean,
	LeaveQueueForParty: (self: any, party: Party | string) -> boolean,
	GetQueueInfo: (self: any) -> QueueInfo,
}

export type OrionParameters = {
	mouse_postion: Vector2?,
	player_data: PlayerData?,
}

export type AttackType = "M1" | "Skill" | "Ultimate" | "Support"

export type AttackFunction = (Player, ...any) -> unknown
export type AttackModule = {
	GetMaxCombo: () -> number,
	moveset: {
		AttackType: AttackFunction,
	},
}

export type PlayerData = {
	player: Player,
	profile: Profile,
	current_card: string,
	combo_info: ComboData,
	shield_info: unknown,
	element_active: boolean, -- if we initialized the attack stuff
	element_singleton: any,
}

export type StyleModule = {
	model: Model,
	player: Player,

	grip_info: GripInfo,
	character: Model,
	_connections: { RBXScriptConnection },
	_hit_cache: { [Player]: number },
	_trail: Trail?,
	_can_hit: boolean,
}

export type ComboData = {
	CurrentCombo: number,
	LastHitTime: number,
	MaxCombo: number,
}

export type GripInfo = {
	offset: CFrame,
	joint: Motor6D?,
	model: Model,
	attachment: Attachment?,
	hand: "Left" | "Right",
}

return nil
