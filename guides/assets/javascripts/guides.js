function guideMenu(){
  if (document.getElementById('guides').style.display == "none") {
    document.getElementById('guides').style.display = "block";
  } else {
    document.getElementById('guides').style.display = "none";
  }
}

$.fn.selectGuide = function(guide){
  $("select", this).val(guide);
}

guidesIndex = {
  bind: function(){
    var currentGuidePath = window.location.pathname;
    var currentGuide = currentGuidePath.substring(currentGuidePath.lastIndexOf("/")+1);
    $(".guidesIndex").
      on("change", "select", guidesIndex.navigate).
      selectGuide(currentGuide);
  },
  navigate: function(e){
    var $list = $(e.target);
    url = $list.val();
    window.location = url;
  }
}
