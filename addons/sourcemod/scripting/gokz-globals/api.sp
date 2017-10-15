/*
	API
	
	GOKZ Globals API.
*/



Handle H_OnNewTopTime;



// =========================  FORWARDS  ========================= //

void CreateGlobalForwards()
{
	H_OnNewTopTime = CreateGlobalForward("GOKZ_GL_OnNewTopTime", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
}

void Call_OnNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall)
{
	Call_StartForward(H_OnNewTopTime);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_PushCell(mode);
	Call_PushCell(timeType);
	Call_PushCell(rank);
	Call_PushCell(rankOverall);
	Call_Finish();
} 