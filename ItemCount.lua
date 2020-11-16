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

local FIRST_BAG_SLOT = BACKPACK_CONTAINER
local LAST_BAG_SLOT = FIRST_BAG_SLOT + NUM_BAG_SLOTS
local LAST_BANK_SLOT = NUM_BAG_SLOTS + NUM_BANKBAGSLOTS
local FIRST_BANK_SLOT = NUM_BAG_SLOTS + 1
local FIRST_INV_SLOT = INVSLOT_FIRST_EQUIPPED
local LAST_INV_SLOT = INVSLOT_LAST_EQUIPPED
local BAG_TYPE_BAG = 'bags'
local BAG_TYPE_BANK = 'bank'
local BAG_TYPE_REAGENTS = 'reagents'
local BAG_TYPE_VAULT = 'vault'
local BAG_TYPE_EQUIP = 'equip'
local BAG_TYPE_BAGSLOTS = 'bagslots'
local BAG_TYPE_BANKBAGSLOTS = 'bankbagslots'

local itemCountCache = {}
local playerRealmCache
local playerCache

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
    return BAG_TYPE_REAGENTS
  end

  -- this part should never be reached
  return BAG_TYPE_BAG
end

local function updateCacheCount (cache, item)
  if (type(item) ~= 'string') then
    return
  end

  local link, count = strsplit(';', item)
  local id = strsplit(':', link)

  id = tonumber(id)
  count = tonumber(count or 1)

  cache[id] = (cache[id] or 0) + count
end

local function initBagItemCountCache (bagCache, bagData)
  if (type(bagData) ~= 'table') then
    return bagCache
  end

  for _, item in pairs(bagData) do
    updateCacheCount(bagCache, item)
  end

  return bagCache
end

local function initBagRangeCache (ownerData, firstBag, lastBag)
  local bagCache = {}

  for x = firstBag, lastBag, 1 do
    initBagItemCountCache(bagCache, ownerData[x])
  end

  return bagCache
end

local function initBagCache (ownerData)
  return initBagRangeCache(ownerData, FIRST_BAG_SLOT, LAST_BAG_SLOT)
end

local function initBankCache (ownerData)
  local bankCache = initBagRangeCache(ownerData, FIRST_BAG_SLOT, LAST_BANK_SLOT)

  return initBagItemCountCache(bankCache, ownerData[BANK_CONTAINER])
end

local function initReagentsCache (ownerData)
  return initBagItemCountCache({}, ownerData[REAGENTBANK_CONTAINER])
end

local function initEquipRangeCache (ownerData, firstSlot, lastSlot)
  local bagData = ownerData.equip
  local equipCache = {}

  for x = firstSlot, lastSlot, 1 do
    updateCacheCount(equipCache, bagData[x])
  end

  return equipCache
end

local function initEquipCache (ownerData)
  return initEquipRangeCache(ownerData, FIRST_INV_SLOT, LAST_INV_SLOT)
end

local function initVaultCache (ownerData)
  return initBagItemCountCache({}, ownerData.vault)
end

local function initBagSlotCache (ownerData)
  return initEquipRangeCache(ownerData,
      ContainerIDToInventoryID(FIRST_BAG_SLOT),
      ContainerIDToInventoryID(LAST_BAG_SLOT))
end

local function initBankBagSlotCache (ownerData)
  return initEquipRangeCache(ownerData,
      ContainerIDToInventoryID(FIRST_BANK_SLOT),
      ContainerIDToInventoryID(LAST_BANK_SLOT))
end

local function initBagCacheContents (ownerCache, bag, ownerData)
  local bagCache

  if (bag == BAG_TYPE_BAG) then
    bagCache = initBagCache(ownerData)
  elseif (bag == BAG_TYPE_BANK) then
    bagCache = initBankCache(ownerData)
  elseif (bag == BAG_TYPE_EQUIP) then
    bagCache = initEquipCache(ownerData)
  elseif (bag == BAG_TYPE_REAGENTS) then
    bagCache = initReagentsCache(ownerData)
  elseif (bag == BAG_TYPE_VAULT) then
    bagCache = initVaultCache(ownerData)
  elseif (bag == BAG_TYPE_BAGSLOTS) then
    bagCache = initBagSlotCache(ownerData)
  elseif (bag == BAG_TYPE_BANKBAGSLOTS) then
    bagCache = initBankBagSlotCache(ownerData)
  else
    print('BagBrother: unknown bag type "' .. bag .. '"');
  end

  ownerCache[bag] = bagCache

  return bagCache
end

local function initBagTypeCache (realm, owner, bag)
  local BrotherBags = _G.BrotherBags or {}
  local realmData = BrotherBags[realm]
  local ownerData = realmData and realmData[owner]

  if (ownerData == nil) then
    return nil
  end

  local realmCache = itemCountCache[realm] or {}
  local ownerCache = realmCache[owner] or {}
  local bagCache

  if (realmData == addon.BagBrother.Realm) then
    playerRealmCache = realmCache
  end

  if (ownerData == addon.BagBrother.Player) then
    playerCache = ownerCache
  end

  bagCache = initBagCacheContents(ownerCache, bag, ownerData)

  realmCache[owner] = ownerCache
  itemCountCache[realm] = realmCache

  return bagCache
end

local function getOwnerBagCache (realm, owner, bag)
  local cache = itemCountCache[realm]
  cache = cache and cache[owner]
  return cache and cache[bag]
end

function addon:UnCachePlayerBag (bag)
  if (not playerCache) then return end

  playerCache[getBagType(bag)] = nil
end

function addon:UnCacheRealmOwner (owner)
  if (not playerRealmCache) then return end

  playerRealmCache[owner] = nil
end

function addon:GetItemCount (realm, owner, bag, itemId)
  local data

  bag = getBagType(bag)
  data = getOwnerBagCache(realm, owner, bag)

  if (data) then
    return data[itemId] or 0
  else
    data = initBagTypeCache(realm, owner, bag)

    return data and data[itemId] or 0
  end
end
