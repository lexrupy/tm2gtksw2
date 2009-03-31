# This software was addapted from tm2jed (http://github.com/sickill/tm2jed/tree/master)

require 'rexml/document'

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
    @src_theme = @src_theme.merge(global_settings)
    @src_theme = GlobHash.new(@src_theme)
  end

  def get_theme
    theme = OpenStruct.new
    theme.name = @name
    theme.foreground = normalize_color(@src_theme[:foreground])
    theme.background = normalize_color(@src_theme[:background])
    theme.caret = normalize_color(@src_theme[:caret])
    theme.selection = normalize_color(@src_theme[:selection], theme.background)
    theme.eol_marker = normalize_color(@src_theme[:invisibles], theme.background)
    theme.line_highlight = normalize_color(@src_theme[:lineHighlight], theme.background)

    # CONSTANT
    theme.constant = @src_theme["variable.other.constant"] || @src_theme["constant"]

    # #foo
    theme.comment = @src_theme["comment"]

    # "foo"
    theme.string = @src_theme["string"]

    # Invisibles
    theme.invisibles = @src_theme["invisibles"]

    # :foo
    theme.label = @src_theme["constant"]

    # Current line
    theme.highlight = @src_theme["lineHighlight"]

    # Diff
    theme.diffadd = @src_theme["markup.inserted"] || "#144212"
    theme.diffdel = @src_theme["markup.deleted"] || "#660000"
    theme.difflct = @src_theme["meta.diff.header"] || "#2F33AB"

    # 123
    theme.number = @src_theme["constant.numeric"]

    # class, def, if, end
    theme.keyword = @src_theme["keyword.control"]

    # true, false, nil
    theme.special_constant = @src_theme["constant.language"]

    # @foo
    theme.variable = @src_theme["variable"] || @src_theme["variable.other"]

    # = < + -
    theme.operator = @src_theme["keyword.operator"]

    # def foo
    theme.function = @src_theme["entity.name.function"]

    # class MyClass
    theme.entityname = @src_theme["entity.name"] || theme.constant

    # "string with #{someother} string"
    theme.interpolation = @src_theme["constant.character.escaped"] || theme.string

    # /jola/
    theme.regexp = @src_theme["string.regexp"]

    # UserSpace, CGI, JOLA_MISIO
    #theme.constant = @src_theme["support"]

    # <div>
    theme.markup = @src_theme["meta.tag"]

    theme
  end

  private

  def blend(col_a, col_b, alpha)
    newcol = []
    [0,1,2].each do |i|
      newcol[i] = (1.0 - alpha) * col_a[i] + alpha * col_b[i]
    end
    newcol
  end

  def color_to_triplet(color)
    color.slice(1,6).scan(/.{2}/).map { |x| x.hex.to_f / 255.0 }
  end

  def normalize_color(color, bg=nil)
    alpha = color.slice(7,9).to_i(16)
    if bg && (1..254).include?(alpha)
      bg = color_to_triplet(bg)
      color = color_to_triplet(color)
      result = blend(bg, color, alpha.to_f / 255.0)
      value = "%02x%02x%02x" % result.map { |x| (x*255.0).to_i }
    else
      value = color.slice(1,6).downcase
    end
    "\##{value}"
  end

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
