/*
	Hooks between specifically named func_buttons and GOKZ.
*/



static Regex RE_BonusStartButton;
static Regex RE_BonusEndButton;



// =====[ EVENTS ]=====

void OnPluginStart_MapButtons()
{
	RE_BonusStartButton = CompileRegex(GOKZ_BONUS_START_BUTTON_NAME_REGEX);
	RE_BonusEndButton = CompileRegex(GOKZ_BONUS_END_BUTTON_NAME_REGEX);
}

void OnEntitySpawned_MapButtons(int entity)
{
	char buffer[32];
	
	GetEntityClassname(entity, buffer, sizeof(buffer));
	if (!StrEqual("func_button", buffer, false))
	{
		return;
	}
	
	if (GetEntityName(entity, buffer, sizeof(buffer)) == 0)
	{
		return;
	}
	
	int course = 0;
	if (StrEqual(GOKZ_START_BUTTON_NAME, buffer, false))
	{
		HookSingleEntityOutput(entity, "OnPressed", OnStartButtonPress);
		RegisterCourseStart(course);
	}
	else if (StrEqual(GOKZ_END_BUTTON_NAME, buffer, false))
	{
		HookSingleEntityOutput(entity, "OnPressed", OnEndButtonPress);
		RegisterCourseEnd(course);
	}
	else if ((course = GetStartButtonBonusNumber(entity)) != -1)
	{
		HookSingleEntityOutput(entity, "OnPressed", OnBonusStartButtonPress);
		RegisterCourseStart(course);
	}
	else if ((course = GetEndButtonBonusNumber(entity)) != -1)
	{
		HookSingleEntityOutput(entity, "OnPressed", OnBonusEndButtonPress);
		RegisterCourseEnd(course);
	}
}

public void OnStartButtonPress(const char[] name, int caller, int activator, float delay)
{
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	if (GOKZ_StartTimer(activator, 0))
	{
		// Only called on success to prevent virtual button exploits
		OnStartButtonPress_VirtualButtons(activator, 0);
	}
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
	if (!IsValidEntity(caller) || !IsValidClient(activator))
	{
		return;
	}
	
	int course = GetStartButtonBonusNumber(caller);
	if (GOKZ_IsValidCourse(course, true))
	{
		if (GOKZ_StartTimer(activator, course))
		{
			// Only called on success to prevent virtual button exploits
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
	
	int course = GetEndButtonBonusNumber(caller);
	if (GOKZ_IsValidCourse(course, true))
	{
		GOKZ_EndTimer(activator, course);
		OnEndButtonPress_VirtualButtons(activator, course);
	}
}



// =====[ PRIVATE ]=====

static int GetStartButtonBonusNumber(int entity)
{
	return MatchIntFromEntityName(entity, RE_BonusStartButton, 1);
}

static int GetEndButtonBonusNumber(int entity)
{
	return MatchIntFromEntityName(entity, RE_BonusEndButton, 1);
} 