--[[
Should rate limit
4 cases
  1: key not in cache (create new entry, count = 1, return false)
  2: key in cache, not expired, count < max (increment count, return false)
  3. key in cache, not expired, count >= max (return true)
  4. key in cache, expired (create new entry, count = 1, return false)
--]]


cache = {}


function unixTime()
    return os.time(os.date("!*t"))
end


function rateLimit(key, interval, maxCount)
    local t = unixTime()
    local e = cache[key]
    if e == nil then
        -- Not in cache
        -- Case 1
        cache[key] = {endTime = t + interval, count = 1}
        return false
    end

    -- In cache
    if t < e.endTime then
        -- Not expired
        if e.count < maxCount then
            -- In cache, not expired, count < max
            -- Case 2
            e.count = e.count + 1
            cache[key] = e
            return false
        end

        -- In cache, not expired, count >= max
        -- Case 3
        return true
    end

    -- Expired
    -- Case 4
    cache[key] = {endTime = t + interval, count = 1}
    return false
end


function test(key, interval, maxCount)
    -- false
    print(rateLimit(key, interval, maxCount))
    print(rateLimit(key, interval, maxCount))
    print(rateLimit(key, interval, maxCount))

    -- true
    print(rateLimit(key, interval, maxCount))
end


test("key1", 5, 3)