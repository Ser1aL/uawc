$(document).ready(function(){

  $('.submit-button').click(function(event){
    event.preventDefault();
    var button = $(this)
    $('.loader').removeClass('hidden');
    $('.output').removeClass('error').html('');
    button.attr('disabled', 'disabled');

    $.ajax({
      url: '/generate',
      method: 'POST',
      data: button.closest('form').serialize()
    })
    .done(function(response){
      console.log(response);

      if(response['error'] != undefined){
        $('.output').addClass('error').html(response['error']);
        $('.loader').addClass('hidden');
        button.removeAttr('disabled');
      }
      else {
        $('.output').html('Collecting...');
        button.data('submission_key', response['submission_key']);
        button.data('interval_id', setInterval(getSubmissionStatus, 500));
      }
    });
  });

  function getSubmissionStatus(){
    var key = $('.submit-button').data('submission_key');

    $.ajax({
      url: '/get_status',
      method: 'POST',
      data: {key: key}
    })
    .done(function(response){
      if(response['sitemap']) {
        $('.loader').addClass('hidden');
        $('.submit-button').removeAttr('disabled');
        $('.output').html('');
        clearInterval($('.submit-button').data('interval_id'));

        if(response['email_sent']){
          $('.output').html('Email has successfully been sent');
        }
        else {
          $('.output').append(
            $('<a/>')
              .html('Download archive(rename to .tar.gz)')
              .attr('href', '/get_file/' + response['sitemap'])
              .addClass('btn')
              .addClass('btn-success')
            );
        }
      }
    });
  }

  $('.delivery-type').click(function(){
    if($(this).val() == 'email') {
      $('.email-group').removeClass('hidden');
    }
    else {
      $('.email-group').addClass('hidden');
    }
  });

});