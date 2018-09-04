/*
	Movement Function Stock Library

	Website: https://github.com/danzayau/MovementAPI
*/

#if defined _movement_included_
 #endinput
#endif
#define _movement_included_



// =========================  STOCKS  ========================= //

/**
 * Calculates the horizontal distance between two vectors.
 *
 * @param vec1			First vector.
 * @param vec2			Second vector.
 * @return				Vector horizontal distance.
 */
stock float GetVectorHorizontalDistance(const float vec1[3], const float vec2[3])
{
	return SquareRoot(Pow(vec2[0] - vec1[0], 2.0) + Pow(vec2[1] - vec1[1], 2.0));
}

/**
 * Calculates a vector's horizontal length.
 *
 * @param vec			Vector.
 * @return				Vector horizontal length (magnitude).
 */
stock float GetVectorHorizontalLength(const float vec[3])
{
	return SquareRoot(Pow(vec[0], 2.0) + Pow(vec[1], 2.0));
}

/**
 * Scales a vector to a certain horizontal length.
 *
 * @param vec			Vector.
 * @param length		New horizontal length.
 */
stock void SetVectorHorizontalLength(float vec[3], float length)
{
	float newVec[3];
	newVec = vec;
	newVec[2] = 0.0;
	NormalizeVector(newVec, newVec);
	ScaleVector(newVec, length);
	newVec[2] = vec[2];
	vec = newVec;
}

/**
 * Gets a player's currently pressed buttons.
 *
 * @param client		Client index.
 * @return				Bitsum of buttons.
 */
stock int Movement_GetButtons(int client)
{
	return GetClientButtons(client);
}

/**
 * Gets the player's origin.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 */
stock void Movement_GetOrigin(int client, float result[3])
{
	GetClientAbsOrigin(client, result);
}

/**
 * Gets the player's origin.
 * If the player is on the ground, a trace hull is used to find the
 * exact height of the ground the player is standing on. This is thus
 * more accurate than Movement_GetOrigin when player is on ground.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 */
stock void Movement_GetOriginEx(int client, float result[3])
{
	if (!Movement_GetOnGround(client))
	{
		GetClientAbsOrigin(client, result);
		return;
	}
	
	// Get the coordinate of the solid beneath the player's origin
	// More accurate than GetClientAbsOrigin when on ground
	float startPosition[3], endPosition[3];
	GetClientAbsOrigin(client, startPosition);
	endPosition = startPosition;
	endPosition[2] = startPosition[2] - 2.0; // Should be less than 2.0 units away
	Handle trace = TR_TraceHullFilterEx(
		startPosition, 
		endPosition, 
		view_as<float>( { -16.0, -16.0, 0.0 } ),  // Players are 32 x 32 x 72
		view_as<float>( { 16.0, 16.0, 72.0 } ), 
		MASK_PLAYERSOLID, 
		TraceEntityFilterPlayers, 
		client);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(result, trace);
		result[2] = result[2] - 0.03125; // Get rid of the offset
	}
	else
	{
		result = startPosition; // Fallback to GetClientAbsOrigin
	}
	delete trace;
}

public bool TraceEntityFilterPlayers(int entity, int contentsMask)
{
	return entity > MaxClients;
}

/**
 * Sets the player's origin by teleporting them.
 *
 * @param client		Client index.
 * @param origin		New origin.
 */
stock void Movement_SetOrigin(int client, const float origin[3])
{
	TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
}

/**
 * Gets the player's velocity.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 */
stock void Movement_GetVelocity(int client, float result[3])
{
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", result);
}

/**
 * Sets the player's velocity by teleporting them.
 *
 * @param client		Client index.
 * @param velocity		New velocity.
 */
stock void Movement_SetVelocity(int client, const float velocity[3])
{
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}

/**
 * Gets the player's horizontal speed.
 *
 * @param client		Client index.
 * @return				Player's horizontal speed.
 */
stock float Movement_GetSpeed(int client)
{
	float velocity[3];
	Movement_GetVelocity(client, velocity);
	return GetVectorHorizontalLength(velocity);
}

/**
 * Sets the player's horizontal speed.
 *
 * @param client		Client index.
 * @param value			New horizontal speed.
 * @param applyBaseVel	Whether to apply base velocity as well.
 */
stock void Movement_SetSpeed(int client, float value, bool applyBaseVel = false)
{
	float velocity[3];
	Movement_GetVelocity(client, velocity);
	SetVectorHorizontalLength(velocity, value)
	if (applyBaseVel)
	{
		float baseVelocity[3];
		Movement_GetBaseVelocity(client, baseVelocity);
		AddVectors(velocity, baseVelocity, velocity);
	}
	Movement_SetVelocity(client, velocity);
}

/**
 * Gets the player's vertical velocity.
 *
 * @param client		Client index.
 * @return				Player's vertical velocity.
 */
stock float Movement_GetVerticalVelocity(int client)
{
	float velocity[3];
	Movement_GetVelocity(client, velocity);
	return velocity[2];
}

/**
 * Sets the player's vertical velocity.
 *
 * @param client		Client index.
 * @param value			New vertical velocity.
 */
stock void Movement_SetVerticalVelocity(int client, float value)
{
	float velocity[3];
	Movement_GetVelocity(client, velocity);
	velocity[2] = value;
	Movement_SetVelocity(client, velocity);
}

/**
 * Gets the player's base velocity.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 */
stock void Movement_GetBaseVelocity(int client, float result[3])
{
	GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", result);
}

/**
 * Sets the player's base velocity.
 *
 * @param client		Client index.
 * @param baseVelocity	New base velocity.
 */
stock void Movement_SetBaseVelocity(int client, const float baseVelocity[3])
{
	SetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", baseVelocity);
}

/**
 * Gets the player's eye angles.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 */
stock void Movement_GetEyeAngles(int client, float result[3])
{
	GetClientEyeAngles(client, result);
}

/**
 * Sets the player's eye angles by teleporting them.
 *
 * @param client		Client index.
 * @param eyeAngles		New eye angles.
 */
stock void Movement_SetEyeAngles(int client, const float eyeAngles[3])
{
	TeleportEntity(client, NULL_VECTOR, eyeAngles, NULL_VECTOR);
}

/**
 * Gets whether player is on the ground.
 *
 * @param client		Client index.
 * @return				Whether player is on the ground.
 */
stock bool Movement_GetOnGround(int client)
{
	return view_as<bool>(GetEntityFlags(client) & FL_ONGROUND);
}

/**
 * Gets whether player is ducking or ducked.
 *
 * @param client		Client index.
 * @return				Whether player is ducking or ducked.
 */
stock bool Movement_GetDucking(int client)
{
	return GetEntProp(client, Prop_Send, "m_bDucked") || GetEntProp(client, Prop_Send, "m_bDucking");
}

/**
 * Gets the player's "m_flDuckSpeed" value.
 *
 * @param client			Client index.
 * @return					Value of "m_flDuckSpeed".
 */
stock float Movement_GetDuckSpeed(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flDuckSpeed");
}

/**
 * Sets the player's "m_flDuckSpeed" value.
 *
 * @param client			Client index.
 * @param value				New "m_flDuckSpeed" value.
 */
stock void Movement_SetDuckSpeed(int client, float value)
{
	SetEntPropFloat(client, Prop_Send, "m_flDuckSpeed", value);
}

/**
 * Gets the player's "m_flVelocityModifier" value.
 *
 * @param client		Client index.
 * @return				Value of "m_flVelocityModifier".
 */
stock float Movement_GetVelocityModifier(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flVelocityModifier");
}

/**
 * Sets the player's "m_flVelocityModifier" value.
 *
 * @param client		Client index.
 * @param value			New "m_flVelocityModifier" value.
 */
stock void Movement_SetVelocityModifier(int client, float value)
{
	SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", value);
}

/**
 * Gets the player's gravity scale factor.
 *
 * @param client			Client index.
 * @return					Gravity scale factor.
 */
stock float Movement_GetGravity(int client)
{
	return GetEntityGravity(client);
}

/**
 * Sets the player's gravity scale factor.
 *
 * @param client			Client index.
 * @param value				Desired gravity scale factor.
 */
stock void Movement_SetGravity(int client, float value)
{
	SetEntityGravity(client, value);
}

/**
 * Gets the player's move type.
 *
 * @param client		Client index.
 * @return				Player's move type.
 */
stock MoveType Movement_GetMoveType(int client)
{
	return GetEntityMoveType(client);
}

/**
 * Sets the player's move type.
 *
 * @param client		Client index.
 * @param moveType 		New move type.
 */
stock void Movement_SetMoveType(int client, MoveType moveType)
{
	SetEntityMoveType(client, moveType);
}

/**
 * Gets whether player is on a ladder.
 *
 * @param client		Client index.
 * @return				Whether player is on a ladder.
 */
stock bool Movement_GetOnLadder(int client)
{
	return GetEntityMoveType(client) == MOVETYPE_LADDER;
}

/**
 * Gets whether player is noclipping.
 *
 * @param client		Client index.
 * @return				Whether player is noclipping.
 */
stock bool Movement_GetNoclipping(int client)
{
	return GetEntityMoveType(client) == MOVETYPE_NOCLIP;
}



// =========================  METHODMAP  ========================= //

methodmap MovementPlayer __nullable__ {
	
	public MovementPlayer(int client) {
		return view_as<MovementPlayer>(client);
	}
	
	property int id {
		public get() {
			return view_as<int>(this);
		}
	}
	
	property int buttons {
		public get() {
			return Movement_GetButtons(this.id);
		}
	}
	
	public void GetOrigin(float result[3]) {
		Movement_GetOrigin(this.id, result);
	}
	
	public void SetOrigin(const float origin[3]) {
		Movement_SetOrigin(this.id, origin);
	}
	
	public void GetVelocity(float result[3]) {
		Movement_GetVelocity(this.id, result);
	}
	
	public void SetVelocity(const float velocity[3]) {
		Movement_SetVelocity(this.id, velocity);
	}
	
	property float speed {
		public get() {
			return Movement_GetSpeed(this.id);
		}
		public set(float value) {
			Movement_SetSpeed(this.id, value);
		}
	}
	
	property float verticalVelocity {
		public get() {
			return Movement_GetVerticalVelocity(this.id);
		}
		public set(float value) {
			Movement_SetVerticalVelocity(this.id, value);
		}
	}
	
	public void GetBaseVelocity(float result[3]) {
		Movement_GetBaseVelocity(this.id, result);
	}
	
	public void SetBaseVelocity(const float baseVelocity[3]) {
		Movement_SetBaseVelocity(this.id, baseVelocity);
	}
	
	public void GetEyeAngles(float result[3]) {
		Movement_GetEyeAngles(this.id, result);
	}
	
	public void SetEyeAngles(const float eyeAngles[3]) {
		Movement_SetEyeAngles(this.id, eyeAngles);
	}
	
	property bool onGround {
		public get() {
			return Movement_GetOnGround(this.id);
		}
	}
	
	property bool ducking {
		public get() {
			return Movement_GetDucking(this.id);
		}
	}
	
	property float duckSpeed {
		public get() {
			return Movement_GetDuckSpeed(this.id);
		}
		public set(float value) {
			Movement_SetDuckSpeed(this.id, value);
		}
	}
	
	property float velocityModifier {
		public get() {
			return Movement_GetVelocityModifier(this.id);
		}
		public set(float value) {
			Movement_SetVelocityModifier(this.id, value);
		}
	}
	
	property float gravity {
		public get() {
			return Movement_GetGravity(this.id);
		}
		public set(float value) {
			Movement_SetGravity(this.id, value);
		}
	}
	
	property MoveType moveType {
		public get() {
			return Movement_GetMoveType(this.id);
		}
		public set(MoveType moveType) {
			Movement_SetMoveType(this.id, moveType);
		}
	}
	
	property bool onLadder {
		public get() {
			return Movement_GetOnLadder(this.id);
		}
	}
	
	property bool noclipping {
		public get() {
			return Movement_GetNoclipping(this.id);
		}
	}
} 