# Prepare
Cloudant = require("cloudant")
{TaskGroup} = require('taskgroup')
_ = require('lodash')

# Export
module.exports = (BasePlugin) ->
  # Define
  class CloudantPlugin extends BasePlugin
    # Name
    name: 'cloudant'

    # Config
    config:
      collectionDefaults:
        cloudantConfig: {}
        relativeDirPath: null # defaults to collectionName
        extension: ".json"
        injectDocumentHelper: null
        dbName: "cloudant"
        meta: {}
        collectionName: null # defaults to dbName
        includeDesignDocs: false
        viewDocument: null # provide a view document to use
        alwaysReplaceViewDocument: false # useful to turn on while editing your design document
      collections: []

    # DocPad v6.24.0+ Compatible
    # Configuration
    setConfig: ->
      # Prepare
      super
      config = @getConfig()
      # Adjust
      config.collections = config.collections.map (collection) ->
        return _.defaults(collection, config.collectionDefaults)
      # Chain
      @

    getBasePath: (collectionConfig) ->
      "#{collectionConfig.relativeDirPath or collectionConfig.collectionName or collectionConfig.dbName}/"


    getDb: (collectionConfig, next) ->
      Cloudant collectionConfig.cloudantConfig, (err, cloudant) ->
        return next err if err
        next null, cloudant.use(collectionConfig.dbName)

    # Fetch our documents from cloudant
    fetchAllDocs: (collectionConfig, next) =>
      @getDb collectionConfig, (err, db) =>
        return next err if err
        db.list {include_docs:true}, (err, body) ->
          next err, body.rows.map (row) -> row.doc
      # Chain
      @

    fetchView: (collectionConfig, _next) =>
      @getDb collectionConfig, (err, db) ->
        return _next err if err

        next = (err, response) ->
          return _next(err) if err
          _next null, response.rows # note: this is a list of objects with {id, key, value: document} - we'll extract the document later, but we need the id for now

        viewDoc = collectionConfig.viewDocument
        designName = viewDoc._id.replace(/^_design\//, '')
        viewName = Object.keys(viewDoc.views)[0]

        createAndFetchView = (next) ->
          db.insert viewDoc, viewDoc._id, (err) ->
            return next(err) if (err)
            db.view designName, viewName, next

        deleteOldDoc = (next) ->
          # fetch the old doc so that we know what ref to delete
          db.get viewDoc._id, (err, oldViewDoc) ->
            if err
              if err.message is 'missing' or err.message is 'deleted'
                # this is a happy case: doc doesn't exist, so we can consider it deleted
                return next()
              else
                # if it's a different error, then we need to bail
                return next(err) if err
            db.destroy(viewDoc._id, oldViewDoc._rev, next)

        if collectionConfig.alwaysReplaceViewDocument
          deleteOldDoc (err) ->
            return next(err) if (err)
            createAndFetchView(next)
        else
          db.view designName, viewName, (err, response) ->
            if err and (err.message == 'missing' or err.message == 'deleted')
                createAndFetchView(next)
            else
              return next(err, response)

    # convert JSON doc from cloudant to DocPad-style document/file model
    # "body" of docpad doc is a JSON string of the mongo doc, meta includes all data in mongo doc
    toDocpadDoc: (collectionConfig, cloudantDoc, next) ->
      # Prepare
      docpad = @docpad

      if collectionConfig.viewDocument
        # when using a view, rather than using a field on the doc itself, we use the key that the map function emitted.
        # This is usually the document's ID, but it gives the designer flexibility to make it something else.
        id = cloudantDoc.key
        cloudantDoc = cloudantDoc.value
      else
        id = cloudantDoc._id

      documentAttributes =
        data: JSON.stringify(cloudantDoc, null, '\t')
        meta: _.defaults(
          {},
          collectionConfig.meta,

          cloudantId: id
          cloudantDb: collectionConfig.dbName
          # todo check for ctime/mtime/date/etc. fields and upgrade them to Date objects (?)
          relativePath: "#{@getBasePath(collectionConfig)}#{id}#{collectionConfig.extension}"
          original: cloudantDoc, # this gives the original document without DocPad overwriting certain fields

          cloudantDoc # this puts all of the document attributes into the metadata, but some will be overwritten
        )

      # Fetch docpad doc (if it already exists in docpad db, otherwise null)
      document = docpad.getFile({cloudantId:id})


      # Existing document
      if document?
        # todo: check mtime (if available) and return now for docs that haven't changed
        document.set(documentAttributes)

        # New Document
      else
        # Create document from opts
        document = docpad.createDocument(documentAttributes)

      # Inject document helper
      collectionConfig.injectDocumentHelper?.call(@, document)

      # Load the document
      document.action 'load', (err) ->
        # Check
        return next(err, document)  if err

        # Add it to the database (with b/c compat)
        docpad.addModel?(document) or docpad.getDatabase().add(document)

        # Complete
        next(null, document)

      # Return the document
      document

    importDb: (collectionConfig, next) ->
      docpad = @docpad
      plugin = @

      fetcher = if collectionConfig.viewDocument then plugin.fetchView else plugin.fetchAllDocs
      fetcher collectionConfig, (err, cloudantDocs) ->
        return next(err) if err

        isntDesign = (doc) ->
          return doc._id?.substr(0,8) isnt '_design/'

        cloudantDocs = cloudantDocs.filter(isntDesign) unless collectionConfig.includeDesignDocs

        docpad.log('debug', "Retrieved #{cloudantDocs.length} documents from Cloudant db #{collectionConfig.dbName}, converting to DocPad docs...")

        collectionDocs = [];

        docTasks  = new TaskGroup({concurrency:1}).done (err) ->
          return next(err) if err
          docpad.log('debug', "Converted #{cloudantDocs.length} Coudant documents into DocPad docs...")
          next(null, collectionDocs)

        cloudantDocs.forEach (cloudantDoc) ->
          docTasks.addTask (complete) ->
            docpad.log('debug', "Inserting #{cloudantDoc._id} into DocPad database...")
            plugin.toDocpadDoc collectionConfig, cloudantDoc, (err, doc) ->
              return complete(err) if err
              docpad.log('debug', 'inserted')
              collectionDocs.push(doc)
              complete()

        docTasks.run()

    # =============================
    # Events

    # Populate Collections
    # Import MongoDB Data into the Database
    populateCollections: (opts, next) ->
      # Prepare
      plugin = @
      docpad = @docpad
      config = @getConfig()

      # Log
      docpad.log('info', "Importing Cloudant db(s) into DocPad...")

      # concurrency:0 means run all tasks simultaneously
      collectionTasks = new TaskGroup({concurrency:0}).done next

      config.collections.forEach (collectionConfig) ->
        collectionTasks.addTask (complete) ->
          plugin.importDb collectionConfig, (err, docs) ->
            complete(err) if err

            collectionName = collectionConfig.collectionName or collectionConfig.dbName

            # Set the collection
            docpad.setCollection(collectionName, new docpad.FilesCollection(docs))

            docpad.log('info', "Created DocPad collection \"#{collectionName}\" with #{docs.length} documents from Cloudant")
            complete()
      collectionTasks.run()

      # Chain
      @
