--A script to calculate total business earnings (and losses) in D&D 5e
math.randomseed(os.time())

function print_help(error_message)
	if error_message ~= nil then
		io.write("ERROR: ", error_message, "\n")
	end
	io.write("Usage: calculate-business.lua [arguments]\n Valid arguments are:\n\t-h\t\t\t| Print these options\n\t-c <weekly_cost>\t| Sets the weekly cost of upkeep for the business (required)\n\t-w <number_of_weeks>\t| Sets the amount of weeks to roll for; defaults to 1 and conflicts with -f\n\t-f <path_to_file>\t| Defines a file of rolls to use instead of generating them automatically; conflicts with -w\n")
	os.exit()
end

function match_whole_pattern(input, pattern)
	return string.find(input, "%f[%w-]" .. pattern .. "%f[^%w-]")
end

--weeks need to be converted to days for the purpose of calculations
if #arg == 0 or string.match(table.unpack(arg), "-h") then print_help() end
local params = {}
for i = 1, #arg, 2 do
	params[arg[i]] = arg[i+1]
end

local flags_paired = {"-b", "-c", "-d", "-f", "-w", "--divisor"} --if an argument without a following value is ever added, the flag will not appear in this table
for k, v in pairs(params) do --ensure that all arguments have values and are correct
	local match_unrecognized = true
	local match_novalue = false
	for _, w in ipairs(flags_paired) do
		print(k, v, _, w)
		if match_whole_pattern(w, k) ~= nil then match_unrecognized = false end
		if match_whole_pattern(w, v) ~= nil then match_novalue = true end
	end
	print(match_unrecognized, match_novalue)
	if match_unrecognized == true then print_help("Argument not recognized") end
	if match_novalue == true then print_help("An argument is missing a value") end
end

if params["-b"] == nil then
	print_help("No balance provided")
elseif params["-c"] == nil then
	print_help("No weekly cost provided")
elseif params["-w"] ~= nil and params["-f"] ~= nil then
	print_help("-f and -w are incompatible with one another")
elseif params["-d"] ~= nil and params["-f"] ~= nil then
	print_help("-d and -f are incompatible with one another")
elseif params["-w"] ~= nil and params["-d"] ~= nil then
	print_help("-d and -w are incompatible with one another")
end

local balance = params["-b"]
local weekly_cost = params["-c"]
local weeks = params["-w"] or 1
local days = params["-d"] or (tonumber(weeks) * 7)
local file = params["-f"]
local divisor = params["--divisor"] or 1

function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

function lines_from(file)
	if not file_exists(file) then return {} end
	local lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

function roll(sides, number)
	if number == nil then number = 1 end
	result = math.random(sides)
	return result
end

function roll_bonus()
	--track # of days up to 30
	local roll_count = 0
	return function ()
		if roll_count < 30 then roll_count = roll_count + 1 end
		return roll_count --closure to keep track of bonus up to 30
	end
end

function roll_days()
	local rolls = {}
	local bonus = roll_bonus() --arithmetic error
	for i = 1, days do
		rolls[i] = roll(100) + bonus() 
	end
	return rolls
end

function line_days()
	local lines = lines_from(file)
	local bonus = roll_bonus()
	for i, v in ipairs(lines) do
		lines[i] = tonumber(v) + bonus()
	end
	return lines
end

function check_rolls()
	local sum = 0
	local values = {}
	if file ~= nil then
		local values = line_days()
	else
		local values = roll_days()
	end

	for _, value in ipairs(values) do --table from dmg p.128
		if value >= 1 and value <= 20 then
			sum = sum + (weekly_cost * -1.5)
		elseif value >= 21 and value <= 30 then
			sum = sum + (weekly_cost * -1)
		elseif value >= 31 and value <= 40 then
			sum = sum + (weekly_cost * -0.5)
		elseif value >= 41 and value <= 60 then
			goto continue
		elseif value >= 61 and value <= 80 then
			sum = sum + ((roll(6) * 5)/10) --1d6 * 5 /10 to adjust for my campaign
		elseif value >= 81 and value <= 90 then
			sum = sum + ((roll(8, 2) * 5)/10) --2d8 * 5sp
		elseif value >= 91 then
			sum = sum + ((roll(10, 3) * 5)/10) --3d10 * 5sp
		end
		balance = balance + sum
		::continue::
		print("Current iteration: " .. _ .. "\nCurrent value: " .. value .. "\nCurrent sum: " .. sum)
	end
	return sum
end

--[[
local lines = lines_from(file)
for k, v in ipairs(lines) do
	print(k, v)
end
os.exit()
--]]

local total = check_rolls()

if total < 0 then
	io.write("This business has lost ", total, "gp", "\n")
	os.exit()
else
	io.write("This business has made ", total, "gp", "\n")
	os.exit()
end
