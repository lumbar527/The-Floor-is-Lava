require("editor")

function init()
    log_error("BEGIN GAME")
	pts={}
    triangle_function = love.graphics.polygon
    sat = true
    editor = true
    delta_time = 0
	p={x=0,y=0,z=0,a=-0.6,va=0.25}
    points =
    {
			{x=-10,y=-10},
			{x=20,y=0},
            {x=20,y=20},
            {x=0,y=20},
            {x=0,y=40},
            {x=20,y=40}
    }
    sectors = {{points={1,2,3,4},c=20,f=0},{points={3,4,5,6},c=18,f=2}}
	walls =
	{
		-- {
		-- 	{x=0,y=0,z=0},
		-- 	{x=0,y=0,z=20},
		-- 	{x=20,y=0,z=0},
		-- },
		-- {
		-- 	{x=0,y=20,z=0},
		-- 	{x=0,y=20,z=20},
		-- 	{x=20,y=20,z=0}
		-- },
		-- {
		-- 	{x=20,y=20,z=20},
		-- 	{x=0,y=20,z=20},
		-- 	{x=20,y=20,z=0}
		-- },
        -- {
        --     {x=0,y=0,z=20},
        --     {x=0,y=20,z=20},
        --     {x=20,y=0,z=20}
        -- },

		-- {
		-- 	{x=0,y=0,z=20},
		-- 	{x=0,y=0,z=0},
		-- 	{x=0,y=20,z=0}
		-- },
	}
    -- walls = generate_walls(sectors,points)
	screen={w=400,h=400}
--[[	l={
		{1,2},
		{1,3},
		{2,4},
		{3,4}
	}]]--
	ol={}
	horizon=0
	moving=false
	wait=90
    mx = 0
    my = 0

    love.window.setMode(screen.w,screen.h)

    editor_init()
end

function do_intersect(x1,y1,x2,y2,x3,y3,x4,y4)
	-- lines are 1-2 and 3-4
	
    if x1 == x2 then
        x1 = x1 + 1
    end
    if y1 == y2 then
        y1 = y1 + 1
    end
    if x3 == x4 then
        x3 = x4 + 1
    end
    if y3 == y4 then
        y3 = y4 + 1
    end

	t = ((x1 - x3) * (y3 - y4)) - ((y1 - y3) * (x3 - x4))
	t_div = ((x1 - x2) * (y3 - y4)) - ((y1 - y2) * (x3 - x4))
	
	if t_div ~= 0 then
        t = t / t_div
        p_x, p_y = x1 + t * (x2 - x1), y1 + t * (y2 - y1)
        
        -- if p_x>=math.min(x1,x2) and p_x<=math.max(x1,x2) and p_y>=math.min(y1,y2) and p_y<=math.max(y1,y2) and p_x>=math.min(x3,x4) and p_x<=math.max(x3,x4) and p_y>=math.min(y3,y4) and p_y<=math.max(y3,y4) then
        if p_x>=math.min(x3,x4) and p_x<=math.max(x3,x4) and p_y>=math.min(y3,y4) and p_y<=math.max(y3,y4) then
            local dist=math.sqrt((x1-p_x)^2 + (y1-p_y)^2)
            -- if math.sqrt((x2-p_x)^2 + (y2-p_y)^2) > math.sqrt((x1-x2)^2 + (y1-y2)^2) and math.sqrt((x1-p_x)^2 + (y1-p_y)^2) < math.sqrt((x1-x2)^2 + (y1-y2)^2) then
            if (x2 - x1 < 0 and p_x - x1 >= 0) or (x2 - x1 >= 0 and p_x - x1 < 0) then
                dist = -dist
            end

            return {true, p_x, p_y, 0, 0, dist}
        end
	end
	
	return {false, 0, 0, 0, 0, 0}
end

function sort(l)
	local prev=0
	for i=1,#l do
		for j=i+1,#l do
			if l[i][1]>l[j][1] then
				prev=l[j]
				l[j]=l[i]
				l[i]=prev
			end
		end
	end
	return l
end

function eqlst(l1,l2)
	if #l1==#l2 then
		for i=1,#l1 do
			if l1[i]~=l2[i] then
				return false
			end
		end
		return true
	end
	return false
end

function make_cplane(cx,cy,a,cd,cw)
	cdx=cx+math.sin(a*math.pi*2)*cd
	cdy=cy+math.cos(a*math.pi*2)*cd
	
	px1=cdx+math.sin((a+0.25)*math.pi*2)*cw/2
	py1=cdy+math.cos((a+0.25)*math.pi*2)*cw/2
	px2=cdx+math.sin((a-0.25)*math.pi*2)*cw/2
	py2=cdy+math.cos((a-0.25)*math.pi*2)*cw/2
	
	return {px1,py1,px2,py2}
end

function main()
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill",0,0,screen.w,screen.h)
    local nothing = nil

	pts={}
    flr_draw = {}
    ceil_draw = {}

    -- if love.keyboard.isDown("left") then
    --     p.a = p.a + .01
    -- end
    -- if love.keyboard.isDown("right") then
    --     p.a = p.a - .01
    -- end
    p.a = p.a - mx/100
    p.va = p.va + my/100
    -- love.graphics.print(mx/100)
    mx = 0
    my = 0
    if love.keyboard.isDown("w") and can_move(p.x+math.sin(p.a*math.pi*2),p.y+math.cos(p.a*math.pi*2),p.z,2,p.a) then
        p.x = p.x + math.sin(p.a*math.pi*2)
        p.y = p.y + math.cos(p.a*math.pi*2)
        nothing,p.z = can_move(p.x+math.sin(p.a*math.pi*2),p.y+math.cos(p.a*math.pi*2),p.z,2,p.a)
    end
    if love.keyboard.isDown("s") and can_move(p.x-math.sin(p.a*math.pi*2),p.y-math.cos(p.a*math.pi*2),p.z,2,p.a) then
        p.x = p.x - math.sin(p.a*math.pi*2)
        p.y = p.y - math.cos(p.a*math.pi*2)
        nothing,p.z = can_move(p.x-math.sin(p.a*math.pi*2),p.y-math.cos(p.a*math.pi*2),p.z,2,p.a)
    end
    if love.keyboard.isDown("d") and can_move(p.x-math.sin((p.a+.25)*math.pi*2),p.y-math.cos((p.a+.25)*math.pi*2),p.z,2,p.a) then
        p.x = p.x - math.sin((p.a+.25)*math.pi*2)
        p.y = p.y - math.cos((p.a+.25)*math.pi*2)
        nothing,p.z = can_move(p.x-math.sin(p.a*math.pi*2),p.y+math.cos(p.a*math.pi*2),p.z,2,p.a)
    end
    if love.keyboard.isDown("a") and can_move(p.x+math.sin((p.a+.25)*math.pi*2),p.y-math.cos((p.a+.25)*math.pi*2),p.z,2,p.a) then
        p.x = p.x + math.sin((p.a+.25)*math.pi*2)
        p.y = p.y + math.cos((p.a+.25)*math.pi*2)
        nothing,p.z = can_move(p.x+math.sin(p.a*math.pi*2),p.y+math.cos(p.a*math.pi*2),p.z,2,p.a)
    end

	local pplane=make_cplane(p.x,p.y,p.a,10,20)
	local vplane=make_cplane(54,63+p.z+10,p.va,10,10)
    walls = generate_walls(sectors,points,pplane,vplane)

    local lplane=make_cplane(p.x,p.y,p.a,10,100)
	local lvplane=make_cplane(54,63+p.z+10,p.va,10,100)

    -- for i=1,#walls do
    --     -- love.graphics.line(walls[i][1].x+20,walls[i][1].y+20,walls[i][2].x+20,walls[i][2].y+20)
    --     love.graphics.polygon("line",math.sqrt((walls[i][1].x-p.x)^2+(walls[i][1].y-p.y)^2)+64,64+walls[i][1].z,math.sqrt((walls[i][2].x-p.x)^2+(walls[i][2].y-p.y)^2)+64,64+walls[i][2].z,math.sqrt((walls[i][3].x-p.x)^2+(walls[i][3].y-p.y)^2)+64,64+walls[i][3].z,math.sqrt((walls[i][4].x-p.x)^2+(walls[i][4].y-p.y)^2)+64,64+walls[i][4].z)
    -- end

	for i=1,#walls do
		local t={}
        local this_ceil = {index=walls[i][5]}
        local this_floor = {index=walls[i][5]}
		for j=1,4 do
            t[j] = do_intersect(pplane[1],pplane[2],pplane[3],pplane[4],walls[i][j].x,walls[i][j].y,p.x,p.y)
			-- add(t,do_intersect(pplane[1],pplane[2],pplane[3],pplane[4],walls[i][j].x,walls[i][j].y,p.x,p.y))

            -- ::rewall_top::

			-- t[j][6]=20-t[j][6]

			local pdist=math.sqrt((walls[i][j].x-p.x)^2+(walls[i][j].y-p.y)^2)

            -- if not t[j][1] then -- clip
            --     if j==1 or j==3 then
            --         love.graphics.setColor(1,1,1)
            --         love.graphics.print("true")
            --         love.graphics.print("false")
            --         love.graphics.setColor(0,0,0)
            --         love.graphics.print(tostring(do_intersect(pplane[1],pplane[2],pplane[3],pplane[4],walls[i][j+1].x,walls[i][j+1].y,p.x,p.y)[1]))
            --         if do_intersect(pplane[1],pplane[2],pplane[3],pplane[4],walls[i][j+1].x,walls[i][j+1].y,p.x,p.y)[1] then
            --             -- move t[j] along
            --             t[j] = do_intersect(pplane[1],pplane[2],pplane[3],pplane[4],walls[i][j].x,walls[i][j].y,walls[i][j+1].x,walls[i][j+1].y) -- {true, p_x, p_y, 0, 0, dist}
            --             goto rewall_top
            --         else
            --             goto not_seen
            --         end
            --     -- else
            --     --     if do_intersect(pplane[1],pplane[2],pplane[3],pplane[4],walls[i][j+1].x,walls[i][j+1].y,p.x,p.y)[1] then
            --     --         t[j] = do_intersect(pplane[1],pplane[2],pplane[3],pplane[4],walls[i][j].x,walls[i][j].y,walls[i][j+1].x,walls[i][j+1].y)
            --     --         if t[j][1] then
            --     --             goto rewall_top
            --     --         end
            --     --     end
            --     end
            -- end



-- 			local z1=do_intersect(vplane[1],vplane[2],vplane[3],vplane[4],--[[64,54-p.z,63,74-p.z,]]pdist+64,64+walls[i][j].z,54,63)
-- 			-- local z2=do_intersect(64,54-p.z,63,74-p.z,pdist+64,64-walls[i][j].z2,54,63)
-- 			if not z1[1] then
-- 				t[j][1] = false
-- 			end
-- --		local z1=do_intersect(vplane[1],vplane[2],vplane[3],vplane[4],pdist+64,64-m[i].z1,54,63)
-- --		local z2=do_intersect(vplane[1],vplane[2],vplane[3],vplane[4],pdist+64,64-m[i].z2,54,63)

-- 			t[j][4]=10-z1[6]

            t[j][4] = 10 * -(walls[i][j].z - p.z - 10) / pdist + screen.h / 40 - (p.va - .25) * 10

            if (walls[i][j].z == sectors[walls[i][5]].f or walls[i][j].z == sectors[walls[i][5]].c) and t[j][1] then
                this_floor[#this_floor+1] = t[j]
            end
            if (walls[i][j].z == sectors[walls[i][5]].c or walls[i][j].z == sectors[walls[i][5]].f) and t[j][1] then
                this_ceil[#this_ceil+1] = t[j]
            end

			-- pts[i][5]=z2[6]
            -- ::not_seen::
		end
		pts[#pts+1] = t
        if this_floor[1] ~= nil and this_floor[2] ~= nil and this_ceil[1] ~= nil and this_ceil[2] ~= nil then
            flr_draw[#flr_draw+1] = this_floor
            ceil_draw[#ceil_draw+1] = this_ceil
        end
	end
	
    --[[
    What shout I tell it to draw? How about this:
        Idea #1:
            Generation:
                Organize sectors by distance.
                Per sector:
                    Chose what points to draw and generate walls.
                Continue
            Per sector (farthest first):
                Draw floor/ceiling
                Draw walls (farthest first)
        Using this method, we don't have to worry about making the wall drawing function work for the floor/ceiling drawing.
        We can ignore floors/ceilings for now as the walls with give them borders.

        Note: To make a n tall thing look as tall as an n wide is wide, multiply drawing x and y by the same value and just constrain drawing to the window.
    ]]
	for i=1,#walls do
		local pdist1=math.sqrt((walls[i][1].x-p.x)^2+(walls[i][1].y-p.y)^2+(walls[i][1].z-p.z)^2)
		local pdist2=math.sqrt((walls[i][2].x-p.x)^2+(walls[i][2].y-p.y)^2+(walls[i][2].z-p.z)^2)
		local pdist3=math.sqrt((walls[i][3].x-p.x)^2+(walls[i][3].y-p.y)^2+(walls[i][3].z-p.z)^2)
		local pdist4=math.sqrt((walls[i][4].x-p.x)^2+(walls[i][4].y-p.y)^2+(walls[i][4].z-p.z)^2)
		local pdist=(pdist1+pdist2+pdist3+pdist4)/4
	
		ol[i]={pdist,i}
	end
	sort(ol)

    -- centers = {}
    -- for i=1,#sectors do
    --     centers[i] = false
    -- end
    -- for i=1,#flr_draw do
    --     -- log_error("Start "..tostring(flr_draw[i][1]))
    --     if not centers[flr_draw[i].index] then
    --         local point_list = {}
    --         x = flr_draw[i][1][4] + 1
    --         for j=1,#sectors[flr_draw[i].index].points do
    --             point_list[#point_list+1] = map[sectors[flr_draw[i].index].points[j]].x
    --             point_list[#point_list+1] = map[sectors[flr_draw[i].index].points[j]].y
    --         end
    --         if point_in_polygon(p.x,p.y,point_list) then
    --             centers[flr_draw[i].index] = {0,0,0,10,0,20}
    --             -- log_error("PIP true")
    --         else
    --             centers[flr_draw[i].index] = {0,0,0,flr_draw[i][1][4],0,flr_draw[i][1][6]}
    --             -- log_error("PIP false")
    --         end
    --     else
    --         -- x = flr_draw[i][1][4] + 1
    --         -- x = flr_draw[i][2][4] + 1 -- nil
    --         -- x = centers[flr_draw[i].index][4] + 1
    --         local l = {flr_draw[i][1][4]*screen.w/20,flr_draw[i][1][6]*screen.h/20,flr_draw[i][2][4]*screen.w/20,flr_draw[i][2][4]*screen.h/20,centers[flr_draw[i].index][4]*screen.w/20,centers[flr_draw[i].index][6]*screen.w/20}
    --         triangle_function("fill",l)
    --         -- log_error("Drawn")
    --     end
    --     -- log_error("End "..tostring(flr_draw[i][1]))
    -- end
    -- flr_draw = merge(flr_draw)
    -- for i=1,#flr_draw do
    --     local l = {}
    --     for j=1,#flr_draw[i] do
    --         l[#l+1] = flr_draw[i][j][6]*screen.w/20
    --         l[#l+1] = flr_draw[i][j][4]*screen.h/20
    --         -- log_error(l[j])
    --     end
    --     love.graphics.setColor(0,0,1)
    --     if #l > 5 then
    --         triangle_function("fill",l)
    --     end
    -- end

    -- ceil_draw = merge(ceil_draw)
    -- for i=1,#ceil_draw do
    --     local l = {}
    --     for j=1,#ceil_draw[i] do
    --         l[#l+1] = ceil_draw[i][j][6]*screen.w/20
    --         l[#l+1] = ceil_draw[i][j][4]*screen.h/20
    --         -- log_error(l[j])
    --     end
    --     love.graphics.setColor(0,0,1)
    --     if #l > 5 then
    --         triangle_function("fill",l)
    --     end
    -- end

    
    love.graphics.setColor(0,0,1)
    centers = {}
    for i=1,#sectors do
        centers[i] = false
    end
    for i=1,#flr_draw do
        -- log_error("Start "..tostring(flr_draw[i][1]))
        if not centers[flr_draw[i].index] then
            local point_list = {}
            -- x = flr_draw[i][1][4] + 1
            for j=1,#sectors[flr_draw[i].index].points do
                point_list[#point_list+1] = map[sectors[flr_draw[i].index].points[j]].x
                point_list[#point_list+1] = map[sectors[flr_draw[i].index].points[j]].y
            end
            if point_in_polygon(p.x,p.y,point_list) then
                centers[flr_draw[i].index] = {0,0,0,20,0,10}
                -- log_error("PIP true")
            else
                centers[flr_draw[i].index] = {0,0,0,flr_draw[i][1][4],0,flr_draw[i][1][6]}
                -- log_error("PIP false")
            end
        else
            -- x = flr_draw[i][1][4] + 1
            -- x = flr_draw[i][2][4] + 1 -- nil
            -- x = centers[flr_draw[i].index][4] + 1
            local l = {flr_draw[i][1][6]*screen.w/20,flr_draw[i][1][4]*screen.h/20,flr_draw[i][2][6]*screen.w/20,flr_draw[i][2][4]*screen.h/20,centers[flr_draw[i].index][6]*screen.w/20,centers[flr_draw[i].index][4]*screen.w/20}
            triangle_function("fill",l)
            -- log_error("Drawn")
        end
        -- log_error("End "..tostring(flr_draw[i][1]))
    end

    -- it's drawing from the floor
    centers = {}
    for i=1,#sectors do
        centers[i] = false
    end
    for i=1,#ceil_draw do
        -- log_error("Start "..tostring(flr_draw[i][1]))
        if not centers[ceil_draw[i].index] then
            local point_list = {}
            -- x = ceil_draw[i][1][4] + 1
            for j=1,#sectors[ceil_draw[i].index].points do
                point_list[#point_list+1] = map[sectors[ceil_draw[i].index].points[j]].x
                point_list[#point_list+1] = map[sectors[ceil_draw[i].index].points[j]].y
            end
            if point_in_polygon(p.x,p.y,point_list) then
                centers[ceil_draw[i].index] = {0,0,0,0,0,10}
                -- log_error("PIP true")
            else
                centers[ceil_draw[i].index] = {0,0,0,ceil_draw[i][1][4],0,ceil_draw[i][1][6]}
                -- log_error("PIP false")
            end
        else
            -- x = ceil_draw[i][1][4] + 1
            -- x = ceil_draw[i][2][4] + 1 -- nil
            -- x = centers[ceil_draw[i].index][4] + 1
            local l = {ceil_draw[i][1][6]*screen.w/20,ceil_draw[i][1][4]*screen.h/20,ceil_draw[i][2][6]*screen.w/20,ceil_draw[i][2][4]*screen.h/20,centers[ceil_draw[i].index][6]*screen.w/20,centers[ceil_draw[i].index][4]*screen.w/20}
            triangle_function("fill",l)
            -- log_error("Drawn")
        end
        -- log_error("End "..tostring(flr_draw[i][1]))
    end

	for i=#ol,1,-1 do
		local px=ol[i]
        local pt1=pts[px[2]][1]
        local pt2=pts[px[2]][2]
        local pt3=pts[px[2]][3]
        local pt4=pts[px[2]][4]
        if pt1[1] and pt2[1] and pt3[1] and pt4[1] then
            --[[
            pt1[6]*6.4,pt1[4]*12.8
            pt2[6]*6.4,pt2[4]*12.8
            pt1[6]*6.4,pt1[5]*12.8
            pt2[6]*6.4,pt2[5]*12.8
            ]]--
            -- tri(pt1[6]*screen.w/20,pt1[4]*screen.h/10,pt2[6]*screen.w/20,pt2[4]*screen.h/10,pt3[6]*screen.w/20,pt3[4]*screen.h/10,c)
            love.graphics.setColor(0,1/ol[i][1]*10,0)
            triangle_function("fill",pt1[6]*screen.w/20,pt1[4]*screen.h/20,pt2[6]*screen.w/20,pt2[4]*screen.h/20,pt3[6]*screen.w/20,pt3[4]*screen.h/20,pt4[6]*screen.w/20,pt4[4]*screen.h/20)
            ::skip::
        end
	end

    -- centers = {}
    -- for i=1,#sectors do
    --     centers[i] = false
    -- end
    -- for i=1,#ceil_draw do
    --     -- log_error("Start "..tostring(flr_draw[i][1]))
    --     if not centers[ceil_draw[i].index] then
    --         local point_list = {}
    --         x = ceil_draw[i][1][4] + 1
    --         for j=1,#sectors[ceil_draw[i].index].points do
    --             point_list[#point_list+1] = map[sectors[ceil_draw[i].index].points[j]].x
    --             point_list[#point_list+1] = map[sectors[ceil_draw[i].index].points[j]].y
    --         end
    --         if point_in_polygon(p.x,p.y,point_list) then
    --             centers[ceil_draw[i].index] = {0,0,0,10,0,20}
    --             -- log_error("PIP true")
    --         else
    --             centers[ceil_draw[i].index] = {0,0,0,ceil_draw[i][1][4],0,ceil_draw[i][1][6]}
    --             -- log_error("PIP false")
    --         end
    --     else
    --         -- x = flr_draw[i][1][4] + 1
    --         -- x = flr_draw[i][2][4] + 1 -- nil
    --         -- x = centers[flr_draw[i].index][4] + 1
    --         local l = {ceil_draw[i][1][6]*screen.w/20,ceil_draw[i][1][4]*screen.h/20,ceil_draw[i][2][6]*screen.w/20,ceil_draw[i][2][4]*screen.h/20,centers[ceil_draw[i].index][6]*screen.w/20,centers[ceil_draw[i].index][4]*screen.w/20}
    --         triangle_function("fill",l)
    --         -- log_error("Drawn")
    --     end
    --     -- log_error("End "..tostring(flr_draw[i][1]))
    -- end

    if love.keyboard.isDown("e") then
        editor = true
    end
    -- for i=1,#points do
    --     love.graphics.circle("line",points[i].x,points[i].y,5)
    --     love.graphics.line(points[i].x,points[i].y,p.x,p.y)
    -- end

    -- love.graphics.line(lplane[1]+20,lplane[2]+20,lplane[3]+20,lplane[4]+20)
    -- love.graphics.line(p.x+20,p.y+20,p.x+20+math.sin(p.a*math.pi*2),p.y+20+math.cos(p.a*math.pi*2))
    -- love.graphics.line(lvplane[1],lvplane[2],lvplane[3],lvplane[4])
end

function hit_square(px,py,px2,py2,sx,sy,sx3,sy3,sx4,sy4,sx2,sy2)
    local hit,x,y,dist = do_intersect(px,py,px2,py2,sx,sy,sx2,sy2)
    if hit then
        return hit,x,y,dist
    end
    local hit,x,y,dist = do_intersect(px,py,px2,py2,sx3,sy3,sx2,sy2)
    if hit then
        return hit,x,y,dist
    end
    local hit,x,y,dist = do_intersect(px,py,px2,py2,sx3,sy3,sx4,sy4)
    if hit then
        return hit,x,y,dist
    end
    local hit,x,y,dist = do_intersect(px,py,px2,py2,sx,sy,sx4,sy4)
    if hit then
        return hit,x,y,dist
    end
    return false,0,0,0
end

function dist_func(a,b) -- not in use but I like it.
    local dist_a = 0
    local dist_b = 0
    for i=1,#a do
        dist_a = dist_a + a[i].dist
        if i==#a then
            dist_a = dist_a / #a
        end
    end
    for i=1,#b do
        dist_b = dist_b + b[i].dist
        if i==#b then
            dist_b = dist_b / #b
        end
    end
    return dist_a > dist_b
end

function generate_walls(sect,map,plane,vplane) -- maybe put clipping here
    local val = {}
    for i=1,#sect do
        for j=1,#sectors[i].points do
            if j==#sectors[i].points then
                bool,floor,ceiling,floor2,ceiling2 = wall_or_not(sectors[i].points[j],sectors[i].points[1],i)
                if bool then
                    if floor~=ceiling then
                        val[#val+1] =
                        {
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = ceiling},
                            {x = map[sect[i].points[1]].x, y = map[sect[i].points[1]].y, z = ceiling},
                            {x = map[sect[i].points[1]].x, y = map[sect[i].points[1]].y, z = floor},
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = floor},i
                        }
                        val[#val] = constrain_wall(val[#val],plane,vplane)
                    end
                    if floor2~=ceiling2 then
                        val[#val+1] =
                        {
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = ceiling2},
                            {x = map[sect[i].points[1]].x, y = map[sect[i].points[1]].y, z = ceiling2},
                            {x = map[sect[i].points[1]].x, y = map[sect[i].points[1]].y, z = floor2},
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = floor2},i
                        }
                        val[#val] = constrain_wall(val[#val],plane,vplane)
                    end
                    if floor==ceiling and floor2==ceiling2 then
                        val[#val+1] =
                        {
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = sect[i].f},
                            {x = map[sect[i].points[1]].x, y = map[sect[i].points[1]].y, z = sect[i].f},
                            {x = map[sect[i].points[1]].x, y = map[sect[i].points[1]].y, z = sect[i].c},
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = sect[i].c},i
                        }
                        val[#val] = constrain_wall(val[#val],plane,vplane)
                    end
                end
                -- val[#val+1] =
                -- {
                --     {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = sect[i].f},
                --     {x = map[sect[i].points[1]].x, y = map[sect[i].points[1]].y, z = sect[i].f},
                --     {x = map[sect[i].points[1]].x, y = map[sect[i].points[1]].y, z = sect[i].c},
                --     {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = sect[i].c},
                -- }
            else
                bool,floor,ceiling,floor2,ceiling2 = wall_or_not(sectors[i].points[j],sectors[i].points[j+1],i)
                if bool then
                    if floor~=ceiling then
                        val[#val+1] =
                        {
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = ceiling},
                            {x = map[sect[i].points[j+1]].x, y = map[sect[i].points[j+1]].y, z = ceiling},
                            {x = map[sect[i].points[j+1]].x, y = map[sect[i].points[j+1]].y, z = floor},
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = floor},i
                        }
                        val[#val] = constrain_wall(val[#val],plane,vplane)
                    end
                    if floor2~=ceiling2 then
                        val[#val+1] =
                        {
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = ceiling2},
                            {x = map[sect[i].points[j+1]].x, y = map[sect[i].points[j+1]].y, z = ceiling2},
                            {x = map[sect[i].points[j+1]].x, y = map[sect[i].points[j+1]].y, z = floor2},
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = floor2},i
                        }
                        val[#val] = constrain_wall(val[#val],plane,vplane)
                    end
                    if floor==ceiling and floor2==ceiling2 then
                        val[#val+1] =
                        {
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = sect[i].f},
                            {x = map[sect[i].points[j+1]].x, y = map[sect[i].points[j+1]].y, z = sect[i].f},
                            {x = map[sect[i].points[j+1]].x, y = map[sect[i].points[j+1]].y, z = sect[i].c},
                            {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = sect[i].c},i
                        }
                        -- file = love.filesystem.newFile("error.txt")
                        -- file:open("a")
                        -- file:write(tostring(os.time()).." gw: "..tostring(map[i].z).."\n") -- nil
                        -- file:close()
                        -- log_error("gw: "..tostring(val[#val][1].z))
                        val[#val] = constrain_wall(val[#val],plane,vplane)
                    end
                end
                -- val[#val+1] =
                -- {
                --     {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = sect[i].f},
                --     {x = map[sect[i].points[j+1]].x, y = map[sect[i].points[j+1]].y, z = sect[i].f},
                --     {x = map[sect[i].points[j+1]].x, y = map[sect[i].points[j+1]].y, z = sect[i].c},
                --     {x = map[sect[i].points[j]].x, y = map[sect[i].points[j]].y, z = sect[i].c},
                -- }
            end
        end
    end
    return val
end

function wall_or_not(a,b,exclude)
    local floor = 0
    local ceiling = 0
    local floor2 = 0
    local ceiling2 = 0
    for i=1,#sectors do
        if i~=exclude then
            for j=1,#sectors[i].points do
                if j==#sectors[i].points then
                    if (a==sectors[i].points[j] and b==sectors[i].points[1]) or (b==sectors[i].points[j] and a==sectors[i].points[1]) then
                        if sectors[exclude].c > sectors[i].c then
                            floor = sectors[i].c
                            ceiling = sectors[exclude].c
                        end
                        if sectors[exclude].c < sectors[i].c then
                            ceiling = sectors[i].c
                            floor = sectors[exclude].c
                        end
                        if sectors[exclude].f > sectors[i].f then
                            floor2 = sectors[i].f
                            ceiling2 = sectors[exclude].f
                        end
                        if sectors[exclude].f < sectors[i].f then
                            ceiling2 = sectors[i].f
                            floor2 = sectors[exclude].f
                        end
                        if not (sectors[exclude].f == sectors[i].f and sectors[exclude].c == sectors[i].c) then
                            return true,floor,ceiling,floor2,ceiling2
                        else
                            return false
                        end
                    end
                else
                    if (a==sectors[i].points[j] and b==sectors[i].points[j+1]) or (b==sectors[i].points[j] and a==sectors[i].points[j+1]) then
                        if sectors[exclude].c > sectors[i].c then
                            floor = sectors[i].c
                            ceiling = sectors[exclude].c
                        end
                        if sectors[exclude].c < sectors[i].c then
                            ceiling = sectors[i].c
                            floor = sectors[exclude].c
                        end
                        if sectors[exclude].f > sectors[i].f then
                            floor2 = sectors[i].f
                            ceiling2 = sectors[exclude].f
                        end
                        if sectors[exclude].f < sectors[i].f then
                            ceiling2 = sectors[i].f
                            floor2 = sectors[exclude].f
                        end
                        if not (sectors[exclude].f == sectors[i].f and sectors[exclude].c == sectors[i].c) then
                            return true,floor,ceiling,floor2,ceiling2
                        else
                            return false
                        end
                    end
                end
            end
        end
    end
    return true
end

function constrain_wall(wall,plane,vplane)
    -- add vplane check as well
    local query = do_intersect(plane[1],plane[2],plane[3],plane[4],wall[1].x,wall[1].y,wall[2].x,wall[2].y)
    if query[1] then
        if do_intersect(plane[1],plane[2],plane[3],plane[4],wall[1].x,wall[1].y,p.x,p.y)[1] then
            -- local oldwall = {wall[2].x,wall[2].y}
            -- love.graphics.print(wall[2].x-query[2] - math.sin(p.a * math.pi * 2))
            wall[2].x = query[2] + math.sin(p.a * math.pi * 2)
            wall[2].y = query[3] + math.cos(p.a * math.pi * 2)
            wall[3].x = query[2] + math.sin(p.a * math.pi * 2)
            wall[3].y = query[3] + math.cos(p.a * math.pi * 2)
            if not do_intersect(plane[1],plane[2],plane[3],plane[4],wall[2].x,wall[2].y,p.x,p.y)[1] then
                x()
            end
            -- if oldwall[1]==wall[2].x + math.sin(p.a * math.pi * 2) and oldwall[2]==wall[2].y + math.cos(p.a * math.pi * 2) then
            --     scream()
            -- end
        elseif do_intersect(plane[1],plane[2],plane[3],plane[4],wall[2].x,wall[2].y,p.x,p.y)[1] then
            -- local oldwall = {wall[1].x,wall[1].y}
            wall[1].x = query[2] + math.sin(p.a * math.pi * 2)
            wall[1].y = query[3] + math.cos(p.a * math.pi * 2)
            wall[4].x = query[2] + math.sin(p.a * math.pi * 2)
            wall[4].y = query[3] + math.cos(p.a * math.pi * 2)
            -- if oldwall[1]==wall[1].x + math.sin(p.a * math.pi * 2) and oldwall[2]==wall[1].y + math.cos(p.a * math.pi * 2) then
            --     scream()
            -- end
        -- else
            -- y()
        end
    end
    return wall--constrain_wall_v(wall,vplane)
end

function constrain_wall_v(wall,plane) -- make work
    -- vplane check

    local pdist1 = dist_non_absolute(wall[1].x,wall[1].y,p.x,p.y,0,p.z,0,p.z+10) --math.sqrt((wall[1].x - p.x)^2 + (wall[1].y - p.y)^2)
    local pdist2 = dist_non_absolute(wall[2].x,wall[2].y,p.x,p.y,0,p.z,0,p.z+10) --math.sqrt((wall[2].x - p.x)^2 + (wall[2].y - p.y)^2)
    local pdist3 = dist_non_absolute(wall[3].x,wall[3].y,p.x,p.y,0,p.z,0,p.z+10) --math.sqrt((wall[3].x - p.x)^2 + (wall[3].y - p.y)^2)
    local pdist4 = dist_non_absolute(wall[4].x,wall[4].y,p.x,p.y,0,p.z,0,p.z+10) --math.sqrt((wall[4].x - p.x)^2 + (wall[4].y - p.y)^2)
    local pdist = {pdist1,pdist2,pdist3,pdist4}
    local tan = math.tan(p.a * math.pi * 2)
    local mod = 1
    if p.a < .25 and p.a < .75 then
        mod = -1
    end
    local next_pt = 0
    local query = {}

    for i=1,4 do
        -- get the next point
        if i==4 then
            next_pt = 1
        else
            next_pt = i + 1
        end
        -- what's the visibility of this line?
        if do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[i]+64,64+wall[i].z,54,63)[1] and do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[next_pt]+64,64+wall[next_pt].z,54,63)[1] then
            -- do nothing
        elseif do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[i]+64,64+wall[i].z,54,63)[1] then
            query = do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[i]+64,64+wall[i].z,pdist[next_pt]+64,64+wall[next_pt].z)
            wall[next_pt].y = query[6] / math.sqrt(tan^2 + 1)
            wall[next_pt].x = mod * tan * wall[next_pt].y
            pdist[next_pt] = dist_non_absolute(wall[next_pt].x,wall[next_pt].y,p.x,p.y,0,p.z,0,p.z+10)
        elseif do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[next_pt]+64,64+wall[next_pt].z,54,63)[1] then
            query = do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[i]+64,64+wall[i].z,pdist[next_pt]+64,64+wall[next_pt].z)
            wall[i].y = query[6] / math.sqrt(tan^2 + 1)
            wall[i].x = mod * tan * wall[i].y
            pdist[i] = dist_non_absolute(wall[i].x,wall[i].y,p.x,p.y,0,p.z,0,p.z+10)
        else

        end
    end

    -- for i=1,4 do
    --     if i==4 then
    --         local query = do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[i]+64,64+wall[i].z,pdist[1]+64,64+wall[1].z)
    --         if query[1] then
    --             if do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[i]+64,64+wall[i].z,54,63)[1] then -- pdist+64,64+walls[1].z,54,63
    --                 tan = math.tan(p.a * math.pi * 2)
    --                 if p.a < .25 and p.a < .75 then
    --                     mod = -1
    --                 else
    --                     mod = 1
    --                 end
    --                 wall[i].y = (query[2] + math.sin(p.va * math.pi * 2)) / math.sqrt(tan^2 + 1)
    --                 wall[i].x = mod * tan * wall[i].y
    --                 wall[i].z = query[3] + math.cos(p.a * math.pi * 2)
    --             elseif do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[1]+64,64+wall[1].z,54,63)[1] then
    --                 wall[1].y = (query[2] + math.sin(p.va * math.pi * 2)) / math.sqrt(tan^2 + 1)
    --                 wall[1].x = mod * tan * wall[1].y
    --                 wall[1].z = query[3] + math.cos(p.a * math.pi * 2)
    --             end
    --         end
    --     else
    --         -- file = love.filesystem.newFile("error.txt")
    --         -- file:open("a")
    --         -- file:write(tostring(os.time()).." cwv: "..tostring(map[i].z).."\n") -- nil
    --         -- file:close()
    --         -- log_error("cwv: "..tostring(pdist[i]))
    --         local query = do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[i]+64,64+wall[i].z,pdist[i+1]+64,64+wall[i+1].z)
    --         if query[1] then
    --             if do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[i]+64,64+wall[i].z,54,63)[1] then -- pdist+64,64+walls[1].z,54,63
    --                 tan = math.tan(p.a * math.pi * 2)
    --                 if p.a < .25 and p.a < .75 then
    --                     mod = -1
    --                 else
    --                     mod = 1
    --                 end
    --                 wall[i].y = (query[2] + math.sin(p.va * math.pi * 2)) / math.sqrt(tan^2 + 1)
    --                 wall[i].x = mod * tan * wall[i].y
    --                 wall[i].z = query[3] + math.cos(p.a * math.pi * 2)
    --             elseif do_intersect(plane[1],plane[2],plane[3],plane[4],pdist[i+1]+64,64+wall[i+1].z,54,63)[1] then
    --                 wall[i+1].y = (query[2] + math.sin(p.va * math.pi * 2)) / math.sqrt(tan^2 + 1)
    --                 wall[i+1].x = mod * tan * wall[i+1].y
    --                 wall[i+1].z = query[3] + math.cos(p.a * math.pi * 2)
    --             end
    --         end
    --     end
    -- end
    return wall
end

-- found online
function pointincircle(px, py, cx, cy, r)
	local dx, dy = px - cx, py - cy
	return dx*dx + dy*dy <= r*r
end

function pointonsegment(px, py, x1, y1, x2, y2)
	local cx, cy = px - x1, py - y1
	local dx, dy = x2 - x1, y2 - y1
	local d = (dx*dx + dy*dy)
	if d == 0 then
		return x1, y1
	end
	local u = (cx*dx + cy*dy)/d
	if u < 0 then
		u = 0
	elseif u > 1 then
		u = 1
	end
	return x1 + u*dx, y1 + u*dy
end

function segmentvscircle(x1, y1, x2, y2, cx, cy, cr)
	local qx, qy = pointonsegment(cx, cy, x1, y1, x2, y2)
	return pointincircle(qx, qy, cx, cy, cr)
end

function can_move(x,y,z,r,a)
    -- local z_change = z
    -- a = a * math.pi * 2
    local point_list = {}

    for i=1,#sectors do
        point_list = {}
        for j=1,#sectors[i].points do
            point_list[#point_list+1] = map[sectors[i].points[j]].x
            point_list[#point_list+1] = map[sectors[i].points[j]].y
        end
        if point_in_polygon(x,y,point_list) then
            if (sectors[i].f <= p.z + 3 and sectors[i].c >= p.z + 9) or (sectors[i].f < p.z and sectors[i].c > p.z + 7) then
                return true, sectors[i].f
            end
        end
    end

    return false, z

    -- for i=1,#walls do
    --     --[[
    --     I'm going with the "are you colliding with a wall" collision detection.
    --     I could also use (and it might be worth it to try) "is the sector you're colliding with passable".
    --     ]]
    --     if segmentvscircle(walls[i][1].x,walls[i][1].y,walls[i][2].x,walls[i][2].y,x,y,r) then
    --         -- we've run into a wall on the map
    --         if (walls[i][1].z < p.z and walls[i][3].z < p.z) or (walls[i][1].z > p.z + 5 and walls[i][3].z > p.z + 5) then
    --             -- the wall is above or below us
    --         else
    --                 -- z = walls[i][1].z + 5
    --             return false,z_change
    --         end
    --     end
    -- end
	-- return true,z_change
end

-- function point_in_polygon(x,y,sect)
--     local hits = 0
--     local hit = false
--     for i=1,#sect do
--         if i==#sect then
--             hit = do_intersect(x,y,x+1,y,map[sect[i]].x,map[sect[i]].y,map[sect[1]].x,map[sect[1]].y)
--             if hit then
--                 hits = hits + 1
--             end
--         else
--             hit = do_intersect(x,y,x+1,y,map[sect[i]].x,map[sect[i]].y,map[sect[i+1]].x,map[sect[i+1]].y)
--             if hit then
--                 hits = hits + 1
--             end
--         end
--     end
--     return hits/2 - math.floor(hits/2) ~= 0
-- end

function log_error(text)
    file = love.filesystem.newFile("error.txt")
    file:open("a")
    file:write(tostring(os.time()).." "..text.."\n")
    file:close()
end

function love.mousemoved( x, y, dx, dy, istouch )
	mx = dx
    my = dy
end

function dist_non_absolute(x1,y1,x2,y2,x3,y3,x4,y4)
    local ret = math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
    if not do_intersect(x1,y1,x2,y2,x3,y3,x4,y4)[1] then
        ret = -ret
    end
    return ret
end

function merge(list)
    local ret = {}
    for i=1,#list do
        local set = false
        for j=1,#ret do
            if ret[j].index == list[i].index then -- list[i][1] = t[j]
                ret[j] = combine(ret[j],list[i])
                ret[j].index = list[i].index
                -- ret[j] = {ret[j][1],ret[j][2],list[i][1],list[i][2],index=list[i].index}
                set = true
            end
        end
        if not set then
            ret[#ret+1] = list[i]
        end
    end
    return ret
end

function combine(l1,l2)
    local ret = {}
    for i=1,#l1 do
        ret[#ret+1] = l1[i]
    end
    for i=2,#l2 do
        ret[#ret+1] = l2[i]
    end
    return ret
end

--[[
l = 
{
    {a,b,index=1},
    {c,d,index=1},
    {e,f,index=2},
    {g,h,index=3},
    {i,j,index=3}
}
merge(l)
i = 1
set = false
#ret = 0
ret[1] = list[1]
i = 2
set = false
#ret = 1
list[2].index == ret[1].index
ret[1] = {a,b,c,d,index=1}

]]

init()

function love.update(dt)
    delta_time = dt
end

function love.draw()
    if editor then
        love.mouse.setRelativeMode(false)
        editor_main()
    else
        love.mouse.setRelativeMode(true)
        main()
    end
end