local riftedSpectrogram = {}

local riftedMusic = require "Rifted.RiftedMusic"

local audio = require "system.game.Audio"
local fileIO = require "system.game.FileIO"
local tick = require "necro.cycles.Tick"

local waveformCache = {}

local loadedFilename = riftedMusic.getLoadedFileName()

local samples = 0

function complex_exp( r, i )
	--r is always 0 for an fft, e^0 = 1
	local theta = i
	local er = {r=math.cos(theta),i=math.sin(theta)}
	
	return er
end

function complex_add( ax, ay, bx, by )
	return {r=ax+bx, i=ay+by}
end

function complex_mult( ax, ay, bx, by )
	local cx = ax * bx - ay * by
	local cy = ax * by + ay * bx
	
	return {r=cx, i=cy}
end  

function fft2( samples )
	local fft = {}
	
	if #samples == 1 then
		fft[1] = {r=samples[1], i=0}
		return fft
	end
	
	local even = {}
	local odd = {}
	
	for i = 1, #samples+1, 2 do
		even[ #even+1 ] = samples[i]
		odd[ #odd+1 ] = samples[i+1]
	end
	
	even = fft2(even)
	odd = fft2(odd)
	
	local alias_factor = math.floor( #samples / 2 )
	for i = 1, #samples do
		local alias = math.fmod( i, alias_factor ) + 1
		
		local ex = complex_exp( 0, -2 * math.pi * (i/#samples) )
		
		local o = odd[alias]
		local ex2 = complex_mult(ex.r, ex.i, o.r, o.i) 
		fft[i] = complex_add( even[alias].r, even[alias].i, ex2.r, ex2.i )
	end
	
	return fft
end

function stft( samples, window_size, hop_size )
	local frame_count = 1 + (#samples - window_size) / hop_size
	frame_count = math.floor( frame_count )
	
	local stft = {}
	
	for i = 1, frame_count do
		local start = hop_size * (i-1)
		local sub_frame = {}
		for j=start, start+window_size do
			sub_frame[ #sub_frame+1 ] = samples[j]
		end
		
		print( "starting dft" )
		local fft = fft2( sub_frame )
		print( "finished dft" )
		print( string.format("%d out of %d", i, frame_count ) )
		stft[ #stft + 1 ] = fft
	end
	
	print( "stft" )
	
	return stft
end  

loadWaveformPiece = tick.delay(function (reader)
	local waveIndex = reader.waveIndex or 0
	reader.waveBuffer = reader.waveBuffer or {}
	local waveBuffer = reader.waveBuffer
	local readSamples = reader.read(waveBuffer, reader.sampleRate * reader.channelCount, 0)
		
	if readSamples == 0 then
		local window_size = (1/50.0) * reader.sampleRate * reader.channelCount
		window_size = math.ceil( math.log(window_size) / math.log(2) )
	
		window_size = 1024--math.pow(2,window_size)
	
		--disable fft for now its too slow
		--stft( waveformCache, window_size, window_size / 2 )
		return
	end
	
	for i = 1, #waveBuffer do
		waveformCache[ #waveformCache + 1 ] = waveBuffer[i]
	end
	
	samples = samples + 1	
	reader.waveIndex = waveIndex + 1
	return false
end, { allowMultiple = true })

local readerMain = fileIO.exists(loadedFilename) and audio.getFileReader(loadedFilename)
if readerMain and readerMain.read then
	readerMain.wave = waveformCache.main
	readerMain.infix = "main"
	loadWaveformPiece(readerMain)
end
