Pimp my Tracks
==============

Customize your GPS tracks : merge, simplify and more...
[Pimp my Tracks on GitHub](https://github.com/freayd/pimp-my-tracks)

Features
========

* Handles a lot of formats : [GPSBabel Capabilities](http://www.gpsbabel.org/capabilities.html)
* Merge multiple tracks
* Connect segment
* Simplify tracks by removing unnecessary points

Requirements
============

* [Ruby](http://www.ruby-lang.org/) and [Bundler gem](http://gembundler.com/)
* [GPSBabel](http://www.gpsbabel.org/)
* Web access to [GPS Visualizer](http://www.gpsvisualizer.com/)

Usage
=====

    ruby pimp-my-tracks.rb [options] directory
    Directory
        Path to the directory which contains your GPS files to pimp
    Options
        -c, --[no-]connect               Connect segments (filenames determine the order)
        -r, --[no-]remove-close          Remove close points (usefull when lot of very close points are recorded during breaks)
        -s, --[no-]simplify              Simplify the track (remove points that have the smallest effect on the overall shape)
        -o, --[no-]open                  Open the pimped file with default application
        -h, --help                       Print this message and exit
        -v, --[no-]verbose               Run verbosely

License
=======

Pimp my Tracks is licensed under the [GPL](http://www.gnu.org/licenses/gpl.txt)