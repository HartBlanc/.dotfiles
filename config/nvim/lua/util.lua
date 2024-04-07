-- git_root returns the absolute path of the root of the git repository that path is in.
-- if path is not provided it defaults to the path of the current buffer.
local M = {}
M.git_root = function(path)
  if not path then
    path = vim.api.nvim_buf_get_name(0)
  end

  local git_dir = vim.fs.find('.git', {
    upward = true,
    path = path,
    type = 'directory',
  })
  if not git_dir then
    vim.notify('failed to find git root', vim.log.levels.WARN)
    return
  end
  return git_dir.path
end

return M
