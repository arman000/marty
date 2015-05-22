describe 'Marty::AuthApp', ->
  it 'logs the marty user in', (done) ->
    click button 'Sign in'
    fill textfield('login'), with: 'marty'
    fill textfield('password'), with: 'marty'
    click button 'OK'
    done()
