function editor_init()
    ox,oy = 0,0 -- ofsets
    map = points
    sect = sectors
    selected = {}
    snap = 10
    time_since_change = 0
    select_poly = 0
	main_controls = "Controls:\nLeft mouse: Select points/sector\nRight Mouse: Add points\nW/A/S/D: Move the camera\nC: Make sector using selected points\nDelete: Remove selected"
	sector_controls = "Controls:\nDelete: Remove sector\nUp/Down: Change ceiling height\nLeft/Right: Change floor height"
	controls = main_controls
end

function editor_main()
    -- setup vars
    local mx,my = love.mouse.getPosition()

    -- main loop
    love.graphics.clear(1,1,1)
    draw_grid(snap)
    love.graphics.setColor(0,0,0)
    for i=1,#sect do
        if select_poly == i then
            love.graphics.setColor(1,.5,0)
        else
            love.graphics.setColor(0,0,0)
    	end
        for j=1,#sect[i].points do
			-- love.graphics.print(tostring(sect[i].points[j]),j*80,i*10)
            if j==#sect[i].points then
                love.graphics.line(map[sect[i].points[j]].x+ox,map[sect[i].points[j]].y+oy,map[sect[i].points[1]].x+ox,map[sect[i].points[1]].y+oy)
            else
                love.graphics.line(map[sect[i].points[j]].x+ox,map[sect[i].points[j]].y+oy,map[sect[i].points[j+1]].x+ox,map[sect[i].points[j+1]].y+oy)
            end
        end
    end
	if select_poly == 0 then
		controls = main_controls
	else
		controls = sector_controls.."\nCeiling: "..sect[select_poly].c.."\nFloor: "..sect[select_poly].f
	end
    if love.mouse.isDown(2) and not is_point(math.floor((mx-ox)/snap+0.5)*snap,math.floor((my-oy)/snap+0.5)*snap) then
        map[#map+1] = {x=math.floor((mx-ox)/snap+0.5)*snap,y=math.floor((my-oy)/snap+0.5)*snap}
    end
    if love.mouse.isDown(1) then
        for i=1,#map do
            if (map[i].x-mx+ox)^2+(map[i].y-my+oy)^2 <= 50 and time_since_change >= 0.2 then
                if within(i,selected) then
                    selected = remove(i,selected)
                else
                    selected[#selected+1] = i
                end
                time_since_change = 0
            end
        end
        if time_since_change >= 0.2 then
            for i=1,#sect do
                if point_in_polygon(mx-ox,my-oy,construct_p_list(sect[i].points)) then
                    if select_poly == i then
                        select_poly = 0
                        selected = {}
                    else
                        select_poly = i
                        selected = sect[i].points
                    end
                end
                time_since_change = 0
            end
        end
    end
    if love.keyboard.isDown("c") and not is_sector(selected) and #selected > 2 then
        sect[#sect+1] = {points=selected,f=0,c=10}
        time_since_change = 0
        selected = {}
    end
	if love.keyboard.isDown("backspace") and time_since_change >= 0.2 then
		if select_poly == 0 then
			for i=1,#selected do
				local rem = true
				for j=1,#sect do
					for k=1,#sect[j].points do
						if selected[i]==sect[j].points[k] then
							rem = false
						end
					end
				end
				if rem then
					map = remove(map[selected[i]],map)
				end	
			end
			selected = {}
		else
			sect = remove(sect[select_poly],sect)
			select_poly = 0
			selected = {}
		end
		time_since_change = 0
	end
	love.graphics.setColor(0,.8,0)
	love.graphics.circle("fill",p.x+ox,p.y+oy,5)
    for i=1,#map do
        if within(i,selected) then
            love.graphics.setColor(1,.5,0)
        else
            love.graphics.setColor(0,0,0)
        end
        love.graphics.circle("fill",map[i].x+ox,map[i].y+oy,5)
    end
    time_since_change = time_since_change + delta_time

	if love.keyboard.isDown("w") then
		oy = oy + 1
	end
	if love.keyboard.isDown("s") and not love.keyboard.isDown("lgui") then
		oy = oy - 1
	end
	if love.keyboard.isDown("a") then
		ox = ox + 1
	end
	if love.keyboard.isDown("d") then
		ox = ox - 1
	end
	if select_poly ~= 0 then
		if love.keyboard.isDown("up") then
			sect[select_poly].c = sect[select_poly].c + .1
		end
		if love.keyboard.isDown("down") then
			sect[select_poly].c = sect[select_poly].c - .1
		end
		if love.keyboard.isDown("right") then
			sect[select_poly].f = sect[select_poly].f + .1
		end
		if love.keyboard.isDown("left") then
			sect[select_poly].f = sect[select_poly].f - .1
		end
	end
	if love.keyboard.isDown("r") then
		points = map
		sectors = sect
		editor = false
	end
    if love.keyboard.isDown("s") and love.keyboard.isDown("lgui") then
        file = love.filesystem.newFile("map.txt")
        file:open("w")
        file:write(tostring({map,sect}))
        file:close()
    end
	-- display controls:
	love.graphics.setColor(0,0,0)
	love.graphics.print(controls,love.window.getMode()-240,0)

end

function draw_grid(size)
    love.graphics.setColor(0,0,0,.3)
    if size > 1 then
        local w,h = love.window.getMode()
        for x=0,w-ox,size do
            love.graphics.line(x+ox,0,x+ox,h)
        end
        for y=0,h-oy,size do
            love.graphics.line(0,y+oy,w,y+oy)
        end
    end
end

function is_point(x,y) -- merge with within?
    for i=1,#map do
        if map[i].x==x and map[i].y==y then
            return true
        end
    end
    return false
end

function within(a,l)
    for i=1,#l do
        if a==l[i] then
            return true
        end
    end
    return false
end

function remove(a,l)
    local ret = {}
    for i=1,#l do
        if l[i]~=a then
            ret[#ret+1] = l[i]
        end
    end
    return ret
end

function is_sector(l)
    if #l==0 then
        return true
    end
    for i=1,#sect do
        if sect[i].points == l then
            return true
        end
    end
    return false
end

function construct_p_list(sector)
    local ret = {}
    for i=1,#sector do
        -- ret[#ret+1] = {x=map[sector[i]].x,y=map[sector[i]].y}
        ret[#ret+1] = map[sector[i]].x
        ret[#ret+1] = map[sector[i]].y
    end
    return ret
end

-- function point_in_polygon(px,py,poly)
--     local hits = 0
--     for i=1,#poly do
--         if i==#poly then
--             if do_intersect(px,py,px+1000,py,poly[i].x,poly[i].y,poly[1].x,poly[1].y) then
--                 hits = hits + 1
--             end
--         else
--             if do_intersect(px,py,px+1000,py,poly[i].x,poly[i].y,poly[i+1].x,poly[i+1].y) then
--                 hits = hits + 1
--             end
--         end
--     end
--     return math.floor(hits/2)~=hits/2
-- end

-- By Pedro Gimeno, donated to the public domain
-- function isPointInPolygon(x, y, poly)
function point_in_polygon(x, y, poly)
	-- poly is a Lua list of pairs like {x1, y1, x2, y2, ... xn, yn}
	local x1, y1, x2, y2
	local len = #poly
	x2, y2 = poly[len - 1], poly[len]
	local wn = 0
	for idx = 1, len, 2 do
		x1, y1 = x2, y2
		x2, y2 = poly[idx], poly[idx + 1]

		if y1 > y then
			if (y2 <= y) and (x1 - x) * (y2 - y) < (x2 - x) * (y1 - y) then
			wn = wn + 1
			end
		else
			if (y2 > y) and (x1 - x) * (y2 - y) > (x2 - x) * (y1 - y) then
			wn = wn - 1
			end
		end
	end
	return wn % 2 ~= 0 -- even/odd rule
end