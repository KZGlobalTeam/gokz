/*
	Toggle soundscapes.
*/

// Search for "coopcementplant.missionselect_blank" id with sv_soundscape_printdebuginfo.
#define BLANK_SOUNDSCAPEINDEX 482
int gI_CurrentSoundscapeIndex[MAXPLAYERS + 1] = {BLANK_SOUNDSCAPEINDEX, ...};

void EnableSoundscape(int client)
{
	if (gI_CurrentSoundscapeIndex[client] != BLANK_SOUNDSCAPEINDEX)
	{
		SetEntProp(client, Prop_Data, "soundscapeIndex", gI_CurrentSoundscapeIndex[client]);
	}
}

void OnPlayerRunCmdPost_Soundscape(int client)
{
	int soundscapeIndex = GetEntProp(client, Prop_Data, "soundscapeIndex");
	if (GOKZ_GetOption(client, gC_QTOptionNames[QTOption_MapSounds]) == MapSounds_Disabled)
	{
		if (soundscapeIndex != BLANK_SOUNDSCAPEINDEX)
		{
			gI_CurrentSoundscapeIndex[client] = soundscapeIndex;
		}
		SetEntProp(client, Prop_Data, "soundscapeIndex", BLANK_SOUNDSCAPEINDEX);
	}
	else
	{
		gI_CurrentSoundscapeIndex[client] = soundscapeIndex;
	}
}