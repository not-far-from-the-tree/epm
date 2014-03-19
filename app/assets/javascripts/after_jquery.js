$('html').removeClass('no-js').addClass('js');

$(function(){

  // expand/contract input as content changes length
  $("form[method!='get']").find("input[data-default_size]").keyup(function(){
    $(this).attr('size', Math.min(100, Math.max($(this).data('default_size'), $(this).val().length)));
  });

});