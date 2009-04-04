#!/bin/ruby

system("rm ~/.gnome2/gedit/styles/*")
for file in Dir.glob("TextMateThemes/*.tmTheme")
  puts "Converting #{file} ..."
  system("ruby tm2gtksw2.rb \"#{file}\"")
  tgt_file = file.gsub("tmTheme", "xml")
  system("mv \"#{tgt_file}\" ~/.gnome2/gedit/styles/")
end

