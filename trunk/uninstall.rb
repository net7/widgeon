require 'fileutils'

class Uninstaller
  class << self
    @widgets_root = File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'widgets')
    
    def uninstall
      response = nil
      while !%w(Y n).include?(response)
        printf "This task will *destroy* all your widgets, are you sure? [Y\\n]: "
        response = gets.chomp
      end
      response = response == 'Y'
      FileUtils.remove_dir(@widgets_root, response) if response and File.directory?(@widgets_root) 
    end
  end
end

Uninstaller.uninstall