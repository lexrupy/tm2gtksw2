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

  def setup_style(stylemap)
    result_style = nil
    stylemap.each do |style|
      unless @theme.colors[style].nil?
        result_style = @theme.colors[style]
        break
      end
    end

    if result_style.nil?
      stylemap.each do |style|
        tmp_style = style.split('.')
        1.upto(tmp_style.length) do |i|
          style_name = tmp_style[0..tmp_style.length-i].join(".")
          next if style_name == ""
          unless @theme.colors[style_name].nil?
            result_style = @theme.colors[style_name]
            break
          end
        end
      end
    end

    result_style
  end

  def setup_mapping
    {
      'def:comment'                       => ['comment.line', 'comment.block'],
      'def:shebang'                       => ['comment.line', 'comment.block'],
      'def:doc-comment'                   => ['comment.line', 'comment.block'],
      'def:doc-comment-element'           => ['comment.line', 'comment.block'],
      'def:constant'                      => ['constant'],
      'def:character'                     => ['constant.character', 'string'],
      'def:string'                        => ['string','string.literal', 'string.quoted.literal', 'string.unquoted.heredoc string', 'string - string source'],
      'def:special-char'                  => ['constant.character.escape', 'constant.character.escaped', 'string constant', 'support.constant'],
      # constant.numeric.ruby included because some themes just refers to that language
      'def:number'                        => ['constant.numeric', 'constant.numeric.ruby'],
      'def:floating-point'                => ['constant.numeric.floating-point', 'constant.numeric',  'constant.numeric.ruby'],
      'def:decimal'                       => ['constant.numeric.floating-point', 'constant.numeric', 'constant.numeric.ruby'],
      'def:base-n-integer'                => ['constant.numeric.integer.int32', 'constant.numeric.integer.int64', 'constant.numeric', 'constant.numeric.ruby'],
      'def:complex'                       => ['constant.numeric', 'constant.numeric.ruby'],
      'def:special-constant'              => ['constant.language'],
      'def:boolean'                       => ['constant.language'],
      'def:identifier'                    => ['variable', 'variable.language', 'variable.other'],
      'def:function'                      => ['entity.name.function'],
      'def:builtin'                       => ['constant.language'],
      'def:statement'                     => ['keyword'],
      'def:operator'                      => ['keyword.operator'],
      'def:keyword'                       => ['keyword.control', 'keyword', 'storage'],
      'def:type'                          => ['support.type'],
      'def:preprocessor'                  => ['support.constant', 'keyword.control.import'],
      'def:error'                         => ['invalid.illegal'],
      'def:reserved'                      => ['keyword'],
      'def:note'                          => ['comment'],
      # Language Specific
      'diff:location'                     => ['meta.diff.header'],
      'diff:added-line'                   => ['markup.inserted'],
      'diff:removed-line'                 => ['markup.deleted'],
      'diff:changed-line'                 => ['markup.changed'],

      'css:keyword'                       => ['support.type.property-name.css'],
      'css:at-rules'                      => ['meta.preprocessor.at-rule', 'keyword.control.at-rule'],
      'css:color'                         => ['constant.other.rgb-value.css'],

      'xml:entity'                        => ['declaration.xml-processing'],
      'xml:doctype'                       => ['declaration.doctype', 'meta.tag.sgml.doctype'],
      'xml:namespace'                     => ['entity.name.tag.namespace'],
      'xml:tag'                           => ['markup.tag', 'declaration.tag', 'entity.name.tag'],
      'xml:element-name'                  => ['entity.name.tag', 'markup.tag'],
      'xml:attribute-name'                => ['entity.other.attribute-name'],

      'html:dtd'                          => ['string.quoted.docinfo.doctype.DTD', 'declaration.doctype.DTD'],
      'html:tag'                          => ['markup.tag', 'declaration.tag', 'entity.name.tag'],

      'js:function'                       => ['support.function.js'],

      'c:preprocessor'                    => ['meta.preprocessor.c'],

      'php:string'                        => ['string.quoted.single.php', 'string.quoted.double.php'],

      'ruby:attribute-definition'         => ['variable.other.constant', 'keyword'],
      'ruby:builtin'                      => ['variable.other.constant'],
      'ruby:instance-variable'            => ['variable', 'variable.language', 'variable.other'],
      'ruby:global-variable'              => ['entity.name.function'],
      'ruby:class-variable'               => ['variable', 'variable.language', 'variable.other'],
      'ruby:special-variable'             => ['keyword'],
      'ruby:predefined-variable'          => ['constant.language'],
      'ruby:constant'                     => ['variable.other.constant','variable.other', 'constant'],
      'ruby:symbol'                       => ['constant.other.symbol'],
      'ruby:regex'                        => ['string.regexp'],
      'ruby:module-handler'               => ['keyword'],

      'rubyonrails:attribute-definition'  => ['variable.other.constant', 'keyword'],
      'rubyonrails:builtin'               => ['variable.other.constant'],
      'rubyonrails:instance-variable'     => ['variable', 'variable.language', 'variable.other'],
      'rubyonrails:global-variable'       => ['entity.name.function'],
      'rubyonrails:class-variable'        => ['variable', 'variable.language', 'variable.other'],
      'rubyonrails:special-variable'      => ['keyword'],
      'rubyonrails:predefined-variable'   => ['constant.language'],
      'rubyonrails:constant'              => ['variable.other.constant','variable.other', 'constant'],
      'rubyonrails:symbol'                => ['constant.other.symbol'],
      'rubyonrails:regex'                 => ['string.regexp'],
      'rubyonrails:module-handler'        => ['keyword'],

      'rubyonrails:class-definition'      => ['support.class.ruby', 'entity.name.type'],
      'rubyonrails:simple-interpolation'  => ['string source', 'string.interpolated', 'source string source', 'constant.character.escaped'],
      'rubyonrails:complex-interpolation' => ['string source', 'string.interpolated', 'source string source', 'constant.character.escaped'],
      'rubyonrails:rails'                 => ['source.ruby.rails', 'variable.other.constant'],

      'python:module-handler'             => ['keyword'],
      'python:special-variable'           => ['keyword'],
      'python:builtin-constant'           => ['keyword'],
      'python:builtin-object'             => ['constant'],
      'python:builtin-function'           => ['entity.name.function', 'constant'],

      'perl:type'                         => ['constant'],
      'perl:line-directive'               => ['constant'],
      'perl:builtin'                      => ['entity.name.function'],
      'perl:variable'                     => ['variable', 'variable.language', 'variable.other'],
      'perl:special-variable'             => ['variable.other.constant', 'constant.language', 'keyword'],
      'perl:include-statement'            => ['keyword.control.import', 'keyword']

    }
  end

  def prepare
    template = File.read('template.xml.erb')
    output = ERB.new(template)

    @theme_name = CGI::escapeHTML(@theme.theme_name)
    @colorscheme = {}
    @colorscheme['text']              = get_style({ :background => @theme.background,     :foreground => @theme.foreground })
    @colorscheme['cursor']            = get_style({ :foreground => @theme.caret })
    @colorscheme['selection']         = get_style({ :background => @theme.selection,      :foreground => @theme.foreground })
    @colorscheme['current-line']      = get_style({ :background => @theme.line_highlight })
    @colorscheme['line-numbers']      = get_style({ :background => @theme.line_highlight, :foreground => @theme.foreground })
    @colorscheme['bracket-match']     = get_style({ :background => @theme.line_highlight, :bold => true })
    @colorscheme['bracket-mismatch']  = get_style({ :background => @theme.line_highlight, :underline => true })
    @colorscheme['search-match']      = get_style({ :background => @theme.line_highlight, :bold => true, :underline => true })
    @colorscheme['draw-spaces']       = get_style({ :foreground => @theme.invisibles })

    @colorscheme['def:note']          = get_style({ :bold => true, :italic => true, :underline => true })

    mappings = setup_mapping

    mappings.keys.each do |key|
      if style = setup_style(mappings[key])
        @colorscheme[key] = get_style(style)
      end
    end

    @lines = output.result(binding)
  end

  def get_theme
    @lines
  end
end

