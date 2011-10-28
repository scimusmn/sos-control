#!/usr/bin/expect -f

############################################################
# This script connects with the SOS system and reloads a 
# defined playlist
############################################################

proc usage {} {
  #send_error "usage: reload_playlist.tcl arguments\n"
  set USAGE [puts "
  This script connects with the SOS system and reloads a 
  defined playlist

  USAGE: reload_playlist playlist_name

  ARGUMENTS:
    playlist_name    Name of the SOS playlist

  EXAMPLE:
    reload_playlist blue_marble.sos

  "]
  send_error $USAGE
  exit 1
}

# Display usage rules if no arhuments are defined
if {[llength $argv] == 0} usage

# Arguments that can be passed to this script

# Playlist name
set playlist [lindex $argv 0]


# Check for a defined playlist
if {$playlist eq ""} {
  puts "ERROR: You didn't specify a playlist to reload."
  usage
}

# Load SOS connection details
source [file dirname [info script]]/config/settings.inc

# :TODO: check for the variables in the config file

# A decent guess at the default prompt for most users
set prompt "(%|#|\\\$) $"

# SOS ready state
# When the SOS automation protocol is working properly
# the system returns a "R" to indicate it is ready
set ready R

# Define error codes
set E_NO_TELNET   2 ;# no usable Telnet command
set E_NO_CONNECT  3 ;# failure to connect to remote server (timed out)
set E_UNKNOWN     25 ;# unexpected failure

# Find the Telnet binary on our system
if {[file executable /usr/bin/telnet]} {
  set TELNETBIN /usr/bin/telnet
} elseif {[file executable /usr/local/bin/telnet]} {
  set TELNETBIN /usr/local/bin/telnet
} else {
  send_error "ERROR: Can't find a usable TELNET on this system.\n"
  exit $E_NO_TELNET
}
# :TODO: Add a final check here that just runs telet and sees if an 
# error comes up. Maybe the user has telnet in their path.

# Telnet to the remote SOS using the SOS automation protocol port
spawn $TELNETBIN $sos_ip 2468
expect {
    # Handle telnet connection errors
    -nocase "nodename nor servname provided, or not known" {
      send_error "\n ERROR: Unable to connect to the SOS \n";
      exit $E_NO_CONNECT;
    }
    -nocase "telnet: Unable to connect to remote host" {
      send_error "\n ERROR: Unable to connect to the SOS \n";
      exit $E_NO_CONNECT;
    }

    # If we connect, enable the automation control
    -nocase "Escape character is '^]'." { send "enable\r"; exp_continue; }

    # If it worked the SOS should return the ready state
    $ready
}

# Load the defined playlist
spawn open_playlist $playlist

expect {
  # :TODO: Write a new function that isn't usage() that helps
  # explain the E04 error
  -nocase "EO4" { send "exit\r"; usage; }
  $ready
}

send "exit\r";
expect EOF
