#!/usr/bin/ruby -w

require 'GD'

$x = 44 
$y = 16 

['blue','green','red'].each_with_index do |color,j|

	img = GD::Image.new($x ,$y )

	$white = img.colorAllocate(255,255,255)
	$black = img.colorAllocate(0,0,0)       
	$red = img.colorAllocate(255,0,0)      
	$blue = img.colorAllocate(0,0,255)
	$green = img.colorAllocate(0,255,0)
	$orange = img.colorAllocate(0xFF,0x99,0x33)
	acolor=[$blue,$green,$red]

	0.upto(20) do |i|
		img.rectangle(0,0,$x-1,$y-1, $black)
		img.filledRectangle(2,2,1+2*i,$y-3, acolor[j])
		f_img = File.new("progressbar_icons/pgb_#{color}_#{5*i}.png",'w')
		img.png(f_img)
		f_img.close
	end
end
