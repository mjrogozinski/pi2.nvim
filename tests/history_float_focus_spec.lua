local Chat = require("pi.ui.chat")

--- Drain deferred focus changes before checking the selected window.
local function pump()
    vim.wait(80, function()
        return false
    end)
end

describe("history focus in side layout", function()
    local chat
    local editor
    local float

    before_each(function()
        editor = vim.api.nvim_get_current_win()
        chat = Chat.new(vim.api.nvim_get_current_tabpage(), "side", {
            send = function()
                return true
            end,
        })
        chat:show()
        pump()
        vim.cmd("stopinsert")
    end)

    after_each(function()
        if float and vim.api.nvim_win_is_valid(float) then
            vim.api.nvim_win_close(float, true)
        end
        float = nil
        chat:hide()
        for _, panel in ipairs({ chat._history, chat._prompt, chat._attachments }) do
            local buf = panel:buf()
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
        pump()
        vim.cmd("stopinsert")
    end)

    it("keeps focus in a floating history view", function()
        chat:focus_history()
        pump()
        float = vim.api.nvim_open_win(chat._history:buf(), true, {
            relative = "editor",
            row = 1,
            col = 1,
            width = 40,
            height = 10,
        })
        pump()
        assert.equals(float, vim.api.nvim_get_current_win())
    end)

    it("keeps focus when entering side history from the editor", function()
        vim.api.nvim_set_current_win(editor)
        vim.api.nvim_set_current_win(chat._layout:history_win())
        pump()
        assert.equals(chat._layout:history_win(), vim.api.nvim_get_current_win())
    end)

    it("does not register WinEnter callbacks for either chat buffer", function()
        for _, panel in ipairs({ chat._history, chat._prompt }) do
            assert.equals(0, #vim.api.nvim_get_autocmds({ event = "WinEnter", buffer = panel:buf() }))
        end
    end)

    it("still permits navigation from the prompt into side history", function()
        chat:focus_history()
        pump()
        assert.equals(chat._layout:history_win(), vim.api.nvim_get_current_win())
    end)
end)
