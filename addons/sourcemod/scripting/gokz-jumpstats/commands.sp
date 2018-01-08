/*
	Commands
	
	Commands for player and admin use.
*/



// =========================  PUBLIC  ========================= //

void CreateCommands()
{
	RegConsoleCmd("sm_jumpstats", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
	RegConsoleCmd("sm_ljstats", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
	RegConsoleCmd("sm_js", CommandJumpstats, "[KZ] Open the jumpstats options menu.");
}



// =========================  COMMAND HANDLERS  ========================= //

public Action CommandJumpstats(int client, int args)
{
	DisplayOptionsMenu(client);
	return Plugin_Handled;
} 