/* 	
	MovementAPI Plugin Include

	Website: https://github.com/danzayau/MovementAPI	
*/

#if defined _movementapi_included_
#endinput
#endif
#define _movementapi_included_

#include <movement>



/*
	Terminology

	Takeoff
	Becoming airborne, including jumping, falling, getting off a ladder and leaving noclip.
	
	Landing
	Leaving the air, including landing on the ground, grabbing a ladder and entering noclip.
	
	Perfect Bunnyhop (Perf)
	When the player has jumped in the tick after landing and keeps their speed.
*/



// =========================  FORWARDS  ========================= //

/**
 * Called when an alive player presses a button.
 *
 * @param client		Client index.
 * @param button		Button pressed e.g. IN_FORWARD, IN_LEFT.
 * @noreturn
 */
forward void Movement_OnButtonPress(int client, int button);

/**
 * Called when an alive player releases a button.
 *
 * @param client		Client index.
 * @param button		Button released e.g. IN_FORWARD, IN_LEFT.
 * @noreturn
 */
forward void Movement_OnButtonRelease(int client, int button);

/**
 * Called when a player starts ducking.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void Movement_OnStartDucking(int client);

/**
 * Called when a player stops ducking.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void Movement_OnStopDucking(int client);

/**
 * Called when a player touches the ground.
 *
 * @param client		Client index.
 * @noreturn
 */
forward void Movement_OnStartTouchGround(int client);

/**
 * Called when a player leaves the ground.
 *
 * @param client		Client index.
 * @param jumped		Whether player jumped to leave ground.
 * @noreturn
 */
forward void Movement_OnStopTouchGround(int client, bool jumped);

/**
 * Called when the player's move type changes.
 *
 * @param client		Client index.
 * @param oldMoveType	Player's old move type.
 * @param newMoveType	Player's new move type.
 * @noreturn
 */
forward void Movement_OnChangeMoveType(int client, MoveType oldMoveType, MoveType newMoveType);



// =========================  NATIVES  ========================= //

/**
 * Gets whether player's last takeoff was a jump.
 *
 * @param client    	Client index.
 * @return        		Whether player's last takeoff was a jump.
 */
native bool Movement_GetJumped(int client);

/**
 * Gets whether player's last takeoff was a perfect bunnyhop.
 *
 * @param client    	Client index.
 * @return        		Whether player's last takeoff was a perfect bunnyhop.
 */
native bool Movement_GetHitPerf(int client);

/**
 * Gets the player's origin at the time of their last takeoff.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 * @noreturn
 */
native void Movement_GetTakeoffOrigin(int client, float result[3]);

/**
 * Gets the player's velocity at the time of their last takeoff.
 *
 * If sv_enablebunnyhopping is 0, CS:GO may adjust the player's 
 * velocity after the takeoff velocity has already been measured.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 * @noreturn
 */
native void Movement_GetTakeoffVelocity(int client, float result[3]);

/**
 * Gets the player's horizontal speed at the time of their last takeoff.
 *
 * If sv_enablebunnyhopping is 0, CS:GO may adjust the player's 
 * velocity after the takeoff velocity has already been measured.
 *
 * @param client    	Client index.
 * @return        		Player's last takeoff speed.
 */
native float Movement_GetTakeoffSpeed(int client);

/**
 * Gets player's tick count at the time of their last takeoff.
 *
 * @param client    	Client index.
 * @return        		Player's last takeoff tick count.
 */
native int Movement_GetTakeoffTick(int client);

/**
 * Gets the player's origin at the time of their last landing.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 * @noreturn
 */
native void Movement_GetLandingOrigin(int client, float result[3]);

/**
 * Gets the player's velocity at the time of their last landing.
 *
 * @param client		Client index.
 * @param result		Resultant vector.
 * @noreturn
 */
native void Movement_GetLandingVelocity(int client, float result[3]);

/**
 * Gets the player's horizontal speed at the time of their last landing.
 *
 * @param client    	Client index.
 * @return        		Last landing speed of the player (horizontal).
 */
native float Movement_GetLandingSpeed(int client);

/**
 * Gets player's tick count at the time of their last landing.
 *
 * @param client    	Client index.
 * @return        		Player's last takeoff tick count.
 */
native int Movement_GetLandingTick(int client);

/**
 * Gets whether player is turning their aim horizontally.
 *
 * @param client    	Client index.
 * @return        		Whether player is turning their aim horizontally.
 */
native bool Movement_GetTurning(int client);

/**
 * Gets whether player is turning their aim left.
 *
 * @param client    	Client index.
 * @return        		Whether player is turning their aim left.
 */
native bool Movement_GetTurningLeft(int client);

/**
 * Gets whether player is turning their aim right.
 *
 * @param client    		Client index.
 * @return        			Whether player is turning their aim right.
 */
native bool Movement_GetTurningRight(int client);



// =========================  METHODMAP  ========================= //

methodmap MovementAPIPlayer __nullable__ < MovementPlayer {
	
	public MovementAPIPlayer(int id) {
		return view_as<MovementAPIPlayer>(id);
	}
	
	property int id {
		public get() {
			return view_as<int>(this);
		}
	}
	
	property bool jumped {
		public get() {
			return Movement_GetJumped(this.id);
		}
	}
	
	property bool hitPerf {
		public get() {
			return Movement_GetHitPerf(this.id);
		}
	}
	
	public void GetTakeoffOrigin(float buffer[3]) {
		Movement_GetTakeoffOrigin(this.id, buffer);
	}
	
	public void GetTakeoffVelocity(float buffer[3]) {
		Movement_GetTakeoffVelocity(this.id, buffer);
	}
	
	property float takeoffSpeed {
		public get() {
			return Movement_GetTakeoffSpeed(this.id);
		}
	}
	
	property int takeoffTick {
		public get() {
			return Movement_GetTakeoffTick(this.id);
		}
	}
	
	public void GetLandingOrigin(float buffer[3]) {
		Movement_GetLandingOrigin(this.id, buffer);
	}
	
	public void GetLandingVelocity(float buffer[3]) {
		Movement_GetLandingVelocity(this.id, buffer);
	}
	
	property float landingSpeed {
		public get() {
			return Movement_GetLandingSpeed(this.id);
		}
	}
	
	property int landingTick {
		public get() {
			return Movement_GetLandingTick(this.id);
		}
	}
	
	property bool turning {
		public get() {
			return Movement_GetTurning(this.id);
		}
	}
	
	property bool turningLeft {
		public get() {
			return Movement_GetTurningLeft(this.id);
		}
	}
	
	property bool turningRight {
		public get() {
			return Movement_GetTurningRight(this.id);
		}
	}
}



// =========================  DEPENDENCY  ========================= //

public SharedPlugin __pl_movementapi = 
{
	name = "movementapi", 
	file = "movementapi.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_movementapi_SetNTVOptional()
{
	MarkNativeAsOptional("Movement_GetJumped");
	MarkNativeAsOptional("Movement_GetHitPerf");
	MarkNativeAsOptional("Movement_GetTakeoffOrigin");
	MarkNativeAsOptional("Movement_GetTakeoffVelocity");
	MarkNativeAsOptional("Movement_GetTakeoffSpeed");
	MarkNativeAsOptional("Movement_GetTakeoffTick");
	MarkNativeAsOptional("Movement_GetLandingOrigin");
	MarkNativeAsOptional("Movement_GetLandingVelocity");
	MarkNativeAsOptional("Movement_GetLandingSpeed");
	MarkNativeAsOptional("Movement_GetLandingTick");
	MarkNativeAsOptional("Movement_GetTurning");
	MarkNativeAsOptional("Movement_GetTurningLeft");
	MarkNativeAsOptional("Movement_GetTurningRight");
}
#endif