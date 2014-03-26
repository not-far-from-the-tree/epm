$('html').removeClass('no-js').addClass('js');

function show_map(html_points) {
  var map = new L.Map('map', {
    zoom: 10,
    minZoom: 3,
    maxZoom: 18,
    layers: [new L.TileLayer('http://{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png', {
      attribution: 'Data &copy; <a href="http://www.openstreetmap.org/">OpenStreetMap</a> contributors; Tiles by <a href="http://www.mapquest.com/">MapQuest</a>',
      subdomains: ['otile1','otile2','otile3','otile4']
    })]
  });
  var points = [];
  $(html_points).each(function(){
    points.push( L.latLng($(this).data('lat'), $(this).data('lng')) );
    L.marker(points[points.length-1]).addTo(map);
  });
  map.fitBounds(points, {maxZoom: 14});
}

$(function(){

  // expand/contract input as content changes length
  $("form[method!='get']").find("input[data-default_size]").keyup(function(){
    $(this).attr('size', Math.min(100, Math.max($(this).data('default_size'), $(this).val().length)));
  });

});