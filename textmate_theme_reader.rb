# This software was addapted from tm2jed (http://github.com/sickill/tm2jed/tree/master)

require 'rexml/document'
require File.join(File.dirname(__FILE__), 'utils.rb')

class GlobHash
  def initialize(hash)
    @hash = hash
  end

  def find_key(key)
    to_check = []
    elems = key.split(".")
    elems.size.times do |i|
      to_check << "(^|,\\s*)"+Regexp.escape(elems[0..i].join("."))+"(\\s*,|$)"
    end
    to_check << "^#{Regexp.escape(key)}$"
    to_check.reverse!
    to_check.each do |r|
      regexp = Regexp.new(r)
      newkey = @hash.keys.grep(regexp).first
      return newkey if newkey
    end
    key
  end

  def [](key)
    key = find_key(key) if key.is_a?(String)
    @hash[key]
  end

  def method_missing(name, *args)
    @hash.send(name, *args)
  end
end

class TextmateThemeReader
  include REXML

  def initialize(source)
    @source = source
    @xml = Document.new(@source)
    root = parse_hash(@xml.root.elements[1])
    @name = root[:name]
    @src_theme = root[:settings]
    global_settings = @src_theme.delete_at(0)[:settings]
    @src_theme = @src_theme.map { |s| { s[:scope] => s[:settings] } }.inject({}) { |v,a| a.merge(v) }
    @multi_keys = @src_theme.keys.select { |k| k.is_a?(String) && k.index(",") }
    @multi_keys.each do |key|
      keys = key.split(",").map { |k| k.strip }
      value = @src_theme.delete(key)
      keys.each do |new_key|
        @src_theme[new_key] = value
      end
    end
    @src_theme = @src_theme.merge(global_settings)
    @src_theme = GlobHash.new(@src_theme)
  end

  def get_theme
    theme = OpenStruct.new
    theme.theme_name = @name
    # Collect the general theme colors
    theme.foreground     = normalize_color(@src_theme[:foreground])
    @global_bg           = normalize_color(@src_theme[:background])
    theme.background     = @global_bg
    theme.caret          = normalize_color(@src_theme[:caret])
    theme.selection      = normalize_color(@src_theme[:selection], @global_bg)
    theme.invisibles     = normalize_color(@src_theme[:invisibles], @global_bg)
    theme.line_highlight = normalize_color(@src_theme[:lineHighlight], @global_bg)
    theme.colors         = {}
    # Collect the language theme colors
    @src_theme.keys.reject{ |k| [:foreground, :background, :caret, :selection, :invisibles, :lineHighlight].include?(k) }.each do |key|
      if style = get_style(@src_theme[key])
        theme.colors[key] = style
      end
    end
    theme
  end

  def get_style(tm_style)
    style = {}
    if tm_style[:fontStyle] =~ /bold/
      style[:bold] ||= true
    end
    if tm_style[:fontStyle] =~ /italic/
      style[:italic] ||= true
    end
    if tm_style[:fontStyle] =~ /underline/
      style[:underline] ||= true
    end
    style[:background] = normalize_color(tm_style[:background], @global_bg) if tm_style[:background]
    style[:foreground] = normalize_color(tm_style[:foreground], @global_bg) if tm_style[:foreground]
    return nil if style.keys.empty?
    style
  end

  private

  def parse_element(e)
    return nil unless e
    if e.name == "dict"
      return parse_hash(e)
    elsif e.name == "array"
      return parse_array(e)
    elsif e.name == "string"
      return e.text.to_s.strip
    end
    nil
  end

  def parse_hash(elem)
    h = {}
    elem.elements.each("key") do |e|
      h[e.text.to_sym] = parse_element(e.next_element)
    end
    h
  end

  def parse_array(elem)
    a = []
    elem.elements.each do |e|
      a << parse_element(e)
    end
    a
  end

end

