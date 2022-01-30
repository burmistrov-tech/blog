module Jekyll
  class TagPageGenerator < Generator
    safe true

    def generate(site)
      tags = site.posts.docs.flat_map { |post| post.data['tags'] || [] }.to_set
      tags.each do |tag|
        site.pages << TagPage.new(site, site.source, tag)
      end
    end
  end

  class TagPage < Page
    def initialize(site, base, tag)
      @site = site
      @base = base
      @dir  = File.join('tags', tag)
      @name = 'index.html'

      posts = site.posts.docs.select { |post| post.data['tags'].include?(tag) }
      posts_count = posts.count()
      
      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag.html')
      self.data['tag'] = tag
      self.data['posts'] = posts
      self.data['title'] = posts_count > 1 ? "There are #{posts_count} posts about #{tag}" : "There is #{posts_count} post about #{tag}"
    end
  end
end