#!/bin/ruby

for file in Dir.glob("*.tmTheme")
  puts "Converting #{file} ..."
  system("ruby tm2gtksw2.rb \"#{file}\"")
end

