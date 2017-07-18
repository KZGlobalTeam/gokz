/*
	Modes
	
	Support for plugin-based movement modes.
*/



static bool modeLoaded[MODE_COUNT];
static bool GOKZHitPerf[MAXPLAYERS + 1];
static float GOKZTakeoffSpeed[MAXPLAYERS + 1];



// =========================  PUBLIC  ========================= //

bool GetModeLoaded(int mode)
{
	return modeLoaded[mode];
}

void SetModeLoaded(int mode, bool loaded)
{
	modeLoaded[mode] = loaded;
}

int GetLoadedModeCount()
{
	int count = 0;
	for (int i = 0; i < MODE_COUNT; i++)
	{
		if (modeLoaded[i])
		{
			count++;
		}
	}
	return count;
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



// =========================  LISTENERS  ========================= //

public void OnPlayerSpawn_Modes(int client)
{
	GOKZHitPerf[client] = false;
	GOKZTakeoffSpeed[client] = 0.0;
} 