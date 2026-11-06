--!strict
--!native
local Color4 = {}
Color4.__index = Color4

Color4.__tostring = function(self: Color4)
	if getmetatable(self :: any) == Color4 then
		return string.format("%f, %f, %f, %f", self.R, self.G, self.B, self.A)
	end
	return "Color4 Constructor"
end

export type Color4 = {
	R: number,
	G: number,
	B: number,
	A: number	
}
& Color4Methods

export type Color4Constructors = {
	New: (r: number, g: number, b: number, a: number?) -> Color4,
	FromRGBA: (r: number, g: number, b: number, a: number?) -> Color4,
	FromHSVA: (hue: number, saturation: number, value: number, a: number?) -> Color4,
	FromHex: (hex: string) -> Color4,
	FromColor3: (c: Color3, a: number?) -> Color4,
}

export type Color4Methods = {
	Lerp: (self: Color4, target: Color4, alpha: number) -> Color4,

	WithAlpha: (self: Color4, a: number) -> Color4,
	Lighten: (self: Color4, amount: number) -> Color4,
	Darken: (self: Color4, amount: number) -> Color4,
	Invert: (self: Color4) -> Color4,
	Saturate: (self: Color4, amount: number?) -> Color4,

	GetLuminance: (self: Color4) -> number,
	GetContrastRatio: (self: Color4, other: Color3 | Color4) -> number,
	GetContrastingColor: (self: Color4, ...Color3 | Color4) -> Color4,

	ToHex: (self: Color4, addAlpha: boolean?) -> string,
	ToRGBA: (self: Color4, addAlpha: boolean?) -> (number, number, number, number?),
	ToHSVA: (self: Color4, addAlpha: boolean?) -> (number, number, number, number?),
	ToColor3: (self: Color4, addAlpha: boolean?) -> (Color3, number?),
}

-- Constructors

function Color4.New(r: number, g: number, b: number, a: number?): Color4
	local self = setmetatable({
		R = math.clamp(r, 0, 1),
		G = math.clamp(g, 0, 1),
		B = math.clamp(b, 0, 1),
		A = math.clamp(a or 1, 0, 1),
	}, Color4)

	return (self :: Color4)
end

function Color4.FromRGBA(r: number, g: number, b: number, a: number?): Color4
	return Color4.New(r / 255, g / 255, b / 255, a)
end

function Color4.FromHSVA(hue: number, saturation: number, value: number, a: number?): Color4
	local tc = Color3.fromHSV(hue, saturation, value)
	return Color4.New(tc.R, tc.G, tc.B, a)
end

function Color4.FromHex(hex: string): Color4
	local clean = string.gsub(hex, "^#", "")

	if not string.match(clean, "^%x+$") then
		error(`Invalid hex characters in '{hex}'`)
	end

	local len = #clean

	if len == 3 then
		clean = clean:gsub("(.)", "%1%1") .. "FF"
	elseif len == 6 then
		clean = clean .. "FF"
	elseif len == 4 then
		clean = clean:gsub("(.)", "%1%1")
	elseif len ~= 8 then
		error(`hex {hex} doesn't have a valid length ({len} is not 3, 4, 6, 8)`)
	end

	local r = (tonumber(string.sub(clean, 1, 2), 16) :: number) / 255
	local g = (tonumber(string.sub(clean, 3, 4), 16) :: number) / 255
	local b = (tonumber(string.sub(clean, 5, 6), 16) :: number) / 255
	local a = (tonumber(string.sub(clean, 7, 8), 16) :: number) / 255

	return Color4.New(r, g, b, a)
end

function Color4.FromColor3(c: Color3, a: number?): Color4
	return Color4.New(c.R, c.G, c.B, a)
end

-- Methods

function Color4.WithAlpha(self: Color4, a: number): Color4
	return Color4.New(self.R, self.G, self.B, a)
end

function Color4.Lerp(self: Color4, target: Color4, alpha: number): Color4
	return Color4.New(
		self.R + (target.R - self.R) * alpha,
		self.G + (target.G - self.G) * alpha,
		self.B + (target.B - self.B) * alpha,
		self.A + (target.A - self.A) * alpha
	)
end

function Color4.ToHex(self: Color4, addAlpha: boolean?): string
	if addAlpha == nil then
		addAlpha = true
	end

	if addAlpha then
		return Color3.new(self.R, self.G, self.B):ToHex() .. string.format("%02x", math.round(self.A * 255))
	else
		return Color3.new(self.R, self.G, self.B):ToHex()
	end
end

function Color4.ToColor3(self: Color4, addAlpha: boolean?): (Color3, number?)
	return Color3.new(self.R, self.G, self.B), if addAlpha then self.A else nil
end

function Color4.ToRGBA(self: Color4, addAlpha: boolean?): (number, number, number, number?)
	if addAlpha == nil then
		addAlpha = true
	end

	return math.round(self.R * 255), math.round(self.G * 255), math.round(self.B * 255), if addAlpha then self.A else nil
end

function Color4.ToHSVA(self: Color4, addAlpha: boolean?): (number, number, number, number?)
	if addAlpha == nil then
		addAlpha = true
	end

	local h, s, v = Color3.new(self.R, self.G, self.B):ToHSV()

	return h, s, v, if addAlpha then self.A else nil
end

function Color4.Lighten(self: Color4, amount: number): Color4
	local p = math.clamp(amount, 0, 1)
	return Color4.New(
		self.R + (1 - self.R) * p,
		self.G + (1 - self.G) * p,
		self.B + (1 - self.B) * p,
		self.A
	)
end

function Color4.Darken(self: Color4, amount: number): Color4
	local p = math.clamp(amount, 0, 1)
	return Color4.New(
		self.R * (1 - p),
		self.G * (1 - p),
		self.B * (1 - p),
		self.A
	)
end

function Color4.Invert(self: Color4): Color4
	return Color4.New(1 - self.R, 1 - self.G, 1 - self.B, self.A)
end

function Color4.GetLuminance(self: Color4): number
	--return (0.2126 * self.R) + (0.7152 * self.G) + (0.0722 * self.B)
	return Color3.new(self.R, self.G, self.B):GetLuminance()
end

function Color4.Saturate(self: Color4, amount: number?): Color4
	local amount = math.clamp(amount or 0, 0, 100)
	local lum = self:GetLuminance()

	return Color4.New(lum + amount * (self.R - lum), lum + amount * (self.G - lum), lum + amount * (self.B - lum), self.A)
end

function Color4.GetContrastRatio(self: Color4, other: Color3 | Color4): number
	--local lum1 = self:GetLuminance()
	--local lum2 = if typeof(other) == "Color3" then Color4.FromColor3(other):GetLuminance() else other:GetLuminance()

	--local lighter = math.max(lum1, lum2)
	--local darker = math.min(lum1, lum2)

	--return (lighter + 0.05) / (darker + 0.05)
	local otherC3 = if typeof(other) == "Color3" then other else other:ToColor3()
	return self:ToColor3():GetContrastRatio(otherC3)
end

function Color4.GetContrastingColor(self: Color4, ...: Color3 | Color4): Color4
	local cols = {...} -- dont care if nils get dropped, there arent supposed to be nils
	local currentTop = nil
	local currentTopScore = 0 -- score will always be higher

	if #cols < 2 then -- drop if 0 or 1 cuz like why are you asking me for it if you know the answer already
		cols = {Color4.New(0,0,0, self.A), Color4.New(1,1,1, self.A)} -- maybe it should have the original colors opacity?
	end

	for _, c in ipairs(cols :: {Color4}) do
		local score = self:GetContrastRatio(c)
		if score > currentTopScore then
			currentTop = c
			currentTopScore = score
		end
	end

	if typeof(currentTop) == "Color3" then
		currentTop = Color4.FromColor3(currentTop, self.A)
	end

	return currentTop :: Color4
end

return Color4 :: Color4Constructors
