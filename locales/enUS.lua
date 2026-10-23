local _, ns = ...

-- enUS is the key, so a missing translation shows English.
ns.L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})
