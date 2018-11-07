void RegisterCommands()
{
	RegConsoleCmd("sm_accept", CommandAccept, "[KZ] Accept an incoming race request.");
	RegConsoleCmd("sm_decline", CommandDecline, "[KZ] Decline an incoming race request.");
	RegConsoleCmd("sm_surrender", CommandSurrender, "[KZ] Surrender your race.");
	RegConsoleCmd("sm_race", CommandRace, "[KZ] Open the race hosting menu.");
	RegConsoleCmd("sm_duel", CommandDuel, "[KZ] Open the duel menu.");
	RegConsoleCmd("sm_challenge", CommandDuel, "[KZ] Open the duel menu.");
	RegConsoleCmd("sm_abort", CommandAbort, "[KZ] Abort the race you are hosting.");
}

public Action CommandAccept(int client, int args)
{
	AcceptRequest(client);
	return Plugin_Handled;
}

public Action CommandDecline(int client, int args)
{
	DeclineRequest(client);
	return Plugin_Handled;
}

public Action CommandSurrender(int client, int args)
{
	SurrenderRacer(client);
	return Plugin_Handled;
}

public Action CommandRace(int client, int args)
{
	DisplayRaceMenu(client);
	return Plugin_Handled;
}

public Action CommandDuel(int client, int args)
{
	DisplayDuelMenu(client);
	return Plugin_Handled;
}

public Action CommandAbort(int client, int args)
{
	AbortHostedRace(client);
	return Plugin_Handled;
} 