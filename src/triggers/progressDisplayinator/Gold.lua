local amount = tonumber(matches[3]) * (matches[2] == "lost" and -1 or 1)

ProgressDisplay:goldUpdate(amount)