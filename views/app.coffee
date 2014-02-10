app = angular.module 'app', ['ngResource']

app.controller 'IndexController', ($scope, $http) ->
  $scope.login = () ->
    return false if $scope.done || $scope.loading
    $scope.loading = true
    $http.post('/login', mail: $scope.mail)
    .success () ->
        $scope.success = true
        $scope.error = false
        $scope.loading = false
    .error () ->
        $scope.success = false
        $scope.error = true
        $scope.loading = false
    return false

app.controller 'ApplicationController', ($scope, $http, $resource, $q) ->
  Contact = $resource '/contact'
  ContactItem__c = $resource '/contact_item/:Id', Id: '@Id'

  initial_loading =
    contact: $q.defer()
    contact_items: $q.defer()
  $q.all(initial_loading.contact, initial_loading.contact_items)
  .then () ->
      $scope.loading = false
  .catch () ->
      location.href = '/'

  $scope.loading = true

  $scope.contact = Contact.get()
  $scope.contact.$promise
  .then () ->
      initial_loading.contact.resolve()
  .catch () ->
      initial_loading.contact.reject()

  $scope.contact_items = ContactItem__c.query()
  $scope.contact_items.$promise
  .then () ->
      initial_loading.contact_items.resolve()
  .catch () ->
      initial_loading.contact_items.reject()

  $scope.save_contact = () ->
    return false if $scope.loading
    $scope.loading = true
    $scope.contact.$save()
    .finally () ->
        $scope.loading = false

  $scope.editing = {}
  $scope.edit = (e) ->
    $scope.editing =
      work: new ContactItem__c(e)
      target: e
    $('#modal').modal 'show'
    return false

  $scope.delete = (e) ->
    return false if $scope.loading
    $scope.loading = true
    e.$delete()
    .then () ->
        i = $scope.contact_items.indexOf e
        $scope.contact_items.splice i, 1 if i != -1
    .catch () ->
        $scope.error = true
    .finally () ->
        $scope.loading = false

  $scope.finish_editing = () ->
    return false if $scope.loading
    $scope.loading = true
    $scope.editing.work.$save()
    .then () ->
        i = $scope.contact_items.indexOf $scope.editing.target
        if i == -1
          $scope.contact_items.push $scope.editing.work
        else
          $scope.contact_items[i] = $scope.editing.work
        $('#modal').modal 'hide'
    .catch () ->
        $scope.error = true
    .finally () ->
        $scope.loading = false
