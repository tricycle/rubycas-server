$(function() {
  // enable placeholders in older browsers
  $('input[placeholder], textarea[placeholder]').placeholder();

  var navigation = {
    "internal.jasperauth.trikeapps.com": {
      "purchasing_portal": "staging.portal.dentalcorp.com.au"
    },
    "accounts.dentalcorp.com.au": {
      "purchasing_portal": "portal.dentalcorp.com.au"
    },
    "staging.accounts.dentalcorp.com.au": {
      "purchasing_portal": "staging.portal.dentalcorp.com.au"
    },
    "accounts.dentalcorp.ca": {
      "purchasing_portal": "portal.dentalcorp.com.au"
    }
  };

  $("#admin_link").attr('href', "http://" + window.location.hostname);
  $("#portal_link").attr('href', "http://" + navigation[window.location.hostname]["purchasing_portal"]);
});
