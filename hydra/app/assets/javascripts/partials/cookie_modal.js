// Homepage Help Modal Cookie
$(function () {
  // set the cookie 
  var myCookie = "ModalShown"; 
  var cookieValue = getCookieValue(myCookie); 
  
  if(cookieValue.length === 0){
    // $('#openModal').modal('show'); 
  } else { 
    $('#openModal').toggleClass("destroy");
  }
  
    $("#openModalbut").click(function (e) {
			e.preventDefault();             
      $("#openModal").toggleClass("destroy");
      document.cookie = "ModalShown=true; expires=Fri, 31 Dec 9999 23:59:59 GMT; path=/";
    });
 
});

function getCookieValue(a, b) {
    b = document.cookie.match('(^|;)\\s*' + a + '\\s*=\\s*([^;]+)');
    return b ? b.pop() : '';
}
