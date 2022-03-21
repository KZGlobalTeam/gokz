/*
	Invalidating invalid jumps, such as ones with a modified velocity.
*/

static Handle processMovementHookPost;

void OnPluginStart_JumpValidating()
{
	Handle gamedataConf = LoadGameConfigFile("gokz-core.games");
	if (gamedataConf == null)
	{
		SetFailState("Failed to load gokz-core gamedata");
	}
	
	// CreateInterface
	// Thanks SlidyBat and ici
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(gamedataConf, SDKConf_Signature, "CreateInterface"))
	{
		SetFailState("Failed to get CreateInterface");
	}
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle CreateInterface = EndPrepSDKCall();
	
	if (CreateInterface == null)
	{
		SetFailState("Unable to prepare SDKCall for CreateInterface");
	}
	
	char interfaceName[64];
	
	// ProcessMovement
	if (!GameConfGetKeyValue(gamedataConf, "IGameMovement", interfaceName, sizeof(interfaceName)))
	{
		SetFailState("Failed to get IGameMovement interface name");
	}
	Address IGameMovement = SDKCall(CreateInterface, interfaceName, 0);
	if (!IGameMovement)
	{
		SetFailState("Failed to get IGameMovement pointer");
	}
	
	int offset = GameConfGetOffset(gamedataConf, "ProcessMovement");
	if (offset == -1)
	{
		SetFailState("Failed to get ProcessMovement offset");
	}

	processMovementHookPost = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore, DHook_ProcessMovementPost);
	DHookAddParam(processMovementHookPost, HookParamType_CBaseEntity);
	DHookAddParam(processMovementHookPost, HookParamType_ObjectPtr);
	DHookRaw(processMovementHookPost, false, IGameMovement);
}

static MRESReturn DHook_ProcessMovementPost(Handle hParams)
{
	int client = DHookGetParam(hParams, 1);
	if (!IsValidClient(client) || IsFakeClient(client))
	{
		return MRES_Ignored;
	}
	float pVelocity[3], velocity[3];
	Movement_GetProcessingVelocity(client, pVelocity);
	Movement_GetVelocity(client, velocity);

	gB_SpeedJustModifiedExternally[client] = false;
	for (int i = 0; i < 3; i++)
	{
		if (FloatAbs(pVelocity[i] - velocity[i]) > EPSILON)
		{
			// The current velocity doesn't match the velocity of the end of movement processing,
			// so it must have been modified by something like a trigger.
			InvalidateJumpstat(client);
			gB_SpeedJustModifiedExternally[client] = true;
			break;
		}
	}

	return MRES_Ignored;
}