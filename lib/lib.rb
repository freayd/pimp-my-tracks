##########################################################################
# This file is part of Pimp my Tracks                                    #
#                                                                        #
# Pimp my Tracks is free software: you can redistribute it and/or modify #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# Pimp my Tracks is distributed in the hope that it will be useful,      #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with Pimp my Tracks. If not, see <http://www.gnu.org/licenses/>. #
##########################################################################

# Cross-platform way of finding an executable in the $PATH
# http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
            cmd = File.join(path, "#{cmd}#{ext}")
            return cmd if File.executable?(cmd)
        end
    end
    return nil
end

# Some OS tools
module OS
    # http://stackoverflow.com/questions/170956/how-can-i-find-which-operating-system-my-ruby-program-is-running-on
    TYPE = case RUBY_PLATFORM
        when /cygwin|mswin|mingw|bccwin|wince|emx/i then 'windows'
        when /darwin/i                              then 'mac'
        when /linux/i                               then 'linux'
    end

    def OS.windows?
        self::TYPE == 'windows'
    end
    
    def OS.mac?
        self::TYPE == 'mac'
    end
    
    def OS.linux?
        self::TYPE == 'linux'
    end

    OPEN_COMMAND = case self::TYPE
        when 'windows' then 'start'
        when 'mac'     then 'open'
        when 'linux'   then 'xdg-open'
    end
end