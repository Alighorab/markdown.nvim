local M = {}

local uv = vim.loop

local options = {
    server = {
        enable = true,
        port = 15213,
    },
    browser = {
        enable = true,
        command = "firefox",
        args = { "http://localhost:15213" }
    }
}

local _pids = {
    server = -1,
    browser = -1,
}

M.setup = function(opts)
    for opt, val in pairs(opts) do
        if val then
            for k, v in pairs(val) do
                if k then
                    options[opt][k] = v
                end
            end
        end
    end
end

M.spawn_server = function()
    if options.server.enable then
        if _pids.server == -1 then
            local _, pid = uv.spawn("grip", {
                args = { options.server.port },
            }, function(code, _)
                print("Server closed with an exit code", code)
            end)
            if pid then
                print("Server started on port:", options.server.port)
                _pids.server = pid
            end
        end
    end
end

M.kill_server = function()
    if _pids.server ~= -1 then
        uv.kill(_pids.server, "sigint")
        _pids.server = -1
    end
end

M.spawn_browser = function()
    if options.browser.enable then
        if _pids.browser == -1 and _pids.server ~= -1 then
            local _, pid = uv.spawn(options.browser.command, {
                args = options.browser.args
            }, function(code, _)
                print("Browser closed with an exit code", code)
            end)
            if pid then
                print("Browser started")
                _pids.browser = pid
            end
        end
    end
end

M.kill_browser = function ()
    if _pids.browser ~= -1 then
        uv.kill(_pids.browser, "sigint")
        _pids.browser = -1
    end
end

return M