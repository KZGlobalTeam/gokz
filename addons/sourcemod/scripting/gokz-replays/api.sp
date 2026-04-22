// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_RP_GetPlaybackInfo", Native_RP_GetPlaybackInfo);
	CreateNative("GOKZ_RP_LoadJumpReplay", Native_RP_LoadJumpReplay);
	CreateNative("GOKZ_RP_UpdateReplayControlMenu", Native_RP_UpdateReplayControlMenu);
}

public int Native_RP_GetPlaybackInfo(Handle plugin, int numParams)
{
	HUDInfo info;
	GetPlaybackState(GetNativeCell(1), info);
	SetNativeArray(2, info, sizeof(HUDInfo));
	return 1;
}

public int Native_RP_LoadJumpReplay(Handle plugin, int numParams)
{
	int len;
	GetNativeStringLength(2, len);
	char[] path = new char[len + 1];
	GetNativeString(2, path, len + 1);
	int botClient = LoadReplayBot(GetNativeCell(1), path);
	return botClient;
}

public int Native_RP_UpdateReplayControlMenu(Handle plugin, int numParams)
{
	return view_as<int>(UpdateReplayControlMenu(GetNativeCell(1)));
}
