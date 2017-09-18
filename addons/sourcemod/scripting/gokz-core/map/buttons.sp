/*
	Mapping API - Buttons
	
	Hooks between func_buttons and GOKZ.
	Not using HookSingleEntityOutput because it sometimes drops fails. Source: george.
	Not using SDKHooks because doesn't call when input is via trigger_multiple output.
	Credits to george.
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
	if (StrEqual("climb_startbutton", tempString)
		 || StrEqual("climb_endbutton", tempString)
		 || MatchRegex(RE_BonusStartButton, tempString) > 0
		 || MatchRegex(RE_BonusEndButton, tempString) > 0)
	{
		DHookEntity(gH_DHooks_OnAcceptInput, false, entity);
	}
}

void OnAcceptInput_MapButtons(int entity, Handle params)
{
	char tempString[32];
	
	// Check input type is "Use"/"use" or "Press"/"press"
	DHookGetParamString(params, 1, tempString, sizeof(tempString));
	if (!StrEqual(tempString, "Use", false) && !StrEqual(tempString, "Press", false))
	{
		return;
	}
	
	// Check entity and activator validity
	if (DHookIsNullParam(params, 2))
	{
		return;
	}
	int activator = DHookGetParam(params, 2);
	if (!IsValidEntity(entity) || !IsValidClient(activator))
	{
		return;
	}
	
	// Process button press
	GetEntPropString(entity, Prop_Data, "m_iName", tempString, sizeof(tempString));
	if (StrEqual("climb_startbutton", tempString))
	{
		TimerStart(activator, 0);
		OnStartButtonPress_VirtualButtons(activator, 0);
	}
	else if (StrEqual("climb_endbutton", tempString))
	{
		TimerEnd(activator, 0);
		OnEndButtonPress_VirtualButtons(activator, 0);
	}
	else if (MatchRegex(RE_BonusStartButton, tempString) > 0)
	{
		GetRegexSubString(RE_BonusStartButton, 1, tempString, sizeof(tempString));
		int course = StringToInt(tempString);
		if (course > 0 && course < MAX_COURSES)
		{
			TimerStart(activator, course);
			OnStartButtonPress_VirtualButtons(activator, course);
		}
	}
	else if (MatchRegex(RE_BonusEndButton, tempString) > 0)
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