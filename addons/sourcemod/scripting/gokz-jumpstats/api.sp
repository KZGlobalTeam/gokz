static GlobalForward H_OnTakeoff;
static GlobalForward H_OnLanding;
static GlobalForward H_OnFailstat;
static GlobalForward H_OnJumpstatAlways;
static GlobalForward H_OnFailstatAlways;
static GlobalForward H_OnJumpInvalidated;



// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnTakeoff = new GlobalForward("GOKZ_JS_OnTakeoff", ET_Ignore, Param_Cell, Param_Cell);
	H_OnLanding = new GlobalForward("GOKZ_JS_OnLanding", ET_Ignore, Param_Array);
	H_OnFailstat = new GlobalForward("GOKZ_JS_OnFailstat", ET_Ignore, Param_Array);
	H_OnJumpstatAlways = new GlobalForward("GOKZ_JS_OnJumpstatAlways", ET_Ignore, Param_Array);
	H_OnFailstatAlways = new GlobalForward("GOKZ_JS_OnFailstatAlways", ET_Ignore, Param_Array);
	H_OnJumpInvalidated = new GlobalForward("GOKZ_JS_OnJumpInvalidated", ET_Ignore, Param_Cell);
}

void Call_OnTakeoff(int client, int jumpType)
{
	Call_StartForward(H_OnTakeoff);
	Call_PushCell(client);
	Call_PushCell(jumpType);
	Call_Finish();
}

void Call_OnLanding(Jump jump)
{
	Call_StartForward(H_OnLanding);
	Call_PushArray(jump, sizeof(jump));
	Call_Finish();
}

void Call_OnJumpInvalidated(int client)
{
	Call_StartForward(H_OnJumpInvalidated);
	Call_PushCell(client);
	Call_Finish();
}

void Call_OnFailstat(Jump jump)
{
	Call_StartForward(H_OnFailstat);
	Call_PushArray(jump, sizeof(jump));
	Call_Finish();
}

void Call_OnJumpstatAlways(Jump jump)
{
	Call_StartForward(H_OnJumpstatAlways);
	Call_PushArray(jump, sizeof(jump));
	Call_Finish();
}

void Call_OnFailstatAlways(Jump jump)
{
	Call_StartForward(H_OnFailstatAlways);
	Call_PushArray(jump, sizeof(jump));
	Call_Finish();
}



// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_JS_InvalidateJump", Native_InvalidateJump);
}

public int Native_InvalidateJump(Handle plugin, int numParams)
{
	InvalidateJumpstat(GetNativeCell(1));
	return 0;
} 
