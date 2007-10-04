require 'fileutils'

widgets_root = File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', '..', 'widgets')
views_root   = File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', '..', 'app', 'views', 'widgets')

response = nil
while !%w(Y n).include?(response)
  printf "This task will *destroy* all your widgets, are you sure? [Y\\n]: "
  response = gets.chomp
end
response = response == 'Y'
if response
  [widgets_root, views_root].each {|dir| FileUtils.remove_dir(dir, response) if File.directory?(dir) }
end