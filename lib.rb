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

class PimpMyTracks
    @options = nil
    class << self
        attr_accessor :options
    end
end

# Print a message telling that a process is running (details are printed only in verbose mode). Available options:
# :force_verbose           (default: false)
# :order_by_leading_number (default: true)
def print_process(message, details)
    verbose = details.delete(:force_verbose) == true ? true : PimpMyTracks.options.verbose
    leading_number = details.delete(:order_by_leading_number) || true
    leading_pattern = /^(\d+)\.?\s*/

    puts message + (verbose ? ':' : '...')

    return unless verbose
    details.keys.sort_by { |k| leading_number ? k.match(leading_pattern)[0] : k }.each do |key|
        value = details[key]
        next if value.nil? or (value.respond_to?(:empty?) and value.empty?)

        print_object((leading_number ? key.gsub(leading_pattern, '') : key) + ':', true, '    ')
        print_object(value, true, '        ')
    end
end

# Print objects
def print_object(obj, do_print, leading_spaces, quote_strings = false)
    return '' if obj.nil?

    str = '' if obj.respond_to?(:empty?) and obj.empty?
    str ||= case obj
        when Symbol then ":#{obj.to_s}"
        when String then obj.gsub("\n", "\n#{leading_spaces}")
        when File   then "File('#{obj.path}')"
        when Array
            obj.each do |item|
                print_object(item, do_print, leading_spaces)
            end
            return
        when Hash
            obj.keys.sort_by { |key| key.to_s }.each do |key|
                print_object(print_object(key, false, '', true) + ' => ' + print_object(obj[key], false, '', true),
                             do_print,
                             leading_spaces)
            end
            return
        else obj.to_s
    end

    str = "'#{str}'" if quote_strings and obj.is_a?(String)
    if do_print
        puts leading_spaces + str
    else
        leading_spaces + str
    end
end

# Run a command then print output/errors to the console and exit in case of failure
def run_command(name, args, verbose)
    require 'open4'

    header = "#{name}:"
    command = "    Command:\n        " + args.to_a.join("\n        ")
    out, err = nil, nil
    status = Open4::popen4(args.to_a.join(' ')) do |pid, stdin, stdout, stderr|
        out = stdout.readlines
        err = stderr.readlines
    end

    print_process(name,
                  '1. Command' => args,
                  '2. Output'  => out,
                  '3. Error'   => err,
                  :force_verbose => (not status.success?))
    abort unless status.success?
end

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
    nil
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