require('dotenv').load({path: __dirname + "/.env"})

module.exports =
  plugins:
    cloudant:
      collections: [
        cloudantConfig: {url: process.env.CLOUDANT_URL}
        dbName: 'test_data'
#        injectDocumentHelper: (doc) ->
#          doc.setMeta({'_rev': '1'})
#          doc.set({'_rev': '1'})
#          attributes = doc.getMeta('attributes')
#          attributes._rev = 1
#          doc.setMeta({attributes})
#          require('fs').writeFileSync(__dirname + '/test-' + Math.random() + '.txt', require('util').inspect(doc) + '\n\ncontent: ' + doc.getContent() + '\n\outContent: ' + doc.getOutContent() + '\n\njson: ' + JSON.stringify(doc.toJSON(), null, '\t') )
      ]
