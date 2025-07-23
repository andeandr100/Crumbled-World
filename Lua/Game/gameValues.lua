require("Tower/UpgradeData.lua")
require("Tower/supportManager.lua")
require("Game/campaignData.lua")

GameValues = {}
function GameValues.new()
	local self = {}
	local language = Language()
	local campaignData = CampaignData.new()
	local files = campaignData.getMaps()
	local campaingConfig = Core.getGlobalBillboard("MapInfo")
	
	-- function:	add
	-- purpose:
	function self.add(value1, value2)
		return value1 + value2
	end
	-- function:	mul
	-- purpose:
	function self.mul(value1, value2)
		return value1 * value2
	end
	
	-- function:	mul
	-- purpose:
	function self.set(value1, value2)
		return value2
	end
	
	function self.getMapIndex(filePath)
		for i=1, #files do	
			local file = files[i].file
			if file:isFile() and file:getPath()==filePath then
				return i
			end
		end
		return 0
	end
	
	function self.getStoreGroupNames()
		return {"Passiv", "MinigunTower", "ArrowTower","SwarmTower", "ElectricTower", "BladeTower", "MissileTower", "QuakerTower", "SupportTower", "BankTower"}
	end
	
	
	local campaingDataConfig = Config("CampaignData")			--the real data, used for the shop
	
	
	local damagePerEnergy = 19
	local towersContent = {
		["Passiv"] = {
			upgradeNames = {"boost", "slow", "comet"},
			boost={	
						name = "boost",
						displayName = "Tower Booster",
						toolTip = "tower.shop.Passiv.ability.tower-booster",
						info = "electric tower range",
						infoValues = {"damage", "range"},
						iconId = 1,
						level = 1,
						maxLevel = 3,
						stats = {damage =		{ 2,3,4, func = self.mul, suffix="%" },
								 range = 		{ 7,8,9, func = self.add, suffix="m" } }
					},
			slow={	
						name = "slow",
						displayName = "Slow field",
						toolTip = "tower.shop.Passiv.ability.slow-field",
						info = "electric tower range",
						infoValues = {"slow", "slowTimer"},
						iconId = 3,
						level = 1,
						maxLevel = 3,
						stats = {slow = 	{ 0.15, 0.28, 0.39, func = self.set, suffix="%"  },
								slowTimer = { 2.0, 2.0, 2.0, func = self.set, suffix="s" }}
					},
			comet={	
						name = "comet",
						displayName = "Comet",
						toolTip = "tower.shop.Passiv.ability.comet",
						info = "electric tower range",
						infoValues = {"range", "damage"},
						iconId = 2,
						level = 1,
						maxLevel = 3,
						stats = {range = 		{ 7,8,9, func = self.add, suffix="m"  },
								damage =		{ 0.6,0.7,0.8, func = self.mul, suffix="%"  } }
					}
		},
		["MinigunTower"] = {
			upgradeNames = {"upgrade", "overCharge", "overkill", "range"},
			upgrade={	cost = {200,400,800},
						name = "upgrade",
						displayName = "Upgrade",
						toolTip = "tower.shop.common.upgrade",
						info = "minigun tower level",
						infoValues = {"damage", "RPS", "range"},
						iconId = 56,
						level = 1,
						maxLevel = 3,
						stats = {
								range =		{ 5.0, 5.0, 5.0, suffix="m"  },
								damage = 	{ 115, 325, 405, suffix=" Dmg" },
								RPS = 		{ 2.5, 2.5, 5.0, suffix=" Aps" },
								rotationSpeed =	{ 1.2, 1.4, 1.6 },
								damageWeak = { 1.0, 1.0, 1.0 } }
					},
			boost={		cost = 0,
						name = "boost",
						displayName = "Boost",
						info = "minigun tower boost",
						duration = 10,
						cooldown = 3,
						iconId = 57,
						level = 0,
						maxLevel = 1,
						stats = {range = 		{ 0.75, func = self.add },
								damage =		{ 3, func = self.mul },
								RPS = 			{ 1.25, func = self.mul },
								rotationSpeed =	{ 2.5, func = self.mul } }
					},
			range = {	
						cost = {100,200,300},
						name = "range",
						displayName = "Range extension",
						toolTip = "tower.shop.common.range",
						info = "minigun tower range",
						infoValues = {"range"},
						iconId = 59,
						level = 0,
						maxLevel = 3,
						achievementName = "Range",
						stats = {range = { 0.75, 1.5, 2.25, func = self.add, suffix="m"  }}
					},
			overCharge = {	
						cost = {100,200,300},
						name = "overCharge",
						displayName = "Overcharge",
						toolTip = "tower.shop.MinigunTower.ability.overcharge",
						info = "minigun tower overcharge",
						infoValues = {"damage","overheat"},
						iconId = 63,
						level = 0,
						maxLevel = 3,
						stats = {	damage = 	{ 1.35, 1.7, 2.05, func = self.mul, suffix="%" },
									cooldown =	{ 10.0, 10.0, 10.0, func = self.set},
									overheat =	{ 13.0, 13.0, 13.0, func = self.set, suffix="s" } }
					},
			overkill = {	
						cost = {100,200,300},
						name = "overkill",
						displayName = "Overkill",
						toolTip = "tower.shop.MinigunTower.ability.overkill",
						info = "minigun tower overkill",
						infoValues = {"damageWeak"},
						iconId = 61,
						level = 0,
						maxLevel = 3,
						stats = { damageWeak = { 1.5, 2.0, 2.5, func = self.mul, suffix="%" } }
					}
		},
		["ArrowTower"] = {
			upgradeNames = {"upgrade", "hardArrow", "MarkOfDeath", "range"},
			upgrade = {	cost = {200,400,800},
						name = "upgrade",
						displayName = "Upgrade",
						toolTip = "tower.shop.common.upgrade",
						info = "Arrow tower level",
						infoValues = {"damage", "RPS", "range"},
						iconId = 56,
						level = 1,
						maxLevel = 3,
						stats = {
								range =		{ 9.0, 9.0, 9.0, suffix="m"  },
								damage = 	{ 360, 955, 1920, suffix=" Dmg" },
								RPS = 		{ 1.0/1.5, 1.0/1.3, 1.0/1.1, suffix=" Aps"},
								targetAngle =	{ math.pi*0.175, math.pi*0.175, math.pi*0.175 }  }
					},
			boost = {	cost = 0,
						name = "boost",
						displayName = "Boost",
						info = "minigun tower boost",
						duration = 10,
						cooldown = 3,
						iconId = 57,
						level = 0,
						maxLevel = 1,
						stats = {range = 			{ 1.5, func = self.add },
								damage =			{ 3, func = self.mul },
								detonationRange = 	{ 2.25, func = self.set } }
					},
			range = {	
						cost = {100,200,300},
						name = "range",
						displayName = "Range extension",
						toolTip = "tower.shop.common.range",
						info = "Arrow tower range",
						infoValues = {"range"},
						iconId = 59,
						level = 0,
						maxLevel = 3,
						achievementName = "Range",
						stats = {range = { 1.5, 3.0, 4.5, func = self.add, suffix="m" }}
					},
			hardArrow = {	
						cost = {100,200,300},
						name = "hardArrow",
						displayName = "Hard arrow",
						toolTip = "tower.shop.ArrowTower.ability.hard-arrow",
						info = "Arrow tower hardArrow",
						infoValues = {"damage", "RPS"},
						iconId = 71,
						level = 0,
						maxLevel = 3,
						achievementName = "HardArrow",
						stats = {RPS = { 0.5, 0.4, 0.3, func = self.mul, suffix="%" },
								damage = { 2.35, 3.4, 5.1, func = self.mul, suffix="%" }}
					},
			MarkOfDeath = {	
						cost = {100,200,300},
						name = "markOfDeath",
						displayName = "Mark of death",
						toolTip = "tower.shop.ArrowTower.ability.mark-of-death",
						info = "Arrow tower mark of death",
						infoValues = {"weakenValue"},
						iconId = 31,
						level = 0,
						maxLevel = 3,
						achievementName = "MarkOfDeath",
						stats = {weaken = { 0.08, 0.16, 0.24, func = self.set },
								weakenValue = { 8, 16, 24, func = self.set, suffix="%" },
								weakenTimer = { 5.0, 5.0, 5.0, func = self.set }}
					}
		
		},
		["SwarmTower"] = {
			upgradeNames = {"upgrade", "burnDamage", "range"},
			upgrade = {	cost = {200,400,800},
						name = "upgrade",
						displayName = "Upgrade",
						toolTip = "tower.shop.common.upgrade",
						info = "swarm tower level",
						infoValues = {"damage", "fireBall", "range"},
						iconId = 56,
						level = 1,
						maxLevel = 3,
						stats = {
								range =				{ 6.5, 6.5, 6.5, suffix="m" },
								damage = 			{ 120, 370, 890, suffix=" Dmg"},
								RPS = 				{ 1.0/2.25, 1.0/2.25, 1.0/2.25},
								fireBall =			{ 4, 6, 8 },
								fireballSpeed =		{ 5.5, 5.5, 5.5 },
								fireballLifeTime =	{ 13.0, 13.0, 13.0 },
								fieringTime =		{ 2.25, 2.25, 2.25 },
								targeting =			{ 1, 1, 1 },
								detonationRange =	{ 0.5, 1.0, 1.5 } }
					},
			boost = {	cost = 0,
						name = "boost",
						displayName = "Boost",
						info = "swarm tower boost",
						duration = 10,
						cooldown = 3,
						iconId = 57,
						level = 0,
						maxLevel = 1,
						stats = {range = 		{ 0.75, func = self.add },
								damage =		{ 3, func = self.mul },
								RPS = 			{ 2.0, func = self.mul } }
					},
			range = {	
						cost = {100,200,300},
						name = "range",
						displayName = "Range extension",
						toolTip = "tower.shop.common.range",
						info = "swarm tower range",
						infoValues = {"range"},
						iconId = 59,
						level = 0,
						maxLevel = 3,
						achievementName = "Range",
						stats = {range = { 0.75, 1.5, 2.25, func = self.add, suffix="m" }}
					},
			burnDamage = {	
						cost = {100,200,300},
						name = "burnDamage",
						displayName = "Heavy impact",
						toolTip = "tower.shop.SwarmTower.ability.heavy-impact",
						info = "swarm tower damage",
						infoValues = {"damage"},
						iconId = 2,
						level = 0,
						maxLevel = 3,
						achievementName = "burnDamage",
						stats = {damage = { 1.3, 1.6, 1.9, func = self.mul, suffix="%" }}
					}	
		},
		["ElectricTower"] = {
			upgradeNames = {"upgrade", "ampedSlow", "energyPool", "energy", "range"},
			upgrade = {	cost = {200,400,800},
						name = "upgrade",
						displayName = "Upgrade",
						toolTip = "tower.shop.common.upgrade",
						info = "electric tower level",
						infoValues = {"damage", "RPS", "energyMax", "energyReg", "range"},
						iconId = 56,
						level = 1,
						maxLevel = 3,
						stats = {range =	{ 4.0, 4.0, 4.0, suffix="m" },
								damage = 	{ 575*1.30, 1370*1.30, 2700*1.30, suffix=" Dmg" },
								minDamage = { 145, 340, 675 },
								RPS = 		{ 3.0/3.0, 4.0/3.0, 5.0/3.0, suffix=" Aps" },
								slow = 		{ 0.0, 0.0, 0.0},
								slowTimer = { 2.0, 2.0, 2.0},
								slowRange = { 0.0, 0.0, 0.0},
								attackCost ={ 575/damagePerEnergy, 1370/damagePerEnergy, 2700/damagePerEnergy },
								energyMax = { (575/damagePerEnergy)*10.0, (1370/damagePerEnergy)*10.0, (2700/damagePerEnergy)*10.0, suffix=" Mana"},
								energyReg =	{ (575/damagePerEnergy)*5/36*1.05, (575/damagePerEnergy)*6.5/36*1.05, (575/damagePerEnergy)*8/36*1.05, suffix=" Mana regen"},--0.021/g  [1.25 is just a magic number to increase regen]
								ERPS = 		{ ((575/damagePerEnergy)*5/36*1.05) / (575/damagePerEnergy), ((1370/damagePerEnergy)*6.5/36*1.05) / (1370/damagePerEnergy), ((2700/damagePerEnergy)*8/36*1.05) / (2700/damagePerEnergy)},
								equalizer =	{ 0.0, 0.0, 0.0} }
					},
			boost = {	cost = 0,
						name = "boost",
						displayName = "Boost",
						info = "electric tower boost",
						duration = 10,
						cooldown = 3,
						iconId = 57,
						level = 0,
						maxLevel = 1,
						stats = {range = 		{ 1.0, func = self.add },
								damage =		{ 2, func = self.mul },
								RPS = 			{ 1.5, func = self.mul },
								attackCost =	{ 0.0, func = self.set } }
					},
			ampedSlow = {	
						cost = {100,200,300},
						name = "ampedSlow",
						displayName = "Amped slow",
						toolTip = "tower.shop.ElectricTower.ability.amped-slow",
						info = "electric tower slow",
						infoValues = {"slow","slowRange", "damage", "RPS"},
						iconId = 55,
						level = 0,
						maxLevel = 3,
						stats = {slow =		{ 0.15, 0.28, 0.39, func = self.add, suffix="%"},
								damage =	{ 0.90, 0.81, 0.73, func = self.mul, suffix="%"},
								RPS =		{ 0.75, 0.56, 0.42, func = self.mul, suffix="%"},
								slowRange = { 0.75, 1.25, 1.75, func = self.add, suffix="m"} }
					},
			energyPool = {	
						cost = {100,200,300},
						name = "energyPool",
						displayName = "Energy pool",
						toolTip = "tower.shop.ElectricTower.ability.energy-pool",
						info = "electric tower energy pool",
						infoValues = {"energyMax"},
						iconId = 41,
						level = 0,
						maxLevel = 3,
						stats = {energyMax = { 1.30, 1.60, 1.90, func = self.mul, suffix="%" }}
					},
			energy = {	
						cost = {100,200,300},
						name = "energy",
						displayName = "Energy regeneration",
						toolTip = "tower.shop.ElectricTower.ability.energy-regeneration",
						info = "electric tower energy regen",
						infoValues = {"energyReg"},
						iconId = 50,
						level = 0,
						maxLevel = 3,
						stats = {energyReg ={ 1.15, 1.30, 1.45, func = self.mul, suffix="%"},
								ERPS =		{ 1.15, 1.30, 1.45, func = self.mul},
								equalizer =	{ 1.0, 1.0, 1.0, func = self.add} }
					},
			range = {	
						cost = {100,200,300},
						name = "range",
						displayName = "Range extension",
						toolTip = "tower.shop.common.range",
						info = "electric tower range",
						infoValues = {"range"},
						iconId = 59,
						level = 0,
						maxLevel = 3,
						achievementName = "Range",
						stats = {range = { 0.75, 1.5, 2.25, func = self.add, suffix="m" }}
					}
		
		},
		["BladeTower"] = {
			upgradeNames = {"upgrade", "attackSpeed", "electricBlade", "shieldBreaker", "range"},
			upgrade = {	cost = {200,400,800},
						name = "upgrade",
						displayName = "Upgrade",
						toolTip = "tower.shop.common.upgrade",
						info = "blade tower level",
						infoValues = {"damage", "RPS", "range"},
						iconId = 56,
						level = 1,
						maxLevel = 3,
						stats = {
								range =			{ 10.0, 10.0, 10.0, suffix="m" },
								damage = 		{ 150, 480, 1135, suffix=" Dmg"},
								RPS = 			{ 1.0/2.5, 1.0/2.5, 1.0/2.5, suffix=" Aps"},
								bladeSpeed =	{ 10.5, 10.5, 10.5 },
								shieldBypass =	{ 0.0, 0.0, 0.0 } }
					},
			boost = {	cost = 0,
						name = "boost",
						displayName = "Boost",
						info = "blade tower boost",
						duration = 10,
						cooldown = 3,
						iconId = 57,
						level = 0,
						maxLevel = 1,
						stats = {shieldBypass = { 1.0, func = self.add },
								damage =		{ 3, func = self.mul },
								RPS = 			{ 2.0, func = self.mul } }
					},
			range = {	
						cost = {100,200,300},
						name = "range",
						displayName = "Range extension",
						toolTip = "tower.shop.common.range",
						info = "blade tower range",
						infoValues = {"range"},
						iconId = 59,
						level = 0,
						maxLevel = 3,
						achievementName = "Range",
						stats = {range = { 1.5, 3.0, 4.5, func = self.add, suffix="m" }}
					},
			attackSpeed = {	
						cost = {100,200,300},
						name = "attackSpeed",
						displayName = "Attack speed",
						toolTip = "tower.shop.BladeTower.ability.attack-speed",
						info = "blade tower attackSpeed",
						infoValues = {"RPS"},
						iconId = 58,
						level = 0,
						maxLevel = 3,
						achievementName = "BladeSpeed",
						stats = {RPS = { 1.15, 1.3, 1.45, func = self.mul, suffix="%", }}
					},
			electricBlade = {	
						cost = {100,200,300},
						name = "electricBlade",
						displayName = "Amped slow",
						toolTip = "tower.shop.BladeTower.ability.amped-slow",
						info = "blade tower slow",
						infoValues = {"slow"},
						iconId = 55,
						level = 0,
						maxLevel = 3,
						achievementName = "ElectricBlade",
						stats = {slow = 	{ 0.20, 0.36, 0.49, func = self.set, suffix="%" },
								slowTimer = { 2.0, 2.0, 2.0, func = self.set }}
					},
			shieldBreaker = {	
						cost = {100},
						name = "shieldBreaker",
						displayName = "Shield breaker",
						toolTip = "tower.shop.BladeTower.ability.shield-breaker",
						info = "blade tower shield",
						infoValues = {},
						iconId = 40,
						level = 0,
						maxLevel = 1,
						achievementName = "shieldBreaker",
						stats = {shieldBypass = { 1, func = self.set }}
					}
		
		},
		["MissileTower"] = {
			upgradeNames = {"upgrade", "Blaster", "shieldSmasher", "range"},
			upgrade = {	cost = {200,400,800},
						name = "upgrade",
						displayName = "Upgrade",
						toolTip = "tower.shop.common.upgrade",
						info = "missile tower level",
						infoValues = {"damage", "RPS", "dmg_range", "range", "missile"},
						iconId = 56,
						level = 1,
						maxLevel = 3,
						stats = {
								range =				{ 7.0, 7.0, 7.0, suffix="m" },
								damage = 			{ 270, 570, 980, suffix=" Dmg"},
								RPS = 				{ 3.0/12.0, 4.0/12.0, 5.0/12.0, suffix=" Aps"},
								replaceTime =		{ 12, 12, 12 },
								fieringTime =		{ 1.25, 1.25, 1.25 },
								dmg_range =			{ 1.5, 1.75, 2.0, suffix="m" },
								missile = 			{ 3, 4, 5 },
								missileSpeed =		{ 7.0, 7.0, 7.0 },
								missileSpeedAcc =	{ 4.5, 4.5, 4.5 },
								shieldDamageMul =	{ 1.0, 1.0, 1.0 } }
					},
			boost = {	cost = 0,
						name = "boost",
						displayName = "Boost",
						info = "missile tower boost",
						duration = 10,
						cooldown = 3,
						iconId = 57,
						level = 0,
						maxLevel = 1,
						stats = {range = 			{ 1.0, func = self.add },
								damage =			{ 3, func = self.mul },
								dmg_range = 		{ 1.1, func = self.mul },
								missileSpeedAcc = 	{ 1.25, func = self.mul },
								fieringTime = 		{ -0.25, func = self.add },
								replaceTime = 		{ 0.5, func = self.mul } }
					},
			range = {	
						cost = {100,200,300},
						name = "range",
						displayName = "Range extension",
						toolTip = "tower.shop.common.range",
						info = "missile tower range",
						infoValues = {"range"},
						iconId = 59,
						level = 0,
						maxLevel = 3,
						achievementName = "Range",
						stats = {range = { 1.0, 2.0, 3.0, func = self.add, suffix="m" }}
					},
			Blaster = {	
						cost = {100,200,300},
						name = "Blaster",
						displayName = "High explosion",
						toolTip = "tower.shop.MissileTower.ability.high-explosion",
						info = "missile tower explosion",
						infoValues = {"damage", "dmg_range"},
						iconId = 39,
						level = 0,
						maxLevel = 3,
						achievementName = "Blaster",
						stats = {damage = { 1.08, 1.16, 1.24, func = self.mul, suffix="%" },
								dmg_range = { 1.08, 1.16, 1.24, func = self.mul, suffix="%" }}
					},
			shieldSmasher = {	
						cost = {200},
						name = "shieldSmasher",
						displayName = "Shield smasher",
						toolTip = "tower.shop.MissileTower.ability.shield-smasher",
						info = "missile tower shield destroyer",
						infoValues = {},
						iconId = 42,
						level = 0,
						maxLevel = 1,
						achievementName = "forcefieldSmasher",
						stats = { shieldDamageMul = { 3.0, func = self.mul } }
					}
		
		},
		["QuakerTower"] = {
			upgradeNames = {"upgrade", "fireCrit", "electricStrike"},
			upgrade = {	cost = {200,400,800},
						name = "upgrade",
						displayName = "Upgrade",
						toolTip = "tower.shop.common.upgrade",
						info = "quak tower level",
						infoValues = {"damage", "RPS", "range"},
						iconId = 56,
						level = 1,
						maxLevel = 3,
						stats = {
								range =				{ 2.75, 2.75, 2.75, suffix="m" },
								damage = 			{ 215, 580, 1200, suffix=" Dmg"},
								RPS = 				{ 0.28, 0.34, 0.4, suffix=" Aps"} }
					},
			boost = {	cost = 0,
						name = "boost",
						displayName = "Boost",
						info = "quak tower boost",
						duration = 10,
						cooldown = 3,
						iconId = 57,
						level = 0,
						maxLevel = 1,
						stats = {range = 		{ 0.4, func = self.add },
								damage =		{ 3, func = self.mul },
								RPS = 			{ 1.35, func = self.mul } }
					},
			fireCrit = {	
						cost = {100,200,300},
						name = "fireCrit",
						displayName = "High impact",
						toolTip = "tower.shop.QuakerTower.ability.firecrit",
						info = "quak tower firecrit",
						infoValues = {"damage"},
						iconId = 36,
						level = 0,
						maxLevel = 3,
						achievementName = "Range",
						stats = {damage = { 1.3, 1.6, 1.9, func = self.mul, suffix="%" }}
					},
			electricStrike = {	
						cost = {100,200,300},
						name = "electricStrike",
						displayName = "Amped slow",
						toolTip = "tower.shop.QuakerTower.ability.amped-slow",
						info = "quak tower electric",
						infoValues = {"damage","slow"},
						iconId = 50,
						level = 0,
						maxLevel = 3,
						achievementName = "ElectricStorm",
						stats = {damage = 	{ 1.3, 1.6, 1.9, func = self.mul, suffix="%" },
								slow = 		{ 0.15, 0.28, 0.39, func = self.set, suffix="%" },
								slowTimer = { 2.0, 2.0, 2.0, func = self.set },
								count = 	{ 7, 7, 7, func = self.set } }
					}
		
		},
		["SupportTower"] = {
			upgradeNames = {"upgrade", "weaken", "gold", "range"},
			upgrade = {	cost = {200,300,400},
						name = "upgrade",
						displayName = "Upgrade",
						toolTip = "tower.shop.SupportTower.upgrade",
						info = "support tower level",
						infoValues = {"supportDamage", "range"},
						iconId = 56,
						level = 1,
						maxLevel = 3,
						stats = { 	range =		  { 2.8, 2.8, 2.8, suffix="m" },
									supportDamage = { 10, 20, 30, suffix="%"}}
					},
			range = {	
						cost = {100,200,300},
						name = "range",
						displayName = "Range extender",
						toolTip = "tower.shop.SupportTower.ability.range-extender",
						info = "support tower range",
						infoValues = {"SupportRange"},
						iconId = 65,
						level = 0,
						maxLevel = 3,
						achievementName = "UpgradeSupportRange",
						stats = {SupportRange = { 10, 20, 30, func = self.set, suffix="%" }}
					},
			weaken = {	
						cost = {100,200,300},
						name = "weaken",
						displayName = "Weaken field",
						toolTip = "tower.shop.SupportTower.ability.weaken-field",
						info = "support tower weaken",
						infoValues = {"supportWeaken"},
						iconId = 66,
						level = 0,
						maxLevel = 3,
						achievementName = "UpgradeSupportMarkOfDeath",
						stats = {weaken =		{ 0.08, 0.16, 0.24, func = self.set},
								supportWeaken ={ 8, 16, 24, func = self.set, suffix="%"},
								weakenTimer =	{ 1, 1, 1, func = self.set} }
					},
			gold = {	
						cost = {100,200,300},
						name = "gold",
						displayName = "Gold area",
						toolTip = "tower.shop.SupportTower.ability.gold-area",
						info = "support tower gold",
						infoValues = {"supportGold"},
						iconId = 67,
						level = 0,
						maxLevel = 3,
						achievementName = "UpgradeSupportGold",
						stats = {supportGold =	{ 1, 2, 3, func = self.set, suffix=" Gold"} }
					}
		
		},
		["BankTower"] = {
			upgradeNames = {"upgrade", "gold"},
			upgrade = {	cost = {500,500,500},
						name = "upgrade",
						displayName = "Upgrade",
						toolTip = "tower.shop.common.upgrade",
						info = "bank tower level",
						infoValues = {"supportGoldPerWave", "range"},
						iconId = 56,
						level = 1,
						maxLevel = 3,
						stats = {
								range =					{ 2.8, 2.8, 2.8, suffix="m" },
								supportGoldPerWave = 	{ 50, 105, 160, suffix=" Gold"} }
					},
			gold = {	
						cost = {100,200,300},
						name = "gold",
						displayName = "Gold area",
						toolTip = "tower.shop.BankTower.ability.gold-area",
						info = "support tower gold",
						infoValues = {"supportGold"},
						iconId = 67,
						level = 0,
						maxLevel = 3,
						achievementName = "UpgradeSupportGold",
						stats = {supportGold =	{ 1, 2, 3, func = self.set, suffix=" Gold"} }
					}
		}	
		
	}
	
	function self.getUvCoordAndTextFromName(name)
		local toolTip = language:getText("towerToolTip."..name)
		if name=="damage" or name=="dmg" then
			return Vec2(0.25,0.0),Vec2(0.375,0.0625), toolTip
		elseif name=="RPS" then
			return Vec2(0.25,0.25),Vec2(0.375,0.3125), toolTip
		elseif name=="ERPS" then
			return Vec2(0.25,0.375),Vec2(0.375,0.4375), toolTip
		elseif name=="range" then
			return Vec2(0.375,0.4375),Vec2(0.5,0.5), toolTip
		elseif name=="slow" then
			return Vec2(0.875,0.375),Vec2(1.0,0.4375), toolTip
		elseif name=="bladeSpeed" then
			return Vec2(0.125,0.25),Vec2(0.25,0.3125), toolTip
		elseif name=="dmg_range" then
			return Vec2(0.875,0.25),Vec2(1.0,0.3125), toolTip
		elseif name=="supportDamage" then
			return Vec2(0.0,0.5),Vec2(0.125,0.5625), toolTip
		elseif name=="SupportRange" then
			return Vec2(0.125,0.5),Vec2(0.25,0.5625), toolTip
		elseif name=="weakenValue" then
			return Vec2(0.875,0.1875),Vec2(1.0,0.25), toolTip
		elseif name=="supportWeaken" then
			return Vec2(0.25,0.5),Vec2(0.375,0.5625), toolTip
		elseif name=="supportGold" then
			return Vec2(0.375,0.5),Vec2(0.5,0.5625), toolTip
		elseif name=="supportGoldPerWave" then
			return Vec2(0.75,0.5), Vec2(0.875, 0.5625), toolTip
		elseif name=="energyMax" then
			return Vec2(0.125,0.3125), Vec2(0.25, 0.375), toolTip
		elseif name=="energyReg" then
			return Vec2(0.25,0.375), Vec2(0.375, 0.4375), toolTip
		elseif name=="slowRange" then
			return Vec2(0.875,0.25),Vec2(1.0,0.3125), toolTip
		else
			return Vec2(0.0,0.25),Vec2(0.125,0.3125), toolTip
		end
	end
	
	function self.getCampaingTowerAbiliyLevel(towerName, abilityName)
		local groupConfig = campaingDataConfig:get(towerName)
		if groupConfig then
			return groupConfig:get(abilityName):getInt()
		end
		return 3
	end
	
	function self.isCampaingTowerAbiliyUnlocked(towerName, abilityName, abilityLevel)
		local groupConfig = campaingDataConfig:get(towerName)
		if groupConfig then
			return groupConfig:get(abilityName):getInt() >= abilityLevel
		end
		return false
	end
	
	function self.isTowerUnlocked(towerName)
		if towerName and campaingConfig:getBool("isCampaign") then
			local groupConfig = campaingDataConfig:get(towerName)
			if groupConfig then
				return groupConfig:get("upgrade"):getInt() >= 1
			end
		end
		return true
	end
	
	
	
	function self.getTowerValues(towerName)
		local towerData = towersContent[towerName]
		if towerData == nil then
			abort("data not found")
		end
		
		--load in campaign data
		local groupConfig = campaingDataConfig:get(towerName)
		for i=1, #towerData.upgradeNames do
			local abilityName = towerData.upgradeNames[i]
			towerData[abilityName].unlocked = groupConfig:get(abilityName):getInt()
		end
		
		return towerData
	end
	
	function self.getTowerAbilityValues(towerName, ability)
		local abilityData = towersContent[towerName][ability]
		if abilityData == nil then
			abort("data not found")
		end
		if campaingConfig:getBool("isCampaign") then
			abilityData.campaingUnlockedLevel = self.getCampaingTowerAbiliyLevel(towerName, ability)
		else
			abilityData.campaingUnlockedLevel = 100
		end
		return abilityData
	end
	
	function self.setUnlockedLevel(towerName, ability, unlockedLevel)
		campaingDataConfig:get(towerName):get(ability):setInt(unlockedLevel)
		campaingDataConfig:save()
		
	end
	
	function self.reloadConfig()
		campaingDataConfig = Config("CampaignData")
	end
	
	function self.saveConfig()
		campaingDataConfig:save()
	end
	
	function self.setSelectedMap(filePath)
		campaingDataConfig:get("SelectedMap"):get("mapPath"):setString(filePath)
		campaingDataConfig:save()
	end
	
	function self.setSelectedMapDifficulty(difficulty)
		campaingDataConfig:get("SelectedMap"):get("difficulty"):setInt(difficulty)
		campaingDataConfig:save()
	end
	
	function self.setSelectedMapGameMode(gameMode)
		campaingDataConfig:get("SelectedMap"):get("gameMode"):setInt(gameMode)
		campaingDataConfig:save()
	end
	
	function self.getSelectedMapGameMode()
		return campaingDataConfig:get("SelectedMap"):get("gameMode", 1):getInt()
	end
	
	function self.getSelectedMapDifficulty()
		return campaingDataConfig:get("SelectedMap"):get("difficulty", 1):getInt()
	end
	
	function self.getSelectedMap()
		return campaingDataConfig:get("SelectedMap"):exist("mapPath") and campaingDataConfig:get("SelectedMap"):get("mapPath"):getString() or nil
	end
	
	function self.setLevelCompleted(mapIndex)
		if mapIndex <= 0 or mapIndex > #files then
			return
		end
		
		local mapFile = files[mapIndex]
		
		local mapStatus = campaingDataConfig:get("maps"):get(mapFile.file:getName())
		if mapStatus:exist("playedAndWon") == false or mapStatus:get("playedAndWon"):getBool() ~= true then
			mapStatus:get("playedAndWon"):setBool(true)
			campaingDataConfig:save()
		end
	end
	
	
	function self.setMapUnLockedStatus(fileName, unlocked)
		local mapStatus = campaingDataConfig:get("maps"):get(fileName)
		if mapStatus:exist("unlocked") == false or mapStatus:get("unlocked"):getBool() ~= unlocked then
			mapStatus:get("unlocked"):setBool(unlocked)
			campaingDataConfig:save()
		end
	end
	
	function self.getMapStatus(fileName)
		local mapStatus = campaingDataConfig:get("maps"):get(fileName)
		return mapStatus:get("playedAndWon", false):getBool(), mapStatus:get("unlocked", false):getBool()
	end
	
	function self.getCrystals()
		return campaingDataConfig:get("crystal"):getInt()
	end
	
	function self.addCrystal( crystals )
		local crystalConf = campaingDataConfig:get("crystal")
		crystalConf:setInt( crystalConf:getInt() + crystals )
		campaingDataConfig:save()
	end
	
	function self.removeCrystal( crystals )
		local crystalConf = campaingDataConfig:get("crystal")
		crystalConf:setInt( crystalConf:getInt() - crystals )
		campaingDataConfig:save()
	end
	
	local function init()
		--Init default Values
		local groups = self.getStoreGroupNames()
		local saveConfig = false
		
		--ensure that the crystal counter is there
		if campaingDataConfig:exist("crystal") == false then
			campaingDataConfig:get("crystal"):setInt(0)
		end
		for n=1, #groups do
			local groupName = groups[n]
			if campaingDataConfig:exist(groupName) == false then
				local groupConfig = campaingDataConfig:get(groupName)
				local towerData = self.getTowerValues(groupName)
				for i=1, #towerData.upgradeNames do
					local abilityName = towerData.upgradeNames[i]
					saveConfig = true
					groupConfig:get(abilityName):setInt(0)
					--if it is one of the base tower se towers to be fully unlocked
					if abilityName == "upgrade" and ( groupName == "MinigunTower" or groupName == "ArrowTower" ) then
						groupConfig:get(abilityName):setInt(3)
					end
				end
			end
		end
		
		if saveConfig then
			campaingDataConfig:save()
		end
	end
	
	
	init()
	
	return self
end