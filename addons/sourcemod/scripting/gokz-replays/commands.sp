void RegisterCommands()
{
	RegConsoleCmd("sm_replay", CommandReplay, "[KZ] Open the replay loading menu.");
}

public Action CommandReplay(int client, int args)
{
	DisplayReplayModeMenu(client);
	return Plugin_Handled;
} 