/*
	Hide sound effect from ambient_generics.
	Credit to Haze - https://github.com/Haze1337/Sound-Manager
*/

Handle getPlayerSlot;

void OnPluginStart_Ambient()
{
	HookSendSound();
}
static void HookSendSound()
{
	GameData gd = LoadGameConfigFile("gokz-quiet.games");

	DynamicDetour sendSoundDetour = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_Address); 
	DHookSetFromConf(sendSoundDetour, gd, SDKConf_Signature, "CGameClient::SendSound");
	DHookAddParam(sendSoundDetour, HookParamType_ObjectPtr);
	DHookAddParam(sendSoundDetour, HookParamType_Bool);
	if (!DHookEnableDetour(sendSoundDetour, false, DHooks_OnSendSound))
	{
		SetFailState("Couldn't enable CGameClient::SendSound detour.");
	}

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gd, SDKConf_Virtual, "CBaseClient::GetPlayerSlot");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	getPlayerSlot = EndPrepSDKCall();
	if (getPlayerSlot == null)
	{
		SetFailState("Could not initialize call to CBaseClient::GetPlayerSlot.");
	}
}


/*struct SoundInfo_t
{
    Vector          vOrigin;           Offset: 0   | Size: 12
    Vector          vDirection         Offset: 12  | Size: 12
    Vector          vListenerOrigin;   Offset: 24  | Size: 12
    const char      *pszName;          Offset: 36  | Size: 4
    float           fVolume;           Offset: 40  | Size: 4
    float           fDelay;            Offset: 44  | Size: 4
    float           fTickTime;         Offset: 48  | Size: 4
    int             nSequenceNumber;   Offset: 52  | Size: 4
    int             nEntityIndex;      Offset: 56  | Size: 4
    int             nChannel;          Offset: 60  | Size: 4
    int             nPitch;            Offset: 64  | Size: 4
    int             nFlags;            Offset: 68  | Size: 4
    unsigned int    nSoundNum;         Offset: 72  | Size: 4
    int             nSpeakerEntity;    Offset: 76  | Size: 4
    int             nRandomSeed;       Offset: 80  | Size: 4
    soundlevel_t    Soundlevel;        Offset: 84  | Size: 4
    bool            bIsSentence;       Offset: 88  | Size: 1
    bool            bIsAmbient;        Offset: 89  | Size: 1
    bool            bLooping;          Offset: 90  | Size: 1
};*/

//void CGameClient::SendSound( SoundInfo_t &sound, bool isReliable )
public MRESReturn DHooks_OnSendSound(Address pThis, Handle hParams)
{
	// Check volume
	float volume = DHookGetParamObjectPtrVar(hParams, 1, 40, ObjectValueType_Float);
	if(volume == 0.0)
	{
		return MRES_Ignored;
	}

	Address pIClient = pThis + view_as<Address>(0x4);
	int client = view_as<int>(SDKCall(getPlayerSlot, pIClient)) + 1;

	if(!IsValidClient(client))
	{
		return MRES_Ignored;
	}

	bool isAmbient = DHookGetParamObjectPtrVar(hParams, 1, 89, ObjectValueType_Bool);
	if (!isAmbient)
	{
		return MRES_Ignored;
	}
	
	float newVolume;
	if (GOKZ_QT_GetOption(client, QTOption_AmbientSounds) == -1 || GOKZ_QT_GetOption(client, QTOption_AmbientSounds) == 10)
	{
		newVolume = volume;
	}
	else
	{
		float volumeFactor = float(GOKZ_QT_GetOption(client, QTOption_AmbientSounds)) * 0.1;
		newVolume = volume * volumeFactor;
	}

	if (newVolume <= 0.0)
	{
		return MRES_Supercede;
	}
	DHookSetParamObjectPtrVar(hParams, 1, 40, ObjectValueType_Float, newVolume);
	return MRES_ChangedHandled;
}