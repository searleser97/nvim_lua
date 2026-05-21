local M = {}

-- Override this if auto-detection doesn't suit your setup (e.g., vim.g.cell_ratio = 1.75)
local DEFAULT_RATIO = 2.0

-- Platform-specific pixel measurement providers.
-- Each returns (pixel_width, pixel_height) or nil on failure.

local function measure_pixels_win32()
  local ok, ffi = pcall(require, "ffi")
  if not ok then return nil end
  local success, pw, ph = pcall(function()
    if not M._ffi_defined then
      ffi.cdef[[
        typedef struct { long left; long top; long right; long bottom; } ORIENTATION_RECT;
        void* GetForegroundWindow(void);
        int GetClientRect(void* hWnd, ORIENTATION_RECT* lpRect);
      ]]
      M._ffi_defined = true
    end
    local hwnd = ffi.C.GetForegroundWindow()
    if hwnd == nil then return nil, nil end
    local rect = ffi.new("ORIENTATION_RECT")
    if ffi.C.GetClientRect(hwnd, rect) == 0 then return nil, nil end
    return rect.right - rect.left, rect.bottom - rect.top
  end)
  if success and pw and pw > 0 and ph and ph > 0 then
    return pw, ph
  end
  return nil
end

local function measure_pixels_unix()
  local ok, ffi = pcall(require, "ffi")
  if not ok then return nil end
  local success, pw, ph = pcall(function()
    if not M._ffi_defined_unix then
      ffi.cdef[[
        typedef struct { unsigned short ws_row; unsigned short ws_col; unsigned short ws_xpixel; unsigned short ws_ypixel; } orientation_winsize;
        int ioctl(int fd, unsigned long request, ...);
      ]]
      M._ffi_defined_unix = true
    end
    -- TIOCGWINSZ: 0x5413 on Linux, 0x40087468 on macOS
    local TIOCGWINSZ = (vim.fn.has("mac") == 1) and 0x40087468 or 0x5413
    local ws = ffi.new("orientation_winsize")
    if ffi.C.ioctl(1, TIOCGWINSZ, ws) == -1 then return nil, nil end
    return tonumber(ws.ws_xpixel), tonumber(ws.ws_ypixel)
  end)
  if success and pw and pw > 0 and ph and ph > 0 then
    return pw, ph
  end
  return nil
end

local function measure_pixels()
  if vim.fn.has("win32") == 1 then
    return measure_pixels_win32()
  else
    return measure_pixels_unix()
  end
end

local function get_cell_ratio()
  if vim.g.cell_ratio then return vim.g.cell_ratio end
  return DEFAULT_RATIO
end

--- Returns "landscape" or "portrait" based on the terminal's physical dimensions.
function M.get()
  local pw, ph = measure_pixels()
  if pw then
    -- Direct pixel comparison — no ratio needed
    return pw > ph and "landscape" or "portrait"
  end
  -- Fallback: estimate using character grid + assumed cell ratio
  local ratio = get_cell_ratio()
  if vim.o.columns > vim.o.lines * ratio then
    return "landscape"
  end
  return "portrait"
end

--- Returns the current cell aspect ratio (cell_height / cell_width).
function M.ratio()
  local pw, ph = measure_pixels()
  if pw then
    local cell_w = pw / vim.o.columns
    local cell_h = ph / vim.o.lines
    return cell_h / cell_w
  end
  return get_cell_ratio()
end

return M
