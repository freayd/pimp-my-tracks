### Parameters ###
gpsbabel_command = '/Applications/GPSBabelFE.app/Contents/MacOS/gpsbabel'
input_type  = 'gpx'
input_file  = 'tracks/*.gpx'
output_type = 'kml'
output_file = 'tracks/pimped.kml'

### Arguments - Input files ###
args = [ "'#{gpsbabel_command}'" ]
Dir.glob(input_file) do |filepath|
    args << "-i #{input_type} -f '#{filepath}'" unless filepath == output_file
end
args << '-x track,pack'

### Arguments - Filters ###
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
# Time-shifting
# args << '-x track,move=+1h'

### Arguments - Output file ###
args << "-o #{output_type} -F '#{output_file}'"

### Run GPSBabel ###
puts   args.join(' ').gsub(/ -([a-eg-zA-EG-Z]) /, "\n    -\\1 ")
system args.join(' ')
exit unless $?.success?

### Open result file ###
open_command = case RUBY_PLATFORM
    when /cygwin|mswin|mingw|bccwin|wince|emx/i then 'start'      # Windows
    when /darwin/i                              then 'open'       # Mac OS
    when /linux/i                               then 'gnome-open' # Linux
    else '# Open the file'
end
puts   "'#{open_command}' '#{output_file}'"
system "'#{open_command}' '#{output_file}'"

# TODO Grab the profile from http://www.gpsvisualizer.com/profile_input
# http://code.jquery.com/jquery-1.9.1.min.js
# jQuery('form input').each(function(){console.log( '#' + this.type + ' : ' + this.name + ' = ' + this.value );})
# http://www.krio.me/how-to-send-post-request-return-contents-ruby/
