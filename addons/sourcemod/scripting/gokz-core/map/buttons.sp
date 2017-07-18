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



// =========================  PUBLIC  ========================= //

void UpdateMapButtons()
{
	int entity = -1;
	char tempString[32];
	
	while ((entity = FindEntityByClassname(entity, "func_button")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", tempString, sizeof(tempString));
		
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
	
	TimerStart(activator, 0);
	OnStartButtonPress_VirtualButtons(activator, 0);
}

public void OnEndButtonPress(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	TimerEnd(activator, 0);
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
		int bonus = StringToInt(tempString);
		if (bonus > 0)
		{
			TimerStart(activator, bonus);
			OnStartButtonPress_VirtualButtons(activator, bonus);
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
		int bonus = StringToInt(tempString);
		if (bonus > 0)
		{
			TimerEnd(activator, bonus);
			OnEndButtonPress_VirtualButtons(activator, bonus);
		}
	}
} 