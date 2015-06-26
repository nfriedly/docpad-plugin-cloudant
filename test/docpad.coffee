require('dotenv').load({path: __dirname + "/.env"})

module.exports =
  plugins:
    cloudant:
      collections: [{
        cloudantConfig: {url: process.env.CLOUDANT_URL}
        dbName: 'test_data'
      },{
        cloudantConfig: {url: process.env.CLOUDANT_URL}
        dbName: 'test_data'
        collectionName: 'view_test'
        viewDocument:
          _id: "_design/design_doc"
          views:
            test_view:
              # the map function is sent to couchdb as a string.. but you can just wrap a regular function in parenthesis and call .toString() on it ;)
              map: ((doc) ->
                if doc._id is "1"
                  emit "view-" + doc._id, { # note: docpad can only have one document per id. If documents show up in two different views with the same ID, they will be merged in docpad
                    title: doc.title,
                    extra: "extra data from view"
                  }
                ).toString()
      }]
