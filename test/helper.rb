#####-------------------------------------------------------------------------------------------------------
require 'test/unit'
require 'rubygems'
begin
  require 'shoulda'
rescue LoadError
  abort "shoulda is not available: sudo gem install thoughtbot-shoulda --source=http://gems.github.com"
end
begin
  require 'matchy'
rescue LoadError
  abort "matchy is not available: sudo gem install mhennemeyer-matchy --source=http://gems.github.com"
end
 
#####-------------------------------------------------------------------------------------------------------
$:.unshift('lib')
require 'rubygems'
require 'synaptic4r'

#####-------------------------------------------------------------------------------------------------------
require 'mock'
require 'matchers'
Dir["test/*_messages.rb"].each{|f| require f}


#.........................................................................................................
def client
  args = {:key=>'thesecret', :site=>'https://nowhere.com', :subtenant=>'abcdef1245', :uid=>'noone'}
  client = Synaptic4r::Client.new(args)
  [args, client]
end
