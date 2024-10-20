local droneManager = {
    drones = {}
}

function droneManager.add(id, dronePosition)
    droneManager.drones[id] = {
        id = id,
        position = dronePosition,
        status = "idle"
    }
    print("Drone " .. id .. " added successfully")
end

function droneManager.remove(id)
    if droneManager.drones[id] then
        droneManager.drones[id] = nil
        print("Drone " .. id .. " removed successfully.")
    else
        print("Drone " .. id .. " not found.")
    end
end

function droneManager.list()
    for id, drone in pairs(droneManager.drones) do
        print(string.format("Drone %s: Position(%d,%d,%d), Status: %s",
            id, 
            droneManager.position.x, 
            droneManager.position.y, 
            droneManager.position.z, 
            droneManager.status))
    end
end

return droneManager