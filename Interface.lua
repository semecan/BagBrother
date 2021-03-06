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

local addonName, addon = ...

local Interface = LibStub:NewLibrary('BagBrotherInterface', 1)
Interface.IsItemCache = true


--[[ Realms ]]--

function Interface:GetPlayers(realm)
  local realm = BrotherBags[realm] or {}
  local owner

  return function()
    while true do
      owner = next(realm, owner)

      if not owner or not owner:find('*$') then
        return owner
      end
    end
  end
end

function Interface:GetGuilds(realm)
  local realm = BrotherBags[realm] or {}
  local owner

  return function()
    while true do
      owner = next(realm, owner)

      if not owner or owner:find('*$') then
        return owner and owner:sub(1,-2)
      end
    end
  end
end


--[[ Owners ]]--

function Interface:GetPlayer(realm, owner)
  realm = BrotherBags[realm]
  owner = realm and realm[owner]

  return owner and {
    money = owner.money,
    class = owner.class,
    race = owner.race,
    guild = owner.guild,
    gender = owner.sex,
    faction = owner.faction and 'Alliance' or 'Horde' }
end

function Interface:DeletePlayer(realm, name)
    realm = BrotherBags[realm]
    if realm then
      realm[name] = nil
    end
end

function Interface:GetGuild(realm, name)
  return Interface:GetPlayer(realm, name .. '*')
end

function Interface:DeleteGuild(realm, name)
  return Interface:DeletePlayer(realm, name .. '*')
end


--[[ Bags ]]--

function Interface:GetBag(realm, player, bag)
  bag = tonumber(bag)

  if not bag then return end

  local item

  if (bag > 0) then
    item = Interface:GetItem(realm, player, 'equip', ContainerIDToInventoryID(bag))
  else
    item = {}
  end

  realm = BrotherBags[realm]
  player = realm and realm[player]
  bag = player and player[bag]

  return bag and item and {
    owned = true,
    count = bag.size,
    link = item.link,
  }
end

function Interface:GetGuildTab(realm, guild, tab)
  realm = BrotherBags[realm]
  guild = realm and realm[guild .. '*']
  tab = guild and guild[tab]

  return tab and {
    name = tab.name,
    icon = tab.icon,
    viewable = tab.view,
    deposit = tab.deposit,
    withdraw = tab.withdraw,
    remaining = tab.remaining }
end


--[[ Items ]]--

function Interface:GetItem(realm, owner, bag, slot)
  realm = BrotherBags[realm]
  owner = realm and realm[owner]
  bag = owner and owner[bag]

  local item = bag and bag[slot]
  if item then
    local link, count = strsplit(';', item)
    return {link = link, count = tonumber(count)}
  end
end

function Interface:GetItemCount(realm, owner, bag, itemId)
  return addon:GetItemCount(realm, owner, bag, itemId)
end

function Interface:GetGuildItem(realm, name, tab, slot)
  return Interface:GetItem(realm, name .. '*', tab, slot)
end

function Interface:GetGuildItemCount(realm, owner, itemId)
  return addon:GetItemCount(realm, owner .. '*', 'guild', itemId)
end
