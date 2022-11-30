local md = {}

local uv = vim.loop

local options = {
    server = {
        enable = true,
        port = "${port}",
    },
    browser = {
        enable = true,
        command = "firefox",
        args = {},
    }
}

local grip_port = ""

local _pids = {
    server = -1,
    browser = -1,
}

local function free_port()
    local server = uv.new_tcp("inet")
    server:bind("127.0.0.1", 0)
    local data = server:getsockname()
    server:close()
    return data.port
end

local function spawn_grip()
    local _, pid = uv.spawn("grip", {
        args = { grip_port },
    }, function(code, _)
        print("Server closed with an exit code", code)
    end)
    if pid then
        print("Server started on port:", grip_port)
        _pids.server = pid
    end
end

md.setup = function(opts)
    for opt, val in pairs(opts) do
        if val then
            for k, v in pairs(val) do
                if k then
                    options[opt][k] = v
                end
            end
        end
    end

    vim.api.nvim_create_autocmd({
        "BufDelete",
        "ExitPre",
        "QuitPre",
        "WinClosed",
        "FileType"
    }, {
        pattern = "*.md",
        group = vim.api.nvim_create_augroup("MarkdownPreview", { clear = true }),
        callback = function ()
            md.kill_server()
            md.kill_browser()
        end
    })
end

md.spawn_server = function()
    if options.server.enable then
        if _pids.server == -1 then
            if options.server.port == "${port}" then
                grip_port = tostring(free_port())
            else
                grip_port = options.server.port
            end
            spawn_grip()
        end
    end
end

md.kill_server = function()
    if _pids.server ~= -1 then
        uv.kill(_pids.server, "sigint")
        _pids.server = -1
    end
end

md.spawn_browser = function()
    if options.browser.enable then
        if _pids.browser == -1 and _pids.server ~= -1 then
            if options.server.port == "${port}" then
                table.insert(options.browser.args, "http://localhost:" .. grip_port)
            else
                table.insert(options.browser.args, "http://localhost:" .. options.server.port)
            end

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

md.kill_browser = function ()
    if _pids.browser ~= -1 then
        uv.kill(_pids.browser, "sigint")
        _pids.browser = -1
    end
end

return md
