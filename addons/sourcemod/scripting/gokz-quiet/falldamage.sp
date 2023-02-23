/*
	Toggle player's fall damage sounds.
*/

void OnPluginStart_FallDamage()
{
	AddNormalSoundHook(Hook_NormalSound);
}

static Action Hook_NormalSound(int clients[MAXPLAYERS], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags, char soundEntry[PLATFORM_MAX_PATH], int& seed)
{
	if (!StrEqual(soundEntry, "Player.FallDamage"))
	{
		return Plugin_Continue;
	}

	for (int i = 0; i < numClients; i++)
	{
		int client = clients[i];
		if (!IsValidClient(client))
		{
			continue;
		}
		int clientArray[1];
		clientArray[0] = client;
		float newVolume;
		if (GOKZ_QT_GetOption(client, QTOption_FallDamageSound) == -1 || GOKZ_QT_GetOption(client, QTOption_FallDamageSound) == 10)
		{
			newVolume = volume;
		}
		else
		{
			float volumeFactor = float(GOKZ_QT_GetOption(client, QTOption_FallDamageSound)) * 0.1;
			newVolume = volume * volumeFactor;
		}

		EmitSoundEntry(clientArray, 1, soundEntry, sample, entity, channel, level, seed, flags, newVolume, pitch);
	}
	return Plugin_Handled;
}