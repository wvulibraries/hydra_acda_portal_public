document.addEventListener('DOMContentLoaded', function() {
  const email_field = document.getElementById('mail_to');
  const checkbox = document.getElementById('checkbox');
  checkbox.addEventListener('change', function() {
    email_field.required = this.checked
  });
});
