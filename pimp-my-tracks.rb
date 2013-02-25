#!/usr/bin/env ruby
##########################################################################
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

require File.join(File.dirname(__FILE__), 'lib', 'lib.rb')
require 'optparse'
require 'ostruct'

### Parse parameters ###
options = OpenStruct.new
options.connect      = true
options.remove_close = true
options.simplify     = true
options.open         = false
options.verbose      = false
option_parser = OptionParser.new do |opt|
    opt.banner = "Usage: ruby #{__FILE__} [options] directory"
    opt.separator 'Directory'
    opt.separator '    Path to the directory which contains your GPS files to pimp'
    opt.separator 'Options'

    opt.on('-c', '--[no-]connect', 'Connect segments (filenames determine the order)') do |c|
        options.connect = c
    end

    opt.on('-r', '--[no-]remove-close', 'Remove close points (usefull when lot of very close points are recorded during breaks)') do |r|
        options.remove_close = r
    end

    opt.on('-s', '--[no-]simplify', 'Simplify the track (remove points that have the smallest effect on the overall shape)') do |s|
        options.simplify = s
    end

    opt.on('-o', '--[no-]open', 'Open the pimped file with default application') do |o|
        options.open = o
    end

    opt.on('-h', '--help', 'Print this message and exit') do
        puts opt
        exit
    end

    opt.on('-v', '--[no-]verbose', 'Run verbosely') do |v|
        options.verbose = v
    end
end
option_parser.parse!
if ARGV.length != 1
    puts option_parser
    exit
end
input_directory = ARGV[0]
unless File.directory?(input_directory)
    puts "'#{directory}' isn't a directory !"
    exit
end

### Search GPSBabel command ###
gpsbabel_command = which('gpsbabel')
if gpsbabel_command.nil?
    gpsbabel_command = case OS::TYPE
        when 'windows' then 'C:\Program Files\GPSBabel\gpsbabel.exe'
        when 'mac'     then '/Applications/GPSBabelFE.app/Contents/MacOS/gpsbabel'
        when 'linux'   then '/usr/bin/gpsbabel'
    end
end
gpsbabel_command = nil unless not gpsbabel_command.nil? and File.executable?(gpsbabel_command)
if gpsbabel_command.nil?
    puts 'GPSBabel could not be found on your computer. May be you should install it and add the GPSBabel folder in the environment variable PATH?'
    exit
end
gpsbabel_command = "'#{gpsbabel_command}'" if gpsbabel_command.match(/ /)

### Parameters ###
input_type  = 'gpx'
input_file  = File.join(input_directory, '*.gpx')
output_type = 'kml'
output_file = File.join(input_directory, File.basename(input_directory) + '.kml')

### GPSBabel Arguments - Input files ###
gpsbabel_args = [ gpsbabel_command ]
Dir.glob(input_file) do |filepath|
    gpsbabel_args << "-i #{input_type} -f '#{filepath}'" unless filepath == output_file
end
gpsbabel_args << '-x track,pack'

### GPSBabel Arguments - Filters ###
# Connect segments
gpsbabel_args << '-x track,trk2seg' if options.connect
# Simplify the track
gpsbabel_args << '-x simplify,error=0.01k,crosstrack' if options.simplify
# Remove close points
# NOTE: If a U-turn is done in less than 12 hours (43200 seconds), points of the return way may be deleted. A solution could be :
#       1) Specify in a parameter file the coordinates of the polygon containing the problematic area (recorded many times)
#       2) Process everything but the problematic area (with filter '-x polygon,file=F,exclude') in a first temporary file with filter '-x position,distance=50m'
#       3) Process the problematic area (with filter '-x polygon,file=FILENAME') in a second temporary file with filter '-x position,distance=50m,time=60'
#       4) Merge the two temporary files with filter '-x track,pack'
gpsbabel_args << '-x position,distance=50m,time=43200' if options.remove_close
# TODO Time-shifting
# gpsbabel_args << '-x track,move=+1h'

### GPSBabel Arguments - Output file ###
gpsbabel_args << "-o #{output_type} -F '#{output_file}'"

### Run GPSBabel ###
run_command('Call GPSBabel', gpsbabel_args, options.verbose)

### Open result file ###
run_command('Open file', "#{OS::OPEN_COMMAND} '#{output_file}'", options.verbose) if options.open

# TODO Grab the profile from http://www.gpsvisualizer.com/profile_input
# http://code.jquery.com/jquery-1.9.1.min.js
# jQuery('form input').each(function(){console.log( '#' + this.type + ' : ' + this.name + ' = ' + this.value );})
# http://www.krio.me/how-to-send-post-request-return-contents-ruby/
