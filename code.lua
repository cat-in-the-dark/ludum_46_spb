-- title:  Grecha
-- author: BOOtak
-- desc:   Keep yourself alive crafting food from your inventory
-- script: lua

T = 8
W = 240
H = 136

W3D=80
H3D=45

sf = string.format

UP=0
DOWN=1
LEFT=2
RIGHT=3
Z=4

-- helpers

function safe1( f, arg )
  if f ~= nil then f(arg) end
end

function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepcopy(orig_key)] = deepcopy(orig_value)
    end
    setmetatable(copy, deepcopy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

function removeFrom(tab,obj,toDel)
  if not table.contains(tab, obj) then
    trace("table does not contain object!!!")
  end
  obj.__rem=true
  obj.__del=toDel
end

function cleanup(tab)
  for i = #tab, 1, -1 do
    obj=tab[i]
    if obj.__rem then
      obj.__rem=false
      table.remove(tab, i)
      if obj.__del then obj=nil end
    end
  end
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function table.matches( table1, table2 )
  for i,v in ipairs(table1) do
    if not table.contains(table2, v) then return false end
  end
  for i,v in ipairs(table2) do
    if not table.contains(table1, v) then return false end
  end
  return true
end

-- draw helpers

function make_tex(c0,w,h)
  tex={}
  for i=1,h do
    tex[i]={}
    for j=1,w do
      tex[i][j]=c0 + (j-1) + (i-1)*16
    end
  end
  return tex
end

function draw_entity( e )
  if e.sp == nil then return end
  local offx,offy = e.offx, e.offy
  if offx == nil then offx = 0 end
  if offy == nil then offy = 0 end
  for i,t in ipairs(e.sp) do
    for j,v in ipairs(t) do
      spr(v, e.x+(j-1)*T + offx, e.y+(i-1)*T + offy, 0)
    end
  end
end

function printframe(text,x,y,c,fc,small)
  c = c or 15
  fc = fc or 0
  small = small or false
  print(text,x-1,y,fc,false,1,small)
  print(text,x+1,y,fc,false,1,small)
  print(text,x,y-1,fc,false,1,small)
  print(text,x,y+1,fc,false,1,small)
  print(text,x-1,y-1,fc,false,1,small)
  print(text,x+1,y-1,fc,false,1,small)
  print(text,x-1,y+1,fc,false,1,small)
  print(text,x+1,y+1,fc,false,1,small)
  print(text,x,y,c,false,1,small)
end

-- 3d

cam={
  x=0,
  y=0,
  z=0
}

function point_3d( x,y,z )
  local dz = z - cam.z
  local x2d,y2d = (x-cam.x)/dz, (y-cam.y)/dz
  local xnorm, ynorm = (x2d + W3D/2) / W3D, (y2d + H3D/2) / H3D
  local xproj, yproj = xnorm * W, (-ynorm + 1) * H
  return xproj, yproj
end

function line_3d( x1,y1,z1,x2,y2,z2,c )
  if z1 <= 0 or z2 <= 0 then return end
  xn1,yn1 = point_3d(x1,y1,z1)
  xn2,yn2 = point_3d(x2,y2,z2)
  line(xn1,yn1,xn2,yn2,c)
end

function v3( x,y,z )
  return {x=x,y=y,z=z}
end

function sq( v )
  return v*v
end

function v2dist( v1,v2 )
  local p1,p2 = sq(v1.x-v2.x),sq(v1.y-v2.y)
  local res = math.sqrt(p1+p2)
  return res
end

function v3add( v1,v2 )
  return {x=v1.x+v2.x,y=v1.y+v2.y,z=v1.z+v2.z}
end

function line_3dv( v1,v2,c )
  line_3d(v1.x,v1.y,v1.z,v2.x,v2.y,v2.z,c)
end

function line_3dvv( vecs,c )
  for i=1,#vecs-1 do
    line_3dv(vecs[i], vecs[i+1], c)
  end
end

function circb_3dv( v,r,c )
  local cx,cy = point_3d(v.x,v.y,v.z)
  local dx=v3(r,0,0)
  local p = v3add(v,dx)
  local px,py = point_3d(p.x,p.y,p.z)
  local r2d = math.abs(px-cx)
  circb(cx,cy,r2d,c)
end

function rect_3d( x,y,z,w,h )
  line_3d(x, y, z, x + w, y, z)
  line_3d(x, y, z, x, y - h, z)
  line_3d(x + w, y - h, z, x, y - h, z)
  line_3d(x + w, y - h, z, x + w, y, z)
end

Names={
  bw="Buckwheat",
  tp="Toilet Paper",
  bwp="Buckwheat porridge",
  w="Water",
  chr="Charcoal powder",
  mlk="Milk",
  sc="Sour Cream",
  bt="Butter",
  flw="Buckwheat Flower",
  brd="Bread",
  ink="Ink",
  pap="Paper",
  scrl="Scroll of Wisdom",
  ndls="Noodles",
  dftp="Deep Fried Toilet Paper"
}

Items={
  {
    name=Names.tp,
    nutr=0,
    sp = make_tex(0, 2, 2),
    spoil=-1
  },
  {
    name=Names.bw,
    nutr=10,
    sp = make_tex(2, 2, 2),
    spoil=-1
  },
  {
    name=Names.bwp,
    nutr=20,
    sp = make_tex(6, 2, 2),
    spoil=3
  },
  {
    name=Names.w,
    nutr=1,
    sp = make_tex(4, 2, 2),
    spoil=-1
  },
  {
    name=Names.chr,
    nutr=0,
    sp=make_tex(8, 2, 2),
    spoil=-1
  },
  {
    name=Names.mlk,
    nutr=1,
    spoil=-1
  },
  {
    name=Names.sc,
    nutr=1,
    spoil=-1
  },
  {
    name=Names.bt,
    nutr=1,
    spoil=-1
  },
  {
    name=Names.flw,
    nutr=1,
    spoil=-1
  },
  {
    name=Names.brd,
    nutr=1,
    spoil=-1
  },
  {
    name=Names.ink,
    nutr=1,
    spoil=-1
  },
  {
    name=Names.pap,
    nutr=1,
    spoil=-1
  },
  {
    name=Names.scrl,
    nutr=1,
    spoil=-1
  },
  {
    name=Names.ndls,
    nutr=1,
    spoil=-1
  },
  {
    name=Names.dftp,
    nutr=1,
    spoil=-1
  }
}

Recepies={
  {
    items={Names.bw, Names.w},
    res=Names.bwp
  },
  {
    items={Names.tp},
    res=Names.chr
  },
  {
    items={Names.mlk},
    res=Names.sc
  },
  {
    items={Names.sc},
    res=Names.bt
  },
  {
    items={Names.bw},
    res=Names.flw
  },
  {
    items={Names.tp, Names.w},
    res=Names.pap
  },
  {
    items={Names.flw, Names.mlk},
    res=Names.brd
  },
  {
    items={Names.flw, Names.w},
    res=Names.ndls
  },
  {
    items={Names.chr, Names.w},
    res=Names.ink
  },
  {
    items={Names.ink, Names.pap},
    res=Names.scrl
  },
  {
    items={Names.tp, Names.bt},
    res=Names.dftp
  }
}

Button={
  x=0,
  y=0,
  w=0,
  h=0,
  pressed=false,
  hover=false,
  color=0,
  sp={},
  offx=0,
  offy=0,
  on_enter=nil,
  on_hover=nil,
  on_press=nil,
  on_release=nil,
  on_leave=nil
}

Inventory={
  name="Inventory",
  items={},
  size=15
}
Hand={
  name="Hand",
  items={},
  size=1
}
Craftstable={
  name="Craftstable",
  items={},
  size=2
}

ALL_INVENTORIES={
  Inventory,
  Hand,
  Craftstable
}

HEALTH=100
TIME=0

-- buttons

function g_press( btn )
  btn.color = 6
end

function g_release( btn )
  btn.color = 7
end

function g_hover( btn )
  btn.color = 8
end

function g_leave( btn )
  btn.color = btn.orig_c
end

function make_button( x, y, w, h, color, on_hover, on_leave, on_press, on_release, on_enter, sp, offx, offy )
  local btn = deepcopy(Button)
  btn.x, btn.y = x,y
  btn.w, btn.h = w,h
  btn.color = color
  btn.orig_c = color
  btn.on_hover = on_hover
  btn.on_leave = on_leave
  btn.on_press = on_press
  btn.on_release = on_release
  btn.on_enter = on_enter
  btn.sp = sp
  btn.offx = offx
  btn.offy = offy
  return btn
end

function check_button( btn, mx, my, md )
  local x,y,r,d = btn.x, btn.y, btn.x + btn.w, btn.y + btn.h
  local old_hover = btn.hover
  local old_pressed = btn.pressed
  if x <= mx and r >= mx and y <= my and d >= my then
    btn.hover = true
    if md then
      btn.pressed = true
    else
      btn.pressed = false
    end
  else
    btn.hover = false
  end

  if btn.hover then
    safe1(btn.on_hover, btn)
  end

  if old_hover and not btn.hover then
    safe1(btn.on_leave, btn)
  elseif not old_hover and btn.hover then
    safe1(btn.on_enter, btn)
  end
  if old_pressed and not btn.pressed then
    safe1(btn.on_press, btn)
  elseif btn.pressed and not old_pressed then
    safe1(btn.on_release, btn)
  end
end

function draw_button( btn )
  rect(btn.x, btn.y, btn.w, btn.h, btn.color)
  rectb(btn.x, btn.y, btn.w, btn.h, 2)
  rectb(btn.x + 1, btn.y + 1, btn.w - 1, btn.h - 1, 2)
  if btn.item ~= nil then
    local item,x,y,w,h = btn.item,btn.x,btn.y,btn.w,btn.h
    local ent = {x=x, y=y, sp=item.sp, offx=btn.offx, offy=btn.offy}
    draw_entity(ent)
    local count = item.count
    local width = print(count,W,H,15,false,1,true)
    printframe(count,x+w-width-1,y+h-6,15,0,true)
  end
end

-- inventory

function make_item( name,count )
  for i,it in ipairs(Items) do
    if it.name == name then
      new_item = deepcopy(it)
      new_item.count = count
      return new_item
    end
  end
end

function inventory_get( inv, item )
  for i,it in ipairs(inv.items) do
    if it.name == item.name and it.spoil == item.spoil then return it end
  end
  return nil
end

function inventory_get_count( inv, item, count )
  local it = inventory_get(inv, item)
  if it.count >= count then
    return it
  else
    return nil
  end
end

function inventory_take( inv, item, count )
  for i,it in ipairs(inv.items) do
    if it.name == item.name and it.spoil == item.spoil then
      local taken = math.min(count, it.count)
      local new_item = make_item(it.name, taken)
      new_item.spoil = it.spoil
      it.count = it.count - taken
      if it.count == 0 then
        removeFrom(inv.items, it, true)
      end
      return new_item
    end
  end
  return nil
end

function inventory_get_by_name( inv, name )
  res = {}
  for i,it in ipairs(inv.items) do
    if it.name == name then table.insert(res, it) end
  end
  return res
end

function inventory_add_item( inv, item )
  local same_items = inventory_get_by_name(inv, item.name)
  for i,same in ipairs(same_items) do
    if same.spoil == item.spoil then
      same.count = same.count + item.count
      return true
    end
  end
  if inv.size > #inv.items then
    table.insert(inv.items, item)
    return true
  end
  return false
end

function inventory_add( inv, name, count )
  local new_item = make_item(name, count)
  return inventory_add_item(inv, new_item)
end

function check_recepie( names )
  for i,recepie in ipairs(Recepies) do
    if table.matches(recepie.items, names) then return recepie.res end
  end
  return nil
end

function make_recepie( inv )
  names = {}
  namestr = ""
  min_item_count = -1
  for i,it in ipairs(inv.items) do
    table.insert(names, it.name)
    namestr = sf("%s%s; ", namestr, it.name)
    if min_item_count == -1 or min_item_count > it.count then min_item_count = it.count end
  end

  if min_item_count == 0 then
    trace("unable to make 0 items")
    return false
  end

  local res = check_recepie(names)
  if res ~= nil then
    res_count = min_item_count * #inv.items
    -- check if have all items to remove
    for i,it in ipairs(inv.items) do
      local test = inventory_get_count(inv, it, min_item_count)
      if test == nil or test.count == 0 then return false end
    end

    -- remove items to make room for new item
    for i,it in ipairs(inv.items) do
      inventory_take(inv, it, min_item_count)
    end

    -- cleanup
    cleanup(inv.items)

    -- add new item
    if not inventory_add(inv, res, res_count) then
      trace(sf("Unable to add %s to inventory", res))
      return false
    end
  else
    trace(sf("unable to craft from: %s", namestr))
    return false
  end
  return true
end

function eat( inv )
  if #inv.items <= 0 then return false end

  local item = inv.items[1]
  it = inventory_take(inv, item, 1)
  if it == nil then
    trace(sf("no item %s in inventory!", item.name))
    return false
  end
  HEALTH = HEALTH + it.nutr
  return true
end

function update_spoil( inv )
  for i,it in ipairs(inv.items) do
    if it.spoil ~= -1 then
      it.spoil = it.spoil - 1
      if it.spoil == 0 then
        trace(sf("Remove %s from inv; spoiled!", it.name))
        removeFrom(inv.items, it, true)
      end
    end
  end
end

function on_inventory_hover( btn )
  g_hover(btn)
  if btn.item ~= nil and btn.item.count > 0 then
    if #Hand.items > 0 then return end
    local dx,dy = 5, 5
    local mx,my = mouse()
    local it = btn.item
    local exp_str = sf("%d days", it.spoil)
    if it.spoil == -1 then exp_str = "Never"
    elseif it.spoil == 1 then exp_str = "1 day" end
    local text = sf("%s\nNutrition: %d\nExpires in: %s", it.name, it.nutr, exp_str)
    local width = print(text, W, H)
    rect(math.min(W-width-2, mx + dx-2), my + dy-2, width+5, 22, 8)
    printframe(text, math.min(W-width, mx + dx), my + dy)
  end
end

function move_item( to, from, item, count )
  local temp_item = inventory_get_count(from, item, count)
  if temp_item ~= nil then
    local new_item = deepcopy(temp_item)
    new_item.count = count
    if inventory_add_item(to, new_item) then
      inventory_take(from, item, count)
      return true
    else
      return false
    end
  end
  return false
end

after_craft = false

function on_inventory_click( btn )
  if btn.item ~= nil and btn.inv ~= nil then
    local inv_item = inventory_get(btn.inv, btn.item)

    local to_take = 1
    if btn.inv.name == "Craftstable" and after_craft then
      to_take=inv_item.count
      after_craft = false
    end

    if #Hand.items == 0 then
      move_item(Hand, btn.inv, inv_item, to_take)
    else
      if Hand.prev_click == nil or Hand.prev_click == btn.inv then
        if not move_item(Hand, btn.inv, inv_item, to_take) then
          local hand_item = Hand.items[1]
          if inventory_add_item(btn.inv, hand_item) then
            Hand.items = {}
            move_item(Hand, btn.inv, inv_item, to_take)
          end
        end
      else
        move_item(btn.inv, Hand, Hand.items[1], Hand.items[1].count)
      end
    end
  elseif #Hand.items > 0 then
    move_item(btn.inv, Hand, Hand.items[1], Hand.items[1].count)
  end
  Hand.prev_click = btn.inv
end

function on_craft_click( btn )
  if make_recepie(Craftstable) then
    after_craft = true
  end
end

function on_eat_click( btn )
  state = EATING
end

function draw_buttons( btns )
  for i,v in ipairs(btns) do
    draw_button(v)
  end
end

function update_buttons( btns )
  local mx,my,md = mouse()
  draw_buttons(btns)
  for i,v in ipairs(btns) do
    check_button(v, mx, my, md)
  end
end

function draw_inventory( inv )
  for i,btn in ipairs(INV_BUTTONS) do
    btn.item=nil
    btn.inv=inv
  end
  for i,it in ipairs(inv.items) do
    INV_BUTTONS[i].item=it
  end
end

function draw_craft_table( inv )
  for i,btn in ipairs(CRAFT_BUTTONS) do
    btn.item=nil
    btn.inv=inv
  end
  for i,it in ipairs(inv.items) do
    CRAFT_BUTTONS[i].item=it
  end
end

function draw_hand( inv )
  local mx,my = mouse()
  local dx,dy = -15, -15
  if #inv.items == 1 and inv.items[1].count > 0 then
    local item = inv.items[1]
    draw_entity({x=mx+dx,y=my+dy,sp=item.sp})
    local width = print(item.count, W, H, 0, false, 1, true)
    printframe(item.count, mx+dx+16-width, my+dy+10, 15, 0, true)
  end
end

radius=10
angle=0
angle1=0
radius1=0.3
a_speed=0.015
w_speed=0.01

function move_cam()
  angle = angle + a_speed
  angle1=angle1 + w_speed
  cam.x = math.cos(angle) * radius
  cam.y = math.sin(angle) * radius
  cam.z = 0.2+math.sin(angle1) * radius1
end

pangle=0
delta = math.pi / 10
pspeed = 0.003
min_angle,max_angle=pangle-delta,pangle+pspeed
dir=1

function draw_person(cx,cy)
  b1 = v3(cx, cy,2.2)
  t2=v3add(b1,v3(10,10,0))
  t3=v3add(b1,v3(8,10,-0.2))
  b2=v3add(b1,v3(12,0,0))
  b3=v3add(b1,v3(10,0,-0.25))
  line_3dvv({b1,t2,b2},2)
  line_3dvv({b1,t3,b3},2)

  -- top part
  t1=v3(cx,cy+18,2.2)
  local r=4
  dy=v3(0,r,0)
  local h = v3add(dy,t1)
  b2=v3add(t1,v3(6,-2,0))
  b3=v3add(t1,v3(4,-2,-0.2))
  t2=v3add(t1,v3(2,2,0))
  t3=v3add(t1,v3(0,2,-0.1))

  pangle = pangle + dir*pspeed
  if pangle <= min_angle or pangle >= max_angle then dir = -dir end

  for i,v in ipairs({t1,b2,b3,t2,t3,h}) do
    local dst = v2dist(v,b1)
    local dangle = math.atan(v.y-b1.y,v.x-b1.x)
    local temp = v3add(b1, v3(dst*math.cos(dangle+pangle),dst*math.sin(dangle+pangle), 0))
    v.x,v.y=temp.x,temp.y
  end

  circb_3dv(h,r,2)
  line_3dvv({t1,b2,t2},2)
  line_3dvv({t1,b3,t3},2)
  line_3dv(b1,t1,2)
end

function draw_room()
  -- walls
  local tlx, tly = -W3D / 2 - 10, H3D / 2 + 10
  local trx, try = W3D / 2 + 10, H3D / 2 + 10
  local blx, bly = -W3D / 2 - 10, -H3D / 2 - 10
  local brx, bry = W3D / 2 + 10, -H3D / 2 - 10
  line_3d(tlx, tly, 1, tlx, tly, 3, 2)
  line_3d(trx, try, 1, trx, try, 3, 2)
  line_3d(blx, bly, 1, blx, bly, 3, 2)
  line_3d(brx, bry, 1, brx, bry, 3, 2)
  rect_3d(tlx, tly, 3, trx-tlx, tly-bly)

  -- table
  local l1,l2,l3,l4 = v3(blx+2, bly, 2), v3(blx+2,bly,2.5), v3(blx+24,bly,2.5), v3(blx+24,bly,2)
  local dy = v3(0,20,0)
  local t1,t2,t3,t4 = v3add(l1,dy), v3add(l2,dy), v3add(l3,dy), v3add(l4,dy)
  line_3dv(l1, t1, 2)
  line_3dv(l2, t2, 2)
  line_3dv(l3, t3, 2)
  line_3dv(l4, t4, 2)
  line_3dvv({t1, t2, t3, t4, t1}, 2)

  -- fridge
  local b1,b2,b3,b4 = v3(brx,bry,3), v3(brx-20,bry,3), v3(brx-20,bry,2.7),v3(brx,bry,2.7)
  dy=v3(0,55,0)
  t1,t2,t3,t4 = v3add(b1,dy), v3add(b2,dy), v3add(b3,dy), v3add(b4,dy)
  line_3dvv({b1,b2,b3,b4,b1},2)
  line_3dvv({t1,t2,t3,t4,t1},2)
  line_3dvv({b1,b2,t2,t1,b1},2)
  line_3dvv({b3,b4,t4,t3,b3},2)
  dy=v3(0,30,0)
  local h1,h2 = v3add(b2,dy),v3add(b3,dy)
  line_3dv(h1,h2,2)

  -- furniture 1
  b1,b2,b3,b4 = v3(brx,bry,1), v3(brx,bry,2.7), v3(brx-18,bry,2.7),v3(brx-18,bry,1)
  dy=v3(0,20,0)
  t1,t2,t3,t4 = v3add(b1,dy), v3add(b2,dy), v3add(b3,dy), v3add(b4,dy)
  line_3dvv({b1,b2,b3,b4,b1},2)
  line_3dvv({t1,t2,t3,t4,t1},2)
  line_3dvv({b1,b2,t2,t1,b1},2)
  line_3dvv({b3,b4,t4,t3,b3},2)

  -- window
  t1,t2,t3,t4=v3(brx-30,bry+15,3),v3(blx+30,bry+15,3),v3(blx+30,tly-15,3),v3(brx-30,tly-15,3)
  line_3dvv({t1,t2,t3,t4,t1},2)
  local dx=v3(20,0,0)
  h1,h2 = v3add(t3,dx),v3add(t2,dx)
  line_3dv(h1,h2,c)
  dy=v3(0,-13,0)
  h1,h2 = v3add(t3,dy),v3add(t4,dy)
  line_3dv(h1,h2,c)

  -- person
  draw_person(0, bly)
end

function on_new_day( inv )
  update_spoil(inv)
  FULLNESS = FULLNESS - HUNGER_SPEED
  local to_eat = -1
  local min_spoil = -1
  local max_nutr = -1
  for i,it in ipairs(inv.items) do
    -- take product that expires sooner
    if min_spoil > it.spoil then
      min_spoil = it.spoil
      to_eat = i
      max_nutr = it.nutr
    -- if multiple found expire same day, take more nutricious
    elseif min_spoil == -1 or min_spoil == it.spoil then
      if max_nutr < it.nutr then
        to_eat = i
        max_nutr = it.nutr
      end
    end
  end
  local item = inventory_take(inv, inv.items[to_eat], 1)
  if item ~= nil then
    FULLNESS = FULLNESS + item.nutr
  else
    trace(sf("Unable to eat %s!", inv.items[to_eat].name))
    exit()
  end
end

function handle_eating( inv )
  TICK = TICK + 1
  if TICK == FPD then
    TICK=0
    DAYS=DAYS + 1
    on_new_day(inv)
  end
end

-- init

function init_inv( inv )
  inv.items={}
  inventory_add(inv, Names.bw, 10)
  inventory_add(inv, Names.w, 90)
  inventory_add(inv, Names.tp, 10)
  inventory_add(inv, Names.mlk, 5)
end

function init_buttons()
  local startx,starty = 0, 0
  local w,h = 20, 20
  local c = 10
  for i=1,5 do
    for j=1,3 do
      local btn = make_button(startx + (w + 1) * i, starty + (h + 1) * j, w, h, c, on_inventory_hover, g_leave, g_press, on_inventory_click, nil, nil, 2, 2)
      table.insert(BUTTONS, btn)
      table.insert(INV_BUTTONS, btn)
    end
  end

  startx,starty = 120, 0
  for i=1,2 do
    local btn = make_button(startx + (w + 1) * i, starty + (h + 1), w, h, c, on_inventory_hover, g_leave, g_press, on_inventory_click, nil, nil, 2, 2)
    table.insert(BUTTONS, btn)
    table.insert(CRAFT_BUTTONS, btn)
  end

  local do_craft = make_button(141, 42, 41, 20, c, g_hover, g_leave, g_press, on_craft_click, nil)
  table.insert(BUTTONS, do_craft)

  local do_eat = make_button(141, 106, 40, 20, c, g_hover, g_leave, g_press, on_eat_click, nil)
  table.insert(BUTTONS, do_eat)
end

function INITGame()
  BUTTONS={}
  INV_BUTTONS={}
  CRAFT_BUTTONS={}
  init_inv(Inventory)
  init_buttons()
end

function INITEating()
  DAYS=0
  FPD=60
  TICK=0
  FULLNESS=100
  HUNGER_SPEED=10
end

function TICGame()
  local x,y,left,right,middle,scrollx,scrolly=mouse()

  cls(13)

  if btn(UP) then cam.y = cam.y - 1 end
  if btn(DOWN) then cam.y = cam.y + 1 end
  if btn(LEFT) then cam.x = cam.x - 1 end
  if btn(RIGHT) then cam.x = cam.x + 1 end

  cleanup(Inventory.items)
  cleanup(Hand.items)
  cleanup(Craftstable.items)
  draw_room()
  draw_inventory(Inventory)
  draw_craft_table(Craftstable)
  update_buttons(BUTTONS)
  draw_hand(Hand)
end

function TICEating()
  cls(13)
  -- TODO: eat collected resources
  draw_room()
  move_cam()
  handle_eating(Inventory)
  cleanup(Inventory.items)
  draw_inventory(Inventory)
  draw_buttons(INV_BUTTONS)
  print(sf("Days: %d, Fullness: %d", DAYS, FULLNESS))
  if FULLNESS <= 0 then
    state=GAMEOVER
  end
end

function TICGameover()
  cls(1)
  print(sf("You've managed to survive for %d days", DAYS), 5, 5)
  local x,y,d=mouse()
  if d then state=GAME end
end

GAME=1
GAMEOVER=2
EATING=3

state=GAME
old_state=nil

UPDATE={
  [GAME]=TICGame,
  [GAMEOVER]=TICGameover,
  [EATING]=TICEating
}

INIT={
  [GAME]=INITGame,
  [EATING]=INITEating
}

function TIC()
  if old_state ~= state and INIT[state] ~= nil then
    INIT[state]()
    old_state = state
  end
  UPDATE[state]()
end
