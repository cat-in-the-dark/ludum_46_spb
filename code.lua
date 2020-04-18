-- title:  Grecha
-- author: BOOtak
-- desc:   Keep yourself alive crafting food from your inventory
-- script: lua

T = 8

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
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

function removeFrom(tab,obj,toDel)
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

Names={
  bw="Buckwheat",
  tp="Toilet Paper",
  bwp="Buckwheat porridge",
  w="Water"
}

Items={
  {
    name=Names.tp,
    nutr=0,
    spoil=-1
  },
  {
    name=Names.bw,
    nutr=10,
    spoil=-1
  },
  {
    name=Names.bwp,
    nutr=20,
    spoil=3
  },
  {
    name=Names.w,
    nutr=1,
    spoil=-1
  },
  {
    name=Names.chr,
    nutr=0,
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
  on_hover=nil,
  on_press=nil,
  on_release=nil,
  on_leave=nil
}

Inventory={
  items={},
  size=15
}
Hand={
  items={},
  size=1
}
Craftstable={
  items={},
  size=2
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

function make_button( x, y, w, h, color, on_hover, on_leave, on_press, on_release )
  btn = deepcopy(Button)
  btn.x, btn.y = x,y
  btn.w, btn.h = w,h
  btn.color = color
  btn.on_hover = on_hover
  btn.on_leave = on_leave
  btn.on_press = on_press
  btn.on_release = on_release
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

  if old_hover and not btn.hover then
    safe1(btn.on_hover, btn)
  elseif not old_hover and btn.hover then
    safe1(btn.on_leave, btn)
  end
  if old_pressed and not btn.pressed then
    safe1(btn.on_press, btn)
  elseif btn.pressed and not old_pressed then
    safe1(btn.on_release, btn)
  end
end

function draw_button( btn )
  rect(btn.x, btn.y, btn.w, btn.h, btn.color)
  print(sf("%d %d %d %d %d", btn.x, btn.y, btn.w, btn.h, btn.color), 20, 60)
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

function inventory_get_by_name( inv, name )
  res = {}
  for i,it in ipairs(inv.items) do
    if it.name == name then table.insert(res, it) end
  end
  return res
end

function inventory_add( inv, name, count )
  local new_item = make_item(name, count)
  local same_items = inventory_get_by_name(inv, name)
  for i,same in ipairs(same_items) do
    if same.spoil == new_item.spoil then
      same.count = same.count + count
      return true
    end
  end
  if inv.size > #inv then
    table.insert(inv.items, new_item)
    return true
  end
  return false
end

function check_recepie( names )
  for i,recepie in ipairs(Recepies) do
    if table.matches(recepie.items, names) then return recepie.res end
  end
  return nil
end

function make_recepie( inv, items, count )
  names = {}
  namestr = ""
  min_item_count = count
  for i,it in ipairs(items) do
    table.insert(names, it.name)
    namestr = sf("%s%s; ", namestr, it.name)
    if min_item_count > it.count then min_item_count = it.count end
  end

  if min_item_count == 0 then
    trace("unable to make 0 items")
    return false
  end

  res = check_recepie(names)
  if res ~= nil then
    res_count = min_item_count * #items
    inventory_add(inv, res, res_count)
    trace(sf("add %s to inventory", res))
    for i,it in ipairs(items) do
      inv_it = inventory_get(inv, it)
      if inv_it ~= nil then
        inv_it.count = inv_it.count - min_item_count
        if inv_it.count == 0 then removeFrom(inv.items, inv_it) end
      end
    end
  else
    trace(sf("unable to craft from: %s", namestr))
    return false
  end
  return true
end

function eat( inv, item, count )
  it = inventory_get(inv, item)
  if it == nil then
    trace(sf("no item %s in inventory!", item.name))
    return false
  end
  eaten = math.min(count, it.count)
  HEALTH = HEALTH + it.nutr * eaten
  it.count = it.count - eaten
  if it.count == 0 then removeFrom(inv.items, it) end
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

function update_buttons( btns )
  local mx,my,md = mouse()
  for i,v in ipairs(btns) do
    check_button(v, mx, my, md)
    draw_button(v)
  end
end

function draw_inventory( inv )
  for i,it in ipairs(inv.items) do
    print(sf("%s: %d (%d days left)", it.name, it.count, it.spoil),10,i * T)
  end
end

function on_action( inv )
  update_spoil(inv)
  TIME=TIME+1
  HEALTH = HEALTH - 5
end

function init_inv( inv )
  inventory_add(inv, Names.bw, 10)
  inventory_add(inv, Names.w, 90)
  inventory_add(inv, Names.tp, 10)
end

BUTTONS={}

function init_buttons()
  btn = make_button(50, 50, 20, 20, 5, g_hover, g_leave, g_press, g_release)
  table.insert(BUTTONS, btn)
end

init_inv(Inventory)
init_buttons()

function TICGame()
  if HEALTH <= 0 then
    state = GAMEOVER
  end

  local x,y,left,right,middle,scrollx,scrolly=mouse()

  cls(13)

  draw_inventory(Inventory)
  if btnp(UP) then
    itm1, itm2 = Inventory.items[1], Inventory.items[2]
    count = 2
    if make_recepie(Inventory, {itm1, itm2}, count) then
      on_action(Inventory)
    end
  end
  if btnp(DOWN) then
    itm1 = Inventory.items[1]
    count = 1
    if eat(Inventory, itm1, count) then
      on_action(Inventory)
    end
  end

  cleanup(Inventory.items)
  print(sf("Time: %d; Health: %d", TIME, HEALTH), 10, 120)
  print(sf("(%d %d)", x, y), 10, 50)
  update_buttons(BUTTONS)
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
