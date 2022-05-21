require 'nokogiri'

module Jekyll
  module PostDescription
    def prepare_description(html)
      description = Nokogiri::HTML(html)

      remove_forbidden_elements(description)
      beatify_ul(description)

      return description.text
    end

    private

    def remove_forbidden_elements(html)
      forbidden_elements = [
        'div.highlighter-rouge',
        'code',
        'img',
        'span.caption'
      ]

      html.search(forbidden_elements.join(', ')).each do |element| 
        element.remove
      end
    end

    def beatify_ul(html)
      html.search('ul').each do |ul|
        ul.elements[0..-1-1].each do |li|
          li.content += ', '
        end

        ul.elements[-1].content += '. '
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::PostDescription)