/*
	Jump Tracking
	
	Jumpstat tracking.
*/



static float lastTickSpeed[MAXPLAYERS + 1]; // Last recorded horizontal speed
static int lastPlayerJumpTick[MAXPLAYERS + 1];



void OnJumpValidated_JumpTracking(int client, bool jumped, bool ladderJump)
{
	BeginJumpstat(client, jumped, ladderJump);
}

void OnStartTouchGround_JumpTracking(int client)
{
	EndJumpstat(client);
}

void OnPlayerRunCmd_JumpTracking(int client, int cmdnum)
{
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	if (!Movement_GetOnGround(client) && GetValidJumpstat(client))
	{
		// First tick is done when the jumpstat begins to ensure it is measured
		if (cmdnum != Movement_GetTakeoffCmdNum(client))
		{
			UpdateJumpstat(client);
		}
	}
	
	lastTickSpeed[client] = Movement_GetSpeed(client);
}

void OnStartTouch_JumpTracking(int client)
{
	if (!Movement_GetOnGround(client))
	{
		InvalidateJumpstat(client);
	}
}

void OnPlayerJump_JumpTracking(int client, bool jumpbug)
{
	if (jumpbug)
	{
		InvalidateJumpstat(client);
	}
	lastPlayerJumpTick[client] = GetGameTickCount();
}

void OnJumpInvalidated_JumpTracking(int client)
{
	InvalidateJumpstat(client);
}

void OnOptionChanged_JumpTracking(int client, Option option)
{
	if (option == Option_Mode)
	{
		InvalidateJumpstat(client);
	}
}

static void BeginJumpstat(int client, bool jumped, bool ladderJump)
{
	BeginType(client, jumped, ladderJump);
	BeginHeight(client);
	BeginMaxSpeed(client);
	BeginStrafes(client);
	BeginSync(client);
	BeginDuration(client);
	
	Call_OnTakeoff(client, GetCurrentType(client));
	
	UpdateJumpstat(client); // Measure first tick of jumpstat
}

static void EndJumpstat(int client)
{
	UpdateJumpstat(client); // Measure last tick of jumpstat
	
	EndType(client);
	EndDistance(client);
	EndOffset(client);
	EndHeight(client);
	EndMaxSpeed(client);
	EndStrafes(client);
	EndSync(client);
	EndDuration(client);
	
	Call_OnLanding(client, GetType(client), GetDistance(client), GetOffset(client), GetHeight(client), 
		GOKZ_GetTakeoffSpeed(client), GetMaxSpeed(client), GetStrafes(client), GetSync(client), GetDuration(client));
}

static void UpdateJumpstat(int client)
{
	if (CheckGravity(client) && CheckBaseVelocity(client) && CheckInWater(client))
	{
		// Passed all checks
		UpdateHeight(client);
		UpdateMaxSpeed(client);
		UpdateStrafes(client);
		UpdateSync(client);
		UpdateDuration(client);
	}
	else
	{
		InvalidateJumpstat(client);
	}
}



// =========================  CHECKS  ========================= //

static bool CheckGravity(int client)
{
	float gravity = Movement_GetGravity(client);
	// Allow 1.0 and 0.0 gravity as both values appear during normal gameplay
	if (gravity != 1.0 && gravity != 0.0)
	{
		return false;
	}
	return true;
}

static bool CheckBaseVelocity(int client)
{
	float baseVelocity[3];
	Movement_GetBaseVelocity(client, baseVelocity);
	if (baseVelocity[0] != 0.0 || baseVelocity[1] != 0.0 || baseVelocity[2] != 0.0)
	{
		return false;
	}
	return true;
}

static bool CheckInWater(int client)
{
	int waterLevel = GetEntProp(client, Prop_Data, "m_nWaterLevel");
	return waterLevel == 0;
}



// =========================  TYPE  ========================= //

/*
	Jump type is determined at the beginning of a takeoff.
	A jump may be determined to be invalid
	
	A takeoff occurs when the player stops touching the ground, with
	the exception of ladderjumps, which occur when the player leaves
	a ladderJump.
	
	A brief description of each jump type:
		LongJump - Normal jump.
		Bhop - Bunnyhop after landing a non-bunnyhop type jump.
		MultiBhop - Bunnyhop after landing a bunnyhop type jump.
		WeirdJump - Bhop, except the previous jump was of the Fall type.
		LadderJump - Taking off from a ladderJump.
		Fall - Becoming airborne without jumping, i.e. walking/falling down.
		Other - Jump type can't be determined, or the player touched something.
		Invalid - Jump was deemed invalid e.g. because of teleportation.
		
	Note: If the previous jump had a height offset, a bunnyhop after
	it will be of the Other type.
*/

static int jumpTypeLast[MAXPLAYERS + 1] =  { JumpType_Invalid, ... };
static int jumpTypeCurrent[MAXPLAYERS + 1] =  { JumpType_Invalid, ... };

int GetType(int client)
{
	return jumpTypeLast[client];
}

int GetCurrentType(int client)
{
	return jumpTypeCurrent[client];
}

bool GetValidJumpstat(int client)
{
	return jumpTypeCurrent[client] != JumpType_Invalid;
}

void InvalidateJumpstat(int client)
{
	if (GetValidJumpstat(client))
	{
		jumpTypeLast[client] = JumpType_Invalid;
		jumpTypeCurrent[client] = JumpType_Invalid;
		Call_OnJumpInvalidated(client);
	}
}

static void BeginType(int client, bool jumped, bool ladderJump)
{
	jumpTypeCurrent[client] = DetermineType(client, jumped, ladderJump);
}

static void EndType(int client)
{
	jumpTypeLast[client] = jumpTypeCurrent[client];
}

static int DetermineType(int client, bool jumped, bool ladderJump)
{
	if (gI_TouchingEntities[client] > 0)
	{
		return JumpType_Invalid;
	}
	else if (ladderJump)
	{
		if (GetGameTickCount() - lastPlayerJumpTick[client] <= BHOP_ON_GROUND_TICKS)
		{
			return JumpType_Ladderhop;
		}
		else
		{
			return JumpType_LadderJump;
		}
	}
	else if (!jumped)
	{
		return JumpType_Fall;
	}
	else if (HitBhop(client))
	{
		if (FloatAbs(GetOffset(client)) < EPSILON) // Check for no offset
		{
			switch (GetType(client))
			{
				case JumpType_LongJump:return JumpType_Bhop;
				case JumpType_Bhop:return JumpType_MultiBhop;
				case JumpType_MultiBhop:return JumpType_MultiBhop;
				default:return JumpType_Other;
			}
		}
		// Check for weird jump
		else if (GetType(client) == JumpType_Fall && ValidWeirdJumpDropDistance(client))
		{
			return JumpType_WeirdJump;
		}
		else
		{
			return JumpType_Other;
		}
	}
	return JumpType_LongJump;
}

static bool HitBhop(int client)
{
	return Movement_GetTakeoffCmdNum(client) - Movement_GetLandingCmdNum(client) <= BHOP_ON_GROUND_TICKS;
}

static bool ValidWeirdJumpDropDistance(int client)
{
	float offset = GetOffset(client);
	if (offset < -1 * WEIRDJUMP_MAX_FALL_OFFSET)
	{
		// Don't bother telling them if they fell a very far distance
		if (offset >= -2 * WEIRDJUMP_MAX_FALL_OFFSET)
		{
			GOKZ_PrintToChat(client, true, "%t", "Dropped Too Far (Weird Jump)", -1 * offset, WEIRDJUMP_MAX_FALL_OFFSET);
		}
		return false;
	}
	return true;
}



// =========================  DISTANCE  ========================= //

/*
	Jump distance is the horizontal distance of the jump.
	
	It is measured intuitively, describing the gap between two blocks
	(along the x or y axis) that the player was able to jump. This is
	done by adding 32.0, the size of the player collision box, to the
	distance between the takeoff and landing origins.
*/

static float distanceLast[MAXPLAYERS + 1];

float GetDistance(int client)
{
	return distanceLast[client];
}

static void EndDistance(int client)
{
	distanceLast[client] = CalcDistance(client);
}

static float CalcDistance(int client)
{
	float takeoffOrigin[3], landingOrigin[3], distance;
	Movement_GetTakeoffOrigin(client, takeoffOrigin);
	Movement_GetLandingOrigin(client, landingOrigin);
	distance = GetVectorHorizontalDistance(takeoffOrigin, landingOrigin);
	if (GetType(client) != JumpType_LadderJump)
	{
		distance += 32.0;
	}
	return distance;
}



// =========================  OFFSET  ========================= //

static float offsetLast[MAXPLAYERS + 1];

float GetOffset(int client)
{
	return offsetLast[client];
}

static void EndOffset(int client)
{
	float takeoffOrigin[3], landingOrigin[3];
	Movement_GetTakeoffOrigin(client, takeoffOrigin);
	Movement_GetLandingOrigin(client, landingOrigin);
	offsetLast[client] = landingOrigin[2] - takeoffOrigin[2];
}



// =========================  DURATION  ========================= //

static int durationTicksLast[MAXPLAYERS + 1];
static int durationTicksCurrent[MAXPLAYERS + 1];

float GetDuration(int client)
{
	return durationTicksLast[client] * GetTickInterval();
}

int GetDurationTicks(int client)
{
	return durationTicksLast[client];
}

static void BeginDuration(int client)
{
	durationTicksCurrent[client] = 0;
}

static void EndDuration(int client)
{
	durationTicksLast[client] = durationTicksCurrent[client];
}

static int GetDurationTicksCurrent(int client)
{
	return durationTicksCurrent[client];
}

static void UpdateDuration(int client)
{
	durationTicksCurrent[client]++;
}



// =========================  HEIGHT  ========================= //

static float heightLast[MAXPLAYERS + 1];
static float heightCurrent[MAXPLAYERS + 1];

float GetHeight(int client)
{
	return heightLast[client];
}

static void BeginHeight(int client)
{
	heightCurrent[client] = 0.0;
}

static void EndHeight(int client)
{
	heightLast[client] = heightCurrent[client];
}

static float UpdateHeight(int client)
{
	float takeoffOrigin[3], origin[3];
	Movement_GetTakeoffOrigin(client, takeoffOrigin);
	Movement_GetOrigin(client, origin);
	heightCurrent[client] = FloatMax(heightCurrent[client], origin[2] - takeoffOrigin[2]);
}



// =========================  MAX SPEED  ========================= //

static float maxSpeedLast[MAXPLAYERS + 1];
static float maxSpeedCurrent[MAXPLAYERS + 1];

float GetMaxSpeed(int client)
{
	return maxSpeedLast[client];
}

static void BeginMaxSpeed(int client)
{
	maxSpeedCurrent[client] = 0.0;
}

static void EndMaxSpeed(int client)
{
	maxSpeedLast[client] = maxSpeedCurrent[client];
}

static void UpdateMaxSpeed(int client)
{
	maxSpeedCurrent[client] = FloatMax(maxSpeedCurrent[client], Movement_GetSpeed(client));
}



// =========================  STRAFES  ========================= //

static int strafesLast[MAXPLAYERS + 1];
static int strafesCurrent[MAXPLAYERS + 1];
static int strafesDirection[MAXPLAYERS + 1];
static int strafesTicks[MAXPLAYERS + 1][MAX_TRACKED_STRAFES];
static int strafesGainTicks[MAXPLAYERS + 1][MAX_TRACKED_STRAFES];
static float strafesGain[MAXPLAYERS + 1][MAX_TRACKED_STRAFES];
static float strafesLoss[MAXPLAYERS + 1][MAX_TRACKED_STRAFES];

int GetStrafes(int client)
{
	return strafesLast[client];
}

float GetStrafeAirtime(int client, int strafe)
{
	return float(strafesTicks[client][strafe]) / float(GetDurationTicks(client)) * 100.0;
}

float GetStrafeSync(int client, int strafe)
{
	return float(strafesGainTicks[client][strafe]) / float(strafesTicks[client][strafe]) * 100.0;
}

float GetStrafeGain(int client, int strafe)
{
	return strafesGain[client][strafe];
}

float GetStrafeLoss(int client, int strafe)
{
	return strafesLoss[client][strafe];
}

static void BeginStrafes(int client)
{
	strafesCurrent[client] = 0;
	strafesDirection[client] = StrafeDirection_None;
	for (int strafe = 0; strafe < MAX_TRACKED_STRAFES; strafe++)
	{
		strafesTicks[client][strafe] = 0;
		strafesGainTicks[client][strafe] = 0;
		strafesGain[client][strafe] = 0.0;
		strafesLoss[client][strafe] = 0.0;
	}
}

static void EndStrafes(int client)
{
	strafesLast[client] = strafesCurrent[client];
}

static void UpdateStrafes(int client)
{
	KZPlayer player = new KZPlayer(client);
	if (player.turningLeft && strafesDirection[player.id] != StrafeDirection_Left)
	{
		strafesDirection[player.id] = StrafeDirection_Left;
		strafesCurrent[player.id]++;
	}
	else if (player.turningRight && strafesDirection[player.id] != StrafeDirection_Right)
	{
		strafesDirection[player.id] = StrafeDirection_Right;
		strafesCurrent[player.id]++;
	}
	
	if (strafesCurrent[client] < MAX_TRACKED_STRAFES)
	{
		strafesTicks[client][strafesCurrent[client]]++;
		if (player.speed > lastTickSpeed[client])
		{
			strafesGainTicks[client][strafesCurrent[client]]++;
			strafesGain[client][strafesCurrent[client]] += player.speed - lastTickSpeed[client];
		}
		else
		{
			strafesLoss[client][strafesCurrent[client]] += lastTickSpeed[client] - player.speed;
		}
	}
}



// =========================  SYNC  ========================= //

/*	
	Sync is calculated as the percentage of time spent gaining
	speed during the jump. Maintaining current speed negatively
	affects sync.
*/

static float syncLast[MAXPLAYERS + 1];
static int syncGainTicksCurrent[MAXPLAYERS + 1];

float GetSync(int client)
{
	return syncLast[client];
}

static void BeginSync(int client)
{
	syncGainTicksCurrent[client] = 0;
}

static void EndSync(int client)
{
	syncLast[client] = float(syncGainTicksCurrent[client]) / float(GetDurationTicksCurrent(client)) * 100.0;
}

static void UpdateSync(int client)
{
	float speed = Movement_GetSpeed(client);
	if (speed > lastTickSpeed[client])
	{
		syncGainTicksCurrent[client]++;
	}
} 