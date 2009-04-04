#!/usr/bin/ruby
# This software was addapted from tm2jed (http://github.com/sickill/tm2jed/tree/master)

require 'ostruct'
require File.join(File.dirname(__FILE__), 'textmate_theme_reader.rb')
require File.join(File.dirname(__FILE__), 'gtksourceview_theme_writer.rb')

def teste_symbol(param, param1)
  helper :symbol
  %w(one two three)
  %Q[uma string diferente]
  "uma string com #{interpolacao}"
end

def debug(msg)
  puts msg if DEBUG
end

tm_theme_filename = ARGV.shift
DEBUG = ARGV.shift == '-d'
src = File.read(tm_theme_filename)
reader = TextmateThemeReader.new(src)
theme = reader.get_theme
writer = GtksourceviewThemeWriter.new(theme)
dst = writer.get_theme
jed_theme_filename = tm_theme_filename.gsub("tmTheme", "xml")
File.open(jed_theme_filename, "w") do |f|
  f.write(dst)
end

