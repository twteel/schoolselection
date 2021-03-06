module SchoolsHelper
  
  def distance(distance)
    "#{distance.to_f.round(2)}&nbsp;miles"
  end
  
  def distance_in_miles_from_meters(distance)
    number_with_precision((distance.to_f / METERS_PER_MILE), :precision => 2)
  end
  
  def walk_time(distance)
    (distance.to_f / WALK_TIME_METERS_PER_MINUTE).floor
  end

  def drive_time(distance)
    (distance.to_f / DRIVE_TIME_METERS_PER_MINUTE).floor
  end
  
  def eligibility_title(school)
    if school.eligibility =~ /Walk Zone/
      "Walk&nbsp;Zone"
    elsif school.eligibility =~ /Assignment Zone/
      "Assignment&nbsp;Zone"
    elsif school.eligibility =~ /Citywide/
      "Citywide"
    end      
  end
        
  include EncodePolyline
  def static_schools_map(width, height)
    zone_boundry = encode_line(simplify_points(@assignment_zone.geometry[0].exterior_ring.points,0.001,0.01))
    image_tag("http://maps.google.com/maps/api/staticmap?" + 
      "size=#{width}x#{height}" + 
      '&zoom=10' +
      "&maptype=roadmap" +
      "&sensor=false" +
      "&markers=size:tiny|color:0x53e200|#{@walk_zone_schools.map {|x|"#{x.lat},#{x.lng}"} * "|" }" +
      "&markers=size:tiny|color:0xfcef08|#{@assignment_zone_schools.map {|x|"#{x.lat},#{x.lng}"} * "|" }" +
      "&markers=size:tiny|color:0xc8c8c8|#{@citywide_schools.map {|x|"#{x.lat},#{x.lng}"} * "|" }" +
      "&path=fillcolor:0xfcef08|color:0x0000ff|weight:1|enc:#{zone_boundry}", 
      :alt => "Map View", :class => 'static-map-image')
  end
  
  def static_school_map(width, height, color)
    "http://maps.google.com/maps/api/staticmap?" + 
    "size=#{width}x#{height}" + 
    '&zoom=14' +
    "&maptype=roadmap" +
    "&sensor=false" +
    "&markers=size:large|color:0x#{color}|#{[@school].map {|x|"#{x.lat},#{x.lng}"} * "|" }"
  end
  
  ####### ALL SCHOOLS MAP #######
    
  def walk_zone_map
      gmaps("markers" => {
        "data" => markers_json, 
        "options" => {"list_container" => "markers_list"}}, 
        "polygons" => {
          "data" => assignment_zones_json, 
          "options" => { 
            "fillColor" => "#ffff00", "fillOpacity" => 0.3, 
            "strokeColor" => "#000000", "strokeWeight" => 1.5, 'strokeOpacity' => 0.6 
          }
        }, 
        "circles" => {"data" => walk_zone_json }, 
        "map_options" => { "provider" => "googlemaps", "auto_adjust" => true }
      )
  end
  
  def walk_zone_json
      [{:lng => @geocoded_address.lng, :lat => @geocoded_address.lat, :radius => @grade_level.walk_zone_radius * METERS_PER_MILE, :fillColor => '#61d60e', :fillOpacity => 0.4, :strokeColor => '#000000', :strokeOpacity => 0.6, :strokeWeight => 1.5}].to_json
  end
  
  def assignment_zones_json
    @assignment_zone.shape_to_json
  end
  
  def markers_json
    array = []
    array << @walk_zone_schools.map {|x| create_listing_hash(x, 'green')}
    array << @assignment_zone_schools.map {|x| create_listing_hash(x, 'yellow')}
    array << @citywide_schools.map {|x| create_listing_hash(x, 'gray')}    
    array << [{
      :sidebar => @geocoded_address.street_address,
      :lng => @geocoded_address.lng, :lat => @geocoded_address.lat,
      :picture => '/assets/icons/home.png',
      :width => '18', :height => '15',
      :marker_anchor => [9, 7]
    }]
    array.flatten.to_json
  end
  
  def create_listing_hash(x, color)
    {
      :lng => x.lng, :lat => x.lat,
      :picture => "/images/#{color}-marker.png",
      :width => '21', :height => '38',
      :shadow_picture => '/images/shadow.png',
      :shadow_width => '43', :shadow_height => '38',
      :shadow_anchor => [10, 33],
      :description => %{
        #{alert(x)}
        <ul class='horizontal-list'>
          <li>#{image_tag(x.image(:thumb), :class => 'rounded-corners')}</li>
          <li>
            <h3 class='bold'>#{x.name}</h3>
            #{x.address}<br />
            #{x.city.try(:name)} MA, #{x.zipcode}<br />
            <strong>#{link_to 'Learn More', school_path(x.permalink, search_params())}</strong>
          </li>
        </ul>
      },
      :sidebar => "#{x.name}"
    }
  end
  
  def alert(x)
    if x.id.to_s == session[:sibling_school]
      "<div id='flash' class='normal bold center yellow-background'>This school qualifies for Sibling Priority</div>"
    elsif x.eligibility =~ /Walk Zone/
      "<div id='flash' class='normal bold center green-background'>This school qualifies for Walk Zone Priority</div>"
    end
  end
end
