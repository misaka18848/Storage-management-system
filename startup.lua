local basalt = require("basalt")
local main = basalt.getMainFrame()
:initializeState("search", "", false)
:initializeState("how", "", false)
--管理用的箱子的外设名
local mainchestname = "back"
--存取用的箱子的外设名
local guestchestname = "right"
local activetab = ":"
local mainchest = peripheral.wrap(mainchestname)
local guestchest = peripheral.wrap(guestchestname)
local mainchestlist = {}
local searchlist = {}
local searchshowlist = {}
local tablist = {}
local colorlist = {colors.orange,colors.magenta,colors.lightBlue,colors.yellow,colors.lime,colors.pink,colors.gray,colors.lightGray,colors.cyan,colors.purple,colors.blue,colors.brown,colors.green,colors.red,colors.black}
--local debuglabel = main:addLabel():setPosition(12,3):setText("debug")
local mainx,mainy = term.getSize()
local taby = 1
local function list2show(olist)
    local result = {}
    for i, entry in ipairs(olist) do
        local displayname = string.match(entry.name, ":([^:]*)$") or entry.name
        table.insert(result, {
            name = entry.name,
            count = entry.count,
            displayname = displayname
        })
    end
    return result
end
function mergeItemsByName(items)
    local temp = {} -- 临时表，用于按 name 聚合
    local result = {} -- 最终结果表

    for _, item in pairs(items) do
        if item and item.name then
            if temp[item.name] then
                temp[item.name].count = temp[item.name].count + (item.count or 0)
            else
                temp[item.name] = {
                    name = item.name,
                    displayname = item.displayname,
                    count = item.count or 0
                }
                table.insert(result, temp[item.name])
            end
        end
    end

    return result
end
local tabframe = main:addFrame():setPosition(2, 3):setSize(mainx - 2,1):setBackground(colors.white)
local function tab()
    tablist = {}
    local seen = {}
    local tablang = 5
    for _, item in pairs(mainchest.list()) do
        if item then
        local prefix = item.name:match("([^:]+):")
        if prefix and not seen[prefix] then
            table.insert(tablist, prefix)
            seen[prefix] = true
        end
        end
    end
    taby = 1
    tabframe:clear()
    tabframe:setPosition(2, 3):setSize(mainx - 2,taby):setBackground(colors.white)
    tabframe:addButton():setPosition(1,1):setSize(3,1):setText("all"):onClick(function() activetab = ":" searchstart() end)
    --debuglabel:setText(table.concat(tablist)):updateRender()
    for i, v in ipairs(tablist) do
        local tabline = v

        tabframe:addButton():setBackground(colorlist[math.random(1,#colorlist)]):setForeground(colors.white):setPosition(tablang,taby):setSize(#tabline,1):setText(tabline):onClick(function() activetab = tabline searchstart() end)
        tablang = tablang + #tabline + 1
        if tablang + #tabline + 1 >= mainx - 2 then
            taby = taby + 1
            tablang = 1
            tabframe:setSize(mainx - 2,taby):updateRender()
        end
    end
    tabframe:updateRender()
end
function filterByName(list, target)
    if target == "" or target == " " then
        target = ":"
    end
    local result = {}
    local lowerTarget = string.lower(target or "")
    for i, item in pairs(list) do
        if item and item.name then -- 确保不是 nil 且有 name 字段
            local itemNameLower = string.lower(item.name)
            if not target or itemNameLower:find(lowerTarget, 1, true) then
                table.insert(result, item)
            end
        end
    end
    return result
end
search = main:addInput():setPosition(2, 2):setPlaceholder("type to search"):setWidth("{self.text:len() + 1 < 15 and 15 or self.text:len() + 1 > 51 - 3 and 51 - 2 or self.text:len() + 1}"):bind("text","search"):onChange("text",function () searchstart() end)
howmany = main:addInput():setPosition(2, mainy):setPlaceholder("how"):setPattern("^%d*$"):setWidth("{self.text:len() + 1 < 4 and 4 or self.text:len() + 1 > 51 - 16 and 51 - 16 or self.text:len() + 1}"):bind("text","how")
loading = main:addLabel():setPosition(27,1):setText("Loading"):setVisible(false)
local function itemout(targetitem,itemcount,itemneedcount)
    loading:setVisible(true):updateRender()
    if itemneedcount == "" or tonumber(itemneedcount) > itemcount then
        itemneedcount = itemcount
    else
        itemneedcount = tonumber(itemneedcount)
    end
    for i = 1, mainchest.size(), 1 do
        if mainchest.getItemDetail(i) ~= nil then
            if mainchest.getItemDetail(i).name == targetitem then
                if mainchest.getItemDetail(i).count < itemneedcount then
                    itemneedcount = itemneedcount - mainchest.getItemDetail(i).count
                    mainchest.pushItems(guestchestname,i)
                else
                    mainchest.pushItems(guestchestname,i,itemneedcount)
                    tab()
                    searchstart()
                    break
                end
            end
        end
    end
    loading:setVisible(false):updateRender()
end
local searchframeback = main:addFrame():setPosition(2, 3 + taby):setSize(mainx - 3,mainy - 3 - taby):setBackground(colors.white)
local searchframe = searchframeback:addFrame():setPosition(1, 1):setWidth("{parent.width - 1}"):setBackground(colors.white)
searchbar = searchframeback:addSlider():setPosition("{parent.width}",1):setHeight("{parent.height}"):setHorizontal(false):setVisible(false):onChange("step",function(self,value) searchframe:setPosition(1,2 - math.floor((searchframe.height - mainy +4)/(mainy -4) *value)):updateRender() end)
function searchstart()
    loading:setVisible(true):updateRender()
    searchframeback:setPosition(2, 3 + taby):setSize(mainx - 3,mainy - 3 - taby):updateRender()
    mainchestlist = mainchest.list()
    searchshowlist=mergeItemsByName(list2show(filterByName(filterByName(mainchestlist,activetab),main:getState("search"))))
    searchframe:clear()
    searchframe:setPosition(1, 1):setSize("{parent.width - 1}",#searchshowlist):setBackground(colors.white)
    for i, v in ipairs(searchshowlist) do
        local itemline = v
        searchframe:addLabel():setText(itemline.displayname .. " x " .. itemline.count):setPosition(1, i):setBackground(colors.white)
        searchframe:addButton():setText("get"):setPosition((itemline.displayname .. " x " .. itemline.count):len()+1, i):setSize(3,1):onClick( function() itemout(itemline.name,itemline.count,main:getState("how")) end)
    end
    if searchframe.height > searchframeback.height then
        searchbar:setStep(1):setVisible(true):setMax(#searchshowlist-mainy+3):updateRender()
    else
        searchbar:setStep(1):setVisible(false):updateRender()
    end
    searchframe:updateRender()
    loading:setVisible(false):updateRender()
end
local function itemputin()
    for i = 1, guestchest.size(), 1 do
        guestchest.pushItems(mainchestname,i)
    end
    tab()
    searchstart()
end
main:addButton():setPosition(mainx - 3, 1):setSize(3,1):setText("put"):onClick( function() itemputin() end)
main:addLabel():setPosition(1,1):setHeight(1):setText("Storage management system")
main:addLabel():setPosition(mainx - 14,mainy):setHeight(1):setText("by misaka18848")
tab()
searchstart()
basalt.run()