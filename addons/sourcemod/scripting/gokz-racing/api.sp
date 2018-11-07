static Handle H_OnFinish;
static Handle H_OnSurrender;
static Handle H_OnRequestReceived;
static Handle H_OnRequestAccepted;
static Handle H_OnRequestDeclined;



// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnFinish = CreateGlobalForward("GOKZ_RC_OnFinish", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	H_OnSurrender = CreateGlobalForward("GOKZ_RC_OnSurrender", ET_Ignore, Param_Cell, Param_Cell);
	H_OnRequestReceived = CreateGlobalForward("GOKZ_RC_OnRequestReceived", ET_Ignore, Param_Cell, Param_Cell);
	H_OnRequestAccepted = CreateGlobalForward("GOKZ_RC_OnRequestAccepted", ET_Ignore, Param_Cell, Param_Cell);
	H_OnRequestDeclined = CreateGlobalForward("GOKZ_RC_OnRequestDeclined", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

void Call_OnFinish(int client, int raceID, int place)
{
	Call_StartForward(H_OnFinish);
	Call_PushCell(client);
	Call_PushCell(raceID);
	Call_PushCell(place);
	Call_Finish();
}

void Call_OnSurrender(int client, int raceID)
{
	Call_StartForward(H_OnSurrender);
	Call_PushCell(client);
	Call_PushCell(raceID);
	Call_Finish();
}

void Call_OnRequestReceived(int client, int raceID)
{
	Call_StartForward(H_OnRequestReceived);
	Call_PushCell(client);
	Call_PushCell(raceID);
	Call_Finish();
}

void Call_OnRequestAccepted(int client, int raceID)
{
	Call_StartForward(H_OnRequestAccepted);
	Call_PushCell(client);
	Call_PushCell(raceID);
	Call_Finish();
}

void Call_OnRequestDeclined(int client, int raceID, bool timeout)
{
	Call_StartForward(H_OnRequestDeclined);
	Call_PushCell(client);
	Call_PushCell(raceID);
	Call_PushCell(timeout);
	Call_Finish();
} 