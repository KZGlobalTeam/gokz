/*
	Mapping API - Buttons
	
	Hooks between func_buttons and GOKZ.
*/



static Regex RE_BonusStartButton;
static Regex RE_BonusEndButton;



// =========================  PUBLIC  ========================= //

void CreateRegexesMapButtons()
{
	RE_BonusStartButton = CompileRegex("^climb_bonus(\\d+)_startbutton$");
	RE_BonusEndButton = CompileRegex("^climb_bonus(\\d+)_endbutton$");
}



// =========================  LISTENERS  ========================= //

void OnEntitySpawned_MapButtons(int entity)
{
	char tempString[32];
	
	GetEntityClassname(entity, tempString, sizeof(tempString));
	if (!StrEqual("func_button", tempString))
	{
		return;
	}
	
	GetEntPropString(entity, Prop_Data, "m_iName", tempString, sizeof(tempString));
	if (StrEqual("climb_startbutton", tempString))
	{
		SDKHook(entity, SDKHook_UsePost, SDKHook_OnStartButtonPress);
	}
	else if (StrEqual("climb_endbutton", tempString))
	{
		SDKHook(entity, SDKHook_Use, SDKHook_OnEndButtonPress);
	}
	else if (MatchRegex(RE_BonusStartButton, tempString) > 0)
	{
		SDKHook(entity, SDKHook_UsePost, SDKHook_OnBonusStartButtonPress);
	}
	else if (MatchRegex(RE_BonusEndButton, tempString) > 0)
	{
		SDKHook(entity, SDKHook_UsePost, SDKHook_OnBonusEndButtonPress);
	}
}



// =========================  HANDLERS  ========================= //

public void SDKHook_OnStartButtonPress(int entity, int activator, int caller, UseType type, float value)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	TimerStart(activator, 0);
	OnStartButtonPress_VirtualButtons(activator, 0);
}

public void SDKHook_OnEndButtonPress(int entity, int activator, int caller, UseType type, float value)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	TimerEnd(activator, 0);
	OnEndButtonPress_VirtualButtons(activator, 0);
}

public void SDKHook_OnBonusStartButtonPress(int entity, int activator, int caller, UseType type, float value)
{
	if (!IsValidEntity(entity) || !IsValidClient(activator))
	{
		return;
	}
	
	char tempString[32];
	GetEntPropString(entity, Prop_Data, "m_iName", tempString, sizeof(tempString));
	if (MatchRegex(RE_BonusStartButton, tempString) > 0)
	{
		GetRegexSubString(RE_BonusStartButton, 1, tempString, sizeof(tempString));
		int course = StringToInt(tempString);
		if (course > 0 && course < MAX_COURSES)
		{
			TimerStart(activator, course);
			OnStartButtonPress_VirtualButtons(activator, course);
		}
	}
}

public void SDKHook_OnBonusEndButtonPress(int entity, int activator, int caller, UseType type, float value)
{
	if (!IsValidEntity(entity) || !IsValidClient(activator))
	{
		return;
	}
	
	char tempString[32];
	
	GetEntPropString(entity, Prop_Data, "m_iName", tempString, sizeof(tempString));
	if (MatchRegex(RE_BonusEndButton, tempString) > 0)
	{
		GetRegexSubString(RE_BonusEndButton, 1, tempString, sizeof(tempString));
		int course = StringToInt(tempString);
		if (course > 0 && course < MAX_COURSES)
		{
			TimerEnd(activator, course);
			OnEndButtonPress_VirtualButtons(activator, course);
		}
	}
} 