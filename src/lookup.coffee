$('#search').submit (event) ->
  event.preventDefault()
  $.ajax(
    url: '/lookup'
    data: $(this).serialize()
  ).done( (response) ->
    console.log response
    if response.length
      match = response[0]
      msg = "This address is located in: #{match.name}"
    else
      msg = "Address is not in any registered neighborhood."
    $('#search-results').html msg
  ).fail( ->
    console.log "lookup failed"
  )
