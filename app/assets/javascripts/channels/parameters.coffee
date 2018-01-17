App.parameters = App.cable.subscriptions.create "ParametersChannel",
  connected: ->
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    #$("#parameters").prepend(data.html);
    #alert(data.data)
    #$("#static_page_response_text").append(data.data);
    #$('#static_page_response_text').append(data.data + "\n"); 

    #console.log("id    : " + data.id + ", " + typeof data.id);
    #console.log("gid   : " + gRequestId.toString() + ", " + typeof gRequestId.toString());

    if data.id isnt gRequestId.toString()
      return

    text = $('#api_response_text').val();

    if text.indexOf("Processing") is 0
      $('#api_response_text').val('');
      text = "";

    $('#api_response_text').val(text + data.data + "\n"); 
    #alert($('#api_response_text').val());
