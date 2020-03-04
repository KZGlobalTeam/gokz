/*
	Categorises jumps into tiers based on their distance.
	Tier thresholds are loaded from a config.
*/



static float distanceTiers[JUMPTYPE_COUNT - 2][MODE_COUNT][DISTANCETIER_COUNT];



// =====[ PUBLIC ]=====

int GetDistanceTier(int jumpType, int mode, float distance, float offset = 0.0)
{
	// No tiers given for 'Invalid' jumps.
	if (jumpType == JumpType_Invalid || jumpType == JumpType_Fall || jumpType == JumpType_Other
		 || jumpType != JumpType_LadderJump && offset < -JS_MAX_NORMAL_OFFSET
		 || distance > JS_MAX_JUMP_DISTANCE)
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



// =====[ EVENTS ]=====

void OnMapStart_DistanceTiers()
{
	if (!LoadDistanceTiers())
	{
		SetFailState("Failed to load file: \"%s\".", JS_CFG_TIERS);
	}
}



// =====[ PRIVATE ]=====

static bool LoadDistanceTiers()
{
	KeyValues kv = new KeyValues("tiers");
	if (!kv.ImportFromFile(JS_CFG_TIERS))
	{
		return false;
	}
	
	// It's a bit of a hack to exclude non-tiered jumptypes
	for (int jumpType = 1; jumpType < sizeof(gC_JumpTypeKeys) - 2; jumpType++)
	{
		if (!kv.JumpToKey(gC_JumpTypeKeys[jumpType]))
		{
			return false;
		}
		for (int mode = 0; mode < MODE_COUNT; mode++)
		{
			if (!kv.JumpToKey(gC_ModeKeys[mode]))
			{
				return false;
			}
			for (int tier = DistanceTier_Meh; tier < DISTANCETIER_COUNT; tier++)
			{
				distanceTiers[jumpType][mode][tier] = kv.GetFloat(gC_DistanceTierKeys[tier]);
			}
			kv.GoBack();
		}
		kv.GoBack();
	}
	delete kv;
	return true;
}
