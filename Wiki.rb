require 'nokogiri'
require 'open-uri'

print "Enter starting url: "
# Note: url form should be http://en.wikipedia.org/wiki/PAGENAME
url = gets.chomp
print "Enter depth: "
@depth = gets.chomp.to_i
puts "Depth must be < 0" and return if @depth < 1

def get_links(url)
  doc = Nokogiri::HTML(open(url))
  
  # Each of the following next four lines could be chained into 1,
  # but they're separated for readability. The first line queries 
  # Nokogiri for just the links in the body of the wiki page. The
  # second line then maps them to just the link they represent. 
  # The following line only keeps the ones with a valid (not empty)
  # href field, and one that starts with /wiki and doesn't have a
  # colon in it. This ensures it is a link to a page, and not
  # something else. The final line removes all of the pound symbols
  # and everything after, for links that link to a specific setion
  # of a related page. 
  
  links = doc.css('#bodyContent p a')
  links = links.map {|link| link['href']}
  links.keep_if {|href| href and href.start_with? '/wiki/' and not href.include? ':'}
  links.map! {|link| link.gsub(/#.*/,'')}

  # Here, we convert our array of links into a Hash, where the
  # keys are links, and the values are sub-hashes
  
  Hash[links.map {|link| [link,nil]}]
end

# Initialize our Wiki hash with that page's links
@wiki = get_links(url)

# Performs a depth-first search of a Wikipedia page's links
# We maintain a path, which is an array of the steps we
# took down the @wiki nested hash to reach our current
# location. 
def recursive_search(path,current_depth)
  # If we haven't hit our max depth
  if current_depth < @depth 
    sub_hash = @wiki
    # Follow our path down the hash
    path.each do |node|
      sub_hash = sub_hash[node]
    end

    # Expand this node of the sub-tree
    sub_hash.keys.each do |link|
      sub_hash[link] = get_links("http://en.wikipedia.org#{link}")
      # Here's our magic recursion, add this node to the
      # path, increment our depth, and traverse that
      recursive_search(path+[link],current_depth+1)
    end

  end
end

# Let's get this thing going
recursive_search([],1)

# Show our hard work
p @wiki
