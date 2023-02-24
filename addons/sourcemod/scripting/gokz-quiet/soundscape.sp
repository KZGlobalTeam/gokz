/*
	Toggle soundscapes.
*/

static int currentSoundscapeIndex[MAXPLAYERS + 1] = {BLANK_SOUNDSCAPEINDEX, ...};

void EnableSoundscape(int client)
{
	if (currentSoundscapeIndex[client] != BLANK_SOUNDSCAPEINDEX)
	{
		SetEntProp(client, Prop_Data, "soundscapeIndex", currentSoundscapeIndex[client]);
	}
}

void OnPlayerRunCmdPost_Soundscape(int client)
{
	int soundscapeIndex = GetEntProp(client, Prop_Data, "soundscapeIndex");
	if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_Soundscapes]) == Soundscapes_Disabled)
	{
		if (soundscapeIndex != BLANK_SOUNDSCAPEINDEX)
		{
			currentSoundscapeIndex[client] = soundscapeIndex;
		}
		SetEntProp(client, Prop_Data, "soundscapeIndex", BLANK_SOUNDSCAPEINDEX);
	}
	else
	{
		currentSoundscapeIndex[client] = soundscapeIndex;
	}
}