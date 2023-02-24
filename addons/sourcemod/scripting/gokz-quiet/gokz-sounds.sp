/*
	Volume options for various GOKZ sounds.
*/

public Action GOKZ_OnEmitSoundToClient(int client, const char[] sample, float &volume, const char[] description)
{
	int volumeFactor = 10;
	if (StrEqual(description, "Checkpoint") || StrEqual(description, "Set Start Position"))
	{
		volumeFactor = GOKZ_QT_GetOption(client, QTOption_CheckpointVolume);
		if (volumeFactor == -1)
		{
			return Plugin_Continue;
		}
	}
	else if (StrEqual(description, "Checkpoint"))
	{
		volumeFactor = GOKZ_QT_GetOption(client, QTOption_TeleportVolume);
		if (volumeFactor == -1)
		{
			return Plugin_Continue;
		}
	}
	else if (StrEqual(description, "Timer Start") || StrEqual(description, "Timer End") || StrEqual(description, "Timer False End") || StrEqual(description, "Missed PB"))
	{
		volumeFactor = GOKZ_QT_GetOption(client, QTOption_TimerVolume);
		if (volumeFactor == -1)
		{
			return Plugin_Continue;
		}
	}
	else if (StrEqual(description, "Error"))
	{
		volumeFactor = GOKZ_QT_GetOption(client, QTOption_ErrorVolume);
		if (volumeFactor == -1)
		{
			return Plugin_Continue;
		}
	}
	else if (StrEqual(description, "Server Record"))
	{
		volumeFactor = GOKZ_QT_GetOption(client, QTOption_ServerRecordVolume);
		if (volumeFactor == -1)
		{
			return Plugin_Continue;
		}
	}
	else if (StrEqual(description, "World Record"))
	{
		volumeFactor = GOKZ_QT_GetOption(client, QTOption_WorldRecordVolume);
		if (volumeFactor == -1)
		{
			return Plugin_Continue;
		}
	}
	else if (StrEqual(description, "Jumpstats"))
	{
		volumeFactor = GOKZ_QT_GetOption(client, QTOption_JumpstatsVolume);
		if (volumeFactor == -1)
		{
			return Plugin_Continue;
		}
	}

	if (volumeFactor == 10)
	{
		return Plugin_Continue;
	}
	volume *= float(volumeFactor) * 0.1;
	return Plugin_Changed;
}