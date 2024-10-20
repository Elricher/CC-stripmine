local tunnelManager = {
    tunnels = {},
    nextId = 1
}

-- New function to ensure the data folder exists
local function ensureDataFolder()
    if not fs.exists("tunnel_data") then
        fs.makeDir("tunnel_data")
    end
end

-- New function to write tunnel data to a file
local function writeTunnelToFile(tunnel)
    local file = fs.open("tunnel_data/" .. tunnel.id .. ".txt", "w")
    file.writeLine(string.format("%d,%d,%d,%d,%s,%d,%s,%s",
        tunnel.id,
        tunnel.startPos.x, tunnel.startPos.y, tunnel.startPos.z,
        tunnel.direction,
        tunnel.length,
        tunnel.status,
        tostring(tunnel.accessible)))
    file.close()
end

function tunnelManager.createTunnel(direction, length, startPos, id)
    local tunnel = {
        id = id,
        direction = direction,
        length = length,
        startPos = startPos,
        status = "not_started",
        accessible = (direction == "north" or direction == "south")
    }
    writeTunnelToFile(tunnel)  -- Write to file immediately after creation
    return tunnel
end

function tunnelManager.addTunnel(direction, length, startPos)
    local tunnel = tunnelManager.createTunnel(direction, length, startPos, tunnelManager.nextId)
    tunnelManager.tunnels[tunnelManager.nextId] = tunnel
    tunnelManager.nextId = tunnelManager.nextId + 1
    return tunnel.id
end

function tunnelManager.updateTunnel(id, status)
    if tunnelManager.tunnels[id] then
        tunnelManager.tunnels[id].status = status
        writeTunnelToFile(tunnelManager.tunnels[id])  -- Update file after changing status
        -- If a north-south tunnel is completed, update accessibility of connected east-west tunnels
        if (tunnelManager.tunnels[id].direction == "north" or tunnelManager.tunnels[id].direction == "south") and status == "completed" then
            tunnelManager.updateAccessibility(id)
        end
    end
end

function tunnelManager.updateAccessibility(prevId)
    local mainTunnel = tunnelManager.tunnels[prevId]
    if mainTunnel.direction == "north" then
        for _, tunnel in pairs(tunnelManager.tunnels) do
            if mainTunnel.startPos.y == tunnel.startPos.y and mainTunnel.startPos.z >= tunnel.startPos.z then
                tunnel.accessible = true
                writeTunnelToFile(tunnel)  -- Update file after changing accessibility
            end
        end
    elseif mainTunnel.direction == "south" then
        for _, tunnel in pairs(tunnelManager.tunnels) do
            if mainTunnel.startPos.y == tunnel.startPos.y and mainTunnel.startPos.z <= tunnel.startPos.z then
                tunnel.accessible = true
                writeTunnelToFile(tunnel)  -- Update file after changing accessibility
            end
        end
    end
end

function tunnelManager.getNext()
    for id, tunnel in pairs(tunnelManager.tunnels) do
        if tunnel.status == "not_started" and tunnel.accessible then
            return true, id
        end
    end
    return false
end

function tunnelManager.initialize(depth, range, ewSpacing, entrance)
    ensureDataFolder()  -- Ensure the data folder exists before initializing
    -- Add main north-south tunnels
    tunnelManager.addTunnel("north", range, vector.new(entrance.x, depth, entrance.z-1))
    tunnelManager.addTunnel("south", range, vector.new(entrance.x, depth, entrance.z))
    
    -- Add east-west tunnels
    for z = -range, range, ewSpacing do
        tunnelManager.addTunnel("east", range, vector.new(entrance.x, depth, entrance.z + z))
        tunnelManager.addTunnel("west", range, vector.new(entrance.x, depth, entrance.z + z))
    end
end

function tunnelManager.loadTunnels()
    if not fs.exists("tunnel_data") then
        return false
    end
    
    local files = fs.list("tunnel_data")
    for _, file in ipairs(files) do
        local f = fs.open("tunnel_data/" .. file, "r")
        local data = f.readAll()
        f.close()
        
        local id, x, y, z, direction, length, status, accessible = data:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        
        if id then
            id = tonumber(id)
            -- Reset "in_progress" status to "not_started"
            if status == "in_progress" then
                status = "not_started"
                -- Update the file with the new status
                local updatedData = string.format("%d,%d,%d,%d,%s,%d,%s,%s",
                    id, x, y, z, direction, length, status, accessible)
                local f = fs.open("tunnel_data/" .. file, "w")
                f.write(updatedData)
                f.close()
            end
            
            tunnelManager.tunnels[id] = {
                id = id,
                startPos = vector.new(tonumber(x), tonumber(y), tonumber(z)),
                direction = direction,
                length = tonumber(length),
                status = status,
                accessible = (accessible == "true" and true or false)
            }
            tunnelManager.nextId = math.max(tunnelManager.nextId, id + 1)
        else
            print("failed to load a tunnel")
        end
    end
    
    return #files > 0
end

return tunnelManager