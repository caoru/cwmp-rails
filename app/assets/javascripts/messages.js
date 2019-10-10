
var messages_ready = function() {
    $('.destroy-messages').unbind( "click" );
    $('.destroy-messages').click(function(e) {
          $.ajax({
              url: "/messages",
              method: "DELETE"
        });
    });
};

$(document).on('turbolinks:load',messages_ready);
