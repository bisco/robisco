# Description:
#   Simple kakeibo utility
#
# Commands:
#   家計簿 入 <amount of money: Number>円 <memo> - log income
#   家計簿 出 <amount of money: Number>円 <memo> - log payment
#   家計簿 今日の収支 - today's balance of payments
#   家計簿 今週の収支 - this week's balance of payments
#   家計簿 今月の収支 - this month's balance of payments

mongoose = require "mongoose"
kakeibo_schema = new mongoose.Schema(
  kind: {type: Boolean, require: true, default: false},
  amount: {type: Number, require: true, min: 0},
  spend_date: {type: Date, require: true, default: Date.now},
  memo: {type: String}
  ts: {type: Date, default: Date.now},
)

url = "mongodb://localhost/kakeibo"
db = mongoose.createConnection url, (err, res) ->
  if err
    console.log "Error connected: " + url + " - " + err
  else
    console.log "Success connected: " + url
kakeibo_model = db.model "Kakeibo", kakeibo_schema

## usage of kakeibo
Usage = (res) ->
  usg += "記録したいとき: 家計簿 (入|出) ([1-9][0-9]+)円 (何かメモ)\n"
  usg += "今日の収支を知りたい：家計簿 今日の収支\n"
  usg += "今月の収支を知りたい：家計簿 今月の収支\n"
  res.reply usg

## make today query
gmt_plus9 = () ->
  1000 * 60 * 60 * 9

get_24hour = () ->
  1000 * 60 * 60 * 24

make_today_query = () ->
  start = new Date
  start.setTime(start.getTime() - gmt_plus9())
  start.setHours 0
  start.setMinutes 0
  start.setSeconds 0
  end = new Date
  end.setTime(start.getTime())
  end.setHours 23
  end.setMinutes 59
  end.setSeconds 59
  {spend_date: {$gte: start, $lte: end}}


## this query starts Monday
make_thisweek_query = () ->
  start = new Date
  start.setTime(start.getTime() - gmt_plus9())
  if start.getDay() == 0 # 今日は日曜日
    start.setDate(start.getDate() - 6)
  else
    start.setDate(start.getDate() - start.getDay() + 1)
  start.setHours 0
  start.setMinutes 0
  start.setSeconds 0
  end = new Date
  end.setTime(start.getTime())
  end.setDate(end.getDate() + 6)
  end.setHours 23
  end.setMinutes 59
  end.setSeconds 59
  {spend_date: {$gte: start, $lt: end}}


make_thismonth_query = () ->
  start = new Date
  start.setTime(start.getTime() - gmt_plus9())
  start.setDate 1
  start.setHours 0
  start.setMinutes 0
  start.setSeconds 0
  end = new Date
  end.setTime(start.getTime())
  end.setMonth start.getDate() + 1
  {spend_date: {$gte: start, $lt: end}}


## 一定期間の収支を取得する
get_bop_generic = (err, docs, header, res) ->
  if err
    console.log(err)
    res.reply "データベースに何かエラーがあるみたい"
    res.reply err
  else
    sum = 0
    for value, idx in docs
      if value.kind
        sum = sum + value.amount
      else
        sum = sum - value.amount
  
    if sum > 0
      res.reply header+"は"+sum+"円のプラス"
    else if sum < 0
      res.reply header+"は"+(-1*sum)+"円使ったね"
    else
      res.reply header+"の収支は0だよ"

## main
module.exports = (robot) ->
  robot.respond /家計簿(( |　))((入|出))(( |　))([1-9][0-9]+)円(( |　))(.*)/i, (res) ->
    kak = new kakeibo_model
    type = res.match[3]
    amount = res.match[7]
    memo = if res.match.length >= 11 then res.match[10] else ""
    if type == "入"
      kak.kind = true
    else if type == "出"
      kak.kind = false
    else
      Usage res
      return

    kak.amount = parseInt amount
    if kak.amount == undefined
      Usage res
      return
    kak.memo = memo

    kak.save (err) ->
      if err
        console.log err
        Usage res
        return
      else
        console.log "Success: add data to db"

    if kak.kind
      res.reply kak.amount + " 円受け取りましたね"
    else
      res.reply kak.amount + " 円使いましたね"

  robot.respond /家計簿(( |　))((今日|今週|今月))の収支/i, (res) ->
    if res.match[3] == "今月"
      kakeibo_model.find make_thismonth_query(), (err,docs) ->
        get_bop_generic(err,docs,"今月",res)
    else if res.match[3] == "今週"
      kakeibo_model.find make_thisweek_query(), (err, docs) ->
        get_bop_generic(err,docs,"今週",res)
    else # 今日の収支
      kakeibo_model.find make_today_query(), (err,docs) ->
        get_bop_generic(err,docs,"今日",res)

  robot.respond /家計簿(( |　))help/i, (res) ->
    Usage res
