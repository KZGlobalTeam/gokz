static ConVar CV_EnableDemofix;
static Handle H_DemofixTimer;
static bool mapRunning;

void OnPluginStart_Demofix()
{
	AddCommandListener(Command_Demorestart, "demorestart");
	CV_EnableDemofix = AutoExecConfig_CreateConVar("gokz_demofix", "1", "Whether GOKZ applies demo record fix to server. (0 = Disabled, 1 = Update warmup period once, 2 = Regularly reset warmup period)", _, true, 0.0, true, 2.0);
	CV_EnableDemofix.AddChangeHook(OnDemofixConVarChanged);
	// If the map is tweaking the warmup value, we need to rerun the fix again.
	FindConVar("mp_warmuptime").AddChangeHook(OnDemofixConVarChanged);
	// We assume that the map is already loaded on late load.
	if (gB_LateLoad)
	{
		mapRunning = true;
	}
}

void OnMapStart_Demofix()
{
	mapRunning = true;
}

void OnMapEnd_Demofix()
{
	mapRunning = false;
}

void OnRoundStart_Demofix()
{
	DoDemoFix();
}

public Action Command_Demorestart(int client, const char[] command, int argc)
{
	FixRecord(client);
}

static void FixRecord(int client)
{
	// For some reasons, demo playback speed is absolute trash without a round_start event.
	// So whenever the client starts recording a demo, we create the event and send it to them.
	Event e = CreateEvent("round_start", true);
	int timelimit = FindConVar("mp_timelimit").IntValue;
	e.SetInt("timelimit", timelimit);
	e.SetInt("fraglimit", 0);
	e.SetString("objective", "demofix");

	e.FireToClient(client);
	delete e;
}

public void OnDemofixConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	DoDemoFix();
}

public Action Timer_EnableDemoRecord(Handle timer)
{
	EnableDemoRecord();
	return Plugin_Continue;
}

static void DoDemoFix()
{
	if (H_DemofixTimer != null)
	{
		delete H_DemofixTimer;
	}
	// Setting the cvar value to 1 can avoid clogging the demo file and slightly increase performance.
	switch (CV_EnableDemofix.IntValue)
	{
		case 0:
		{
			if (!mapRunning)
			{
				return;
			}

			GameRules_SetProp("m_bWarmupPeriod", 0);
		}
		case 1:
		{
			// Set warmup time to 2^31-1, effectively forever
			if (FindConVar("mp_warmuptime").IntValue != 2147483647)
			{
				FindConVar("mp_warmuptime").SetInt(2147483647);
			}
			EnableDemoRecord();
		}
		case 2:
		{
			H_DemofixTimer = CreateTimer(1.0, Timer_EnableDemoRecord, _, TIMER_REPEAT);
		}
	}
}

static void EnableDemoRecord()
{
	// Enable warmup to allow demo recording
	// m_fWarmupPeriodEnd is set in the past to hide the timer UI
	if (!mapRunning)
	{
		return;
	}
	GameRules_SetProp("m_bWarmupPeriod", 1);
	GameRules_SetPropFloat("m_fWarmupPeriodStart", GetGameTime() - 1.0);
	GameRules_SetPropFloat("m_fWarmupPeriodEnd", GetGameTime() - 1.0);
}