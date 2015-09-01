--- Get Weather from openweathemap.org.
local json = require "cjson"
local Location = "Lisbon"
local Metrics  = "metric"

local busid = 0  -- I2C Bus ID. Always zero
local sda= 4     -- GPIO2 pin mapping is 4
local scl= 3     -- GPIO0 pin mapping is 3

local MaxTemp = 0
local MinTemp = 0
local CurTemp = 0
local Humidity = 0
local WindSpeed = 0
local Wdesc = "No data yet!..."
local WSCalls = 0

i2c.setup(busid,sda,scl,i2c.SLOW)

function getWeather()
  conn=net.createConnection(net.TCP, 0)
  conn:on("receive", function(conn, payload) 
      record = json.decode(payload)
      --print("-> " .. record.list[1].weather[1].main )
      MaxTemp = record.list[1].main.temp_max
      MinTemp = record.list[1].main.temp_min
      CurTemp = record.list[1].main.temp
      Humidity= record.list[1].main.humidity
      Wdesc = record.list[1].weather[1].main .." , "..record.list[1].weather[1].description
      WindSpeed = record.list[1].wind.speed
      --print("Data received!")
      --print(payload)
    end )
  conn:connect(80,"188.226.175.223")
  conn:send("GET /data/2.5/find?q="..Location.."&units="..Metrics.."\r\nHTTP/1.1\r\nHost: api.openweathermap.org\r\n"
        .."Connection: keep-alive\r\nAccept: */*\r\n\r\n")
  WSCalls = WSCalls + 1  
  if Humidity == 0 then
    tmr.alarm(5,10000, 0 , getWeather)
  else
    tmr.alarm(5,600000, 0 , getWeather)
  end
end


getWeather()   -- Get the weather now.
tmr.alarm(5,10000, 0 , getWeather) -- Obter o tempo de 10 em 10m
lcd = dofile("lcd1602.lua")()
lcd.light(0)
lcd.locate(1,0)

function notice() 
--  print(node.heap()); 
  lcd.run(1, "Heap: "..node.heap().."  WSCalls: "..WSCalls.."  ", 250, 1, notice) 
end

function noticeWeather()
  lcd.run(0, "TCurr: "..CurTemp.."C Max: "..MaxTemp.."C Min: "..MinTemp.."C Desc: "..Wdesc.." Humidity: "..Humidity.."% Wind: "..WindSpeed.."m/s   " ,550, 2, noticeWeather )
end

notice()
noticeWeather()

