local mineSpec = {minDepth = 221, maxDepth = -58, range = 10, gap = 4}
local mineFrameCoords = vector.new(gps.locate())
local mineEntrance = mineFrameCoords + vector.new(0, -1, -6)
local mineExit = mineFrameCoords + vector.new(0, -1, -7)
local rednetID = os.getComputerID()
local droneManager = require("droneManager")
local tunnelManager = require("tunnelManager")
local depot = require("depot")

function sendOrder(droneId, order, arg1, arg2, arg3)
    if not droneManager.drones[droneId] then
        return false, "Drone not found"
    end
    local command = {order}
	if arg1 then
        table.insert(command,arg1)
    end
	if arg2 then
        table.insert(command,arg2)
    end
	if arg3 then
        table.insert(command,arg3)
    end
	rednet.send(droneId, command)
	local _, received = rednet.receive(5)
	if received == nil then
		for i = 1, 5 do
			print("command", order, "failed to send, retrying...")
			rednet.send(droneId, command)
			_, received = rednet.receive(5)
			if received then
				return true
			end
		end
		return false
	end
    return true
end

rednet.open("right")

function main()
    depot.initialize(mineFrameCoords)
    
    -- Check if tunnel data exists and load it
    local tunnelsLoaded = tunnelManager.loadTunnels()
    
    if not tunnelsLoaded then
        -- Only initialize tunnels if no data was loaded
        tunnelManager.initialize(mineSpec.minDepth, mineSpec.range, mineSpec.gap, mineEntrance)
    else
        print("Tunnel data loaded from files.")
    end
    
    print("rednet ID is:")
    print(rednetID)
	local operation = true
	while operation do
		local droneId, droneData  = rednet.receive()
		rednet.send(droneId, true)
		local droneLocation, droneStatus, droneTunnel = table.unpack(droneData)
		if droneStatus == "join" then --new drone has joined
			droneManager.add(droneId, droneLocation)
			droneManager.drones[droneId].status = "idle"
			local depotSpot = depot.send(droneId)
			sendOrder(droneId, "depot", depotSpot, mineFrameCoords)
		elseif droneStatus == "idle" then --drone arrived at the depot and is now idle
			depot.arrived(droneId, droneLocation)
		elseif droneStatus == "complete" then --drone has completed a tunnel
			tunnelManager.updateTunnel(droneTunnel, "completed")
			local _, nextTunnel = tunnelManager.getNext()
			if nextTunnel == nil then
				local depotSpot = depot.send(droneId)
				sendOrder(droneId, "depot", depotSpot)
			else
				sendOrder(droneId, "mine", tunnelManager.tunnels[nextTunnel].startPos, tunnelManager.tunnels[nextTunnel].direction, nextTunnel)
				tunnelManager.updateTunnel(nextTunnel, "in_progress")
			end
		end
		--check list of tunnels and assign drones
		while true do
			local tunnelAvailable, nextTunnel = tunnelManager.getNext()
			if not tunnelAvailable then
				print("no available tunnels")
				break
			end
			local droneAvailable, depotDroneId = depot.pull()
			if not droneAvailable then
				print("no available drones")
				break
			else 
				sendOrder(depotDroneId, "mine", tunnelManager.tunnels[nextTunnel].startPos, tunnelManager.tunnels[nextTunnel].direction, nextTunnel)
				tunnelManager.updateTunnel(nextTunnel, "in_progress")
			end
			sleep(1)
		end
	end
end


main()
