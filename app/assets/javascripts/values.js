var gRequestId = "";

var values_ready = function() {
//$(document).ready(function() {
  //$('#tree').treeview({data: getTree()});
  //$('#tree').treeview({data: <%= @data %>});

  $('#instanceManagement .setInstance').unbind('click');
  $('#instanceManagement .setInstance').click(function() {
    index = $('#instanceManagement input[name=index]').val();
    nodeId = $('#instanceManagement input[name=nodeId]').val();
    node = $('#tree').treeview('getNode', nodeId);
    prev = node.text;
    node.text = index;
    node.name = index;

    html = $('#tree').find('li[data-nodeid=' + nodeId + ']').html();
    html = html.replace(prev, index);
    $('#tree').find('li[data-nodeid=' + nodeId + ']').html(html);
  });

  $('#instanceManagement .addRequest').unbind('click');
  $('#instanceManagement .addRequest').click(function(e) {
    index = $('#instanceManagement input[name=index]').val();
    nodeId = $('#instanceManagement input[name=nodeId]').val();
    node = $('#tree').treeview('getNode', nodeId);

    prev = node.text;
    node.text = index;
    node.name = index;

    html = $('#tree').find('li[data-nodeid=' + nodeId + ']').html();
    html = html.replace(prev, index);
    $('#tree').find('li[data-nodeid=' + nodeId + ']').html(html);

    addRequestParameter(node);
  });

  $('#instanceManagement .operationObject').unbind('click');
  $('#instanceManagement .operationObject').click(function() {
    name = "";
    method = "";
    message = "";
    nodeId = $('#instanceManagement input[name=nodeId]').val();
    node = $('#tree').treeview('getNode', nodeId);
    parentNode = $('#tree').treeview('getParent', node);

    if ($(this).hasClass("add")) {
      name = get_full_name(parentNode);
      method = "POST";
      message = "Processing Add Object '" + name + "'...";
    } else if ($(this).hasClass("delete")) {
      index = $('#instanceManagement input[name=index]').val();
      name = get_full_name(parentNode) + "." + index;
      method = "DELETE";
      message = "Processing Delete Object '" + name + "'...";
    }

    parameters = [{"name": name, "value": "0", "type": "object"}];

    gRequestId = Date.now();
    $('#api_response_text').val(message);
    //$.ajax({ url: "/api/object", method: "DELETE", data: { "name" : name } });
    $.ajax({
      url: "/api/cpe/object",
      method: method,
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
  });

  function get_full_name(node) {
    name = "";

    parentNode = $('#tree').treeview('getParent', node);

    //if (node.nodeId != 0) {
    if (parentNode.nodeId != undefined) {
      parent_name = get_full_name(parentNode);
      name = parent_name + "." + node.name;
    } else {
      name = node.name;
    }

    return name;
  }

  function addRequestParameter(data) {
    name = get_full_name(data);
    operation_type = $('input[type=radio][name=method_select]:checked').val();

    if ((operation_type == "names") && ($('#parameters').html().length > 0)) {
      return ;
    }

    if (data.nodeType != "leaf") {
      name += ".";
    }

    if ($('#tree').hasClass("get")) {
      $.get("/values/form_get", { "name" : name, "type" : data.type },  function( data ) {
        $('#parameters').append(data.html);

        $('#parameters span.icon').click(function() {
          $(this).closest('.form-content').remove();
        });
      });
    } else {

      if (operation_type == "values" && data.access != "readWrite") {
        return ;
      }

      if (operation_type == "attributes") {
        enums = [];
        enums.push("0|Off");
        enums.push("1|Passive notification");
        enums.push("2|Active notification");
        enums.push("3|Passive lightweight notification");
        enums.push("4|Passive notification with passive lightweight notification");
        enums.push("5|Active lightweight notification");
        enums.push("6|Passive notification with active lightweight notification");
      } else {
        enums = data.enums
      }

      $.get("/values/form_set", { "name" : name, "type" : data.type, "enums" : enums },  function( data ) {
        $('#parameters').append(data.html);

        $('#parameters span.icon').click(function() {
          $(this).closest('.form-content').remove();
        });
      });
    }
  }

  function clickEvent(event, data) {
    if (data.nodeType == "instance") {
      index = $('#instanceManagement input[name=nodeId]').val(data.nodeId);

      if (data.access == "readOnly") {
        $('.operationObject').prop('disabled', true);
      } else {
        $('.operationObject').prop('disabled', false);
      }

      $('#instanceManagement').modal('show');

      return false;
    }

    //if (data.icon == undefined) return;

    addRequestParameter(data);
  }
  
  $.get("/api/model", { "tr" : $('input[type=radio][name=tr_select]:checked').val() },  function( data ) {
    $('#tree').treeview({
      data: data,
      onNodeSelected: clickEvent//,
      //onNodeUnselected: clickNode
    });
  });

  $('input[name="commit"].api_values').unbind( "click" );
  $('input[name="commit"].api_values').click(function() {
    var parameters = [];
    var validate = true;
    var method = "GET";
    var operation = "Get";
    var operation_type = "Values";
    var api = "values";
    var method_select = $('input[type=radio][name=method_select]:checked').val();

    if ( method_select == "attributes" ) {
      operation_type = "Attributes";
      api = "attributes"
    } else if ( method_select == "names" ) {
      operation_type = "Names";
      api = "names"
    }

    if ($(this).hasClass("set")) {
      method = "POST";
      operation = "Set";
    }

    $('#parameters').find('.form-content').each(function(index, value) {
      name = $(this).find('label').text();
      value = $(this).find('[name="value"]').val();
      type = $(this).find('input[name="type"]').val();

      if (value.length == 0) {
        alert('Invalid value of ' + name + ".");
        validate = false;
        $(this).find('[name="value"]').focus();
        return false;
      }

      parameters.push({"name": name, "value": value, "type": type});
    });

    if (parameters.length == 0) {
      alert("Select Parameters.");
      return false;
    }

    gRequestId = Date.now();
    $('#api_response_text').val("Processing " + operation + " Parameter " + operation_type + "...");
    $.ajax({
      url: "/api/cpe/" + api,
      method: method,
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

  $('button[name="button"].api_values').unbind( "click" );
  $('button[name="button"].api_values').click(function() {
    $('#parameters').empty('');
    $('#api_response_text').val('');

    return false;
  });

  var currentPosition = parseInt($("#floatPosition").css("top"));
  $(window).scroll(function() {
    var position = $(window).scrollTop();
    if (position < 140 ) {
      //$("#floatPosition").stop().animate({"top":position+currentPosition+"px"},1000);
      $("#floatPosition").stop().animate({"top":position+(currentPosition-position)+"px"},1000);
    } else {
      $("#floatPosition").stop().animate({"top":position+60+"px"},1000);
    }
  });

  $('input[type=radio][name=tr_select]').unbind( "change" );
  $('input[type=radio][name=tr_select]').change(function() {
    $('#tree').empty();
    $.get("/api/model", { "tr" : this.value },  function( data ) {
      $('#tree').treeview({
        data: data,
        onNodeSelected: clickEvent//,
        //onNodeUnselected: clickNode
      });
    });
  });

  $('input[type=radio][name=method_select]').unbind( "change" );
  $('input[type=radio][name=method_select]').change(function() {

    if (($(this).closest('#floatPosition').hasClass('set')) || (this.value == "names")) {
      $('#parameters').empty('');
    }
    /*
    $('#tree').empty();
    $.get("/api/model", { "tr" : this.value },  function( data ) {
      $('#tree').treeview({
        data: data,
        onNodeSelected: clickEvent//,
        //onNodeUnselected: clickNode
      });
    });
    */
  });

};

//$(document).ready(ready);
$(document).on('turbolinks:load', values_ready);

