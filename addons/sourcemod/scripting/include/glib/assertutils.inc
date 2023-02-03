#if defined _assertutils_included
#endinput
#endif
#define _assertutils_included

/* Compile time settings for this include. Should be defined before including this file.
*  #define ASSERTUTILS_DISABLE			//Disables all assertions
*  #define ASSERTUTILS_FAILSTATE_FUNC	//Define the name of the function that should be called when assertion is hit
*/

#if !defined SNAME
#define __SNAME ""
#else
#define __SNAME SNAME
#endif

#define ASSERT_FMT_STRING_LEN 512

#if defined ASSERTUTILS_DISABLE

#define ASSERT(%1)%2;
#define ASSERT_MSG(%1,%2)%3;
#define ASSERT_FMT(%1,%2)%3;
#define ASSERT_FINAL(%1)%2;
#define ASSERT_FINAL_MSG(%1,%2)%3;

#elseif defined ASSERTUTILS_FAILSTATE_FUNC

#define ASSERT(%1) if(!(%1)) ASSERTUTILS_FAILSTATE_FUNC(__SNAME..."Assertion failed: \""...#%1..."\"")
#define ASSERT_MSG(%1,%2) if(!(%1)) ASSERTUTILS_FAILSTATE_FUNC(__SNAME...%2)
#define ASSERT_FMT(%1,%2) if(!(%1)) ASSERTUTILS_FAILSTATE_FUNC(__SNAME...%2)
#define ASSERT_FINAL(%1) if(!(%1)) SetFailState(__SNAME..."Assertion failed: \""...#%1..."\"")
#define ASSERT_FINAL_MSG(%1,%2) if(!(%1)) SetFailState(__SNAME...%2)

#else

#define ASSERT(%1) if(!(%1)) SetFailState(__SNAME..."Assertion failed: \""...#%1..."\"")
#define ASSERT_MSG(%1,%2) if(!(%1)) SetFailState(__SNAME...%2)
#define ASSERT_FMT(%1,%2) if(!(%1)) SetFailState(__SNAME...%2)
#define ASSERT_FINAL(%1) ASSERT(%1)
#define ASSERT_FINAL_MSG(%1,%2) ASSERT_MSG(%1,%2)

#endif

// Might be redundant as default ASSERT_MSG accept format arguments just fine.
#if 0
stock void ASSERT_FMT(bool result, char[] fmt, any ...)
{
#if !defined ASSERTUTILS_DISABLE
	if(!result)
	{
		char buff[ASSERT_FMT_STRING_LEN];
		VFormat(buff, sizeof(buff), fmt, 3);
		
		SetFailState(__SNAME..."%s", buff);
	}
#endif
}
#endif

#undef ASSERT_FMT_STRING_LEN