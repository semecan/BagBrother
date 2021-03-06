--[[
Copyright 2011-2020 João Cardoso
BagBrother is distributed under the terms of the GNU General Public License (Version 3).
As a special exception, the copyright holders of this addon do not give permission to
redistribute and/or modify it.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the addon. If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.

This file is part of BagBrother.
--]]

local _, addon = ...
local BagBrother = addon.BagBrother

local FIRST_BANK_SLOT = 1 + NUM_BAG_SLOTS
local LAST_BANK_SLOT = NUM_BANKBAGSLOTS + NUM_BAG_SLOTS

function BagBrother:IsBankBag(bag)
  return (bag == BANK_CONTAINER or
          (bag >= FIRST_BANK_SLOT and bag <= LAST_BANK_SLOT));
end

function BagBrother:SaveBag(bag)
	self:SaveBagContent(bag)
	self:SaveEquip(ContainerIDToInventoryID(bag), 1)
end

function BagBrother:SaveBagContent (bag)
	local size = GetContainerNumSlots(bag)

	if size == 0 then
		self.Player[bag] = nil
		addon:UnCachePlayerBag(bag)
		return
	end

	local items = {}

	for slot = 1, size do
		local _, count, _,_,_,_, link = GetContainerItemInfo(bag, slot)
		items[slot] = self:ParseItem(link, count)
	end

	items.size = size
	self.Player[bag] = items
	addon:UnCachePlayerBag(bag)
end

function BagBrother:UpdateBagSlot (bag, slot)
	local items = self.Player[bag]
	local _, count, _,_,_,_, link = GetContainerItemInfo(bag, slot)

	items[slot] = self:ParseItem(link, count)
	addon:UnCachePlayerBag(bag)
end

function BagBrother:SaveEquip(i, count)
	local oldLink = self.Player.equip[i]
	local link = GetInventoryItemLink('player', i)

	count = count or GetInventoryItemCount('player', i)
	link = self:ParseItem(link, count)

	if (link ~= oldLink) then
		self.Player.equip[i] = link
		addon:UnCachePlayerBag('equip')
	end
end

function BagBrother:ParseItem(link, count)
	if link then
		local id = tonumber(link:match('item:(%d+):')) -- check for profession window bug
		if id == 0 and TradeSkillFrame then
			local focus = GetMouseFocus():GetName()

			if focus == 'TradeSkillSkillIcon' then
				link = GetTradeSkillItemLink(TradeSkillFrame.selectedSkill)
			else
				local i = focus:match('TradeSkillReagent(%d+)')
				if i then
					link = GetTradeSkillReagentItemLink(TradeSkillFrame.selectedSkill, tonumber(i))
				end
			end
		end

		if link:find('0:0:0:0:0:%d+:%d+:%d+:0:0') then
			link = link:match('|H%l+:(%d+)')
		else
			link = link:match('|H%l+:([%d:]+)')
		end

		if count and count > 1 then
			link = link .. ';' .. count
		end

		return link
	end
end
