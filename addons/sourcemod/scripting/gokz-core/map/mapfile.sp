/*
	Mapping API
	
	Reads data from the current map file.
*/

static Regex RE_BonusStartButton;
static Regex RE_BonusEndButton;

// NOTE: 4 megabyte array for entity lump reading.
static char gEntityLump[4194304];

// =====[ PUBLIC ]=====

void EntlumpParse(StringMap antiBhopTriggers, StringMap teleportTriggers, StringMap timerButtonTriggers, int &mappingApiVersion)
{
	char mapPath[512];
	GetCurrentMap(mapPath, sizeof(mapPath));
	Format(mapPath, sizeof(mapPath), "maps/%s.bsp", mapPath);
	
	// https://developer.valvesoftware.com/wiki/Source_BSP_File_Format
	
	File file = OpenFile(mapPath, "rb");
	if (file != INVALID_HANDLE)
	{
		int identifier;
		file.ReadInt32(identifier);
		
		if (identifier == GOKZ_BSP_HEADER_IDENTIFIER)
		{
			// skip version number
			file.Seek(4, SEEK_CUR);
			
			// the entity lump info is the first lump in the array, so we don't need to seek any further.
			int offset;
			int length;
			file.ReadInt32(offset);
			file.ReadInt32(length);
			
			// jump to the start of the entity lump
			file.Seek(offset, SEEK_SET);
			
			int charactersRead = file.ReadString(gEntityLump, sizeof(gEntityLump), length);
			delete file;
			if (charactersRead >= sizeof(gEntityLump) - 1)
			{
				PushMappingApiError("ERROR: Entity lump: The map's entity lump is too big! Reduce the amount of entities in your map.");
				return;
			}
			gEntityLump[length] = '\0';
			
			int index = 0;
			
			StringMap entity = new StringMap();
			bool gotWorldSpawn = false;
			while (EntlumpParseEntity(entity, gEntityLump, index))
			{
				char classname[128];
				char targetName[GOKZ_ENTLUMP_MAX_VALUE];
				entity.GetString("classname", classname, sizeof(classname));
				
				if (!gotWorldSpawn && StrEqual("worldspawn", classname, false))
				{
					gotWorldSpawn = true;
					char versionString[32];
					if (entity.GetString("climb_mapping_api_version", versionString, sizeof(versionString)))
					{
						if (StringToIntEx(versionString, mappingApiVersion) == 0)
						{
							PushMappingApiError("ERROR: Entity lump: Couldn't parse Mapping API version from map properties: \"%s\".", versionString);
							mappingApiVersion = GOKZ_MAPPING_API_VERSION_NONE;
						}
					}
					else
					{
						// map doesn't have a mapping api version.
						mappingApiVersion = GOKZ_MAPPING_API_VERSION_NONE;
					}
				}
				else if (StrEqual("trigger_multiple", classname, false))
				{
					TriggerType triggerType;
					if (!gotWorldSpawn || mappingApiVersion != GOKZ_MAPPING_API_VERSION_NONE)
					{
						if (entity.GetString("targetname", targetName, sizeof(targetName)))
						{
							// get trigger properties if applicable
							triggerType = GetTriggerType(targetName);
							if (triggerType == TriggerType_Antibhop)
							{
								AntiBhopTrigger trigger;
								if (GetAntiBhopTriggerEntityProperties(trigger, entity))
								{
									char key[32];
									IntToString(trigger.hammerID, key, sizeof(key));
									antiBhopTriggers.SetArray(key, trigger, sizeof(trigger));
								}
							}
							else if (triggerType == TriggerType_Teleport)
							{
								TeleportTrigger trigger;
								if (GetTeleportTriggerEntityProperties(trigger, entity))
								{
									char key[32];
									IntToString(trigger.hammerID, key, sizeof(key));
									teleportTriggers.SetArray(key, trigger, sizeof(trigger));
								}
							}
						}
					}
					
					// Tracking legacy timer triggers that press the timer buttons upon triggered.
					if (triggerType == TriggerType_Invalid)
					{
						char touchOutput[128];
						ArrayList value;	
						
						if (entity.GetString("OnStartTouch", touchOutput, sizeof(touchOutput)))
						{
							TimerButtonTriggerCheck(touchOutput, sizeof(touchOutput), entity, timerButtonTriggers);
						}
						else if (entity.GetValue("OnStartTouch", value)) // If there are multiple outputs, we have to check for all of them.
						{
							for (int i = 0; i < value.Length; i++)
							{
								value.GetString(i, touchOutput, sizeof(touchOutput));
								TimerButtonTriggerCheck(touchOutput, sizeof(touchOutput), entity, timerButtonTriggers);
							}
						}
					}
				}
				else if (StrEqual("func_button", classname, false))
				{
					char pressOutput[128];
					ArrayList value;	
					
					if (entity.GetString("OnPressed", pressOutput, sizeof(pressOutput)))
					{
						TimerButtonTriggerCheck(pressOutput, sizeof(pressOutput), entity, timerButtonTriggers);
					}
					else if (entity.GetValue("OnPressed", value)) // If there are multiple outputs, we have to check for all of them.
					{
						for (int i = 0; i < value.Length; i++)
						{
							value.GetString(i, pressOutput, sizeof(pressOutput));
							TimerButtonTriggerCheck(pressOutput, sizeof(pressOutput), entity, timerButtonTriggers);
						}
					}
				}
				// clear for next loop
				entity.Clear();
			}
			delete entity;
		}
		delete file;
	}
	else
	{
		// TODO: do something more elegant
		SetFailState("Catastrophic extreme hyperfailure! Mapping API Couldn't open the map file for reading! %s. The map file might be gone or another program is using it.", mapPath);
	}
}


// =====[ EVENTS ]=====

void OnPluginStart_MapFile()
{
	char buffer[64];
	char press[8];
	FormatEx(press, sizeof(press), "%s%s", CHAR_ESCAPE, "Press");

	buffer = GOKZ_BONUS_START_BUTTON_NAME_REGEX;
	ReplaceStringEx(buffer, sizeof(buffer), "$", "");
	StrCat(buffer, sizeof(buffer), press);
	RE_BonusStartButton = CompileRegex(buffer);

	buffer = GOKZ_BONUS_END_BUTTON_NAME_REGEX;
	ReplaceStringEx(buffer, sizeof(buffer), "$", "");
	StrCat(buffer, sizeof(buffer), press);
	RE_BonusEndButton = CompileRegex(buffer);
}


// =====[ PRIVATE ]=====

static void EntlumpSkipAllWhiteSpace(char[] entityLump, int &index)
{
	while (IsCharSpace(entityLump[index]) && entityLump[index] != '\0')
	{
		index++;
	}
}

static int EntlumpGetString(char[] result, int maxLength, int copyCount, char[] entityLump, int entlumpIndex)
{
	int finalLength;
	for (int i = 0; i < maxLength - 1 && i < copyCount; i++)
	{
		if (entityLump[entlumpIndex + i] == '\0')
		{
			break;
		}
		result[i] = entityLump[entlumpIndex + i];
		finalLength++;
	}
	
	result[finalLength] = '\0';
	return finalLength;
}

static EntlumpToken EntlumpGetToken(char[] entityLump, int &entlumpIndex)
{
	EntlumpToken result;
	
	EntlumpSkipAllWhiteSpace(entityLump, entlumpIndex);
	
	switch (entityLump[entlumpIndex])
	{
		case '{':
		{
			result.type = EntlumpTokenType_OpenBrace;
			EntlumpGetString(result.string, sizeof(result.string), 1, entityLump, entlumpIndex);
			entlumpIndex++;
		}
		case '}':
		{
			result.type = EntlumpTokenType_CloseBrace;
			EntlumpGetString(result.string, sizeof(result.string), 1, entityLump, entlumpIndex);
			entlumpIndex++;
		}
		case '\0':
		{
			result.type = EntlumpTokenType_EndOfStream;
			EntlumpGetString(result.string, sizeof(result.string), 1, entityLump, entlumpIndex);
			entlumpIndex++;
		}
		case '\"':
		{
			result.type = EntlumpTokenType_Identifier;
			int identifierLen;
			entlumpIndex++;
			for (int i = 0; i < sizeof(result.string) - 1; i++)
			{
				// NOTE: Unterminated strings can probably never happen, since the map has to be
				// loaded by the game first and the engine will fail the load before we get to it.
				if (entityLump[entlumpIndex + i] == '\0')
				{
					result.type = EntlumpTokenType_Unknown;
					break;
				}
				if (entityLump[entlumpIndex + i] == '\"')
				{
					break;
				}
				result.string[i] = entityLump[entlumpIndex + i];
				identifierLen++;
			}
			
			entlumpIndex += identifierLen + 1; // +1 to skip over last quotation mark
			result.string[identifierLen] = '\0';
		}
		default:
		{
			result.type = EntlumpTokenType_Unknown;
			result.string[0] = entityLump[entlumpIndex];
			result.string[1] = '\0';
		}
	}
	
	return result;
}

static bool EntlumpParseEntity(StringMap result, char[] entityLump, int &entlumpIndex)
{
	EntlumpToken token;
	token = EntlumpGetToken(entityLump, entlumpIndex);
	if (token.type == EntlumpTokenType_EndOfStream)
	{
		return false;
	}
	
	// NOTE: The following errors will very very likely never happen, since the entity lump has to be
	// loaded by the game first and the engine will fail the load before we get to it.
	// But if there's an obscure bug in this code, then we'll know!!!
	for (;;)
	{
		token = EntlumpGetToken(entityLump, entlumpIndex);
		switch (token.type)
		{
			case EntlumpTokenType_OpenBrace:
			{
				continue;
			}
			case EntlumpTokenType_Identifier:
			{
				EntlumpToken valueToken;
				valueToken = EntlumpGetToken(entityLump, entlumpIndex);
				if (valueToken.type == EntlumpTokenType_Identifier)
				{
					char tempString[GOKZ_ENTLUMP_MAX_VALUE];
					ArrayList values;
					if (result.GetString(token.string, tempString, sizeof(tempString)))
					{
						result.Remove(token.string);
						values = new ArrayList(ByteCountToCells(GOKZ_ENTLUMP_MAX_VALUE));
						values.PushString(tempString);
						values.PushString(valueToken.string);
						result.SetValue(token.string, values);
					}
					else if (result.GetValue(token.string, values))
					{
						values.PushString(valueToken.string);
					}
					else
					{
						result.SetString(token.string, valueToken.string);
					}
				}
				else
				{
					PushMappingApiError("ERROR: Entity lump: Unexpected token \"%s\".", valueToken.string);
					return false;
				}
			}
			case EntlumpTokenType_CloseBrace:
			{
				break;
			}
			case EntlumpTokenType_EndOfStream:
			{
				PushMappingApiError("ERROR: Entity lump: Unexpected end of entity lump! Entity lump parsing failed.");
				return false;
			}
			default:
			{
				PushMappingApiError("ERROR: Entity lump: Invalid token \"%s\". Entity lump parsing failed.", token.string);
				return false;
			}
		}
	}
	
	return true;
}

static bool GetHammerIDFromEntityStringMap(int &result, StringMap entity)
{
	char hammerID[32];
	if (!entity.GetString("hammerid", hammerID, sizeof(hammerID))
		|| StringToIntEx(hammerID, result) == 0)
	{
		// if we don't have the hammer id, then we can't match the entity to an existing one!
		char origin[64];
		entity.GetString("origin", origin, sizeof(origin));
		PushMappingApiError("ERROR: Failed to parse \"hammerid\" keyvalue on trigger! \"%i\" origin: %s.", result, origin);
		return false;
	}
	return true;
}

static bool GetAntiBhopTriggerEntityProperties(AntiBhopTrigger result, StringMap entity)
{
	if (!GetHammerIDFromEntityStringMap(result.hammerID, entity))
	{
		return false;
	}
	
	char time[32];
	if (!entity.GetString("climb_anti_bhop_time", time, sizeof(time))
		|| StringToFloatEx(time, result.time) == 0)
	{
		result.time = GOKZ_ANTI_BHOP_TRIGGER_DEFAULT_DELAY;
	}
	
	return true;
}

static bool GetTeleportTriggerEntityProperties(TeleportTrigger result, StringMap entity)
{
	if (!GetHammerIDFromEntityStringMap(result.hammerID, entity))
	{
		return false;
	}
	
	char buffer[64];
	if (!entity.GetString("climb_teleport_type", buffer, sizeof(buffer))
		|| StringToIntEx(buffer, view_as<int>(result.type)) == 0)
	{
		result.type = GOKZ_TELEPORT_TRIGGER_DEFAULT_TYPE;
	}
	
	if (!entity.GetString("climb_teleport_destination", result.tpDestination, sizeof(result.tpDestination)))
	{
		// We don't want triggers without destinations dangling about, so we need to tell everyone about it!!!
		PushMappingApiError("ERROR: Could not find \"climb_teleport_destination\" keyvalue on a climb_teleport trigger! hammer id \"%i\".",
			result.hammerID);
		return false;
	}
	
	if (!entity.GetString("climb_teleport_delay", buffer, sizeof(buffer))
		|| StringToFloatEx(buffer, result.delay) == 0)
	{
		result.delay = GOKZ_TELEPORT_TRIGGER_DEFAULT_DELAY;
	}
	
	if (!entity.GetString("climb_teleport_use_dest_angles", buffer, sizeof(buffer))
		|| StringToIntEx(buffer, result.useDestAngles) == 0)
	{
		result.useDestAngles = GOKZ_TELEPORT_TRIGGER_DEFAULT_USE_DEST_ANGLES;
	}
	
	if (!entity.GetString("climb_teleport_reset_speed", buffer, sizeof(buffer))
		|| StringToIntEx(buffer, result.resetSpeed) == 0)
	{
		result.resetSpeed = GOKZ_TELEPORT_TRIGGER_DEFAULT_RESET_SPEED;
	}
	
	if (!entity.GetString("climb_teleport_reorient_player", buffer, sizeof(buffer))
		|| StringToIntEx(buffer, result.reorientPlayer) == 0)
	{
		result.reorientPlayer = GOKZ_TELEPORT_TRIGGER_DEFAULT_REORIENT_PLAYER;
	}
	
	if (!entity.GetString("climb_teleport_relative", buffer, sizeof(buffer))
		|| StringToIntEx(buffer, result.relativeDestination) == 0)
	{
		result.relativeDestination = GOKZ_TELEPORT_TRIGGER_DEFAULT_RELATIVE_DESTINATION;
	}
	
	// NOTE: Clamping
	if (IsBhopTrigger(result.type))
	{
		result.delay = FloatMax(result.delay, GOKZ_TELEPORT_TRIGGER_BHOP_MIN_DELAY);
	}
	else
	{
		result.delay = FloatMax(result.delay, 0.0);
	}
	
	return true;
}

static void TimerButtonTriggerCheck(char[] touchOutput, int size, StringMap entity, StringMap timerButtonTriggers)
{
	int course = 0;
	char startOutput[128];
	char endOutput[128];
	FormatEx(startOutput, sizeof(startOutput), "%s%s%s", GOKZ_START_BUTTON_NAME, CHAR_ESCAPE, "Press");
	FormatEx(endOutput, sizeof(endOutput), "%s%s%s", GOKZ_END_BUTTON_NAME, CHAR_ESCAPE, "Press");
	if (StrContains(touchOutput, startOutput, false) != -1)
	{
		TimerButtonTrigger trigger;
		if (GetHammerIDFromEntityStringMap(trigger.hammerID, entity))
		{
			trigger.course = 0;
			trigger.isStartTimer = true;
		}
		char key[32];
		IntToString(trigger.hammerID, key, sizeof(key));
		timerButtonTriggers.SetArray(key, trigger, sizeof(trigger));
	}
	else if (StrContains(touchOutput, endOutput, false) != -1)
	{
		TimerButtonTrigger trigger;
		if (GetHammerIDFromEntityStringMap(trigger.hammerID, entity))
		{
			trigger.course = 0;
			trigger.isStartTimer = false;
		}
		char key[32];
		IntToString(trigger.hammerID, key, sizeof(key));
		timerButtonTriggers.SetArray(key, trigger, sizeof(trigger));
	}
	else if (RE_BonusStartButton.Match(touchOutput) > 0)
	{
		RE_BonusStartButton.GetSubString(1, touchOutput, sizeof(size));
		course = StringToInt(touchOutput);
		TimerButtonTrigger trigger;
		if (GetHammerIDFromEntityStringMap(trigger.hammerID, entity))
		{
			trigger.course = course;
			trigger.isStartTimer = true;
		}
		char key[32];
		IntToString(trigger.hammerID, key, sizeof(key));
		timerButtonTriggers.SetArray(key, trigger, sizeof(trigger));
	}
	else if (RE_BonusEndButton.Match(touchOutput) > 0)
	{
		RE_BonusEndButton.GetSubString(1, touchOutput, sizeof(size));
		course = StringToInt(touchOutput);
		TimerButtonTrigger trigger;
		if (GetHammerIDFromEntityStringMap(trigger.hammerID, entity))
		{
			trigger.course = course;
			trigger.isStartTimer = false;
		}
		char key[32];
		IntToString(trigger.hammerID, key, sizeof(key));
		timerButtonTriggers.SetArray(key, trigger, sizeof(trigger));
	}
}