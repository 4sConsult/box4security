// fetch(`/api/user/${$(e.delegateTarget).data('user-id')}`, {method: 'GET'})
//           .then((response) => {
//             return response.json()
//           }).then((u) => {
//             $('#edit-{{ userform.email.id }}').val(u.email);
//             $('#edit-{{ userform.last_name.id }}').val(u.last_name);
//             $('#edit-{{ userform.first_name.id }}').val(u.first_name);
//             $('#edit-{{ userform.roles.id }}').dropdown('clear');
//             u.roles.forEach((role, i) => {
//               $(`#edit-{{ userform.roles.id }}`).dropdown('set selected', role.id);
//             });
//             //$('#edit-active').prop("checked", !!u.active);
//             $('#edit-email_confirmed').prop("checked", !!u.email_confirmed_at); // convert date to bool
//             $('#edit-submit').data('user-id', u.id);
//             $('#modal-edit').modal('show');
//           });
$('#modal-edit').modal('show');