/*
	API
	
	GOKZ Local Ranks API.
*/



// =========================  FORWARDS  ========================= //

void CreateGlobalForwards()
{
	gH_OnTimeProcessed = CreateGlobalForward("GOKZ_LR_OnTimeProcessed", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell);
	gH_OnNewRecord = CreateGlobalForward("GOKZ_LR_OnNewRecord", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
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
	Call_StartForward(gH_OnTimeProcessed);
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

void Call_OnNewRecord(int client, int steamID, int mapID, int course, int mode, int style, KZRecordType recordType)
{
	Call_StartForward(gH_OnNewRecord);
	Call_PushCell(client);
	Call_PushCell(steamID);
	Call_PushCell(mapID);
	Call_PushCell(course);
	Call_PushCell(mode);
	Call_PushCell(style);
	Call_PushCell(recordType);
	Call_Finish();
} 