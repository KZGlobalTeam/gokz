/*
	gokz-anticheat Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_anticheat_included_
#endinput
#endif
#define _gokz_anticheat_included_



// =====[ ENUMS ]=====

enum ACReason:
{
	ACReason_BhopMacro, 
	ACReason_BhopHack
};



// =====[ CONSTANTS ]=====

#define AC_MAX_BUTTON_SAMPLES 40
#define AC_MAX_BHOP_GROUND_TICKS 4
#define AC_MAX_BHOP_SAMPLES 30
#define AC_BINDEXCEPTION_SAMPLES 5
#define AC_LOG_PATH "logs/gokz-anticheat.log"



// =====[ FORWARDS ]=====

/**
 * Called when gokz-anticheat suspects a player of cheating.
 *
 * @param client		Client index.
 * @param reason		Reason for suspicion.
 * @param notes			Additional reasoning, description etc.
 * @param stats			Data supporting the suspicion e.g. scroll pattern.
 */
forward void GOKZ_AC_OnPlayerSuspected(int client, ACReason reason, const char[] notes, const char[] stats);



// =====[ NATIVES ]=====

/**
 * Gets the number of recent bhop samples available for a player.
 *
 * @param client		Client index.
 * @return				Number of bhop samples available.
 */
native int GOKZ_AC_GetSampleSize(int client);

/**
 * Gets whether a player hit a perfect bhop for a number of 
 * recent bhops. Buffer must be large enough to fit the sample
 * size.
 *
 * @param client		Client index.
 * @param buffer		Buffer for perfect bhop booleans, with the first element being the most recent bhop.
 * @param sampleSize	Maximum recent bhop samples.
 * @return				Number of bhop samples.
 */
native int GOKZ_AC_GetHitPerf(int client, bool[] buffer, int sampleSize);

/**
 * Gets a player's number of perfect bhops out of a sample 
 * size of bhops.
 *
 * @param client		Client index.
 * @param sampleSize	Maximum recent bhop samples to include in calculation.
 * @return				Player's number of perfect bhops.
 */
native int GOKZ_AC_GetPerfCount(int client, int sampleSize);

/**
 * Gets a player's ratio of perfect bhops to normal bhops.
 *
 * @param client		Client index.
 * @param sampleSize	Maximum recent bhop samples to include in calculation.
 * @return				Player's ratio of perfect bhops to normal bhops.
 */
native float GOKZ_AC_GetPerfRatio(int client, int sampleSize);

/**
 * Gets a player's jump input counts for a number of recent 
 * bhops. Buffer must be large enough to fit the sample size.
 *
 * @param client		Client index.
 * @param buffer		Buffer for jump input counts, with the first element being the most recent bhop.
 * @param sampleSize	Maximum recent bhop samples.
 * @return				Number of bhop samples.
 */
native int GOKZ_AC_GetJumpInputs(int client, int[] buffer, int sampleSize);

/**
 * Gets a player's average number of jump inputs for a number 
 * of recent bhops.
 *
 * @param client		Client index.
 * @param sampleSize	Maximum recent bhop samples to include in calculation.
 * @return				Player's average number of jump inputs.
 */
native float GOKZ_AC_GetAverageJumpInputs(int client, int sampleSize);

/**
 * Gets a player's jump input counts prior to a number of recent 
 * bhops. Buffer must be large enough to fit the sample size. 
 * Includes the jump input that resulted in the jump.
 *
 * @param client		Client index.
 * @param buffer		Buffer for jump input counts, with the first element being the most recent bhop.
 * @param sampleSize	Maximum recent bhop samples.
 * @return				Number of bhop samples.
 */
native int GOKZ_AC_GetPreJumpInputs(int client, int[] buffer, int sampleSize);

/**
 * Gets a player's jump input counts after a number of recent 
 * bhops. Buffer must be large enough to fit the sample size. 
 * Excludes the jump input that resulted in the jump.
 *
 * @param client		Client index.
 * @param buffer		Buffer for jump input counts, with the first element being the most recent bhop.
 * @param sampleSize	Maximum recent bhop samples.
 * @return				Number of bhop samples.
 */
native int GOKZ_AC_GetPostJumpInputs(int client, int[] buffer, int sampleSize);



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_anticheat = 
{
	name = "gokz-anticheat", 
	file = "gokz-anticheat.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gokz_anticheat_SetNTVOptional()
{
	MarkNativeAsOptional("GOKZ_AC_GetSampleSize");
	MarkNativeAsOptional("GOKZ_AC_GetHitPerf");
	MarkNativeAsOptional("GOKZ_AC_GetPerfCount");
	MarkNativeAsOptional("GOKZ_AC_GetPerfRatio");
	MarkNativeAsOptional("GOKZ_AC_GetJumpInputs");
	MarkNativeAsOptional("GOKZ_AC_GetAverageJumpInputs");
	MarkNativeAsOptional("GOKZ_AC_GetPreJumpInputs");
	MarkNativeAsOptional("GOKZ_AC_GetPostJumpInputs");
}
#endif