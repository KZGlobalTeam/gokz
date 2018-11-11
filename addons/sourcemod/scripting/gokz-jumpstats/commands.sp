void RegisterCommands()
{
	RegConsoleCmd("sm_jumpstats", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
	RegConsoleCmd("sm_ljstats", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
	RegConsoleCmd("sm_js", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
}

public Action CommandJumpstats(int client, int args)
{
	DisplayJumpstatsOptionsMenu(client);
	return Plugin_Handled;
} 