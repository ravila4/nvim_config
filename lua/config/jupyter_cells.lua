local M = {}

local function is_marker(line)
  return line:match("^%s*#%s*%%%%") ~= nil
end

local function first_content_line(lines, marker_line)
  local line = marker_line + 1
  while line <= #lines and not is_marker(lines[line]) and lines[line]:match("^%s*$") do
    line = line + 1
  end
  return math.min(line, #lines)
end

function M.bounds(lines, cursor_line)
  local start_line = 1
  local end_line = #lines

  for line = math.min(cursor_line, #lines), 1, -1 do
    if is_marker(lines[line]) then
      start_line = line + 1
      break
    end
  end

  for line = cursor_line + 1, #lines do
    if is_marker(lines[line]) then
      end_line = line - 1
      break
    end
  end

  while start_line <= end_line and lines[start_line]:match("^%s*$") do
    start_line = start_line + 1
  end
  while end_line >= start_line and lines[end_line]:match("^%s*$") do
    end_line = end_line - 1
  end

  return { start_line, end_line }
end

function M.next_line(lines, cursor_line)
  for line = cursor_line + 1, #lines do
    if is_marker(lines[line]) then
      return first_content_line(lines, line)
    end
  end
  return cursor_line
end

function M.previous_line(lines, cursor_line)
  local current_marker
  for line = math.min(cursor_line, #lines), 1, -1 do
    if is_marker(lines[line]) then
      current_marker = line
      break
    end
  end

  if current_marker then
    for line = current_marker - 1, 1, -1 do
      if is_marker(lines[line]) then
        return first_content_line(lines, line)
      end
    end
    return first_content_line(lines, current_marker)
  end

  return 1
end

return M
