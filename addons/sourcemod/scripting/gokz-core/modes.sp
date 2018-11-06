static bool modeLoaded[MODE_COUNT];
static int modeVersion[MODE_COUNT];
static bool GOKZHitPerf[MAXPLAYERS + 1];
static float GOKZTakeoffSpeed[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

bool GetModeLoaded(int mode)
{
	return modeLoaded[mode];
}

int GetModeVersion(int mode)
{
	return modeLoaded[mode] ? modeVersion[mode] : -1;
}

void SetModeLoaded(int mode, bool loaded, int version = -1)
{
	if (!modeLoaded[mode] && loaded)
	{
		modeLoaded[mode] = true;
		modeVersion[mode] = version;
		Call_GOKZ_OnModeLoaded(mode);
	}
	else if (modeLoaded[mode] && !loaded)
	{
		modeLoaded[mode] = false;
		Call_GOKZ_OnModeUnloaded(mode);
	}
}

int GetLoadedModeCount()
{
	int count = 0;
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		if (modeLoaded[mode])
		{
			count++;
		}
	}
	return count;
}

int GetALoadedMode()
{
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		if (GOKZ_GetModeLoaded(mode))
		{
			return mode;
		}
	}
	return -1; // Uh-oh
}

bool GetGOKZHitPerf(int client)
{
	return GOKZHitPerf[client];
}

void SetGOKZHitPerf(int client, bool hitPerf)
{
	GOKZHitPerf[client] = hitPerf;
}

float GetGOKZTakeoffSpeed(int client)
{
	return GOKZTakeoffSpeed[client];
}

void SetGOKZTakeoffSpeed(int client, float takeoffSpeed)
{
	GOKZTakeoffSpeed[client] = takeoffSpeed;
}



// =====[ EVENTS ]=====

void OnAllPluginsLoaded_Modes()
{
	if (GetLoadedModeCount() <= 0)
	{
		SetFailState("At least one GOKZ mode plugin is required.");
	}
}

void OnPlayerSpawn_Modes(int client)
{
	GOKZHitPerf[client] = false;
	GOKZTakeoffSpeed[client] = 0.0;
}

void OnOptionChanged_Mode(int client, Option option)
{
	if (option == Option_Mode)
	{
		// Remove speed when switching modes
		Movement_SetVelocityModifier(client, 1.0);
		Movement_SetVelocity(client, view_as<float>( { 0.0, 0.0, 0.0 } ));
	}
} 