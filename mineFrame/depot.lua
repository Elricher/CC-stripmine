local depot = {
    empty = {},
	occupied = {}
}

function depot.initialize(mineFrameCoords)
    local depotLength = 15
    for i = 1, depotLength do
        local leftSpot = {position = vector.new(mineFrameCoords.x - 4, mineFrameCoords.y - 1, mineFrameCoords.z - i), droneId = nil}
        local rightSpot = {position = vector.new(mineFrameCoords.x + 4, mineFrameCoords.y - 1, mineFrameCoords.z - i), droneId = nil}
        table.insert(depot.empty, leftSpot)
        table.insert(depot.empty, rightSpot)
    end
end

function depot.send(droneId)
    if #depot.empty == 0 then
        return false, "Depot is full"
    end
    local spot = table.remove(depot.empty)
	print("sending drone to depot, ID:", droneId)
    return spot.position
end

function depot.arrived(id, location)
	local spot = {position = location, droneId = id}
	table.insert(depot.occupied, spot)
end

function depot.pull()
    if #depot.occupied == 0 then
        return false, "No drones in depot"
    end
    local spot = table.remove(depot.occupied)
    local droneId = spot.droneId
    spot.droneId = nil
	print("pulling drone from depot, ID:", droneId)
    table.insert(depot.empty, spot)
    return true, droneId
end

return depot