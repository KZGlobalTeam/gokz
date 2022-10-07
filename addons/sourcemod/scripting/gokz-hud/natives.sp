void CreateNatives()
{
	CreateNative("GOKZ_HUD_ForceUpdateTPMenu", Native_ForceUpdateTPMenu);
}

public int Native_ForceUpdateTPMenu(Handle plugin, int numParams)
{
	SetForceUpdateTPMenu(GetNativeCell(1));
	return 0;
}