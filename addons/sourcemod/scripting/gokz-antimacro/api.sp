/*
	API
	
	GOKZ Antimacro plugin API.
*/



static Handle H_OnPlayerSuspected;



// =========================  FORWARDS  ========================= //

void CreateGlobalForwards()
{
	H_OnPlayerSuspected = CreateGlobalForward("GOKZ_AM_OnPlayerSuspected", ET_Ignore, Param_Cell, Param_Cell, Param_String);
}

void Call_OnPlayerSuspected(int client, AMReason reason, const char[] details)
{
	Call_StartForward(H_OnPlayerSuspected);
	Call_PushCell(client);
	Call_PushCell(reason);
	Call_PushString(details);
	Call_Finish();
}



// =========================  NATIVES  ========================= //

void CreateNatives()
{
	CreateNative("GOKZ_AM_GetSampleSize", Native_GetSampleSize);
	CreateNative("GOKZ_AM_GetHitPerf", Native_GetHitPerf);
	CreateNative("GOKZ_AM_GetPerfCount", Native_GetPerfCount);
	CreateNative("GOKZ_AM_GetPerfRatio", Native_GetPerfRatio);
	CreateNative("GOKZ_AM_GetJumpInputs", Native_GetJumpInputs);
	CreateNative("GOKZ_AM_GetAverageJumpInputs", Native_GetAverageJumpInputs);
	CreateNative("GOKZ_AM_GetPreJumpInputs", Native_GetPreJumpInputs);
	CreateNative("GOKZ_AM_GetPostJumpInputs", Native_GetPostJumpInputs);
}

public int Native_GetSampleSize(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return IntMin(gI_BhopCount[client], BHOP_SAMPLES);
}

public int Native_GetHitPerf(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int sampleSize = IntMin(GOKZ_AM_GetSampleSize(client), GetNativeCell(3));
	
	if (sampleSize == 0)
	{
		return 0;
	}
	
	bool[] perfs = new bool[sampleSize];
	SortByRecent(gB_BhopHitPerf[client], BHOP_SAMPLES, perfs, sampleSize, gI_BhopIndex[client]);
	SetNativeArray(2, perfs, sampleSize);
	return sampleSize;
}

public int Native_GetPerfCount(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int sampleSize = IntMin(GOKZ_AM_GetSampleSize(client), GetNativeCell(2));
	
	if (sampleSize == 0)
	{
		return 0;
	}
	
	bool[] perfs = new bool[sampleSize];
	GOKZ_AM_GetHitPerf(client, perfs, sampleSize);
	
	int perfCount = 0;
	for (int i = 0; i < sampleSize; i++)
	{
		if (perfs[i])
		{
			perfCount++;
		}
	}
	return perfCount;
}

public int Native_GetPerfRatio(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int sampleSize = IntMin(GOKZ_AM_GetSampleSize(client), GetNativeCell(2));
	
	if (sampleSize == 0)
	{
		return view_as<int>(0.0);
	}
	
	int perfCount = GOKZ_AM_GetPerfCount(client, sampleSize);
	return view_as<int>(float(perfCount) / float(sampleSize));
}

public int Native_GetJumpInputs(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int sampleSize = IntMin(GOKZ_AM_GetSampleSize(client), GetNativeCell(3));
	
	if (sampleSize == 0)
	{
		return 0;
	}
	
	int[] preJumpInputs = new int[sampleSize];
	SortByRecent(gI_BhopPreJumpInputs[client], BHOP_SAMPLES, preJumpInputs, sampleSize, gI_BhopIndex[client]);
	int[] postJumpInputs = new int[sampleSize];
	SortByRecent(gI_BhopPostJumpInputs[client], BHOP_SAMPLES, postJumpInputs, sampleSize, gI_BhopIndex[client]);
	
	int[] jumpInputs = new int[sampleSize];
	for (int i = 0; i < sampleSize; i++)
	{
		jumpInputs[i] = preJumpInputs[i] + postJumpInputs[i];
	}
	
	SetNativeArray(2, jumpInputs, sampleSize);
	return sampleSize;
}

public int Native_GetAverageJumpInputs(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int sampleSize = IntMin(GOKZ_AM_GetSampleSize(client), GetNativeCell(2));
	
	if (sampleSize == 0)
	{
		return view_as<int>(0.0);
	}
	
	int[] jumpInputs = new int[sampleSize];
	GOKZ_AM_GetJumpInputs(client, jumpInputs, sampleSize);
	
	int jumpInputCount = 0;
	for (int i = 0; i < sampleSize; i++)
	{
		jumpInputCount += jumpInputs[i];
	}
	return view_as<int>(float(jumpInputCount) / float(sampleSize));
}

public int Native_GetPreJumpInputs(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int sampleSize = IntMin(GOKZ_AM_GetSampleSize(client), GetNativeCell(3));
	
	if (sampleSize == 0)
	{
		return 0;
	}
	
	int[] preJumpInputs = new int[sampleSize];
	SortByRecent(gI_BhopPreJumpInputs[client], BHOP_SAMPLES, preJumpInputs, sampleSize, gI_BhopIndex[client]);
	SetNativeArray(2, preJumpInputs, sampleSize);
	return sampleSize;
}

public int Native_GetPostJumpInputs(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int sampleSize = IntMin(GOKZ_AM_GetSampleSize(client), GetNativeCell(3));
	
	if (sampleSize == 0)
	{
		return 0;
	}
	
	int[] postJumpInputs = new int[sampleSize];
	SortByRecent(gI_BhopPostJumpInputs[client], BHOP_SAMPLES, postJumpInputs, sampleSize, gI_BhopIndex[client]);
	SetNativeArray(2, postJumpInputs, sampleSize);
	return sampleSize;
} 