function get_url() {
  var operation = "download";

  if ($('#updownload_file_type').hasClass("upload")) {
    operation = "upload";
  }

  if (!$('#updownload_file_type').val()) {
      return false;
  }

  $.ajax({
    url: "/api/cpe/url/" + operation + "/" + $('#updownload_file_type').val(),
    method: "GET",
    success: function(data) {
      if (data.result == "true") {
        $('#updownload_url').empty();
        $.each(data.urls, function (i, item) {
          $('#updownload_url').append($('<option>', {
            value: item,
            text : item
          }));
        });

        if (data.urls[0].startsWith("File")) {
          $('#upload_file').css("display", "inline");
          $('#updownload_file_name').css("display", "inline");
          $('#progress-wrp').css("display", "none");
          $('#updownload_url.download').css("display", "none");
        } else {
          $('#upload_file').css("display", "none");
          $('#updownload_file_name').css("display", "none");
          $('#progress-wrp').css("display", "none");
          $('#updownload_url.download').css("display", "inline");
        }
      }
    }
  });
}

function show_flash(type, title, desc) {
  $('#flash').append(
    '<div class="alert alert-' + type + ' fade in">' +
      '<a href="#" class="close" data-dismiss="alert">&times;</a>' +
      '<strong><span class="title">' + title + '</span></strong> <span class="desc">' + desc + '</span>' +
    '</div>'
    );
  $('#flash').css("display", "block");
}

var Upload = function (file) {
  this.file = file;
};

Upload.prototype.getType = function() {
  return this.file.type;
};
Upload.prototype.getSize = function() {
  return this.file.size;
};
Upload.prototype.getName = function() {
  return this.file.name;
};
Upload.prototype.doUpload = function () {
  var type = $('#updownload_file_type').val();
  var that = this;
  var formData = new FormData();

  // add assoc key values, this will be posts values
  formData.append("file", this.file, this.getName());
  formData.append("upload_file", true);

  $('#progress-wrp').css("display", "block");

  $.ajax({
    type: "POST",
    url: "/upload/" + type,
    xhr: function () {
      var myXhr = $.ajaxSettings.xhr();
      if (myXhr.upload) {
        myXhr.upload.addEventListener('progress', that.progressHandling, false);
      }
      return myXhr;
    },
    success: function (data) {
      // your callback here
      show_flash("success", "Success!", "File upload successfully.");

      get_url();
    },
    error: function (error) {
      console.log("error");
      // handle error
      $("#progress-wrp .progress-bar").css("width", "0%");
      $("#progress-wrp .status").text("0%");
      $("#progress-wrp").css("display", "none");
      show_flash("danger", "Error!", "File upload failure.");
    },
    async: true,
    data: formData,
    cache: false,
    contentType: false,
    processData: false,
    timeout: 60000
  });
};
    
Upload.prototype.progressHandling = function (event) {
  var percent = 0;
  var position = event.loaded || event.position;
  var total = event.total;
  var progress_bar_id = "#progress-wrp";

  if (event.lengthComputable) {
    percent = Math.ceil(position / total * 100);
  }

  // update progressbars classes so it fits your code
  $(progress_bar_id + " .progress-bar").css("width", +percent + "%");
  $(progress_bar_id + " .status").text(percent + "%");
};

var static_pages_ready = function() {
  /*
  $('.list-group-item').unbind( "click" );
  $('.list-group-item').click(function(e) {
    e.preventDefault();
    return false;
  });
  */

  $('#flash .close').unbind( "click" );
  $('#flash .close').click(function(e) {
    $('#flash').css("display", "none");
  });

  $('.settings .apply').unbind( "click" );
  $('.settings .apply').click(function(e) {
    $.ajax({
      url: "/api/settings",
      method: "PUT",
      data: {
        "cpe": {
          "ip": $('#api_cpe_ip').val(),
          "port": $('#api_cpe_port').val(),
          "path": $('#api_cpe_path').val(),
          "username": $('#api_cpe_username').val(),
          "password": $('#api_cpe_password').val()
        },
        "acs": {
          "name": $('#api_acs_name').val(),
          "username": $('#api_acs_username').val(),
          "password": $('#api_acs_password').val(),
          "firmware_prefix": $('#api_acs_firmware_prefix').val(),
          "default_model": $('#api_acs_default_model').val()
        }
      },
      success: function(data) {
        if (data.result == "false") {
          alert("Apply failed.");
        } else {
          alert("Apply success.");
          update_info();
        }
      }
    });

    return false;
  });

  $.ajax({
    url: "/api/settings",
    method: "GET",
    success: function(data) {
      if (data.result == "true") {
        $('#api_cpe_ip').val(data.cpe.ip);
        $('#api_cpe_port').val(data.cpe.port);
        $('#api_cpe_path').val(data.cpe.path);
        $('#api_cpe_username').val(data.cpe.username);
        $('#api_cpe_password').val(data.cpe.password);

        $('#api_acs_name').val(data.acs.name);
        $('#api_acs_username').val(data.acs.username);
        $('#api_acs_password').val(data.acs.password);
        $('#api_acs_firmware_prefix').val(data.acs.firmware_prefix);
        $('#api_acs_default_model').val(data.acs.default_model);

        $('#updownload_username').val(data.acs.username);
        $('#updownload_password').val(data.acs.password);
      }
    }
  });

  get_url();

  $('#updownload_file_type').unbind( "change" );
  $('#updownload_file_type').change(function() {
    get_url();
  });

  $('#upload_file').unbind( "click" );
  $('#upload_file').click(function() {
    var file = $("#updownload_file_name")[0].files[0];
    var upload = new Upload(file);

    // maby check size or type here with upload.getSize() and upload.getType()
    
    // execute upload
    upload.doUpload();

    return false;
  });

  $('input[name="commit"].apply_updownload').unbind( "click" );
  $('input[name="commit"].apply_updownload').click(function() {
    var api = "download";
    var operation = "Download";

    gRequestId = Date.now();

    if ($(this).hasClass("upload")) {
      api = "upload";
      operation = "Upload";
    }

    parameters = [
      {
        "name": "type",
        "value": $('#updownload_file_type option:selected').text(),
        "type": "string"
      },
      {
        "name": "url",
        "value": $('#updownload_url').val(),
        "type": "string"
      },
      {
        "name": "username",
        "value": $('#updownload_username').val(),
        "type": "string"
      },
      {
        "name": "password",
        "value": $('#updownload_password').val(),
        "type": "string"
      }
    ];

    $('#api_response_text').val("Processing " + operation + "...");

    $.ajax({
      url: "/api/cpe/" + api,
      method: "POST",
      data: {
        "requestId": gRequestId,
        "parameters": parameters
      },
      success: function(data) {
        if (data.result == "false") {
          $('#api_response_text').val(data.error);
        }
      }
    });

    return false;
  });

};

//$(document).ready(ready);
$(document).on('turbolinks:load',static_pages_ready);

