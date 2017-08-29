/*
	Jump Tracking
	
	Jumpstat tracking.
*/



#define BHOP_ON_GROUND_TICKS 5



void OnJumpValidated_JumpTracking(int client, bool jumped, bool ladderJump)
{
	BeginJumpstat(client, jumped, ladderJump);
}

void OnStartTouchGround_JumpTracking(int client)
{
	EndJumpstat(client);
}

void OnPlayerRunCmd_JumpTracking(int client)
{
	if (!IsPlayerAlive(client) || !InValidJump(client))
	{
		return;
	}
	
	CheckGravity(client);
	CheckBaseVelocity(client);
	
	UpdateHeight(client);
	UpdateMaxSpeed(client);
	UpdateStrafes(client);
	UpdateSync(client);
	UpdateDuration(client);
}

void OnJumpInvalidated_JumpTracking(int client)
{
	InvalidateJump(client);
}

void OnStartTouch_JumpTracking(int client)
{
	InvalidateJump(client);
}

static void BeginJumpstat(int client, bool jumped, bool ladderJump)
{
	BeginType(client, jumped, ladderJump);
	BeginHeight(client);
	BeginMaxSpeed(client);
	BeginStrafes(client);
	BeginSync(client);
	BeginDuration(client);
	
	Call_OnTakeoff(client, GetType(client));
}

static void EndJumpstat(int client)
{
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



// =========================  CHECKS  ========================= //

static void CheckGravity(int client)
{
	float gravity = Movement_GetGravity(client);
	// Allow 1.0 and 0.0 gravity as both values appear during normal gameplay
	if (gravity != 1.0 && gravity != 0.0)
	{
		InvalidateJump(client);
	}
}

static void CheckBaseVelocity(int client)
{
	float baseVelocity[3];
	Movement_GetBaseVelocity(client, baseVelocity);
	if (baseVelocity[0] != 0.0 || baseVelocity[1] != 0.0 || baseVelocity[2] != 0.0)
	{
		InvalidateJump(client);
	}
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
		DropBhop - Bhop, except the previous jump had a negative height offset, and was not a Fall.
		WeirdJump - Bhop, except the previous jump was of the Fall type.
		LadderJump - Taking off from a ladderJump.
		Fall - Becoming airborne without jumping, i.e. walking/falling down.
		Other - Jump type can't be determined, or the player touched something.
		Invalid - Jump was deemed invalid e.g. because of teleportation.
		
	Note: If the previous jump had a height offset, a bunnyhop after
	it will be of the Other type.
*/

static JumpType jumpTypeLast[MAXPLAYERS + 1];
static JumpType jumpTypeCurrent[MAXPLAYERS + 1];

JumpType GetType(int client)
{
	return jumpTypeLast[client];
}

bool InValidJump(int client)
{
	return !Movement_GetOnGround(client) && jumpTypeCurrent[client] != JumpType_Invalid;
}

void InvalidateJump(int client)
{
	if (InValidJump(client))
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

static JumpType DetermineType(int client, bool jumped, bool ladderJump)
{
	if (gI_TouchingEntities[client] > 0)
	{
		return JumpType_Invalid;
	}
	if (ladderJump)
	{
		return JumpType_LadderJump;
	}
	if (!jumped)
	{
		return JumpType_Fall;
	}
	else if (HitBhop(client))
	{
		if (FloatAbs(GetOffset(client)) <= 0.01)
		{
			switch (GetType(client))
			{
				case JumpType_LongJump:return JumpType_Bhop;
				case JumpType_Bhop:return JumpType_MultiBhop;
				case JumpType_MultiBhop:return JumpType_MultiBhop;
				default:return JumpType_Other;
			}
		}
		else if (GetType(client) == JumpType_Fall)
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
	return Movement_GetTakeoffTick(client) - Movement_GetLandingTick(client) <= BHOP_ON_GROUND_TICKS;
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

static float durationLast[MAXPLAYERS + 1];
static int durationTicksCurrent[MAXPLAYERS + 1];

float GetDuration(int client)
{
	return durationLast[client];
}

static void BeginDuration(int client)
{
	durationTicksCurrent[client] = 0;
}

static void EndDuration(int client)
{
	durationLast[client] = durationTicksCurrent[client] * GetTickInterval();
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
static StrafeDirection strafesDirection[MAXPLAYERS + 1];

int GetStrafes(int client)
{
	return strafesLast[client];
}

static void BeginStrafes(int client)
{
	strafesCurrent[client] = 0;
	strafesDirection[client] = StrafeDirection_None;
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
}



// =========================  SYNC  ========================= //

/*	
	Sync is calculated as the percentage of time spent gaining
	speed during the jump. Maintaining current speed negatively
	affects sync.
*/

static float syncLast[MAXPLAYERS + 1];
static float syncLastTickSpeed[MAXPLAYERS + 1]; // Last recorded speed
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
	if (speed > syncLastTickSpeed[client])
	{
		syncGainTicksCurrent[client]++;
	}
	syncLastTickSpeed[client] = speed;
} 