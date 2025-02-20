## -*- tcl -*-
# ### ### ### ######### ######### #########
##
## Tcl implementation for map::slippy
##
## See
##	http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#Pseudo-Code
##
## for the coordinate conversions and other information.

# ### ### ### ######### ######### #########
## Requisites

package require math::constants

# ### ### ### ######### ######### #########
## API - Ensemble setup

namespace eval ::map::slippy {
    math::constants::constants pi radtodeg degtorad

    variable ourtilesize 256 ; # Size of slippy tiles <pixels>
}

# ### ### ### ######### ######### #########
## Implementation

proc ::map::slippy::tcl_length {level} {
    variable ourtilesize
    return [expr {$ourtilesize * (1 << $level)}]
}

proc ::map::slippy::tcl_tiles {level} {
    return [expr {1 << $level}]
}

proc ::map::slippy::tcl_tile_size {} {
    variable ::map::slippy::ourtilesize
    return $ourtilesize
}

proc ::map::slippy::tcl_tile_valid {tile levels {msgv {}}} {
    if {$msgv ne ""} { upvar 1 $msgv msg }

    # Bad syntax.
    if {[llength $tile] != 3} {
	set msg "Bad tile <[join $tile ,]>, expected 3 elements (zoom, row, col)"
	return 0
    }

    lassign $tile z r c

    # Requests outside of the valid ranges are rejected immediately

    if {($z < 0) || ($z >= $levels)} {
	set msg "Bad zoom level '$z' (max: $levels)"
	return 0
    }

    set tiles [map slippy tiles $z]
    if {($r < 0) || ($r >= $tiles) ||
	($c < 0) || ($c >= $tiles)
    } {
	set msg "Bad cell '$r $c' (max: $tiles)"
	return 0
    }

    return 1
}

proc ::map::slippy::tcl_geo_distance {geoa geob} {
    ::map::slippy::Check $geoa
    ::map::slippy::Check $geob
    
    # https://en.wikipedia.org/wiki/Haversine_formula
    # https://wiki.tcl-lang.org/page/geodesy
    # https://en.wikipedia.org/wiki/Geographical_distance	| For radius used in angle
    # https://en.wikipedia.org/wiki/Earth_radius		| to meter conversion
    ##
    # Go https://en.wikipedia.org/wiki/N-vector ?
    
    #puts deg.A($geoa)-B($geob)
    
    variable ::map::slippy::degtorad
    variable ::map::slippy::pi

    # Get the decimal degrees
    lassign $geoa _ lata lona
    lassign $geob _ latb lonb

    # Convert all to radians
    set lata [expr {$degtorad * $lata}]
    set lona [expr {$degtorad * $lona}]
    set latb [expr {$degtorad * $latb}]
    set lonb [expr {$degtorad * $lonb}]

    #puts rad.A($lata|$lona)-B($latb|$lonb)

    set dlat [expr {$latb - $lata}]
    set dlon [expr {$lonb - $lona}]

    # puts d.lat($dlat).lon.($dlon)

    set h [expr {pow((sin($dlat/2)),2) + cos($lata)*cos($latb)*pow((sin($dlon/2)),2)}]
    #       dy^2 + cos*cos*dx^2
    #       dy^2 + (sqrt(cos*cos)*dx)^2
    # puts H.($h)

    # Fix rounding errors, clamp to range -1...1
    if {abs($h) > 1.0} { set h [expr {($h > 0) ? 1.0 : -1.0}] }
    # puts HC.($h)

    # Distance angle
    set d [expr {2 * asin(sqrt($h))}]
    # puts D.($d)

    # set d [expr {2*asin(hypot( sin($dlat/2), sqrt(cos($y1)*cos($y2)) * sin($dlon/2) )  )}]
    # not sure how bad that is with rounding errors for antipodal points.
    
    # Convert to meters and return
    set meters [expr {6371009*$d}]
    #puts M.($meters)
    return $meters
}

# Coordinate conversions.
# geo   = zoom, latitude, longitude
# tile  = zoom, row,      column
# point = zoom, y,        x

proc ::map::slippy::tcl_geo_2tile {geo} {
    ::map::slippy::Check $geo
    
    variable ::map::slippy::degtorad
    variable ::map::slippy::pi
    lassign $geo zoom lat lon
    # lat, lon are in degrees.
    # The missing sec() function is computed using the 1/cos equivalency.
    set tiles  [map slippy tiles $zoom]
    set latrad [expr {$degtorad * $lat}]
    set row    [expr {int((1 - (log(tan($latrad) + 1.0/cos($latrad)) / $pi)) / 2 * $tiles)}]
    set col    [expr {int((($lon + 180.0) / 360.0) * $tiles)}]
    return [list $zoom $row $col]
}

proc ::map::slippy::tcl_geo_2tilef {geo} {
    ::map::slippy::Check $geo
    
    variable ::map::slippy::degtorad
    variable ::map::slippy::pi
    lassign $geo zoom lat lon
    # lat, lon are in degrees.
    # The missing sec() function is computed using the 1/cos equivalency.
    set tiles  [map slippy tiles $zoom]
    set latrad [expr {$degtorad * $lat}]
    set row    [expr {(1 - (log(tan($latrad) + 1.0/cos($latrad)) / $pi)) / 2 * $tiles}]
    set col    [expr {(($lon + 180.0) / 360.0) * $tiles}]
    return [list $zoom $row $col]
}

proc ::map::slippy::tcl_geo_2point {geo} {
    ::map::slippy::Check $geo
    
    variable ::map::slippy::degtorad
    variable ::map::slippy::pi
    variable ::map::slippy::ourtilesize
    lassign $geo zoom lat lon
    # Essence: [geo 2tile $geo] * $ourtilesize, with 'geo 2tile' inlined.
    set tiles  [map slippy tiles $zoom]
    set latrad [expr {$degtorad * $lat}]
    set y      [expr {$ourtilesize * ((1 - (log(tan($latrad) + 1.0/cos($latrad)) / $pi)) / 2 * $tiles)}]
    set x      [expr {$ourtilesize * ((($lon + 180.0) / 360.0) * $tiles)}]
    return [list $zoom $y $x]
}

proc ::map::slippy::tcl_geo_2points {levels geo} {
    ::map::slippy::Check $geo
    
    # Ignore z in input, compute points for all (zoom) levels.
    set r {}
    for {set z 0} {$z < $levels} {incr z} {
	lappend r [2point [lreplace $geo 0 0 $z]]
    }
    return $r
}

proc ::map::slippy::tcl_tile_2geo {tile} {
    ::map::slippy::Check $tile
    
    variable ::map::slippy::radtodeg
    variable ::map::slippy::pi
    lassign $tile zoom row col
    # Note: For integer row/col the geo location is for the upper left corner of the tile. To get
    #       the geo location of the center simply add 0.5 to the row/col values.
    set tiles [map slippy tiles $zoom]
    set lat   [expr {$radtodeg * (atan(sinh($pi * (1 - 2 * $row / double($tiles)))))}]
    set lon   [expr {$col / double($tiles) * 360.0 - 180.0}]
    return [list $zoom $lat $lon]
}

proc ::map::slippy::tcl_tile_2point {tile} {
    ::map::slippy::Check $tile

    variable ::map::slippy::ourtilesize
    lassign $tile zoom row col
    # Note: For integer row/col the pixel location is for the upper left corner of the tile. To get
    #       the pixel location of the center simply add 0.5 to the row/col values.
    # set tiles [tiles $zoom]
    set y     [expr {$ourtilesize * $row}]
    set x     [expr {$ourtilesize * $col}]
    return [list $zoom $y $x]
}

proc ::map::slippy::tcl_point_2geo {point} {
    ::map::slippy::Check $point

    variable ::map::slippy::radtodeg
    variable ::map::slippy::pi
    lassign $point zoom y x
    set length [map slippy length $zoom]
    set lat    [expr {$radtodeg * (atan(sinh($pi * (1 - 2 * double($y) / $length))))}]
    set lon    [expr {double($x) / $length * 360.0 - 180.0}]
    return [list $zoom $lat $lon]
}

proc ::map::slippy::tcl_point_2tile {point} {
    ::map::slippy::Check $point

    variable ::map::slippy::ourtilesize
    lassign $point zoom y x
    #set tiles [tiles $zoom]
    set row   [expr {double($y) / $ourtilesize}]
    set col   [expr {double($x) / $ourtilesize}]
    return [list $zoom $row $col]
}

proc ::map::slippy::tcl_fit_geobox {canvdim geobox zmin zmax} {
    variable ::map::slippy::ourtilesize
    lassign $canvdim canvw canvh
    lassign $geobox  lat0 lat1 lon0 lon1

    # NOTE we assume ourtilesize == [map::slippy length 0].
    # Further, we assume that each zoom step "grows" the linear resolution by a factor 2
    # (that's the log(2) down there)
    set canvw [expr {abs($canvw)}]
    set canvh [expr {abs($canvh)}]
    set z [expr {int(log(min( \
		  ($canvh/$ourtilesize) / (abs($lat1 - $lat0)/180), \
		  ($canvw/$ourtilesize) / (abs($lon1 - $lon0)/360))) \
                 / log(2))}]
    # clamp $z
    set z [expr {($z<$zmin) ? $zmin : (($z>$zmax) ? $zmax : $z)}]
    # Now $zoom is an approximation, since the scale factor isn't uniform across the map
    # (the vertical dimension depends on latitude). So we have to refine iteratively
    # (It is expected to take just one step):
    while {1} {
	# Now we can run "uphill", then there's z0 = z - 1 and "downhill", then there's z1 = z + 1
	# (from the last iteration)
	#puts "try zoom $z"
	lassign [map slippy geo 2point [list $z $lat0 $lon0]] _ y0 x0
	lassign [map slippy geo 2point [list $z $lat1 $lon1]] _ y1 x1

	set w [expr {abs($x1 - $x0)}]
	set h [expr {abs($y1 - $y0)}]
	if { $w > $canvw ||  $h > $canvh } {
	    # too big: shrink
	    #puts "too big: shrink..."
	    if { [info exists z0] } break; # but not if we come "from below"
	    if {$z <= $zmin} break; # can't be < $zmin
	    set z1 $z
	    incr z -1
	} else {
	    # fits: grow
	    #puts "fits: grow..."
	    if { [info exists z1] } break; # but not if we come "from above"
	    set z0 $z
	    incr z
	}
    }
    if { [info exists z0] } { return $z0 }
    return $z
}

proc ::map::slippy::Check {p} {
    if {[llength $p] != 3} {
	return -code error {Bad point, expected list of 3}
    }
    lassign $p a b c
    if {![string is int    -strict $a]} { return -code error "expected integer but got \"$a\"" }
    if {![string is double -strict $b]} { return -code error "expected floating-point number but got \"$b\"" }
    if {![string is double -strict $c]} { return -code error "expected floating-point number but got \"$c\"" }
    return
}

# ### ### ### ######### ######### #########
## Ready
return
