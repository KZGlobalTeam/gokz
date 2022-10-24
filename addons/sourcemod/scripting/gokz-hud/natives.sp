void CreateNatives()
{
	CreateNative("GOKZ_HUD_ForceUpdateTPMenu", Native_ForceUpdateTPMenu);
	CreateNative("GOKZ_HUD_GetMenuShowing", Native_GetMenuShowing);
	CreateNative("GOKZ_HUD_SetMenuShowing", Native_SetMenuShowing);
	CreateNative("GOKZ_HUD_GetMenuSpectatorText", Native_GetSpectatorText);
}

public int Native_ForceUpdateTPMenu(Handle plugin, int numParams)
{
	SetForceUpdateTPMenu(GetNativeCell(1));
	return 0;
}

public int Native_GetMenuShowing(Handle plugin, int numParams)
{
	return view_as<int>(gB_MenuShowing[GetNativeCell(1)]);
}

public int Native_SetMenuShowing(Handle plugin, int numParams)
{
	gB_MenuShowing[GetNativeCell(1)] = view_as<bool>(GetNativeCell(2));
	return 0;
}

public int Native_GetSpectatorText(Handle plugin, int numParams)
{
	HUDInfo info;
	GetNativeArray(2, info, sizeof(HUDInfo));
	KZPlayer player = KZPlayer(GetNativeCell(1));
	FormatNativeString(3, 0, 0, GetNativeCell(4), _, "", FormatSpectatorTextForMenu(player, info));
	return 0;
}