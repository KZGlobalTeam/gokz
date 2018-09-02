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
	if (!StrEqual("func_button", tempString, false))
	{
		return;
	}
	
	if (GetEntPropString(entity, Prop_Data, "m_iName", tempString, sizeof(tempString)) > 0)
	{
		if (StrEqual("climb_startbutton", tempString, false))
		{
			HookSingleEntityOutput(entity, "OnPressed", OnStartButtonPress);
		}
		else if (StrEqual("climb_endbutton", tempString, false))
		{
			HookSingleEntityOutput(entity, "OnPressed", OnEndButtonPress);
		}
		else if (MatchRegex(RE_BonusStartButton, tempString) > 0)
		{
			HookSingleEntityOutput(entity, "OnPressed", OnBonusStartButtonPress);
		}
		else if (MatchRegex(RE_BonusEndButton, tempString) > 0)
		{
			HookSingleEntityOutput(entity, "OnPressed", OnBonusEndButtonPress);
		}
	}
}



// =========================  HANDLERS  ========================= //

public void OnStartButtonPress(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	GOKZ_StartTimer(activator, 0);
	OnStartButtonPress_VirtualButtons(activator, 0);
}

public void OnEndButtonPress(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	GOKZ_EndTimer(activator, 0);
	OnEndButtonPress_VirtualButtons(activator, 0);
}

public void OnBonusStartButtonPress(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator)) {
		return;
	}
	
	char tempString[32];
	GetEntPropString(caller, Prop_Data, "m_iName", tempString, sizeof(tempString));
	
	if (MatchRegex(RE_BonusStartButton, tempString) > 0)
	{
		GetRegexSubString(RE_BonusStartButton, 1, tempString, sizeof(tempString));
		int course = StringToInt(tempString);
		if (course > 0 && course < MAX_COURSES)
		{
			GOKZ_StartTimer(activator, course);
			OnStartButtonPress_VirtualButtons(activator, course);
		}
	}
}

public void OnBonusEndButtonPress(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	char tempString[32];
	GetEntPropString(caller, Prop_Data, "m_iName", tempString, sizeof(tempString));
	
	if (MatchRegex(RE_BonusEndButton, tempString) > 0)
	{
		GetRegexSubString(RE_BonusEndButton, 1, tempString, sizeof(tempString));
		int course = StringToInt(tempString);
		if (course > 0 && course < MAX_COURSES)
		{
			GOKZ_EndTimer(activator, course);
			OnEndButtonPress_VirtualButtons(activator, course);
		}
	}
} 