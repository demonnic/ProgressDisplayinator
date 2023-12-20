-- This has been shamelessly ripped off from Bulrok, stuffed unceremoniously
-- into a new namespace and setup to create and update to an AdjustableContainer
-- rather than being displayed in the main window scroll.
ProgressDisplay = ProgressDisplay or {
  font = "Ubuntu Mono",
  fontSize = 10,
  height = 200,
  width = 400
}
ProgressDisplay.goldLog = ProgressDisplay.goldLog or {}
ProgressDisplay.expLog = ProgressDisplay.expLog or {}

function ProgressDisplay:reset()
  self.goldLog = {}
  self.expLog = {}
  self.startTime = os.time()
end

function ProgressDisplay.format_int(number)
  number = math.floor(number)
  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
  -- reverse the int-string and append a comma to all blocks of 3 digits
  int = int:reverse():gsub("(%d%d%d)", "%1,")
  -- reverse the int-string back remove an optional comma and put the 
  -- optional minus and fractional part back
  return minus .. int:reverse():gsub("^,", "") .. fraction
end

function ProgressDisplay.breakdownTime(time)
  local hours, minutes, seconds = shms(time)
  hours = tonumber(hours)
  minutes = tonumber(minutes)
  seconds = tonumber(seconds)
  local days = math.floor(hours / 24)
  hours = hours % 24
  return days, hours, minutes, seconds
end

function ProgressDisplay:create()
  self.container = Adjustable.Container:new({
    name = "Progress Display",
    x = 0,
    y = 0,
    height = self.height,
    width = self.width,
  })
  self.console = Geyser.MiniConsole:new({
    name = "progress displayinator gold console",
    x = 0,
    y = 0,
    height = "100%",
    width = "100%",
    font = self.font,
    fontSize = self.fontSize,
    color = "black",
  }, self.container)
  self:update()
end

function ProgressDisplay:show()
  self.container:show()
  self:update()
end

function ProgressDisplay:hide()
  self.container:hide()
end

function ProgressDisplay:update()
  if self.container.hidden then return end
  ProgressDisplay:expCheck()
  ProgressDisplay:goldCheck()
end

function ProgressDisplay:goldUpdate(amount)
  local goldLog = self.goldLog
  local where = gmcp.Room.Info
  local when = os.time()
  local logEntry = {
    ["where"] = {
      ["roomNum"] = where.num,
      ["area"] = where.area,
    },
    ["when"] = when,
    ["amount"] = amount,
  }
  goldLog[#goldLog+1] = logEntry
  self:update()
end

function ProgressDisplay:expUpdate(amount)
  local expLog = self.expLog
  local where = gmcp.Room.Info
  local when = os.time()

  local entry = {
    ["where"] = {
      ["roomNum"] = where.num,
      ["area"] = where.area,
    },
    ["when"] = when,
    ["amount"] = amount,
  }
  expLog[#expLog+1] = entry
  self:update()
end

function ProgressDisplay:expCheck()
  local console = self.console
  local total = 0
  if not self.startTime then
    self.startTime = os.time()
  end
  local startTime = self.startTime
  local endTime = os.time()
  local thisArea, thisRoom = "Unknown", "Unknown"
  if gmcp.Room and gmcp.Room.Info then
    thisArea = gmcp.Room.Info.area
    thisRoom = gmcp.Room.Info.num
  end
  local areaExp = 0
  local roomExp = 0
  console:clear()
  for _, log in ipairs(self.expLog) do
    if log.where.area == thisArea then
      areaExp = areaExp + log.amount
    end
    if log.where.roomNum == thisRoom then
      roomExp = roomExp + log.amount
    end
    total = total + log.amount
  end
  local duration = endTime - startTime
  local days, hours, minutes, seconds = self.breakdownTime(duration)
  local timeString = f"{days} days {hours} hours {minutes} minutes {seconds} seconds"

  local xph = total / (duration / 60 / 60)
  local xpToLevel, xpPercentGained = "Unknown", "Unknown"
  if gmcp.Char and gmcp.Char.Vitals then
    xpToLevel = tonumber(gmcp.Char.Vitals.maxxp) - tonumber(gmcp.Char.Vitals.xp)
    xpPercentGained = string.format("%.2f", (total*100)/tonumber(gmcp.Char.Vitals.maxxp))
  end
  local timeToLevel = "Infinity"
  if xph > 1 then
    timeToLevel = string.format("%.2f", xpToLevel / xph)
  end

  local readable_total = self.format_int(total)
  local readable_xph = self.format_int(xph)


  console:cecho(f[[
<white>Area        : <green>{thisArea}
<white>Time Period : <green>{timeString}
<LightSlateBlue>Exp change  : {total<0 and "<red>" or "<green>"}{readable_total} <green>({xpPercentGained}%)
<LightSlateBlue>Exp/Hour    : {xph<0 and "<red>" or "<green>"}{readable_xph}
<LightSlateBlue>Hrs to Lvl  : <yellow>{timeToLevel} <green>hours
]])
end

function ProgressDisplay:goldCheck()
  local console = self.console
  local goldLog = self.goldLog
  local total = 0
  local startTime = self.startTime
  local endTime = os.time()
  local thisArea = "Unknown"
  if gmcp.Room and gmcp.Room.Info then
    thisArea = gmcp.Room.Info.area:gsub("an unstable section of ","")
  end
  local areaGold = 0
  for _, log in ipairs(goldLog) do
    if log.where.area == thisArea then
      areaGold = areaGold + log.amount
    end
    total = total + log.amount
  end
  local duration = endTime - startTime
  local gps = total / duration
  local gph = total / (duration/60/60)

  console:cecho(f[[
<yellow>Gold change : {total<=0 and "<red>" or "<green>"}{total}
<yellow>Gold in area: <green>{areaGold}
<yellow>Gold/Second : <green>{string.format("%.2f",gps)}
<yellow>Gold/Hour   : <green>{string.format("%.2f",gph)}]])

end

if not ProgressDisplay.container then
  ProgressDisplay:create()
  ProgressDisplay:reset()
end
registerNamedTimer("ProgressDisplay", "regular update", 1, function() ProgressDisplay:update() end, true)