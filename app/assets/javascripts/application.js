// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require bootstrap
//= require rails-ujs
//= require turbolinks
//= require_tree .

var application_ready = function() {

  $('#get_rpc_method').unbind( "click" );
  $('#get_rpc_method').click(function() {
    gRequestId = Date.now();
    $('#api_response_text').val("Processing Get RPC Method...");
    $.ajax({
      url: "/api/cpe/get_rpc_method",
      method: "GET",
      data: {
        "requestId": gRequestId
      },
      success: function(data) {
        if (data.result == "false") {
          $('#api_response_text').val(data.error);
        }
      }
    });

    $('#operations').attr("aria-expanded", "false");
    $('#operations').closest("li").removeClass("open");

    return false;
  });

  $('#get_all_queued_transfers').unbind( "click" );
  $('#get_all_queued_transfers').click(function() {
    gRequestId = Date.now();
    $('#api_response_text').val("Processing Get All Queued Transfers Method...");
    $.ajax({
      url: "/api/cpe/get_all_queued_transfers",
      method: "GET",
      data: {
        "requestId": gRequestId
      },
      success: function(data) {
        if (data.result == "false") {
          $('#api_response_text').val(data.error);
        }
      }
    });

    $('#operations').attr("aria-expanded", "false");
    $('#operations').closest("li").removeClass("open");

    return false;
  });

  $('#reboot').unbind( "click" );
  $('#reboot').click(function() {
    if (confirm("The CPE will be rebooting.\nReally continue?")) {
      //$.post("/api/reboot");
      gRequestId = Date.now();
      $('#api_response_text').val("Processing Reboot...");
      $.ajax({
        url: "/api/cpe/reboot",
        method: "POST",
        data: {
          "requestId": gRequestId
        },
        success: function(data) {
          if (data.result == "false") {
            $('#api_response_text').val(data.error);
          }
        }
      });
    }

    $('#operations').attr("aria-expanded", "false");
    $('#operations').closest("li").removeClass("open");

    return false;
  });

  $('#factory_reset').unbind( "click" );
  $('#factory_reset').click(function() {
    if (confirm("The CPE will be rebooting and factory reset.\nReally continue?")) {
      //$.post("/api/factory_reset");
      gRequestId = Date.now();
      $('#api_response_text').val("Processing Factory Reset...");
      $.ajax({
        url: "/api/cpe/factory_reset",
        method: "POST",
        data: {
          "requestId": gRequestId
        },
        success: function(data) {
          if (data.result == "false") {
            $('#api_response_text').val(data.error);
          }
        }
      });
    }

    $('#operations').attr("aria-expanded", "false");
    $('#operations').closest("li").removeClass("open");

    return false;
  });

  update_info();
};

function update_info() {
  $.ajax({
    url: "/api/settings",
    method: "GET",
    success: function(data) {
      if (data.result == "true") {
        info = "http://" +
              data.cpe.username + ":" + data.cpe.password + "@" +
              data.cpe.ip + ":" + data.cpe.port + data.cpe.path;
        $('#info').html(info);
      }
    }
  });
}

function setCookie(name,value,days) {
  var expires = "";
  if (days) {
    var date = new Date();
    date.setTime(date.getTime() + (days*24*60*60*1000));
    expires = "; expires=" + date.toUTCString();
  }
  document.cookie = name + "=" + (value || "")  + expires + "; path=/";
}

function getCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for(var i=0;i < ca.length;i++) {
    var c = ca[i];
    while (c.charAt(0)==' ') c = c.substring(1,c.length);
      if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
  return null;
}

function eraseCookie(name) {   
  document.cookie = name+'=; Max-Age=-99999999;';  
}

function getXml(epoch) {
  window.open("/api/cpe/message.xml?epoch="+epoch, '_blank');
  /*
  $.ajax({
    url: "/api/cpe/xml.xml",
    method: "GET",
    data: { "id" : id },
    success: function(data) {
      if (data.result == "true") {
        xml = String(data.xml).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
        $('#xmlFileModal .request-id').html("RequestId: " + id);
        $('#xmlFileModal .xml-file').html(xml);
        $('#xmlFileModal').modal('show');
      }
    }
  });
  */
}

$(document).on('turbolinks:load', application_ready);
