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

require File.join(File.dirname(__FILE__), 'lib.rb')
require 'rubygems'
require 'bundler/setup'
require 'nokogiri'
require 'optparse'
require 'ostruct'
require 'rest-client'

# Parse parameters
PimpMyTracks.options = options = OpenStruct.new(
    :connect      => true,
    :remove_close => true,
    :simplify     => true,
    :open         => false,
    :profile      => false,
    :verbose      => false)
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

    opt.on('-o', '--[no-]open', 'Open the pimped file with default application (also open the profile if generated)') do |o|
        options.open = o
    end

    opt.on('-p', '--[no-]profile', 'Draw a profile') do |p|
        options.profile = p
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
abort option_parser.to_s if ARGV.length != 1
directory_path = ARGV[0]
abort "'#{directory_path}' isn't a directory !" unless File.directory?(directory_path)
directory_name = File.basename(directory_path)
kml_file = File.join(directory_path, directory_name + '.kml')

# Search GPSBabel command
gpsbabel_command = which('gpsbabel')
if gpsbabel_command.nil?
    gpsbabel_command = case OS::TYPE
        when 'windows' then 'C:\Program Files\GPSBabel\gpsbabel.exe'
        when 'mac'     then '/Applications/GPSBabelFE.app/Contents/MacOS/gpsbabel'
        when 'linux'   then '/usr/bin/gpsbabel'
    end
end
gpsbabel_command = nil unless not gpsbabel_command.nil? and File.executable?(gpsbabel_command)
abort 'GPSBabel could not be found on your computer. May be you should install it and add the GPSBabel folder in the environment variable PATH?' if gpsbabel_command.nil?
gpsbabel_command = "'#{gpsbabel_command}'" if gpsbabel_command.match(/ /)

# GPSBabel Arguments - Input files
# TODO Add --format and --list-formats option (fetch formats (name, extension) from "gpsbabel -h")
gpsbabel_args = [ gpsbabel_command ]
Dir.glob(File.join(directory_path, '*.{gpx,kml}')).sort.each do |file_path|
    next if file_path == kml_file
    file_type = File.extname(file_path).gsub(/^\./, '')
    gpsbabel_args << "-i '#{file_type}' -f '#{file_path}'"
end
gpsbabel_args << '-x track,pack'

# GPSBabel Arguments - Filters
gpsbabel_args << '-x track,trk2seg' if options.connect
gpsbabel_args << '-x simplify,error=0.01k,crosstrack' if options.simplify
# WARNING - Remove close points
# If a U-turn is done in less than 12 hours (43200 seconds), points of the return way may be deleted. A solution could be :
#     1) Specify in a parameter file the coordinates of the polygon containing the problematic area (recorded many times)
#     2) Process everything but the problematic area (with filter '-x polygon,file=F,exclude') in a first temporary file with filter '-x position,distance=50m'
#     3) Process the problematic area (with filter '-x polygon,file=FILENAME') in a second temporary file with filter '-x position,distance=50m,time=60'
#     4) Merge the two temporary files with filter '-x track,pack'
gpsbabel_args << '-x position,distance=50m,time=43200' if options.remove_close

# GPSBabel Arguments - Output file
gpsbabel_args << "-o 'kml' -F '#{kml_file}'"

# Run GPSBabel
run_command('Call GPSBabel', gpsbabel_args, options.verbose)
run_command('Open KML file', "#{OS::OPEN_COMMAND} '#{kml_file}'", options.verbose) if options.open

exit unless options.profile

# GPS Visualizer - Fetch form parameters
gpsvisualizer_url = 'http://www.gpsvisualizer.com/profile_input'
print_process('Load GPS Visualizer form',
              '1. Method' => 'GET',
              '2. URL'    => gpsvisualizer_url)
gpsvisualizer_form = Nokogiri::HTML(RestClient.get(gpsvisualizer_url)).at_css('form[action="profile?output"]')
abort "GPS Visualizer form not found on page '#{gpsvisualizer_url}'. May the site has changed ?" if gpsvisualizer_form.nil?
gpsvisualizer_params = {}
gpsvisualizer_form.css('input').each do |input|
    next if ['file', 'reset'].include?(input['type'])
    next if input['name'].nil? or input['value'].nil?
    gpsvisualizer_params[input['name'].to_sym] = input['value']
end
gpsvisualizer_form.css('select').each do |select|
    option = select.at_css('option[selected="selected"]') ||
             select.at_css('option[selected]') ||
             select.at_css('option')
    next if option.nil? or option['value'].nil?
    gpsvisualizer_params[select['name'].to_sym] = option['value']
end
gpsvisualizer_params.merge!(:format          => 'svg',
                            :units           => 'metric',
                            :drawing_title   => directory_name,
                            :add_elevation   => 'auto',
                            :drawing_mode    => 'paths',
                            :uploaded_file_1 => File.new(kml_file))

# Download the profile image 2 times :
#     1) First download
#     2) Search min and max altitudes of the profile
#     3) If found, new download with more comprehensive elevation bounds (ex: [1600, 2500] instead of [1642, 2456]). Stop if not found.
profile_file = nil
2.times do |iteration|

    # GPS Visualizer - Send profile request
    gpsvisualizer_url = 'http://www.gpsvisualizer.com/profile?output'
    print_process('Send GPS Visualizer profile request',
                  '1. Method'     => 'POST',
                  '2. URL'        => gpsvisualizer_url,
                  '3. Parameters' => gpsvisualizer_params)
    gpsvisualizer_result = Nokogiri::HTML(RestClient.post(gpsvisualizer_url, gpsvisualizer_params))
    gpsvisualizer_error = gpsvisualizer_result.at_css('[class="error"]')
    abort "GPS Visualizer error: '#{gpsvisualizer_error.content}'." unless gpsvisualizer_error.nil?
    gpsvisualizer_svg_path = (gpsvisualizer_result.at_css('a[href^="download/"]') || {})['href']
    abort "GPS Visualizer image not found on page '#{gpsvisualizer_url}'. May the site has changed ?" if gpsvisualizer_svg_path.nil?

    # GPS Visualizer - Download the resulting image
    gpsvisualizer_url = "http://www.gpsvisualizer.com/#{gpsvisualizer_svg_path}"
    profile_file = File.join(directory_path, directory_name + '.svg')
    print_process('Download GPS Visualizer profile image',
                  '1. Method'     => 'GET',
                  '2. URL'        => gpsvisualizer_url,
                  '3. Local file' => profile_file)
    File.open(profile_file, 'w') { |f| f.write(RestClient.get(gpsvisualizer_url)) }

    # Search min and max altitudes
    if iteration == 0

        svg_content = Nokogiri::XML(File.open(profile_file).read)
        altitude_min = +1.0/0.0
        altitude_max = -1.0/0.0
        (svg_content.css('g[id="altitude y gridlines"] text') || []).each do |text|
            m = text.content.match(/^\s*(\d+[\.,]?\d*)\s*m\s*$/)
            next if m.nil?
            altitude = m[1].to_f
            altitude_min = [altitude_min, altitude].min
            altitude_max = [altitude_max, altitude].max
        end
        altitude_min = nil if altitude_min == +1.0/0.0
        altitude_max = nil if altitude_max == -1.0/0.0
        print_process('Read profile altitudes',
                      '1. Minimum' => altitude_min.nil? ? 'not found' : "#{altitude_min.to_i} m",
                      '2. Maximum'  => altitude_max.nil? ? 'not found' : "#{altitude_max.to_i} m")

        break unless (not altitude_min.nil? and altitude_min % 100 > 0) or (not altitude_max.nil? and altitude_max % 100 > 0)

        gpsvisualizer_params.merge!(:profile_y_min => altitude_min.nil? ? '' : ((altitude_min / 100    ).to_i * 100).to_s,
                                    :profile_y_max => altitude_max.nil? ? '' : ((altitude_max / 100 + 1).to_i * 100).to_s,
                                    :uploaded_file_1 => File.new(kml_file))
    end

end
run_command('Open profile file', "#{OS::OPEN_COMMAND} '#{profile_file}'", options.verbose) if options.open