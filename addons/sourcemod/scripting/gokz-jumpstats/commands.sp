
void RegisterCommands()
{
	RegConsoleCmd("sm_jumpstats", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
	RegConsoleCmd("sm_ljstats", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
	RegConsoleCmd("sm_js", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
	RegConsoleCmd("sm_jsalways", CommandAlwaysJumpstats, "[KZ] Toggle the always-on jumpstats.");
}

public Action CommandJumpstats(int client, int args)
{
	DisplayJumpstatsOptionsMenu(client);
	return Plugin_Handled;
} 

public Action CommandAlwaysJumpstats(int client, int args)
{
	if (GOKZ_JS_GetOption(client, JSOption_JumpstatsAlways) == JSToggleOption_Enabled)
	{
		GOKZ_JS_SetOption(client, JSOption_JumpstatsAlways, JSToggleOption_Disabled);
		GOKZ_PrintToChat(client, true, "%t", "Jumpstats Option - Jumpstats Always - Disable");
	}
	else
	{
		GOKZ_JS_SetOption(client, JSOption_JumpstatsAlways, JSToggleOption_Enabled);
		GOKZ_PrintToChat(client, true, "%t", "Jumpstats Option - Jumpstats Always - Enable");
	}
	
	return Plugin_Handled;
}
