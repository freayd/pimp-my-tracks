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

require 'lib.rb'

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

### Parameters ###
input_type  = 'gpx'
input_file  = 'tracks/*.gpx'
output_type = 'kml'
output_file = 'tracks/pimped.kml'

### GPSBabel Arguments - Input files ###
args = [ "'#{gpsbabel_command}'" ]
Dir.glob(input_file) do |filepath|
    args << "-i #{input_type} -f '#{filepath}'" unless filepath == output_file
end
args << '-x track,pack'

### GPSBabel Arguments - Filters ###
# Connect segments.
# NOTE: File names must be alphabetically ordered by date.
args << '-x track,trk2seg'
# Simplify the track.
args << '-x simplify,error=0.001k,crosstrack'
# Remove close points (usefull when lot of very close points are recorded during breaks).
# NOTE: If a U-turn is done in less than 12 hours (43200 seconds), points of the return way may be deleted. A solution could be :
#       1) Specify in a parameter file the coordinates of the polygon containing the problematic area (recorded many times)
#       2) Process everything but the problematic area (with filter '-x polygon,file=F,exclude') in a first temporary file with filter '-x position,distance=50m'
#       3) Process the problematic area (with filter '-x polygon,file=FILENAME') in a second temporary file with filter '-x position,distance=50m,time=60'
#       4) Merge the two temporary files with filter '-x track,pack'
args << '-x position,distance=50m,time=43200'
# TODO Time-shifting
# args << '-x track,move=+1h'

### GPSBabel Arguments - Output file ###
args << "-o #{output_type} -F '#{output_file}'"

### Run GPSBabel ###
puts   args.join(' ').gsub(/ -([a-eg-zA-EG-Z]) /, "\n    -\\1 ")
system args.join(' ')
exit unless $?.success?

### Open result file ###
puts   "'#{OS::OPEN_COMMAND}' '#{output_file}'"
system "'#{OS::OPEN_COMMAND}' '#{output_file}'"

# TODO Grab the profile from http://www.gpsvisualizer.com/profile_input
# http://code.jquery.com/jquery-1.9.1.min.js
# jQuery('form input').each(function(){console.log( '#' + this.type + ' : ' + this.name + ' = ' + this.value );})
# http://www.krio.me/how-to-send-post-request-return-contents-ruby/
