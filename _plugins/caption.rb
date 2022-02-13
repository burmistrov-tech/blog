module Jekyll
  class CaptionBlock < Liquid::Tag
    def initialize(tag, text, tokens)
      super
      @text = text
    end

    def render(context)
      return "<span class='caption'>#{@text}</span>"
    end
  end
end

Liquid::Template.register_tag('caption', Jekyll::CaptionBlock)