describe 'Marty::PromiseView', ->
  it 'sees two jobs then filters down to one when searched', (done) ->
    wait ->
      expect(grid().getStore().getCount()).to.eql 2
      fill textfield('live_search_text'), with: 'marty'
      wait 1000, ->
        expect(grid().getStore().getCount()).to.eql 1
        done()
