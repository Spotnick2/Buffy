local H = dofile("tests/harness.lua")

local B = H.load("PRIEST")
local function shop(itemID, price, stock, pack)
    WoW.merchantItems = { { itemID = itemID, price = price, numAvailable = stock or -1,
        stackCount = pack or 1, isPurchasable = true } }
end

shop(17028, 100, -1, 1)
WoW.money = 100000
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "restock disabled by default")
H.eq(B.Get("candleTarget"), 80, "default target")
B.SetConfig("autoBuyCandles", true)
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "unlearned Prayer buys nothing")

WoW.Know(21562, "Prayer of Fortitude", "Rank 1")
WoW.itemCounts[17028] = 20
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 1, "known Fortitude buys Holy Candles")
H.eq(WoW.purchases[1].quantity, 60, "buys only to target")
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 1, "pending purchase is not repeated")
local messageCount = #WoW.messages
WoW.dispatch("BAG_UPDATE_DELAYED")
H.eq(#WoW.messages, messageCount, "attempt does not report a purchase")
WoW.itemCounts[17028] = 80
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 1, "repeated open after restock does not buy")

WoW.purchases = {}
WoW.itemCounts[17028] = 80
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "already stocked")

WoW.itemCounts[17028] = 20
WoW.money = 550
WoW.dispatch("MERCHANT_SHOW")
H.eq(WoW.purchases[1].quantity, 5, "limited by money")
WoW.dispatch("BAG_UPDATE_DELAYED")
WoW.purchases = {}
WoW.money = 100000
shop(17028, 100, 7, 1)
WoW.dispatch("MERCHANT_SHOW")
H.eq(WoW.purchases[1].quantity, 7, "limited by merchant stock")
WoW.dispatch("BAG_UPDATE_DELAYED")
WoW.purchases = {}
WoW.bagFree[0] = 0
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "full bags skip purchase")
WoW.bagFree[0] = 16

WoW.Know(27683, "Prayer of Shadow Protection", "Rank 1")
H.eq(#B.class.candleItems(), 2, "Shadow Prayer needs Sacred alongside Holy")
shop(17029, 100, -1, 1)
WoW.dispatch("MERCHANT_SHOW")
H.eq(WoW.purchases[1].quantity, 80, "Shadow Prayer buys Sacred Candles")
WoW.itemCounts[17029] = 80
WoW.dispatch("BAG_UPDATE_DELAYED")
H.check(WoW.messages[#WoW.messages]:find("Bought 80 Sacred Candles", 1, true), "reports actual gain")
H.eq(#B.class.footerItems(), 2, "footer shows both candle types")
WoW.purchases = {}
WoW.merchantItems[1].hasExtendedCost = true
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "extended cost skipped")

WoW.purchases = {}
WoW.itemCounts[17028] = 72
shop(17028, 200, 15, 5)
WoW.dispatch("MERCHANT_SHOW")
H.eq(WoW.purchases[1].quantity, 5, "batch purchase stays below target")
WoW.flushTimers(3)
H.eq(#WoW.messages, messageCount + 1, "unconfirmed batch is not reported")
WoW.purchases = {}
shop(17056, 100, -1, 1)
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "wrong vendor is ignored")

B = H.load("PRIEST")
B.SetConfig("autoBuyCandles", true)
WoW.Know(21562, "Prayer of Fortitude", "Rank 2")
H.eq(B.class.candleItems()[1], 17029, "Fortitude rank 2 needs Sacred Candle")
shop(17028, 100, -1, 1)
WoW.money = 100000
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "rank 2 does not buy Holy Candles")
shop(17029, 100, 0, 1)
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "sold-out merchant is ignored")
shop(17029, 100, -1, 1)
WoW.money = 0
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "no money makes no purchase")

B = H.load("PRIEST")
B.SetConfig("autoBuyCandles", true)
WoW.Know(27681, "Prayer of Spirit", "Rank 1")
H.eq(B.class.candleItems()[1], 17029, "Spirit alone needs Sacred Candle")

B = H.load("PRIEST")
B.SetConfig("autoBuyCandles", true)
WoW.Know(21562, "Prayer of Fortitude", "Rank 1")
WoW.Know(27683, "Prayer of Shadow Protection", "Rank 1")
WoW.merchantItems = {
    { itemID = 17028, price = 100, numAvailable = -1, stackCount = 1, isPurchasable = true },
    { itemID = 17029, price = 100, numAvailable = -1, stackCount = 1, isPurchasable = true },
}
WoW.money = 1000
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 1, "shared money budget prevents overspending on second candle")
H.eq(WoW.purchases[1].quantity, 10, "first candle uses affordable amount")

B = H.load("DRUID")
shop(17028, 100, -1, 1)
WoW.money = 100000
WoW.dispatch("MERCHANT_SHOW")
H.eq(#WoW.purchases, 0, "other classes do not buy candles")
H.done("merchant")
