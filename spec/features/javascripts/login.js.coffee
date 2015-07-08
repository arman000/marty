describe 'Marty::AuthApp', ->
  it 'logs the marty user in', (done) ->
    Netzke.page.martyAuthApp.authSpecMode = true
    click button 'Sign in'
    fill textfield('login'), with: 'marty'
    fill textfield('password'), with: 'marty'
    click button 'OK'
    done()
