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

-- buttons state
btn_st={
  [UP]=false,
  [DOWN]=false,
  [LEFT]=false,
  [RIGHT]=false,
  [Z]=false
}

-- triiger button event once on contituous button press
function btno(id)
  if btn(id) then
    if not btn_st[id] then
      btn_st[id]=true
      return true
    else
      return false
    end
  else
    btn_st[id]=false
    return false
  end
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

Inventory={}

HEALTH=100
TIME=0

function make_item( name,count )
  for i,it in ipairs(Items) do
    if it.name == name then
      new_item = deepcopy(it)
      new_item.count = count
      return new_item
    end
  end
end

function inventory_get( inv, name )
  for i,it in ipairs(inv) do
    if it.name == name then return it end
  end
  return nil
end

function inventory_add( inv, name, count )
  it = inventory_get(inv, name)
  if it ~= nil then
    it.count = it.count + count
  else
    table.insert(inv, make_item(name, count))
  end
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
    inventory_add(Inventory, res, res_count)
    trace(sf("add %s to inventory", res))
    for i,it in ipairs(items) do
      inv_it = inventory_get(inv, it.name)
      if inv_it ~= nil then
        inv_it.count = inv_it.count - min_item_count
        if inv_it.count == 0 then removeFrom(inv, inv_it) end
      end
    end
  else
    trace(sf("unable to craft from: %s", namestr))
    return false
  end
  return true
end

function eat( inv, item, count )
  it = inventory_get(inv, item.name)
  if it == nil then 
    trace(sf("no item %s in inventory!", item.name))
    return false 
  end
  eaten = math.min(count, it.count)
  HEALTH = HEALTH + it.nutr * eaten
  it.count = it.count - eaten
  if it.count == 0 then removeFrom(inv, it) end
  return true
end

function update_spoil( inv )
  for i,it in ipairs(inv) do
    if it.spoil ~= -1 then
      it.spoil = it.spoil - 1
      if it.spoil == 0 then
        trace(sf("Remove %s from inv; spoiled!", it.name))
        removeFrom(inv, it, true)
      end
    end
  end
end

function init_inv( inv )
  inventory_add(inv, Names.bw, 10)
  inventory_add(inv, Names.w, 90)
  inventory_add(inv, Names.tp, 10)
end

init_inv(Inventory)

function draw_inventory( inv )
  for i,it in ipairs(inv) do
    print(sf("%s: %d (%d days left)", it.name, it.count, it.spoil),10,i * T)
  end
end

function on_action( inv )
  update_spoil(inv)
  TIME=TIME+1
  HEALTH = HEALTH - 5
end

function TIC()
  cls(13)
  draw_inventory(Inventory)
  if btno(UP) then 
    itm1, itm2 = Inventory[1], Inventory[2]
    count = 2
    if make_recepie(Inventory, {itm1, itm2}, count) then
      on_action(Inventory)
    end
  end
  if btno(DOWN) then
    itm1 = Inventory[1]
    count = 1
    if eat(Inventory, itm1, count) then
      on_action(Inventory)
    end
  end

  cleanup(Inventory)
  print(sf("Time: %d; Health: %d", TIME, HEALTH), 10, 120)
end
