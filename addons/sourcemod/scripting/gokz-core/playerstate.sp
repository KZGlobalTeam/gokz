/*
	Player state

	Saves and restores what gokz-core keeps between a player's usercmds.
*/



#define PLAYER_STATE_VERSION 1

bool GetPlayerState(int client, any state[GOKZ_PLAYER_STATE_SIZE])
{
	state[0] = PLAYER_STATE_VERSION;
	state[1] = GetGOKZHitPerf(client);
	state[2] = GetGOKZTakeoffSpeed(client);
	int cell = GetTurnbindsState(client, state, 3);
	return GetMapTriggersState(client, state, cell, sizeof(state));
}

bool SetPlayerState(int client, const any state[GOKZ_PLAYER_STATE_SIZE])
{
	if (state[0] != PLAYER_STATE_VERSION)
	{
		return false;
	}
	SetGOKZHitPerf(client, view_as<bool>(state[1]));
	SetGOKZTakeoffSpeed(client, view_as<float>(state[2]));
	int cell = SetTurnbindsState(client, state, 3);
	SetMapTriggersState(client, state, cell);
	return true;
}
