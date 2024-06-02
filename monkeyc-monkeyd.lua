--      _
-- w  c(..)o     (
--  \__(-)    __)
--      /\   (
--     /(_)___)    monkey c
--    w  /|        monkey d
--       |  \
--       m  m
--
-- MIDI delay, but it's a monkey

-- xmacex

DEBUG = false

its_bananas = false
bnote       = 60

function log(msg)
   if DEBUG then print(msg) end
end

function init()
   params:add_number('midi_dev', 'midi device', 1, 16, 1)
   -- params:add_number('bananas', 'bananas', 1, 22, 5)
   -- params:add_control('bananas', 'bananas', controlspec.MIDINOTE, fmt_bananas)
   params:add_control('bananas', 'how bananas',
		      controlspec.new(0, 35, 'lin', 1, 5),
		      fmt_bananas)
   params:add_control('ripeness', 'how ripe', controlspec.AMP, fmt_ripeness)
   params:set('ripeness', 0.5)
   params:add_number('curvature', 'how curved', 1, 16, 1)
   params:add_option('length', 'how long', {'0.25', '0.5', '0.75', '1', '1.25', '1.5', '1.75', '2'}, 4)

   m = midi.connect(params:get('midi_dev'))
   m.event = midi_monkey
end

function fmt_bananas(p)
   if     p.raw < 0.1 then return "curious"
   elseif p.raw < 0.4 then return "excited"
   elseif p.raw < 0.6 then return "wild"
   elseif p.raw < 0.9 then return "out of control"
   else return "total kaos" end
end

function fmt_ripeness(p)
   if     p.raw < 1/6  then return "green"
   elseif p.raw < 2/3  then return "yellow"
   elseif p.raw < 9/10 then return "dotty"
   else return "brown" end
end

function gate_close(note, ch)
   log("schedule "..note.."@"..ch)
   its_bananas = true
   bnote = note
   redraw()
   clock.sleep(params:get('length')/16)
   log("close "..note.."@"..ch)
   its_bananas = false
   redraw()
   m:note_off(note, 0, ch)
end

function monkey(msg)
   log("/)")
   log("note "..msg.note.."@"..msg.ch)
   clock.sync(1/4 * params:get('curvature'))
   monkey_note = msg.note + math.random(params:get('bananas'))
   monkey_ch   = msg.ch + util.round(math.random() * (params:get('bananas')/params:get_range('bananas')[2]))
   m:note_on(monkey_note, util.round(msg.vel*params:get('ripeness')), monkey_ch)
   clock.run(gate_close, monkey_note, monkey_ch)
end

function midi_monkey(data)
   local msg = midi.to_msg(data)
   if msg.type ~= 'clock' then
      if msg.type == 'note_on' then
	 clock.run(monkey, msg)
      end
   end
end

function redraw()
   screen:clear()
   if its_bananas then draw_banana() end
   screen:update()
end

function draw_banana()
   screen.move(math.floor(bnote), 32)
   screen.text("/)")
end
