-- title:  Grecha
-- author: BOOtak
-- desc:   Keep yourself alive crafting food from your inventory
-- script: lua

T = 8
W = 240
H = 136

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

-- texture helpers

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

Names={
  bw="Buckwheat",
  tp="Toilet Paper",
  bwp="Buckwheat porridge",
  w="Water",
  chr="Charcoal powder"
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
  size=5
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
Diningtable={
  name="Diningtable",
  items={},
  size=1
}

ALL_INVENTORIES={
  Inventory,
  Hand,
  Craftstable,
  Diningtable
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
  btn.color = 5
end

function make_button( x, y, w, h, color, on_hover, on_leave, on_press, on_release, on_enter, sp, offx, offy )
  btn = deepcopy(Button)
  btn.x, btn.y = x,y
  btn.w, btn.h = w,h
  btn.color = color
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
  if btn.item ~= nil then
    local ent = {x=btn.x, y=btn.y, sp=btn.item.sp, offx=btn.offx, offy=btn.offy}
    draw_entity(ent)
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
  local dx,dy = 5, 5
  local mx,my = mouse()
  if btn.item ~= nil and btn.item.count > 0 then
    print(sf("%s: %d", btn.item.name, btn.item.count), mx + dx, my + dy)
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

function on_inventory_click( btn )
  if btn.item ~= nil and btn.inv ~= nil then
    local inv_item = inventory_get(btn.inv, btn.item)
    if #Hand.items == 0 then
      move_item(Hand, btn.inv, inv_item, 1)
    else
      if Hand.prev_click == nil or Hand.prev_click == btn.inv then
        if not move_item(Hand, btn.inv, inv_item, 1) then
          local hand_item = Hand.items[1]
          if inventory_add_item(btn.inv, hand_item) then
            Hand.items = {}
            move_item(Hand, btn.inv, inv_item, 1)
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
    on_action(ALL_INVENTORIES)
  end
end

function on_eat_click( btn )
  if eat(Diningtable) then
    on_action(ALL_INVENTORIES)
  end
end

function update_buttons( btns )
  local mx,my,md = mouse()
  for i,v in ipairs(btns) do
    draw_button(v)
  end
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

function draw_dining_table( inv )
  for i,btn in ipairs(DINING_BUTTONS) do
    btn.item=nil
    btn.inv=inv
  end
  for i,it in ipairs(inv.items) do
    DINING_BUTTONS[i].item=it
  end
end

function draw_hand( inv )
  local mx,my = mouse()
  local dx,dy = 5, 10
  if #inv.items == 1 and inv.items[1].count > 0 then
    local item = inv.items[1]
    local txt = sf("%s %d", item.name, item.count)
    local width = print(txt, W, H)
    if mx + dx + width > W then
      print(txt, W - width, my+dy)
    else
      print(txt, mx + dx, my+dy)
    end
  end
end

function on_action( invs )
  for i,inv in ipairs(invs) do
    update_spoil(inv)
  end
  TIME=TIME+1
  HEALTH = HEALTH - 5
end

function init_inv( inv )
  inventory_add(inv, Names.bw, 10)
  inventory_add(inv, Names.w, 90)
  inventory_add(inv, Names.tp, 10)
end

BUTTONS={}
INV_BUTTONS={}
CRAFT_BUTTONS={}
DINING_BUTTONS={}

function init_buttons()
  local startx,starty = 0, 0
  local w,h = 20, 20
  local c = 5
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

  startx,starty = 141, 84
  local btn = make_button(startx, starty, w, h, c, on_inventory_hover, g_leave, g_press, on_inventory_click, nil, nil, 2, 2)  
  table.insert(BUTTONS, btn)
  table.insert(DINING_BUTTONS, btn)

  local do_craft = make_button(141, 42, 41, 20, c, g_hover, g_leave, g_press, on_craft_click, nil)
  table.insert(BUTTONS, do_craft)

  local do_eat = make_button(141, 106, 40, 20, c, g_hover, g_leave, g_press, on_eat_click, nil)
  table.insert(BUTTONS, do_eat)
end

init_inv(Inventory)
init_buttons()

function TICGame()
  if HEALTH <= 0 then
    state = GAMEOVER
  end

  local x,y,left,right,middle,scrollx,scrolly=mouse()

  cls(13)

  cleanup(Inventory.items)
  cleanup(Hand.items)
  cleanup(Craftstable.items)
  cleanup(Diningtable.items)
  print(sf("Time: %d; Health: %d", TIME, HEALTH), 10, 120)
  print(sf("(%d %d)", x, y), 5, 5)
  draw_inventory(Inventory)
  draw_craft_table(Craftstable)
  draw_dining_table(Diningtable)
  update_buttons(BUTTONS)
  draw_hand(Hand)
end

function TICGameover()
  cls(1)
  print("GAME OVER!")
end

GAME=1
GAMEOVER=2

state=GAME

UPDATE={
  [GAME]=TICGame,
  [GAMEOVER]=TICGameover
}

function TIC()
  UPDATE[state]()
end
