local H = dofile("tests/harness.lua")

local function shop(itemID, price, stock)
    WoW.merchantItems = { { itemID = itemID, price = price or 100,
        numAvailable = stock == nil and -1 or stock, stackCount = 1, isPurchasable = true } }
end

local B = H.load("DRUID")
shop(17021)
WoW.money = 100000
WoW.Know(21849, "Gift of the Wild", "Rank 1")
WoW.dispatch("SPELLS_CHANGED")
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "Druid restock disabled by default")
H.eq(B.Get("giftTarget"), 80, "Druid default target")
B.optionsPanel:GetScript("OnShow")(B.optionsPanel)
H.check(B.optionsPanel.controls.autoBuyGift and B.optionsPanel.controls.giftTarget,
    "Druid restock options present")
B.SetConfig("autoBuyGift", true)
B.SetConfig("trackMark", false)
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "disabled Mark prevents Gift restock")
B.SetConfig("trackMark", true)
WoW.itemCounts[17021] = 30
WoW.dispatch("MERCHANT_SHOW")
H.eq(WoW.purchases[1].quantity, 50, "Gift rank 1 buys Wild Berries to target")
WoW.itemCounts[17021] = 80
WoW.dispatch("BAG_UPDATE_DELAYED")
H.check(WoW.messages[#WoW.messages]:find("Bought 50 Wild Berries", 1, true),
    "Druid reports actual Berry gain")
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 1, "Druid repeat visit at target buys nothing")

B = H.load("DRUID")
B.SetConfig("autoBuyGift", true)
shop(17021)
WoW.money = 100000
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "unlearned Gift buys nothing")
WoW.Know(21849, "Gift of the Wild", "Unknown rank")
WoW.dispatch("SPELLS_CHANGED")
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "unreadable Gift rank buys nothing")

B = H.load("DRUID")
B.SetConfig("autoBuyGift", true)
WoW.Know(21849, "Gift of the Wild", "Rank 2")
WoW.dispatch("SPELLS_CHANGED")
shop(17021)
WoW.money = 100000
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "Gift rank 2 does not buy Berries")
shop(17026, 100, 7)
WoW.dispatch("MERCHANT_SHOW")
H.eq(WoW.purchases[1].quantity, 7, "Gift rank 2 buys Thornroot within stock")

B = H.load("MAGE")
shop(17020)
WoW.money = 100000
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "Mage restock disabled by default")
H.eq(B.Get("powderTarget"), 80, "Mage default target")
B.optionsPanel:GetScript("OnShow")(B.optionsPanel)
H.check(B.optionsPanel.controls.autoBuyPowder and B.optionsPanel.controls.powderTarget,
    "Mage restock options present")
B.SetConfig("autoBuyPowder", true)
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "Arcane Intellect alone buys no Powder")
WoW.Know(23028, "Arcane Brilliance", "Rank 1")
WoW.dispatch("SPELLS_CHANGED")
B.SetConfig("trackIntellect", false)
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "disabled Intellect prevents Powder restock")
B.SetConfig("trackIntellect", true)
WoW.itemCounts[17020] = 60
WoW.dispatch("MERCHANT_SHOW")
H.eq(WoW.purchases[1].quantity, 20, "Brilliance buys Powder to target")
WoW.itemCounts[17020] = 80
WoW.dispatch("BAG_UPDATE_DELAYED")
H.check(WoW.messages[#WoW.messages]:find("Bought 20 Arcane Powder", 1, true),
    "Mage reports actual Powder gain")
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 1, "Mage repeat visit at target buys nothing")

B = H.load("MAGE")
B.SetConfig("autoBuyPowder", true)
WoW.Know(23028, "Arcane Brilliance", "Rank 1")
WoW.dispatch("SPELLS_CHANGED")
shop(17020, 100, 0)
WoW.money = 100000
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "sold-out Powder is ignored")
shop(17056)
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "Mage ignores unrelated vendor items")

H.done("merchant classes")
