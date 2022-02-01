module Jekyll
  class TagPageGenerator < Generator
    safe true

    def generate(site)
      tags_posts = TagsPostsCollector.new(site).collect()

      site.pages << TagListPage.new(site, site.source, tags_posts)

      tags_posts.each_pair do |tag, posts|
        site.pages << TagPage.new(site, site.source, tag, posts)
      end
    end
    
    private

    class TagsPostsCollector
      def initialize(site)
        @site = site
      end
  
      def collect()
        tags_posts = Hash.new
        
        @site.posts.docs.each do |post|
          post.data['tags'].each do |tag|
            if tags_posts[tag]
              tags_posts[tag] << post            
            else          
              tags_posts[tag] = [ post ]
            end
          end
        end
  
        return tags_posts
      end
    end      
  end

  class TagListPage < Page
    def initialize(site, base, tags_posts)
      @site = site
      @base = base
      @dir  = File.join('tags')
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag-list.html')
      self.data['tags_posts'] = tags_posts
      self.data['tags'] = tags_posts.keys
      self.data['posts'] = tags_posts.values
    end
  end

  class TagPage < Page
    def initialize(site, base, tag, posts)
      @site = site
      @base = base
      @dir  = File.join('tags', tag)
      @name = 'index.html'
      
      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'tag.html')
      self.data['tag'] = tag
      self.data['posts'] = posts
    end
  end
end