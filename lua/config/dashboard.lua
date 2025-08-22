local M = {}

function M.get_header()
  return [[

 ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
 ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
 ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
 ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
 ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝

                  Your Bioinformatics IDE

]]
end

function M.get_footer()
  local hour = tonumber(os.date("%H"))

  local morning_messages = {
    "Ready to decode some DNA? Coffee first! ☕",
    "Fresh morning, fresh algorithms! 🧬",
    "Time to make some biological discoveries! 🔬",
    "Your genes are calling... answer with code! 🧪"
  }

  local afternoon_messages = {
    "Afternoon analysis session incoming! 📊",
    "Time for some computational biology magic! ✨",
    "Data doesn't analyze itself... let's go! 🚀",
    "Proteins are folding, code should too! 🧬"
  }

  local evening_messages = {
    "Evening coding vibes activated! 🌙",
    "Night owl bioinformatician mode: ON! 🦉",
    "The best discoveries happen after hours! 💡",
    "Late night? Perfect time for breakthrough code! ⭐"
  }

  local late_night_messages = {
    "Burning the midnight oil? Respect! 🔥",
    "3 AM is when the best algorithms are born! 🌃",
    "Sleep is for those without genomics deadlines! 😴",
    "Coffee + Code + Chromosomes = Champion! 🏆"
  }

  local messages
  if hour >= 5 and hour < 12 then
    messages = morning_messages
  elseif hour >= 12 and hour < 18 then
    messages = afternoon_messages
  elseif hour >= 18 and hour < 23 then
    messages = evening_messages
  else
    messages = late_night_messages
  end

  -- Use hour as seed for consistent randomness during the same hour
  math.randomseed(hour * 100 + tonumber(os.date("%M")))
  local selected_message = messages[math.random(#messages)]

  return string.format("                    %s", selected_message)
end

return M
