/*
	Distance Tiers
	
	Categorise jumps into tiers based on their distance.
	Tier thresholds are loaded from cfg/sourcemod/gokz/gokz-jumpstats-tiers.cfg
*/



#define TIERS_CFG_PATH "cfg/sourcemod/gokz/gokz-jumpstats-tiers.cfg"
#define LADDERJUMP_OFFSET_ALLOWANCE 2.0 // How much offset ladder jumps are allowed to have

static float distanceTiers[JUMPTYPE_COUNT - 2][MODE_COUNT][DISTANCETIER_COUNT];



// =========================  PUBLIC  ========================= //

int GetDistanceTier(int jumpType, int mode, float distance, float offset)
{
	// No tiers given for 'Invalid' jumps.
	if (jumpType == JumpType_Invalid || jumpType == JumpType_Fall || jumpType == JumpType_Other
		 || jumpType != JumpType_LadderJump && FloatAbs(offset) >= 0.01
		 || FloatAbs(offset) >= LADDERJUMP_OFFSET_ALLOWANCE)
	{
		// TODO Give a tier to "Other" jumps
		// TODO Give a tier to offset jumps
		return DistanceTier_None;
	}
	
	// Get highest tier distance that the jump beats
	int tier = DistanceTier_None;
	while (tier + 1 < DISTANCETIER_COUNT && distance >= GetDistanceTierDistance(jumpType, mode, tier + 1))
	{
		tier++;
	}
	
	return tier;
}

float GetDistanceTierDistance(int jumpType, int mode, int tier)
{
	return distanceTiers[jumpType][mode][tier];
}



// =========================  LISTENERS  ========================= //

void OnMapStart_DistanceTiers()
{
	if (!LoadDistanceTiers())
	{
		SetFailState("Invalid or missing %s", TIERS_CFG_PATH);
	}
}



// =========================  PRIVATE  ========================= //

static bool LoadDistanceTiers()
{
	KeyValues kv = new KeyValues("tiers");
	if (!kv.ImportFromFile(TIERS_CFG_PATH))
	{
		return false;
	}
	
	for (int jumpType = 0; jumpType < JUMPTYPE_COUNT - 2; jumpType++)
	{
		if (!kv.JumpToKey(gC_KeysJumpType[jumpType]))
		{
			return false;
		}
		for (int mode = 0; mode < MODE_COUNT; mode++)
		{
			if (!kv.JumpToKey(gC_KeysMode[mode]))
			{
				return false;
			}
			for (int tier = 0; tier < DISTANCETIER_COUNT; tier++)
			{
				distanceTiers[jumpType][mode][tier] = kv.GetFloat(gC_KeysDistanceTier[tier]);
			}
			kv.GoBack();
		}
		kv.GoBack();
	}
	delete kv;
	return true;
} 