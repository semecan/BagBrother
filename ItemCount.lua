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

local FIRST_BAG_SLOT = BACKPACK_CONTAINER
local LAST_BAG_SLOT = FIRST_BAG_SLOT + NUM_BAG_SLOTS
local LAST_BANK_SLOT = NUM_BAG_SLOTS + NUM_BANKBAGSLOTS
local FIRST_BANK_SLOT = NUM_BAG_SLOTS + 1
local LAST_INVENTORY_SLOT = ContainerIDToInventoryID(NUM_BAG_SLOTS);
local BAG_TYPE_BANK = 'bank'
local BAG_TYPE_BAG = 'bags'
local BAG_TYPE_EQUIP = 'equip'

local itemCountCache = {}

local function getBagType (bag)
  if (type(bag) ~= 'number') then
    return bag
  end

  if (bag >= FIRST_BAG_SLOT and bag <= LAST_BAG_SLOT) then
    return BAG_TYPE_BAG
  end

  if (bag == BANK_CONTAINER) then
    return BAG_TYPE_BANK
  end

  if (bag >= FIRST_BANK_SLOT and bag <= LAST_BANK_SLOT) then
    return BAG_TYPE_BANK
  end

  if (REAGENTBANK_CONTAINER ~= nil and bag == REAGENTBANK_CONTAINER) then
    return BAG_TYPE_BANK
  end

  -- this part should never be reached
  return BAG_TYPE_BAG
end

local function initItemCountCache(realm, owner)
  local BrotherBags = _G.BrotherBags or {}
  local realmData = BrotherBags[realm]

  if (realmData == nil) then
    return false
  end

  local ownerData = realmData[owner]

  if (ownerData == nil) then
    return false
  end

  local realmCache = itemCountCache[realm] or {}
  local ownerCache = realmCache[owner] or {}

  for bag, bagData in pairs(ownerData) do
    if (type(bagData) == 'table') then
      local bagCounts

      bag = getBagType(bag)
      bagCounts = ownerCache[bag] or {}

      for slot, item in pairs(bagData) do
        if (type(slot) == 'number' and type(item) == 'string' and
            (bag ~= BAG_TYPE_EQUIP or slot <= LAST_INVENTORY_SLOT)) then
          local link, count = strsplit(';', item)
          local id = strsplit(':', link)

          id = tonumber(id)
          count = tonumber(count or 1)

          bagCounts[id] = (bagCounts[id] or 0) + count
        end
      end

      ownerCache[bag] = bagCounts
    end
  end

  itemCountCache[realm] = realmCache
  realmCache[owner] = ownerCache

  return true
end

function addon:GetItemCount (realm, owner, bag, itemId)
  local data = itemCountCache[realm]

  bag = getBagType(bag)

  if ((data == nil or data[owner] == nil) and
      not initItemCountCache(realm, owner)) then
    return 0
  end

  data = itemCountCache[realm][owner][bag]

  if (data == nil) then
    return 0
  end

  return data[itemId] or 0
end
