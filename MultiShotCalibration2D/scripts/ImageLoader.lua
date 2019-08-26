local function getImageFiles(folder)
  local files = {}
  local extensions = {'.png', '.bmp', '.jpg', '.jpeg'}
  for _, ext in ipairs(extensions) do
    local ext_f = File.list(folder, '*' .. ext)
    for f = 1, #ext_f do
      files[#files + 1] = folder .. '/' .. ext_f[f]
    end
  end
  return files
end

local function getImageLoader(folder)
  local files = getImageFiles(folder)
  local file_it = 1

  return function()
    if file_it > #files then
      return nil
    else
      local im = Image.load(files[file_it])
      file_it = file_it + 1
      return im
    end
  end
end

return {
  getFiles = getImageFiles,
  getLoader = getImageLoader
}