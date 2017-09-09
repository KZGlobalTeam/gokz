/*
	API
	
	GOKZ Local Ranks API.
*/



Handle H_OnTimeProcessed;
Handle H_OnNewRecord;
Handle H_OnRecordMissed;



// =========================  FORWARDS  ========================= //

void CreateGlobalForwards()
{
	H_OnTimeProcessed = CreateGlobalForward("GOKZ_LR_OnTimeProcessed", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell, Param_Cell);
	H_OnNewRecord = CreateGlobalForward("GOKZ_LR_OnNewRecord", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	H_OnRecordMissed = CreateGlobalForward("GOKZ_LR_OnRecordMissed", ET_Ignore, Param_Cell, Param_Float, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
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

void Call_OnNewRecord(int client, int steamID, int mapID, int course, int mode, int style, int recordType)
{
	Call_StartForward(H_OnNewRecord);
	Call_PushCell(client);
	Call_PushCell(steamID);
	Call_PushCell(mapID);
	Call_PushCell(course);
	Call_PushCell(mode);
	Call_PushCell(style);
	Call_PushCell(recordType);
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