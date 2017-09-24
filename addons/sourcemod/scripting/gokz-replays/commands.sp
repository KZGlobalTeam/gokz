/*
	Commands
	
	Commands for player and admin use.
*/



// =========================  PUBLIC  ========================= //

void CreateCommands()
{
	RegConsoleCmd("sm_replay", CommandReplay, "[KZ] Open the replay loading menu.");
}



// =========================  COMMAND HANDLERS  ========================= //

public Action CommandReplay(int client, int args)
{
	DisplayReplayModeMenu(client);
	return Plugin_Handled;
} 