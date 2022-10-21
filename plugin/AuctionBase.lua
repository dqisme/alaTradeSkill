--[[--
	by ALA @ 163UI
--]]--

local __addon, __private = ...;
local __db__ = __private.__db__;
local L = __private.L;

-->		upvalue
	local next = next;
	local strmatch = string.match;
	local RequestLoadItemDataByID = RequestLoadItemDataByID or C_Item.RequestLoadItemDataByID;
	local GetItemInfo = GetItemInfo;
-->

local SET = nil;
local F = CreateFrame('FRAME');


-->		****
__private:BuildEnv("AuctionBase");
-->		****


local AuctionBase = {  };

local T_MaterialVendorPrice = __db__.T_MaterialVendorPrice;
local T_MaterialVendorPriceByName = {  };
local function LF_CacheItem(id)
	local name = GetItemInfo(id);
	if name ~= nil then
		T_MaterialVendorPriceByName[name] = T_MaterialVendorPrice[id];
		return true;
	else
		return false;
	end
end
local N_MaterialVendorPrice = 0;
for id, price in next, T_MaterialVendorPrice do
	N_MaterialVendorPrice = N_MaterialVendorPrice + 1;
end
F:RegisterEvent("ITEM_DATA_LOAD_RESULT");
F:SetScript("OnEvent", function(self, event, arg1, arg2)
	if T_MaterialVendorPrice[arg1] ~= nil then
		if arg2 and LF_CacheItem(arg1) then
			N_MaterialVendorPrice = N_MaterialVendorPrice - 1;
		else
			RequestLoadItemDataByID(arg1);
		end
		if N_MaterialVendorPrice <= 0 then
			self:SetScript("OnEvent", nil);
			self:UnregisterAllEvents();
			F = nil;
		end
	end
end);
for id, price in next, T_MaterialVendorPrice do
	RequestLoadItemDataByID(id);
end
--
function AuctionBase.F_QueryVendorPriceByLink(link, num)
	local id = tonumber(strmatch(link, "item:(%d+)"));
	return id ~= nil and AuctionBase.F_QueryVendorPriceByID(id, num);
end
function AuctionBase.F_QueryVendorPriceByID(id, num)
	local p = T_MaterialVendorPrice[id];
	if p ~= nil then
		if num ~= nil then
			return p * num;
		else
			return p;
		end
	else
		return nil;
	end
end
function AuctionBase.F_QueryVendorPriceByName(name, num)
	local p = T_MaterialVendorPriceByName[name];
	if p ~= nil then
		if num ~= nil then
			return p * num;
		else
			return p;
		end
	else
		return nil;
	end
end

function AuctionBase.F_QueryNameByID(id)
	return nil;
end
function AuctionBase.F_QueryQualityByID(id)
	return nil;
end

local T_AuctionList = {  };
local T_AuctionDrop = {
	["*"] = {
		text = L.SLASH_NOTE["first_auction_mod:*"],
		para = { "*", },
	},
};
local T_AuctionModList = {  };
local T_AliasList = {
	F_QueryVendorPriceByLink = "get_material_vendor_price_by_link",
	F_QueryVendorPriceByID = "get_material_vendor_price_by_id",
	F_QueryVendorPriceByName = "get_material_vendor_price_by_name",
	F_QueryNameByID = "query_name_by_id",
	F_QueryQualityByID = "query_quality_by_id",
	--
	F_QueryPriceByName = "query_ah_price_by_name",
	F_QueryPriceByID = "query_ah_price_by_id",
	F_OnDBUpdate = "add_cache_callback",
};
local function handler(_, addon)
	if addon ~= SET.first_auction_mod then
		SET.first_auction_mod = addon;
		if T_AuctionModList[addon] ~= nil then
			__private:FireEvent("AUCTION_MOD_LOADED", T_AuctionModList[addon]);
		end
	end
end
local function __onshow(Button)
	Button.Text:SetText(">> |cff00ff00" .. (Button.Text:GetText() or "") .. "|r <<");
end
function __private.F_GetAuctionListDropMeta()
	local meta = {
		handler = handler,
		elements = {  },
	};
	local pos = 1;
	if SET.first_auction_mod == "*" or T_AuctionDrop[SET.first_auction_mod] == nil then
		local v = T_AuctionDrop["*"];
		v.__onshow = __onshow;
		meta.elements[1] = v;
		pos = 2;
	else
		local v = T_AuctionDrop[SET.first_auction_mod];
		v.__onshow = __onshow;
		meta.elements[1] = v;
		local v = T_AuctionDrop["*"];
		v.__onshow = nil;
		meta.elements[2] = v;
		pos = 3;
	end
	for index = 1, #T_AuctionList do
		local addon = T_AuctionList[index];
		if addon ~= SET.first_auction_mod then
			local v = T_AuctionDrop[addon];
			if v ~= nil then
				v.__onshow = nil;
				meta.elements[pos] = v;
				pos = pos + 1;
			end
		end
	end
	return meta;
end
function __private.F_AddAuctionMod(id, mod)
	for key, val in next, AuctionBase do
		local alias = T_AliasList[key];
		mod[key] = mod[key] or mod[alias] or val;
	end
	if T_AuctionModList[id] == nil then
		T_AuctionModList[#T_AuctionModList + 1] = id;
	end
	T_AuctionModList[id] = mod;
	if id == SET.first_auction_mod or T_AuctionModList[SET.first_auction_mod] == nil then
		__private:FireEvent("AUCTION_MOD_LOADED", mod);
	end
end
function __private.F_GetAuctionMod()
	return T_AuctionModList[T_AuctionModList[1]];
end
function __private.F_AuctionModCallback(addon, callback)
	if T_AuctionList[addon] == nil then
		local index = #T_AuctionList + 1;
		T_AuctionList[index] = addon;
		T_AuctionList[addon] = index;
		T_AuctionDrop[addon] = {
			text = addon,
			para = { addon, },
		};
	end
	__private:AddAddOnCallback(addon, callback);
end
function __private.init_auctionmod()
	SET = __private.SET;
end
