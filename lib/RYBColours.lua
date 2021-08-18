--[[
*	RYBColours - R.Y.B. colours
*
*	Colour wheel: an illustrative organization of color hues in a circle that shows relationships.
*	Colourfulness, chroma, purity, or saturation: how "intense" or "concentrated" a color is. 
*		Technical definitions distinguish between colourfulness, chroma, and saturation as distinct 
*		perceptual attributes and include purity as a physical quantity. These terms, and others related 
*		to light and colour are internationally agreed upon and published in the CIE Lighting Vocabulary.
*		More readily available texts on colorimetry also define and explain these terms.
*	Dichromatism: a phenomenon where the hue is dependent on concentration and thickness of the absorbing substance.
*	Hue: the colour's direction from white, for example in a color wheel or chromaticity diagram.
*	Shade: a colour made darker by adding black.
*	Tint: a colour made lighter by adding white.
*	Value, brightness, lightness, or luminosity: how light or dark a colour is.
]]

local wx 		= require "wx"
local hslConv 	= require("lib.hsl")

-- ----------------------------------------------------------------------------
-- Secondary colours have 1 underscore
-- Tertiary colours have 2 underscores
--
local ColourTable =
{
	["Red"]			=  hslConv.fromHSL(  5.33898, 0.99159, 0.53333),
	["__Vermillion"]=  hslConv.fromHSL( 21.32231, 0.97580, 0.51372),
	["_Orange"]		=  hslConv.fromHSL( 36.38554, 0.98418, 0.49607),
	["__Amber"]		=  hslConv.fromHSL( 47.25663, 0.97413, 0.54509),
	["Yellow"]		=  hslConv.fromHSL( 60.00000, 0.99024, 0.59803),
	["__Chartreuse"]=  hslConv.fromHSL( 73.45454, 0.67346, 0.51960),
	["_Green"]		=  hslConv.fromHSL( 80.00000, 0.43820, 0.34901),
	["__Teal"]		=  hslConv.fromHSL(196.80000, 0.49019, 0.40000),
	["Blue"]		=  hslConv.fromHSL(223.57142, 0.99212, 0.50196),
	["__Violet"]	=  hslConv.fromHSL(250.78651, 0.71200, 0.49019),
	["_Purple"]		=  hslConv.fromHSL(285.86206, 0.98863, 0.34509),
	["__Magenta"]	=  hslConv.fromHSL(333.79310, 0.81308, 0.41960),
	
	["Gray0"]		=  hslConv.fromHSL(  0.00000, 0.00000, 0.00000),
	["Gray25"]		=  hslConv.fromHSL(  0.00000, 0.00000, 0.25098),
	["Gray50"]		=  hslConv.fromHSL(  0.00000, 0.00000, 0.50196),
	["Gray75"]		=  hslConv.fromHSL(  0.00000, 0.00000, 0.75294),
	["Gray100"]		=  hslConv.fromHSL(  0.00000, 0.00000, 1.00000),
}

-- ----------------------------------------------------------------------------
--
local function AsWxColour(inHSLColour)

	return wx.wxColour(inHSLColour:toRGB())
end

-- ----------------------------------------------------------------------------
--
return 
{
	tColours	= ColourTable,
	wxColour 	= AsWxColour,
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
