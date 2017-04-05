cfg={}
cfg.ssid="ESP_STATION"
cfg.pwd="12345678"
wifi.ap.config(cfg)
wifi.setmode(wifi.SOFTAP)

strip_offset = 10

red = 0
green = 0
blue = 0
red2 = 0
green2 = 0
blue2 = 0
density = 0
quantity = 1
brightness = 0
speed = 1
new_speed = 1

mybool = true

ws2812.init();

buffer = ws2812.newBuffer(300, 3); 
buffer:fill(0, 0, 0);
new_buffer = ws2812.newBuffer(300, 3); 
new_buffer:fill(0, 0, 0);
local max = math.max; 
local min = math.min;
local floor = math.floor;

tmr.register(0, 30, tmr.ALARM_AUTO, function()

    buffer:shift(1, ws2812.SHIFT_CIRCULAR)
    ws2812.write(buffer)
   
end)

function update ()

    --  Prepare a new buffer
    new_buffer:fill(0, 0, 0)

    offsets = {300,150,100,60,
               50,30,20,10,6}

    step = offsets[quantity]
    centre = offsets[quantity]/2
    sections = 300/offsets[quantity]

    -- At full density, we want to colorise 
    -- 'centre' amount of pixels
    active_pixels = density*centre/128

    -- Diminish pixels using brightness parameter
    alpha = brightness/8

    -- At centre point, we want to be displaying
    -- the primary RGB colour
    if active_pixels ~= 0 then
        
        g_slope = (green - green2)/active_pixels
        r_slope = (red - red2)/active_pixels
        b_slope = (blue - blue2)/active_pixels

    -- Do for each section
    for j = 1,sections do

        -- Get the centre pixel
        centre_pixel = (j-1)*step + centre

        -- Colorise about the centre
        for k = 0,active_pixels do

            new_buffer:set(centre_pixel + k,
            green2 + k*g_slope, 
            red2 + k*r_slope, 
            blue2 + k*b_slope)
            
            new_buffer:set(centre_pixel - k + 1, 
            green2 + k*g_slope, 
            red2 + k*r_slope, 
            blue2 + k*b_slope)

        end

        -- Smooth transitions
        for k = 0,centre do

            last_g, last_r, last_b = new_buffer:get(centre_pixel + k - 2)
            current_g, current_r, current_b = new_buffer:get(centre_pixel + k - 1)
            last_g = (current_g + last_g)/2
            last_r = (current_r + last_r)/2
            last_b = (current_b + last_b)/2
            new_buffer:set(centre_pixel + k - 1, last_g, last_r, last_b)

            last_g, last_r, last_b = new_buffer:get(centre_pixel - k + 2)
            current_g, current_r, current_b = new_buffer:get(centre_pixel - k + 1)
            last_g = (current_g + last_g)/2
            last_r = (current_r + last_r)/2
            last_b = (current_b + last_b)/2
            new_buffer:set(centre_pixel - k + 1, last_g, last_r, last_b)

        end

    end

    -- Do for each pixel
    for j = 1,300 do

        g, r, b = new_buffer:get(j)
        new_buffer:set(j, g*alpha, r*alpha, b*alpha)

    end

    end

    -- Compensate for strip offset
    new_buffer:shift(strip_offset, ws2812.SHIFT_CIRCULAR)
             
    --print("update")
    --for j = 1,300 do
    --    print(new_buffer:get(j))
    --end

    -- Speed update
    if new_speed ~= speed then

        speed = new_speed

        -- stop the timer and write the pixels once
        if new_speed == 0 then

            tmr.stop(0)
            ws2812.write(new_buffer)

        -- change the timer and restart if necessary
        else

            tmr.interval(0, 160 - speed)
            tmr.start(0)
            
        end
            
    end

    buffer = new_buffer

end

print("Hola")

-- Initialise
update()
tmr.start(0)

srv=net.createServer(net.UDP)

srv:listen(8888)
srv:on("receive", function(srv, msg)

    red = string.byte(msg, 1)
    green = string.byte(msg, 2)
    blue = string.byte(msg, 3)
    red2 = string.byte(msg, 4)
    green2 = string.byte(msg, 5)
    blue2 = string.byte(msg, 6)
    density = string.byte(msg, 7)
    quantity = floor(string.byte(msg, 8)/16) + 1
    brightness = string.byte(msg, 9)
    new_speed = string.byte(msg, 10)

    update()

end)

