local num = matches[2]:gsub(",","")
local amount = tonumber(num)
ProgressDisplay:expUpdate(amount)