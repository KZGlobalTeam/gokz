static GlobalForward H_OnTimeProcessed;
static GlobalForward H_OnNewRecord;
static GlobalForward H_OnRecordMissed;
static GlobalForward H_OnPBMissed;



// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnTimeProcessed = new GlobalForward("GOKZ_LR_OnTimeProcessed", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell);
	H_OnNewRecord = new GlobalForward("GOKZ_LR_OnNewRecord", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Float, Param_Cell);
	H_OnRecordMissed = new GlobalForward("GOKZ_LR_OnRecordMissed", ET_Ignore, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	H_OnPBMissed = new GlobalForward("GOKZ_LR_OnPBMissed", ET_Ignore, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
}

void Call_OnTimeProcessed(
	int client, 
	int steamID, 
	int mapID, 
	int course, 
	int mode, 
	int style, 
	float runTime, 
	int teleports, 
	bool firstTime, 
	float pbDiff, 
	int rank, 
	int maxRank, 
	bool firstTimePro, 
	float pbDiffPro, 
	int rankPro, 
	int maxRankPro)
{
	Call_StartForward(H_OnTimeProcessed);
	Call_PushCell(client);
	Call_PushCell(steamID);
	Call_PushCell(mapID);
	Call_PushCell(course);
	Call_PushCell(mode);
	Call_PushCell(style);
	Call_PushFloat(runTime);
	Call_PushCell(teleports);
	Call_PushCell(firstTime);
	Call_PushFloat(pbDiff);
	Call_PushCell(rank);
	Call_PushCell(maxRank);
	Call_PushCell(firstTimePro);
	Call_PushFloat(pbDiffPro);
	Call_PushCell(rankPro);
	Call_PushCell(maxRankPro);
	Call_Finish();
}

void Call_OnNewRecord(int client, int steamID, int mapID, int course, int mode, int style, int recordType, float pbDiff, int teleportsUsed)
{
	Call_StartForward(H_OnNewRecord);
	Call_PushCell(client);
	Call_PushCell(steamID);
	Call_PushCell(mapID);
	Call_PushCell(course);
	Call_PushCell(mode);
	Call_PushCell(style);
	Call_PushCell(recordType);
	Call_PushFloat(pbDiff);
	Call_PushCell(teleportsUsed);
	Call_Finish();
}

void Call_OnRecordMissed(int client, float recordTime, int course, int mode, int style, int recordType)
{
	Call_StartForward(H_OnRecordMissed);
	Call_PushCell(client);
	Call_PushFloat(recordTime);
	Call_PushCell(course);
	Call_PushCell(mode);
	Call_PushCell(style);
	Call_PushCell(recordType);
	Call_Finish();
}

void Call_OnPBMissed(int client, float pbTime, int course, int mode, int style, int recordType)
{
	Call_StartForward(H_OnPBMissed);
	Call_PushCell(client);
	Call_PushFloat(pbTime);
	Call_PushCell(course);
	Call_PushCell(mode);
	Call_PushCell(style);
	Call_PushCell(recordType);
	Call_Finish();
}



// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_LR_GetRecordMissed", Native_GetRecordMissed);
	CreateNative("GOKZ_LR_GetPBMissed", Native_GetPBMissed);
	CreateNative("GOKZ_LR_ReopenMapTopMenu", Native_ReopenMapTopMenu);
}

public int Native_GetRecordMissed(Handle plugin, int numParams)
{
	return view_as<int>(gB_RecordMissed[GetNativeCell(1)][GetNativeCell(2)]);
}

public int Native_GetPBMissed(Handle plugin, int numParams)
{
	return view_as<int>(gB_PBMissed[GetNativeCell(1)][GetNativeCell(2)]);
}

public int Native_ReopenMapTopMenu(Handle plugin, int numParams)
{
	ReopenMapTopMenu(GetNativeCell(1));
	return 0;
} 