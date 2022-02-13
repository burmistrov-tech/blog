module Jekyll
  class CaptionBlock < Liquid::Tag
    def initialize(tag, raw_params, tokens)
      super
      @text = raw_params
    end

    def render(context)
      return "<span class='caption'>#{@text}</span>"
    end
  end
end

Liquid::Template.register_tag('caption', Jekyll::CaptionBlock)