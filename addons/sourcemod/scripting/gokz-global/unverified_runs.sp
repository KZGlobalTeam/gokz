/*
	Keeps runs finished before the player is globally verified, and sends them once they are.
*/



enum struct UnverifiedRun
{
	int mapID;
	char map[64];
	int course;
	int mode;
	float time;
	int teleportsUsed;
	char replayPath[PLATFORM_MAX_PATH]; // temporary, deleted once uploaded or dropped
}

static ArrayList unverifiedRuns[MAXPLAYERS + 1];

// =====[ PUBLIC ]=====

void KeepUnverifiedRun(int client, int course, int mode, float time, int teleportsUsed)
{
	UnverifiedRun run;
	run.mapID = gI_MapID;
	strcopy(run.map, sizeof(UnverifiedRun::map), gC_CurrentMap);
	run.course = course;
	run.mode = mode;
	run.time = time;
	run.teleportsUsed = teleportsUsed;
	if (unverifiedRuns[client] == null)
	{
		unverifiedRuns[client] = new ArrayList(sizeof(UnverifiedRun));
	}
	else if (unverifiedRuns[client].Length == GL_MAX_UNVERIFIED_RUNS)
	{
		LogMessage("Dropped the oldest of %d runs kept for %L.", GL_MAX_UNVERIFIED_RUNS, client);
		DeleteUnverifiedReplay(client, 0);
		unverifiedRuns[client].Erase(0);
	}
	unverifiedRuns[client].PushArray(run);
	gI_UnverifiedUserID[client] = GetClientUserId(client);
}

// The replay is saved a breather after its run ended, so it's usually for the last kept run
bool KeepUnverifiedReplay(int client, const char[] map, int course, int timeType, float time, const char[] replayPath)
{
	if (unverifiedRuns[client] == null)
	{
		return false;
	}

	UnverifiedRun run;
	for (int i = unverifiedRuns[client].Length - 1; i >= 0; i--)
	{
		unverifiedRuns[client].GetArray(i, run);
		if (StrEqual(run.map, map) && run.course == course && GOKZ_GetTimeTypeEx(run.teleportsUsed) == timeType && run.time == time
			&& run.replayPath[0] == '\0')
		{
			strcopy(run.replayPath, sizeof(UnverifiedRun::replayPath), replayPath);
			unverifiedRuns[client].SetArray(i, run);
			return true;
		}
	}
	return false;
}

bool HasUnverifiedRuns(int client)
{
	return unverifiedRuns[client] != null;
}

// One at a time, continued by SendTimeCallback, so a backlog doesn't reach the API all at once
void SendNextUnverifiedRun(int client)
{
	UnverifiedRun run;
	while (unverifiedRuns[client] != null)
	{
		unverifiedRuns[client].GetArray(0, run);
		unverifiedRuns[client].Erase(0);
		if (unverifiedRuns[client].Length == 0)
		{
			delete unverifiedRuns[client];
		}
		if (SendTime(client, run.mapID, run.map, run.course, run.mode, run.time, run.teleportsUsed, true, run.replayPath))
		{
			return;
		}
	}
}

void DiscardUnverifiedRuns(int client)
{
	if (unverifiedRuns[client] == null)
	{
		return;
	}

	for (int i = 0; i < unverifiedRuns[client].Length; i++)
	{
		DeleteUnverifiedReplay(client, i);
	}
	delete unverifiedRuns[client];
}

// =====[ PRIVATE ]=====

static void DeleteUnverifiedReplay(int client, int index)
{
	UnverifiedRun run;
	unverifiedRuns[client].GetArray(index, run);
	if (run.replayPath[0] != '\0')
	{
		DeleteFile(run.replayPath);
	}
}
