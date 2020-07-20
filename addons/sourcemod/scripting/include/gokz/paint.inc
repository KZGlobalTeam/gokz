/*
	gokz-paint Plugin Include
	
	Website: https://bitbucket.org/kztimerglobalteam/gokz
*/

#if defined _gokz_paint_included_
#endinput
#endif
#define _gokz_paint_included_



// =====[ ENUMS ]=====

enum PaintOption:
{
	PAINTOPTION_INVALID = -1, 
	PaintOption_Color,
	PaintOption_Size,
	PAINTOPTION_COUNT
};

enum
{
	PaintColor_Red = 0,
	PaintColor_White,
	PaintColor_Black,
	PaintColor_Blue,
	PaintColor_Brown,
	PaintColor_Green,
	PaintColor_Yellow,
	PaintColor_Purple,
	PAINTCOLOR_COUNT
};

enum
{
	PaintSize_Small = 0,
	PaintSize_Medium,
	PaintSize_Big,
	PAINTSIZE_COUNT
};



// =====[ CONSTANTS ]=====

#define PAINT_OPTION_CATEGORY "Paint"
#define MIN_PAINT_SPACING 1.0

stock char gC_PaintOptionNames[PAINTOPTION_COUNT][] = 
{
	"GOKZ Paint - Color",
	"GOKZ Paint - Size"
};

stock char gC_PaintOptionDescriptions[PAINTOPTION_COUNT][] = 
{
	"Paint Color",
	"Paint Size - 0 = Small, 1 = Medium, 2 = Big"
};

stock char gC_PaintOptionPhrases[PAINTOPTION_COUNT][] = 
{
	"Options Menu - Paint Color",
	"Options Menu - Paint Size"
};

stock int gI_PaintOptionCounts[PAINTOPTION_COUNT] = 
{
	PAINTCOLOR_COUNT,
	PAINTSIZE_COUNT
};

stock int gI_PaintOptionDefaults[PAINTOPTION_COUNT] = 
{
	PaintColor_Red,
	PaintSize_Medium
};

stock char gC_PaintColorPhrases[PAINTCOLOR_COUNT][] = 
{
	"Options Menu - Red",
	"Options Menu - White",
	"Options Menu - Black",
	"Options Menu - Blue",
	"Options Menu - Brown",
	"Options Menu - Green",
	"Options Menu - Yellow",
	"Options Menu - Purple"
};

stock char gC_PaintSizePhrases[PAINTSIZE_COUNT][] = 
{
	"Options Menu - Small", 
	"Options Menu - Medium", 
	"Options Menu - Big"
};



// =====[ DEPENDENCY ]=====

public SharedPlugin __pl_gokz_paint = 
{
	name = "gokz-paint", 
	file = "gokz-paint.smx", 
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};
