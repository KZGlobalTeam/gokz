static GlobalForward H_OnTakeoff;
static GlobalForward H_OnLanding;
static GlobalForward H_OnJumpInvalidated;



// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnTakeoff = new GlobalForward("GOKZ_JS_OnTakeoff", ET_Ignore, Param_Cell, Param_Cell);
	H_OnLanding = new GlobalForward("GOKZ_JS_OnLanding", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Float, Param_Float, Param_Float, Param_Cell, Param_Float, Param_Float);
	H_OnJumpInvalidated = new GlobalForward("GOKZ_JS_OnJumpInvalidated", ET_Ignore, Param_Cell);
}

void Call_OnTakeoff(int client, int jumpType)
{
	Call_StartForward(H_OnTakeoff);
	Call_PushCell(client);
	Call_PushCell(jumpType);
	Call_Finish();
}

void Call_OnLanding(int client, int jumpType, float distance, float offset, float height, float preSpeed, float maxSpeed, int strafes, float sync, float duration)
{
	Call_StartForward(H_OnLanding);
	Call_PushCell(client);
	Call_PushCell(jumpType);
	Call_PushFloat(distance);
	Call_PushFloat(offset);
	Call_PushFloat(height);
	Call_PushFloat(preSpeed);
	Call_PushFloat(maxSpeed);
	Call_PushCell(strafes);
	Call_PushFloat(sync);
	Call_PushFloat(duration);
	Call_Finish();
}

void Call_OnJumpInvalidated(int client)
{
	Call_StartForward(H_OnJumpInvalidated);
	Call_PushCell(client);
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
} 