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
    #p to_check
    to_check.each do |r|
      regexp = Regexp.new(r)
      newkey = @hash.keys.grep(regexp).first
      debug "found key #{newkey} for #{key}" if newkey
      return newkey if newkey
    end
    debug "key #{key} not found"
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
    #@src_theme.each_key {|k| @src_theme.delete(k) if (@src_theme[k].keys.to_a.reject{|e| e == :fontStyle } & [:background, :foreground]).empty? }
    @src_theme = @src_theme.merge(global_settings)
    @src_theme = GlobHash.new(@src_theme)
  end

  def get_theme
    theme = OpenStruct.new
    theme.name = @name
    theme.foreground = normalize_color(@src_theme[:foreground])
    @global_bg = normalize_color(@src_theme[:background])
    theme.background = @global_bg
    # Put in an instance variable to be accecible by next normalize color operations
    theme.caret = normalize_color(@src_theme[:caret])
    theme.selection = normalize_color(@src_theme[:selection], @global_bg)
    theme.eol_marker = normalize_color(@src_theme[:invisibles], @global_bg)
    theme.line_highlight = normalize_color(@src_theme[:lineHighlight], @global_bg)
    theme.invisibles = theme.eol_marker

    theme.invalid = get_style(['invalid', 'invalid.illegal'])

    # CONSTANT
    theme.constant = get_style(["constant", "support", "variable.other.constant", "constant.character"])
    # __FILE__ # support.type, support.class
    theme.support = get_style(["support.function", "support"]) || theme.constant
    # #foo
    theme.comment = get_style(["comment", "comment.line", "comment.block"])
    # "foo"
    theme.string = get_style(["string", "string - string source", "string source string"])
    # :foo
    theme.label = get_style(["constant", "constant.other", "constant.other.symbol","constant.other.symbol.ruby"])
    # Diff
    theme.diffadd = get_style(["markup.inserted"])
    theme.diffdel = get_style(["markup.deleted"])
    theme.difflct = get_style(["markup.header"])
    # 123
    theme.number = get_style(["constant.numeric"])
    # class, def, if, end
    theme.keyword = get_style(["keyword.control"])
    # true, false, nil
    theme.special_constant = get_style(["constant.language"])
    # @foo
    theme.variable = get_style(["variable", "variable.other"])
    # = < + -
    theme.operator = get_style(["keyword.operator"])
    # def foo
    theme.function = get_style(["entity.name.function"])
    # class MyClass
    theme.entityname = get_style(["entity.name"]) || theme.constant
    # "string with #{someother} string"
    theme.interpolation = get_style(["string.interpolated",
                                      "constant.character.escaped",
                                      "constant.character.escaped",
                                      "string.quoted source",
                                      "string constant.other.placeholder",
                                      "string source"]) || theme.string
    # /jola/
    theme.regexp = get_style(["string.regexp"])
    # <div>
    theme.markup = get_style(["meta.tag"]) || theme.function
    theme.markup_attr = get_style(["entity.other.attribute-name", "declaration.tag", "meta.attribute.smarty"]) || theme.function
    theme.markup_tag = get_style(["entity.name.tag", "meta.tag entity"]) || theme.markup
    theme.markup_inst = get_style(["declaration.xml-processing", "declaration.tag", "declaration.tag.entity", "meta.tag.entity"]) || theme.markup

    theme
  end


  def get_style(keys)
    style = {}
    keys.to_a.each do |key|
      if @src_theme[key]
        if @src_theme[key][:fontStyle] =~ /bold/
          style[:bold] ||= true
        end
        if @src_theme[key][:fontStyle] =~ /italic/
          style[:italic] ||= true
        end
        if @src_theme[key][:fontStyle] =~ /underline/
          style[:underline] ||= true
        end
        style[:background] = normalize_color(@src_theme[key][:background], @global_bg) if @src_theme[key][:background]
        style[:foreground] = normalize_color(@src_theme[key][:foreground], @global_bg) if @src_theme[key][:foreground]
      end
    end
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

