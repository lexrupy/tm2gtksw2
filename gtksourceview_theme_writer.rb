# This software was addapted from tm2jed (http://github.com/sickill/tm2jed/tree/master)

require 'erb'
require 'cgi'
require File.join(File.dirname(__FILE__), 'utils.rb')

class GtksourceviewThemeWriter

  def initialize(theme)
    @theme = theme
    @lines = []
    prepare
  end

  def escape_value(val)
    val.gsub(/:/, '\:').gsub(/#/, '\#')
  end

  def add_line(line)
    @lines << line #"#{name}=#{escape_value(value).strip}"
  end

  def get_style(style, default="")
    if style.to_s =~ /missing prop/ || style.nil?
      return
    end
    s = ""
    s << "foreground=\"#{style[:foreground]}\"" if style[:foreground]
    s << " background=\"#{style[:background]}\"" if style[:background]
    s << " bold=\"true\"" if style[:bold]
    s << " underline=\"true\"" if style[:underline]
    s << " italic=\"true\"" if style[:italic]
    if s.size > 1
      s
    else
      default
    end
  end

  def prepare
    template = File.read('template.xml.erb')
    output = ERB.new(template)

    @theme_name             = CGI::escapeHTML(@theme.name)
    @color_background       = @theme.background
    @color_caret            = @theme.caret
    @color_foreground       = @theme.foreground
    @color_selection        = @theme.selection
    @color_lineHighlight    = @theme.line_highlight
    @color_invisibles       = @theme.invisibles
    @color_brkmatch         = "background=\"#4C4C4C\""
    @color_searchmatch      = "background=\"#404040\""
    @color_error            = get_style(@theme.invalid, "background=\"#C80000\" foreground=\"#F0EA20\"")
    @color_note             = "background=\"#F0EA20\" foreground=\"#C80000\""
    @color_comment          = get_style(@theme.comment)
    @color_keyword          = get_style(@theme.keyword)
    @color_function         = get_style(@theme.function)
    @color_markup           = get_style(@theme.markup)
    @color_markup_tag       = get_style(@theme.markup_tag)
    @color_markup_attr      = get_style(@theme.markup_attr)
    @color_markup_inst      = get_style(@theme.markup_inst)
    @color_class            = get_style(@theme.entityname)
    @color_number           = get_style(@theme.number)
    @color_variable         = get_style(@theme.variable)
    @color_symbol           = get_style(@theme.label)
    @color_special_constant = get_style(@theme.special_constant)
    @color_constant         = get_style(@theme.constant)
    @color_string           = get_style(@theme.string)
    @color_interpolat       = get_style(@theme.interpolation)
    @color_highlight        = get_style(@theme.highlight)
    @color_modulehandl      = get_style(@theme.constant)
    @color_support          = get_style(@theme.support)
    @color_diffadd          = get_style(@theme.diffadd)
    @color_diffrm           = get_style(@theme.diffdel)
    @color_difflct          = get_style(@theme.difflct)
    @color_regexp           = get_style(@theme.regexp)
    @lines = output.result(binding)
  end

  def get_theme
    @lines
  end
end

