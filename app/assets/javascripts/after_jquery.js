$('html').removeClass('no-js').addClass('js');

var me, map;
var markers = [];

function marker_dragged(e) {
  ll = e.target.getLatLng();
  $('#coords input:first').val(ll.lat);
  $('#coords input:last').val(ll.lng);
}

function show_map(html_points) {
  me = L.latLng($('body').data('lat'), $('body').data('lng'));
  var editing = $('#map').parents('form').length > 0
  var points = [];
  if (!html_points) { html_points = [] }
  $(html_points).each(function(){
    points.push(L.latLng($(this).data('lat'), $(this).data('lng')));
  });
  if (editing && $('#coords input:first').val() && $('#coords input:last').val()) {
    points.push(L.latLng($('#coords input:first').val(), $('#coords input:last').val()));
  }
  map = new L.Map('map', {
    center: me,
    zoom: 10,
    minZoom: 3,
    maxZoom: 18,
    layers: [new L.TileLayer('http://{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png', {
      attribution: 'Data &copy; <a href="http://www.openstreetmap.org/">OpenStreetMap</a> contributors; Tiles by <a href="http://www.mapquest.com/">MapQuest</a>',
      subdomains: ['otile1','otile2','otile3','otile4']
    })]
  });
  $(points).each(function(){
    markers.push( L.marker(this, {draggable: editing}).addTo(map) );
  });
  if (editing) {
    $(markers).each(function(){ this.on('dragend', marker_dragged); });
  }
  if (!$('body').hasClass('users-edit') && !$('body').hasClass('users-show')) {
    L.marker(me, {icon: L.divIcon({className: 'me', html: '<div class="inner"></div>', iconSize: L.point(15, 15)})}).addTo(map);
    points.push(me);
  }
  if (points.length > 1) { map.fitBounds(points); }
}

$(function(){

  // expand/contract input as content changes length
  $("form[method!='get']").find("input[data-default_size]").keyup(function(){
    $(this).attr('size', Math.min(100, Math.max($(this).data('default_size'), $(this).val().length)));
  });

});